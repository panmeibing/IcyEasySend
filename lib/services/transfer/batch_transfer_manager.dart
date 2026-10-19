import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../l10n/current_localizations.dart';
import '../../models/transfer_data.dart';
import '../../models/transfer_file_item.dart';
import '../../models/transfer_history.dart';
import '../../utils/constants.dart';
import '../../utils/error_messages.dart';
import '../../utils/hex_util.dart';
import '../../utils/http_helper.dart';
import '../../utils/log_util.dart';
import '../../utils/network_util.dart';
import '../../utils/operation_result.dart';
import '../../utils/peer_error.dart';
import '../../utils/transfer_status_provider.dart';
import '../preferences_service.dart';
import '../validation_service.dart';
import 'batch_progress.dart';
import 'file_sender.dart' as sender;
import 'health_checker.dart';
import 'transfer_cancellation.dart';
import 'transfer_history_manager.dart';
import 'transfer_request_builder.dart';

/// Manager for handling batch file transfers
class BatchTransferManager {
  final HealthChecker _healthChecker;
  final sender.FileSender _fileSender;
  final ValidationService _validationService;
  final PreferencesService _preferencesService;
  final TransferRequestBuilder _requestBuilder;
  final TransferHistoryManager _historyManager;
  final TransferStatusProvider _statusProvider;

  final String logTag = LogTags.transfer;

  BatchTransferManager({
    HealthChecker? healthChecker,
    sender.FileSender? fileSender,
    ValidationService? validationService,
    PreferencesService? preferencesService,
    TransferRequestBuilder? requestBuilder,
    TransferHistoryManager? historyManager,
    TransferStatusProvider? statusProvider,
  }) : _healthChecker = healthChecker ?? HealthChecker(),
       _fileSender = fileSender ?? sender.FileSender(),
       _validationService = validationService ?? ValidationService(),
       _preferencesService = preferencesService ?? PreferencesService(),
       _requestBuilder = requestBuilder ?? TransferRequestBuilder(),
       _historyManager = historyManager ?? TransferHistoryManager(),
       _statusProvider = statusProvider ?? TransferStatusProvider();

  /// Send multiple files with batch confirmation
  Future<Map<String, OperationResult<TransferData>>> sendFilesWithBatchConfirm({
    required String targetIP,
    required List<TransferFileItem> files,
    String? secretKey,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
    void Function(
      int fileIndex,
      double progress,
      int bytesTransferred,
      int totalBytes,
    )?
    onFileProgress,
    void Function(String status)? onStatusChange,
    VoidCallback? onHistoryUpdated,
    TransferCancellation? cancellation,
  }) async {
    final results = <String, OperationResult<TransferData>>{};

    if (files.isEmpty) {
      return results;
    }

    try {
      // Step 1: Health check
      onStatusChange?.call(_statusProvider.checkingTargetDevice);
      final healthResult = await _healthChecker.checkHealth(targetIP);
      if (!healthResult.isSuccess) {
        for (final item in files) {
          results[item.transferName] = OperationResult.failure(
            _statusProvider.targetDeviceError(healthResult.errorMessage ?? ''),
          );
        }
        return results;
      }

      // Step 2: Prepare sender info
      onStatusChange?.call(_statusProvider.preparingTransferInfo);
      final senderIP = await NetworkUtil.getLocalIPAddress();
      String? deviceName = await _preferencesService.getDeviceName();
      if (deviceName == null || deviceName.isEmpty) {
        deviceName = await NetworkUtil.getDeviceName();
      }

      // Step 3: Validate files and prepare file list
      final fileList = <Map<String, dynamic>>[];
      final fileSizes = <String, int>{};

      final validationResults = await _validationService
          .validateFilesForSending(files);

      for (final entry in validationResults.entries) {
        final fileName = entry.key;
        final validationResult = entry.value;

        if (!validationResult.isSuccess) {
          results[fileName] = OperationResult.failure(
            validationResult.errorMessage!,
          );
          cancellation?.markFinished(fileName);
          continue;
        }

        final fileData = validationResult.data!;
        fileSizes[fileName] = fileData.fileSize;
        fileList.add({
          'fileName': fileData.fileName,
          'fileSize': fileData.fileSize,
        });
      }

      if (fileList.isEmpty) {
        return results;
      }

      void cancelRemaining() {
        for (final fileData in fileList) {
          results[fileData['fileName'] as String] = OperationResult.failure(
            ErrorMessages.transferCancelled,
          );
        }
      }

      if (cancellation?.isAborted ?? false) {
        cancelRemaining();
        return results;
      }

      // Step 4: Send batch confirmation request
      onStatusChange?.call(
        _statusProvider.waitingForReceiverConfirmFiles(fileList.length),
      );

      // Lets the sender withdraw the request while the receiver is still
      // looking at it, before any transfer ID exists to name the files by.
      final requestId = HexUtil.random(16);
      final confirmUrl = _requestBuilder.buildBatchConfirmationUrl(targetIP);
      final confirmBody = jsonEncode({
        'files': fileList,
        'senderIP': senderIP,
        'senderDeviceName': deviceName,
        'requestId': requestId,
      });

      LogUtil.iTag(
        logTag,
        "sendFilesWithBatchConfirm() confirmUrl: [$confirmUrl], confirmBody: [$confirmBody]",
      );

      // Add secret key to headers if provided
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (secretKey != null && secretKey.isNotEmpty) {
        headers['X-Secret-Key'] = secretKey;
      }

      final confirmRequest = HttpHelper.post(
        confirmUrl,
        headers: headers,
        body: confirmBody,
        timeout: AppConstants.confirmTimeout,
      );
      final confirmResult = cancellation == null
          ? await confirmRequest
          : await cancellation.unlessAborted(confirmRequest);

      if (confirmResult == null) {
        LogUtil.iTag(logTag, '等待接收方确认时已取消，撤回请求');
        unawaited(_withdrawRequest(targetIP, requestId));
        cancelRemaining();
        return results;
      }

      if (!confirmResult.isSuccess) {
        final errorMsg = confirmResult.errorMessage!;
        LogUtil.eTag(logTag, errorMsg);
        for (final fileData in fileList) {
          results[fileData['fileName'] as String] = OperationResult.failure(
            errorMsg,
          );
        }
        return results;
      }

      final confirmResponse = confirmResult.data!;

      LogUtil.dTag(
        logTag,
        "sendFilesWithBatchConfirm() confirmResponse statusCode: ${confirmResponse.statusCode}, Body: ${confirmResponse.body}",
      );

      if (!HttpHelper.isSuccessResponse(confirmResponse)) {
        final errorMsg = HttpHelper.extractErrorMessage(
          confirmResponse,
          _statusProvider.receiverRejectedWithStatus(
            confirmResponse.statusCode,
          ),
        );
        LogUtil.eTag(logTag, errorMsg);

        for (final fileData in fileList) {
          results[fileData['fileName'] as String] = OperationResult.failure(
            errorMsg,
          );
        }
        return results;
      }

      // Parse confirmation response
      final parseResult = HttpHelper.parseJsonResponse(confirmResponse);
      if (!parseResult.isSuccess) {
        final errorMsg = parseResult.errorMessage!;
        LogUtil.eTag(logTag, errorMsg);
        for (final fileData in fileList) {
          results[fileData['fileName'] as String] = OperationResult.failure(
            errorMsg,
          );
        }
        return results;
      }

      final confirmData = parseResult.data!;

      if (confirmData['accepted'] != true) {
        final errorMsg = PeerError.describeBody(
          confirmData,
          _statusProvider.receiverRejected,
        );
        for (final fileData in fileList) {
          results[fileData['fileName'] as String] = OperationResult.failure(
            errorMsg,
          );
        }
        return results;
      }

      final transferIds = Map<String, String>.from(
        confirmData['transferIds'] as Map,
      );

      cancellation?.onChanged = (names) {
        unawaited(_notifyPeerCancelled(targetIP, names, transferIds));
      };
      final alreadyCancelled = cancellation?.cancelled ?? const <String>{};
      if (alreadyCancelled.isNotEmpty) {
        unawaited(
          _notifyPeerCancelled(targetIP, alreadyCancelled, transferIds),
        );
      }

      // Step 5: Send files with concurrent control
      await _sendFilesWithConcurrency(
        files: files,
        transferIds: transferIds,
        targetIP: targetIP,
        senderIP: senderIP,
        deviceName: deviceName,
        secretKey: secretKey,
        fileSizes: fileSizes,
        results: results,
        onProgress: onProgress,
        onFileProgress: onFileProgress,
        onStatusChange: onStatusChange,
        cancellation: cancellation,
      );

      // Step 6: Save all transfer histories in batch after all transfers complete
      await _saveBatchTransferHistories(
        files: files,
        results: results,
        fileSizes: fileSizes,
        targetIP: targetIP,
        deviceName: deviceName,
      );

      // Step 7: Trigger history refresh callback
      onHistoryUpdated?.call();

      return results;
    } catch (e) {
      LogUtil.eTag(logTag, "sendFilesWithBatchConfirm() ${e.toString()}");
      for (final item in files) {
        if (!results.containsKey(item.transferName)) {
          results[item.transferName] = OperationResult.failure(
            'Unexpected error: ${e.toString()}',
          );
        }
      }
      return results;
    }
  }

  /// Send files with concurrency control
  Future<void> _sendFilesWithConcurrency({
    required List<TransferFileItem> files,
    required Map<String, String> transferIds,
    required String targetIP,
    required String senderIP,
    String? deviceName,
    String? secretKey,
    required Map<String, int> fileSizes,
    required Map<String, OperationResult<TransferData>> results,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
    void Function(
      int fileIndex,
      double progress,
      int bytesTransferred,
      int totalBytes,
    )?
    onFileProgress,
    void Function(String status)? onStatusChange,
    TransferCancellation? cancellation,
  }) async {
    final concurrentCount = max(
      1,
      await _preferencesService.getConcurrentTransfers(),
    );

    final validFileIndices = <int>[];
    for (int i = 0; i < files.length; i++) {
      if (transferIds.containsKey(files[i].transferName)) {
        validFileIndices.add(i);
      } else {
        cancellation?.markFinished(files[i].transferName);
      }
    }

    final progress = BatchProgress({
      for (final i in validFileIndices)
        i: fileSizes[files[i].transferName] ?? 0,
    });
    void reportOverall() {
      onProgress?.call(
        progress.fraction,
        progress.sentBytes,
        progress.totalBytes,
      );
    }

    // Function to send a single file with timeout protection
    Future<OperationResult<TransferData>> sendFile(int fileIndex) async {
      final item = files[fileIndex];
      final file = item.file;
      final fileName = item.transferName;

      if (results.containsKey(fileName)) {
        return results[fileName]!;
      }

      final transferId = transferIds[fileName];
      if (transferId == null) {
        return OperationResult.failure(_statusProvider.transferIdNotFound);
      }

      if (cancellation?.isCancelled(fileName) ?? false) {
        return OperationResult.failure(ErrorMessages.transferCancelled);
      }

      onStatusChange?.call(
        _statusProvider.transferringFile(fileIndex + 1, files.length, fileName),
      );

      try {
        // The sender future returns only after its socket is closed. A timeout
        // wrapped around it used to mark the file failed and free this slot
        // while the upload was still running, so the next wave stacked more
        // connections on top of the ones that had already stalled.
        final result = await _fileSender.sendFileWithTransferId(
          targetIP: targetIP,
          file: file,
          transferId: transferId,
          senderIP: senderIP,
          deviceName: deviceName,
          secretKey: secretKey,
          transferName: fileName,
          cancellation: cancellation,
          onProgress: (fraction, bytes, total) {
            onFileProgress?.call(fileIndex, fraction, bytes, total);
            progress.update(fileIndex, bytes);
            reportOverall();
          },
        );

        return result;
      } catch (e) {
        // Catch any unexpected errors to prevent Future from hanging
        LogUtil.eTag(logTag, 'Unexpected error sending file $fileName: $e');
        return OperationResult.failure(appText.unexpectedError('$e'));
      }
    }

    // A pool rather than waves: a slot frees up the moment its file ends, so
    // one slow file holds one slot instead of the whole next wave.
    var next = 0;
    Future<void> worker() async {
      while (next < validFileIndices.length) {
        final fileIndex = validFileIndices[next++];
        final fileName = files[fileIndex].transferName;
        OperationResult<TransferData> result;
        try {
          result = await sendFile(fileIndex);
        } catch (error) {
          LogUtil.eTag(logTag, 'Error in batch transfer for $fileName: $error');
          result = OperationResult.failure(appText.unexpectedError('$error'));
        }
        results[fileName] = result;
        progress.settle(fileIndex, success: result.isSuccess);
        reportOverall();
      }
    }

    await Future.wait([
      for (var i = 0; i < min(concurrentCount, validFileIndices.length); i++)
        worker(),
    ]);
  }

  Future<void> _notifyPeerCancelled(
    String targetIP,
    Set<String> names,
    Map<String, String> transferIds,
  ) async {
    final ids = <String>[
      for (final name in names)
        if (transferIds[name] != null) transferIds[name]!,
    ];
    if (ids.isEmpty) return;
    try {
      await HttpHelper.post(
        _requestBuilder.buildBatchCancelUrl(targetIP),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'transferIds': ids}),
        timeout: const Duration(seconds: 3),
      );
    } catch (e) {
      LogUtil.wTag(logTag, '通知对端取消失败: $e');
    }
  }

  /// Takes back a confirmation request the receiver may still be showing.
  ///
  /// The empty ID list keeps older receivers, which only know `transferIds`,
  /// from rejecting the body.
  Future<void> _withdrawRequest(String targetIP, String requestId) async {
    try {
      await HttpHelper.post(
        _requestBuilder.buildBatchCancelUrl(targetIP),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'transferIds': <String>[], 'requestId': requestId}),
        timeout: const Duration(seconds: 3),
      );
    } catch (e) {
      LogUtil.wTag(logTag, '撤回确认请求失败: $e');
    }
  }

  /// Save all transfer histories in batch after transfers complete
  /// This prevents concurrent write conflicts to the history file
  Future<void> _saveBatchTransferHistories({
    required List<TransferFileItem> files,
    required Map<String, OperationResult<TransferData>> results,
    required Map<String, int> fileSizes,
    required String targetIP,
    String? deviceName,
  }) async {
    try {
      final histories = <TransferHistory>[];

      for (final item in files) {
        final result = results[item.transferName];

        if (result != null) {
          // The size measured before sending. Reading it again would throw
          // for a file deleted since, and lose the whole batch's history.
          final fileSize =
              fileSizes[item.transferName] ?? await _lengthOrZero(item.file);
          final history = _historyManager.createTransferHistory(
            fileName: item.transferName,
            fileSize: fileSize,
            targetIP: targetIP,
            success: result.isSuccess,
            isReceived: false,
            deviceName: deviceName,
            savedPath: result.isSuccess ? result.data?.savedPath : null,
          );
          histories.add(history);
        }
      }

      // Save all histories in one batch operation
      if (histories.isNotEmpty) {
        await _historyManager.saveTransferHistoryBatch(histories);
        LogUtil.iTag(logTag, '批量保存了 ${histories.length} 条传输历史记录');
      }
    } catch (e) {
      LogUtil.eTag(logTag, '批量保存传输历史失败: $e');
    }
  }

  static Future<int> _lengthOrZero(File file) async {
    try {
      return await file.length();
    } on FileSystemException {
      return 0;
    }
  }
}
