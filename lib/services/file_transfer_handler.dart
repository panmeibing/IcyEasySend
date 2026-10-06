import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shelf/shelf.dart';

import '../l10n/current_localizations.dart';
import '../models/transfer_data.dart';
import '../models/transfer_history.dart';
import '../utils/constants.dart';
import '../utils/disk_space_error.dart';
import '../utils/error_messages.dart';
import '../utils/hex_util.dart';
import '../utils/log_util.dart';
import '../utils/operation_result.dart';
import '../utils/peer_error.dart';
import '../utils/server_http_util.dart';
import '../utils/transfer_path_util.dart';
import 'batch_receive_manager.dart';
import 'disk_full_notifier.dart';
import 'file_transfer_service.dart';
import 'secret_key_verifier.dart';
import 'transfer/transfer_history_manager.dart';
import 'user_notifier.dart';

/// Handler for file transfer endpoint
///
/// Provides a RESTful endpoint to receive files from other devices.
class FileTransferHandler {
  final BuildContext? Function()? contextGetter;
  final bool Function()? isInBackgroundGetter;
  final FileTransferService _fileTransferService;
  final BatchReceiveManager _batchReceiveManager;
  final TransferHistoryManager _historyManager;
  final SecretKeyVerifier _secretKeyVerifier;
  final VoidCallback? Function()? historyRefreshCallbackGetter;
  final String logTag = LogTags.server;

  /// Accepted files waiting for their `/transfer`, keyed by transfer ID.
  ///
  /// Each ticket is good once, for the file the user agreed to, from the
  /// address that asked.
  final Map<String, _Ticket> _tickets = {};

  /// Confirmation dialogs currently waiting on the local user.
  int _promptsOnScreen = 0;

  // Store progress callbacks for active transfers: transferId -> callback
  final Map<String, void Function(double, int, int)> _progressCallbacks = {};

  FileTransferHandler({
    this.contextGetter,
    this.isInBackgroundGetter,
    this.historyRefreshCallbackGetter,
    FileTransferService? fileTransferService,
    BatchReceiveManager? batchReceiveManager,
    TransferHistoryManager? historyManager,
    SecretKeyVerifier? secretKeyVerifier,
  }) : _fileTransferService = fileTransferService ?? FileTransferService(),
       _batchReceiveManager = batchReceiveManager ?? BatchReceiveManager(),
       _historyManager = historyManager ?? TransferHistoryManager(),
       _secretKeyVerifier = secretKeyVerifier ?? SecretKeyVerifier.instance;

  bool get _isInBackground => isInBackgroundGetter?.call() ?? false;

  /// Transfer IDs double as one-time tickets for `/transfer`, so they are
  /// random rather than built out of the sender IP, file name and clock, all
  /// of which are known to anyone who can see the traffic.
  static String _newTransferId() => HexUtil.random(16);

  /// Handle POST /batch-confirm-receive requests
  ///
  /// This endpoint is called BEFORE file transfer to ask user for confirmation of multiple files.
  /// Expects JSON body with:
  /// - files: array of file objects with fileName and fileSize
  /// - senderIP: IP address of the sender
  /// - senderDeviceName: (optional) name of the sender device
  ///
  /// Returns a JSON response with:
  /// - accepted: true if user accepted, false if rejected
  /// - transferIds: map of fileName -> transferId (if accepted)
  /// - message: error or success message
  Future<Response> handleBatchConfirmReceive(Request request) async {
    LogUtil.iTag(logTag, '收到批量确认请求: /batch-confirm-receive');
    _dropIdleBatches();

    try {
      final Object? decoded;
      try {
        decoded = await ServerHttpUtil.readJson(
          request,
          maxBytes: AppConstants.maxBatchConfirmBodyBytes,
        );
      } on RequestBodyTooLargeException catch (e) {
        LogUtil.wTag(logTag, '批量确认请求体过大: $e');
        return _confirmError(413, PeerError.badRequest);
      } on FormatException {
        LogUtil.wTag(logTag, '无效的JSON格式');
        return _confirmError(400, PeerError.badRequest);
      }
      if (decoded is! Map<String, dynamic>) {
        return _confirmError(400, PeerError.badRequest);
      }
      final body = decoded;

      final files = body['files'];
      final declaredSenderIP = body['senderIP'];
      final senderDeviceName = body['senderDeviceName'] as String?;
      final secretKey = request.headers['x-secret-key'];
      final remoteAddress = ServerHttpUtil.remoteAddress(request);

      if (files is! List || files.isEmpty) {
        LogUtil.wTag(logTag, '缺少文件列表参数');
        return _confirmError(400, PeerError.badRequest);
      }

      if (declaredSenderIP is! String || declaredSenderIP.isEmpty) {
        LogUtil.wTag(logTag, '缺少发送者IP参数');
        return _confirmError(400, PeerError.badRequest);
      }

      // Grouping, dialogs and history all key on where the request really
      // came from; the declared address is only a fallback for when the
      // connection does not say.
      final peer = remoteAddress ?? declaredSenderIP;

      LogUtil.dTag(
        logTag,
        '批量确认参数: 文件数=${files.length}, 发送方=$peer, 设备名=$senderDeviceName, '
        '秘钥=${secretKey != null ? "已提供" : "未提供"}, 后台=$_isInBackground',
      );

      final skipConfirmation = await _secretKeyVerifier.verify(
        secretKey,
        remoteAddress: remoteAddress,
      );
      if (skipConfirmation) {
        LogUtil.iTag(logTag, '秘钥验证通过，跳过确认对话框');
        final currentCtx = contextGetter?.call();
        if (!_isInBackground && currentCtx != null && currentCtx.mounted) {
          UserNotifier.instance.showSuccess(
            currentCtx,
            appText.filesReceivedWithSecretKey(
              senderDeviceName ?? peer,
              files.length,
            ),
          );
        }
      }

      final pendingFiles = <PendingFileInfo>[];
      final transferIds = <String, String>{};

      for (final fileData in files) {
        if (fileData is! Map) {
          continue;
        }
        final fileName = fileData['fileName'];
        // A JSON number is not guaranteed to decode as an int, so go through
        // num rather than letting a double blow up the whole batch.
        final fileSize = (fileData['fileSize'] as num?)?.toInt();

        if (fileName is! String || fileName.isEmpty || fileSize == null) {
          LogUtil.wTag(logTag, '跳过无效的文件条目: $fileData');
          continue;
        }

        // Rejected here as well as on /transfer so an oversized file never
        // reaches the confirmation dialog in the first place.
        if (fileSize < 0 || fileSize > AppConstants.maxFileSize) {
          LogUtil.wTag(logTag, '跳过大小超出允许范围的文件: $fileName, 大小=$fileSize');
          continue;
        }

        // The response maps names to tickets, so a repeated name would
        // silently take over the earlier entry's ticket.
        if (transferIds.containsKey(fileName)) {
          LogUtil.wTag(logTag, '跳过重复的文件条目: $fileName');
          continue;
        }

        final transferId = _newTransferId();
        transferIds[fileName] = transferId;
        pendingFiles.add(
          PendingFileInfo(
            fileName: fileName,
            fileSize: fileSize,
            transferId: transferId,
          ),
        );
      }

      if (pendingFiles.isEmpty) {
        LogUtil.wTag(logTag, '没有有效的文件');
        return _confirmError(400, PeerError.noValidFiles);
      }

      LogUtil.iTag(logTag, '处理批量接收确认: ${pendingFiles.length}个文件');

      final batch = _ReceiveBatch(
        peer: peer,
        confirmedFrom: remoteAddress,
        expected: pendingFiles.length,
      );
      final ctx = contextGetter?.call();
      final hasUi = ctx != null && ctx.mounted && !_isInBackground;

      bool accepted;
      if (skipConfirmation && !hasUi) {
        LogUtil.iTag(logTag, '密钥自动接受（无界面）');
        batch.flushOnFinish = true;
        batch.headless = true;
        accepted = await _batchReceiveManager.acceptBatchHeadless(
          files: pendingFiles,
          senderIP: peer,
        );
      } else if (!skipConfirmation && _isInBackground) {
        LogUtil.iTag(logTag, '应用在后台且无有效秘钥，拒绝批量接收');
        return _confirmError(403, PeerError.backgroundNeedsSecretKey);
      } else if (ctx == null || !ctx.mounted) {
        LogUtil.eTag(logTag, '无法显示确认对话框：缺少上下文');
        return _confirmError(500, PeerError.noUi);
      } else if (!skipConfirmation &&
          _promptsOnScreen >= AppConstants.maxPendingReceivePrompts) {
        LogUtil.wTag(logTag, '待确认的接收请求过多，拒绝来自 $peer 的请求');
        return _confirmError(429, PeerError.busy);
      } else {
        if (!skipConfirmation) _promptsOnScreen++;
        try {
          accepted = await _batchReceiveManager.requestBatchReceiveConfirmation(
            context: ctx,
            files: pendingFiles,
            senderIP: peer,
            senderDeviceName: senderDeviceName,
            autoAccept: skipConfirmation,
            onComplete: () async {
              await _flushHistories(batch);
              // Files still in flight when the dialog closed are saved once
              // the last of them lands.
              batch.flushOnFinish = true;
            },
          );
        } finally {
          if (!skipConfirmation) _promptsOnScreen--;
        }
      }

      if (!accepted) {
        LogUtil.iTag(logTag, '用户拒绝接收批量文件');
        return _confirmError(403, PeerError.declined);
      }

      for (final fileInfo in pendingFiles) {
        _tickets[fileInfo.transferId] = _Ticket(
          batch: batch,
          fileName: TransferPathUtil.normalizeTransferPath(fileInfo.fileName),
          fileSize: fileInfo.fileSize,
        );
        _progressCallbacks[fileInfo.transferId] =
            (progress, bytesReceived, totalBytes) {
              _batchReceiveManager.updateProgress(
                fileInfo.transferId,
                progress,
                bytesReceived,
                totalBytes,
              );
            };
      }

      LogUtil.iTag(logTag, '用户确认接收批量文件: ${pendingFiles.length}个文件');

      return ServerHttpUtil.json({
        'accepted': true,
        'transferIds': transferIds,
        'message': 'Accepted',
      });
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '批量确认接收处理异常: $e', e, stackTrace);
      return _confirmError(500, PeerError.internalError);
    }
  }

  /// Handle POST /transfer requests
  ///
  /// Expects metadata in query parameters:
  /// - fileName: name of the file
  /// - fileSize: size of the file in bytes
  /// - senderIP: IP address of the sender
  /// - transferId: transfer ID from confirm-receive response
  ///
  /// File data should be sent as raw binary in request body
  ///
  /// NOTE: User confirmation should be done via /batch-confirm-receive first
  Future<Response> handleFileTransfer(Request request) async {
    LogUtil.iTag(LogTags.transfer, '收到文件传输请求: /transfer');
    _dropIdleBatches();

    try {
      final queryParams = request.url.queryParameters;
      final fileName = queryParams['fileName'];
      final fileSizeStr = queryParams['fileSize'];
      final senderDeviceName = queryParams['senderDeviceName'];
      final transferId = queryParams['transferId'];

      LogUtil.dTag(
        LogTags.transfer,
        '传输参数: 文件=$fileName, 大小=$fileSizeStr, transferId=$transferId',
      );

      if (fileName == null || fileName.isEmpty) {
        return _transferError(400, PeerError.badRequest, '缺少文件名参数');
      }

      final fileSize = fileSizeStr == null ? null : int.tryParse(fileSizeStr);
      if (fileSize == null) {
        return _transferError(400, PeerError.badRequest, '文件大小参数格式错误');
      }

      // The sending side checks this too, but it is the side under the
      // attacker's control, so the receiving side cannot take its word for it.
      if (fileSize < 0 || fileSize > AppConstants.maxFileSize) {
        LogUtil.wTag(
          LogTags.transfer,
          '文件大小超出允许范围: $fileName, 大小=$fileSize, '
          '限制=${AppConstants.maxFileSize}',
        );
        return _transferError(413, PeerError.fileTooLarge, '文件大小超出允许范围');
      }

      if (transferId == null || transferId.isEmpty) {
        return _transferError(400, PeerError.notConfirmed, '缺少传输 ID 参数');
      }

      final ticket = _tickets[transferId];
      if (ticket == null) {
        LogUtil.wTag(LogTags.transfer, '未找到确认记录: $transferId');
        return _transferError(403, PeerError.notConfirmed, '未找到确认记录');
      }

      // Neither check below consumes the ticket: dropping it on a mismatch
      // would let a third party cancel a legitimate transfer just by aiming
      // at it.
      final batch = ticket.batch;
      final requestFrom = ServerHttpUtil.remoteAddress(request);
      if (batch.confirmedFrom != null && batch.confirmedFrom != requestFrom) {
        LogUtil.wTag(
          LogTags.transfer,
          '传输来源与确认来源不符，已拒绝: 确认自=${batch.confirmedFrom}, 实际来自=$requestFrom',
        );
        return _transferError(403, PeerError.sourceMismatch, '传输来源与确认来源不符');
      }

      // The user agreed to a particular name and size; a ticket is not a
      // licence to write something else.
      if (TransferPathUtil.normalizeTransferPath(fileName) != ticket.fileName ||
          fileSize != ticket.fileSize) {
        LogUtil.wTag(
          LogTags.transfer,
          '传输内容与确认内容不符，已拒绝: 确认=${ticket.fileName}/${ticket.fileSize}, '
          '实际=$fileName/$fileSize',
        );
        return _transferError(403, PeerError.contentMismatch, '传输内容与确认内容不符');
      }

      _tickets.remove(transferId);
      final progressCallback = _progressCallbacks.remove(transferId);

      LogUtil.iTag(
        LogTags.transfer,
        '开始接收文件流: $fileName, 大小=${(fileSize / AppConstants.bytesPerMB).toStringAsFixed(2)}MB',
      );

      batch.active++;
      batch.touch();
      final OperationResult<TransferData> receiveResult;
      try {
        receiveResult = await _fileTransferService.receiveFileDirectly(
          fileStream: request.read(),
          fileName: fileName,
          fileSize: fileSize,
          senderIP: batch.peer,
          senderDeviceName: senderDeviceName,
          onProgress: progressCallback,
        );
      } finally {
        batch.active--;
        batch.touch();
      }

      batch.results.add(
        _TransferMetadata(
          fileName: fileName,
          fileSize: fileSize,
          senderIP: batch.peer,
          senderDeviceName: senderDeviceName,
          success: receiveResult.isSuccess,
          savedPath: receiveResult.isSuccess
              ? receiveResult.data?.savedPath
              : null,
        ),
      );
      batch.finished++;
      LogUtil.dTag(
        LogTags.transfer,
        '文件传输进度: ${batch.finished}/${batch.expected} 来自 ${batch.peer}',
      );
      if (batch.isDone && batch.flushOnFinish) {
        LogUtil.iTag(LogTags.transfer, '所有文件已接收完成，保存批量历史记录');
        await _flushHistories(batch);
        if (batch.headless) {
          _batchReceiveManager.clearPendingForSender(batch.peer);
        }
      }

      if (!receiveResult.isSuccess) {
        LogUtil.wTag(
          LogTags.transfer,
          '文件接收失败: $fileName, 原因=${receiveResult.errorMessage}',
        );
        _batchReceiveManager.markTransferFailed(
          transferId,
          receiveResult.errorMessage ?? ErrorMessages.fileSaveFailed,
        );

        // A full disk fails every remaining file in the batch, so it is worth
        // interrupting the user rather than leaving the reason buried in the
        // per-file status line. Not awaited: the dialog lives until dismissed
        // and the sender is waiting on this response.
        if (receiveResult.isDiskFull) {
          unawaited(DiskFullNotifier().notify(contextGetter?.call()));
        }

        return _transferError(
          500,
          receiveResult.isDiskFull ? PeerError.diskFull : PeerError.saveFailed,
          '文件保存失败: ${receiveResult.errorMessage}',
        );
      }

      final savedPath = receiveResult.data?.savedPath;
      LogUtil.iTag(LogTags.transfer, '文件传输完成: $fileName, 保存路径=$savedPath');
      return ServerHttpUtil.json({
        'success': true,
        'message': 'Received',
        'savedPath': savedPath,
      });
    } catch (e, stackTrace) {
      LogUtil.eTag(LogTags.transfer, '文件传输处理异常: $e', e, stackTrace);
      return _transferError(500, PeerError.internalError, '文件传输处理异常');
    }
  }

  /// Saves whatever [batch] has received so far as history entries.
  Future<void> _flushHistories(_ReceiveBatch batch) async {
    if (batch.results.isEmpty) return;
    final histories = batch.results.map((m) => m.toTransferHistory()).toList();
    batch.results.clear();

    await _historyManager.saveTransferHistoryBatch(histories);
    LogUtil.dTag(
      logTag,
      '批量保存了 ${histories.length} 条接收历史记录 (来自 ${batch.peer})',
    );
    historyRefreshCallbackGetter?.call()?.call();
  }

  /// Forgets tickets of batches the sender has abandoned, so a confirmed
  /// batch cannot be redeemed indefinitely and never outlives its usefulness
  /// in memory.
  void _dropIdleBatches() {
    final now = DateTime.now();
    final stale = <_ReceiveBatch>{};
    _tickets.removeWhere((transferId, ticket) {
      final batch = ticket.batch;
      final idle =
          batch.active == 0 &&
          now.difference(batch.lastActivity) > AppConstants.receiveBatchIdleTtl;
      if (idle) {
        stale.add(batch);
        _progressCallbacks.remove(transferId);
      }
      return idle;
    });
    for (final batch in stale) {
      LogUtil.iTag(logTag, '丢弃长时间未使用的接收确认: ${batch.peer}');
      unawaited(_flushHistories(batch));
    }
  }

  Response _confirmError(int status, PeerError error) => ServerHttpUtil.json({
    'accepted': false,
    ...error.toJson(),
  }, status: status);

  /// [logMessage] stays on this device; the sender gets [error].
  Response _transferError(int status, PeerError error, String logMessage) {
    LogUtil.wTag(LogTags.transfer, logMessage);
    return ServerHttpUtil.json({
      'success': false,
      ...error.toJson(),
    }, status: status);
  }
}

/// One accepted `/batch-confirm-receive`, tracked until its files arrive.
class _ReceiveBatch {
  _ReceiveBatch({
    required this.peer,
    required this.confirmedFrom,
    required this.expected,
  });

  final String peer;

  /// Address the confirmation came from. Null means it could not be
  /// determined, in which case tickets are not bound to an address.
  final String? confirmedFrom;
  final int expected;

  int finished = 0;
  int active = 0;
  bool headless = false;

  /// Whether histories are saved as soon as the last file lands, rather than
  /// when a progress dialog closes.
  bool flushOnFinish = false;
  DateTime lastActivity = DateTime.now();
  final List<_TransferMetadata> results = [];

  bool get isDone => finished >= expected;

  void touch() => lastActivity = DateTime.now();
}

class _Ticket {
  _Ticket({
    required this.batch,
    required this.fileName,
    required this.fileSize,
  });

  final _ReceiveBatch batch;
  final String fileName;
  final int fileSize;
}

/// Internal class to store transfer metadata for batch history saving
class _TransferMetadata {
  final String fileName;
  final int fileSize;
  final String senderIP;
  final String? senderDeviceName;
  final bool success;
  final String? savedPath;

  _TransferMetadata({
    required this.fileName,
    required this.fileSize,
    required this.senderIP,
    this.senderDeviceName,
    required this.success,
    this.savedPath,
  });

  TransferHistory toTransferHistory() {
    return TransferHistory(
      fileName: fileName,
      fileSize: fileSize,
      peerIP: senderIP.split(':').first,
      peerDeviceName: senderDeviceName,
      timestamp: DateTime.now(),
      isReceived: true,
      success: success,
      savedPath: savedPath,
    );
  }
}
