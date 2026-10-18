import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as path;

import '../../models/transfer_data.dart';
import '../../utils/constants.dart';
import '../../utils/error_messages.dart';
import '../../utils/http_helper.dart';
import '../../utils/log_util.dart';
import '../../utils/operation_result.dart';
import '../../utils/peer_error.dart';
import 'transfer_cancellation.dart';
import 'transfer_http.dart';
import 'transfer_request_builder.dart';

/// Service for sending files to target devices
class FileSender {
  final TransferRequestBuilder _requestBuilder;
  final Dio Function(int fileSize)? _dioFactory;
  final Duration? _stallTimeout;
  final Duration? _ackTimeout;
  final String logTag = LogTags.transfer;

  FileSender({
    TransferRequestBuilder? requestBuilder,
    Dio Function(int fileSize)? dioFactory,
    Duration? stallTimeout,
    Duration? ackTimeout,
  }) : _requestBuilder = requestBuilder ?? TransferRequestBuilder(),
       _dioFactory = dioFactory,
       _stallTimeout = stallTimeout,
       _ackTimeout = ackTimeout;

  /// Send a file with a pre-obtained transfer ID
  ///
  /// Note: This method does NOT save transfer history.
  /// The caller is responsible for collecting results and saving history in batch.
  ///
  /// Progress reporting semantics:
  ///   0%–99% → bytes actually sent by Dio ([onSendProgress])
  ///   99%    → all data has been sent; waiting for the receiver to finish
  ///            writing and acknowledge via HTTP 200; bounded by the ACK
  ///            timeout because no progress can be observed here
  ///   100%   → receiver confirmed successful receipt (HTTP 200 OK received)
  Future<OperationResult<TransferData>> sendFileWithTransferId({
    required String targetIP,
    required File file,
    required String transferId,
    required String senderIP,
    String? deviceName,
    String? secretKey,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
    String? transferName,
    TransferCancellation? cancellation,
  }) async {
    final fileName = transferName != null && transferName.isNotEmpty
        ? transferName
        : path.basename(file.path);
    int fileSize = 0;

    try {
      fileSize = await file.length();
    } catch (e) {
      LogUtil.eTag(
        logTag,
        'Failed to get file size for $fileName: ${e.toString()}',
      );
      return OperationResult.failure('${ErrorMessages.fileNotReadable}\n$e');
    }

    LogUtil.iTag(
      logTag,
      "sendFileWithTransferId() transferId: [$transferId], targetIP: [$targetIP], fileSize: [$fileSize], fileName: [$fileName]",
    );

    final stall = _stallTimeout ?? AppConstants.transferStallTimeout;
    final ack = _ackTimeout ?? AppConstants.transferAckTimeout;
    // No wall-clock body timeout. A slow link that keeps moving must be
    // allowed to finish; only a file that stops producing bytes is cancelled.
    final dio =
        _dioFactory?.call(fileSize) ??
        TransferHttp.createForUpload(fileSize, unbounded: true);
    final cancelToken = CancelToken();
    var settled = false;
    var stalled = false;
    var userCancelled = false;
    DateTime? fullyQueuedAt = fileSize == 0 ? DateTime.now() : null;
    var lastSent = 0;
    var lastProgressAt = DateTime.now();

    void cancelTransfer(String reason) {
      if (settled || cancelToken.isCancelled) return;
      if (reason == 'user') {
        userCancelled = true;
      } else {
        stalled = true;
      }
      LogUtil.wTag(logTag, 'Cancelling transfer $fileName ($reason)');
      try {
        cancelToken.cancel(reason);
      } catch (e) {
        LogUtil.wTag(logTag, 'Cancel already finished for $fileName: $e');
      }
      // abort() on the request does not discard bytes already in the kernel
      // send buffer. Closing the client forces the socket shut so the peer
      // stops receiving instead of draining that buffer.
      try {
        dio.close(force: true);
      } catch (e) {
        LogUtil.wTag(logTag, 'Error closing HTTP client for $fileName: $e');
      }
    }

    // Poll instead of arming a fresh timer on every chunk. The period stays
    // short enough that a test stall of a few hundred milliseconds still fires,
    // and long enough that a 30s production stall is not a busy loop.
    cancellation?.attach(fileName, () => cancelTransfer('user'));

    final watchdog = Timer.periodic(
      _watchdogPeriod(stall < ack ? stall : ack),
      (_) {
        if (settled || cancelToken.isCancelled) return;
        final now = DateTime.now();
        final queuedAt = fullyQueuedAt;
        if (queuedAt != null) {
          if (now.difference(queuedAt) >= ack) cancelTransfer('ack timeout');
        } else if (now.difference(lastProgressAt) >= stall) {
          cancelTransfer('stall');
        }
      },
    );

    try {
      final uri = _requestBuilder.buildTransferUri(
        targetIP: targetIP,
        fileName: fileName,
        fileSize: fileSize,
        senderIP: senderIP,
        deviceName: deviceName,
        transferId: transferId,
      );
      final headers = _requestBuilder.buildTransferHeaders(
        fileSize: fileSize,
        secretKey: secretKey,
      );

      if (fileSize == 0) {
        onProgress?.call(0.0, 0, 0);
      }

      final response = await dio.post<String>(
        uri.toString(),
        data: fileSize == 0 ? const <int>[] : file.openRead(),
        cancelToken: cancelToken,
        options: Options(
          headers: headers,
          contentType: 'application/octet-stream',
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null,
        ),
        onSendProgress: fileSize == 0
            ? null
            : (sent, total) {
                if (sent > lastSent) {
                  lastSent = sent;
                  lastProgressAt = DateTime.now();
                }
                if (sent >= fileSize) fullyQueuedAt ??= DateTime.now();
                final effectiveTotal = total > 0 ? total : fileSize;
                final rawProgress = sent / effectiveTotal;
                final cappedProgress = rawProgress * _kStreamingProgressCap;
                onProgress?.call(cappedProgress, sent, effectiveTotal);
              },
      );

      LogUtil.dTag(
        logTag,
        'All bytes sent for $fileName; waiting for receiver ACK...',
      );

      final result = await _handleTransferResponse(
        statusCode: response.statusCode ?? 0,
        responseBody: response.data ?? '',
        fileName: fileName,
        fileSize: fileSize,
        targetIP: targetIP,
        deviceName: deviceName,
      );

      if (result.isSuccess) {
        onProgress?.call(1.0, fileSize, fileSize);
      }

      return result;
    } on DioException catch (e, stackTrace) {
      if (userCancelled) {
        return OperationResult.failure(ErrorMessages.transferCancelled);
      }
      if (stalled) {
        return OperationResult.failure(ErrorMessages.transferTimeout);
      }
      // Only a connection that got as far as the body can have been cut by
      // the receiver; asking an unreachable peer would just add a timeout.
      final reachedBody =
          e.type != DioExceptionType.connectionTimeout &&
          (e.type != DioExceptionType.connectionError || lastSent > 0);
      if (reachedBody && await _receiverCancelled(targetIP, transferId)) {
        LogUtil.iTag(logTag, '接收方已取消 $fileName');
        return OperationResult.failure(ErrorMessages.transferCancelled);
      }
      LogUtil.eTag(
        logTag,
        'Dio error sending file $fileName: ${e.message}',
        e,
        stackTrace,
      );
      return OperationResult.failure(
        TransferHttp.describeFailure(e, transport: TransferTransport.lan),
      );
    } on FileSystemException catch (e) {
      LogUtil.eTag(logTag, 'File system error for $fileName: ${e.toString()}');
      return OperationResult.failure(
        '${ErrorMessages.fileAccessError}\n${e.message}',
      );
    } catch (e, stackTrace) {
      LogUtil.eTag(
        logTag,
        'Unexpected error sending file $fileName: ${e.toString()}',
        e,
        stackTrace,
      );
      if (userCancelled) {
        return OperationResult.failure(ErrorMessages.transferCancelled);
      }
      if (stalled) {
        return OperationResult.failure(ErrorMessages.transferTimeout);
      }
      return OperationResult.failure(
        ErrorMessages.unexpectedError(e.toString()),
      );
    } finally {
      // The awaited future must not complete while the socket is still up.
      // Batch concurrency waits on this future; leaving the upload running
      // would let the next wave open more connections than configured.
      settled = true;
      cancellation?.markFinished(fileName);
      watchdog.cancel();
      try {
        dio.close(force: true);
      } catch (e) {
        LogUtil.wTag(logTag, 'Error closing HTTP client for $fileName: $e');
      }
    }
  }

  /// Whether a broken upload was the receiver calling the file off.
  ///
  /// The receiver answers 409 when it does, but it also closes the socket
  /// mid-body, and the write fails before that answer can be read. Older
  /// receivers have no such endpoint and come back as "no".
  Future<bool> _receiverCancelled(String targetIP, String transferId) async {
    final result = await HttpHelper.get(
      _requestBuilder.buildTransferStatusUrl(targetIP, transferId),
      timeout: const Duration(seconds: 3),
    );
    final response = result.data;
    if (!result.isSuccess || response == null || response.statusCode != 200) {
      return false;
    }
    try {
      final body = jsonDecode(response.body);
      return body is Map && body['state'] == 'cancelled';
    } catch (_) {
      return false;
    }
  }

  static Duration _watchdogPeriod(Duration stall) {
    final quarter = Duration(microseconds: stall.inMicroseconds ~/ 4);
    if (quarter < const Duration(milliseconds: 50)) {
      return const Duration(milliseconds: 50);
    }
    if (quarter > const Duration(seconds: 1)) {
      return const Duration(seconds: 1);
    }
    return quarter;
  }

  static const double _kStreamingProgressCap = 0.99;

  /// Handle server response
  Future<OperationResult<TransferData>> _handleTransferResponse({
    required int statusCode,
    required String responseBody,
    required String fileName,
    required int fileSize,
    required String targetIP,
    String? deviceName,
  }) async {
    if (statusCode != 200) {
      try {
        return OperationResult.failure(
          PeerError.describeBody(
            jsonDecode(responseBody),
            ErrorMessages.responseStatusCodeError(statusCode),
          ),
        );
      } catch (e) {
        LogUtil.eTag(logTag, e.toString());
        return OperationResult.failure(
          ErrorMessages.responseStatusCodeError(statusCode),
        );
      }
    }

    try {
      final data = jsonDecode(responseBody) as Map<String, dynamic>;
      final savedPath = data['savedPath'] as String?;

      return OperationResult.success(
        data: TransferData(savedPath: savedPath, bytesTransferred: fileSize),
      );
    } catch (e) {
      LogUtil.eTag(logTag, e.toString());
      return OperationResult.failure(ErrorMessages.responseParseError);
    }
  }
}
