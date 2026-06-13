import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../../models/transfer_data.dart';
import '../../utils/constants.dart';
import '../../utils/error_messages.dart';
import '../../utils/log_util.dart';
import '../../utils/operation_result.dart';
import 'transfer_request_builder.dart';

/// Service for sending files to target devices
class FileSender {
  final TransferRequestBuilder _requestBuilder;
  final String logTag = LogTags.transfer;

  FileSender({TransferRequestBuilder? requestBuilder})
    : _requestBuilder = requestBuilder ?? TransferRequestBuilder();

  /// Send a file with a pre-obtained transfer ID
  ///
  /// Note: This method does NOT save transfer history.
  /// The caller is responsible for collecting results and saving history in batch.
  ///
  /// Progress reporting semantics:
  ///   0%–99% → data is being written to the OS TCP send buffer (streaming phase)
  ///   99%    → all data has been handed to the OS; waiting for the receiver to
  ///            finish writing and acknowledge via HTTP 200
  ///   100%   → receiver confirmed successful receipt (HTTP 200 OK received)
  ///
  /// This prevents the classic race condition where the sender hits 100% while the
  /// receiver has not yet started, because [request.sink.add] only puts bytes into
  /// the OS send buffer — not into the receiver's disk.
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
      return OperationResult.failure('无法读取文件大小: ${e.toString()}');
    }

    LogUtil.iTag(
      logTag,
      "sendFileWithTransferId() transferId: [$transferId], targetIP: [$targetIP], fileSize: [$fileSize], fileName: [$fileName]",
    );

    http.StreamedRequest? request;

    try {
      request = _requestBuilder.buildTransferRequest(
        targetIP: targetIP,
        fileName: fileName,
        fileSize: fileSize,
        senderIP: senderIP,
        deviceName: deviceName,
        transferId: transferId,
        secretKey: secretKey,
      );

      final responseFuture = request.send();

      // Stream file bytes into the request body.
      // Progress is capped at 99% here — the remaining 1% is awarded only after
      // the receiver sends HTTP 200, ensuring both sides finish at roughly the
      // same time from the user's perspective.
      await _streamFileData(
        file: file,
        fileSize: fileSize,
        request: request,
        onProgress: onProgress,
      );

      LogUtil.dTag(
        logTag,
        'All bytes handed to OS TCP buffer for $fileName; waiting for receiver ACK...',
      );

      final streamedResponse = await _waitForServerResponse(
        responseFuture: responseFuture,
        fileSize: fileSize,
      );

      final responseBody = await streamedResponse.stream.bytesToString();
      final result = await _handleTransferResponse(
        statusCode: streamedResponse.statusCode,
        responseBody: responseBody,
        fileName: fileName,
        fileSize: fileSize,
        targetIP: targetIP,
        deviceName: deviceName,
      );

      // Report 100% only after the receiver has confirmed success.
      // For failures, leave progress at the last streamed value so the UI can
      // show an error state instead of a misleading "complete" bar.
      if (result.isSuccess) {
        onProgress?.call(1.0, fileSize, fileSize);
      }

      return result;
    } on TimeoutException catch (e) {
      LogUtil.eTag(logTag, 'Timeout sending file $fileName: ${e.toString()}');
      return OperationResult.failure('文件传输超时');
    } on SocketException catch (e) {
      LogUtil.eTag(
        logTag,
        'Socket error sending file $fileName: ${e.toString()}',
      );
      return OperationResult.failure('网络连接失败\n错误: ${e.message}');
    } on FileSystemException catch (e) {
      LogUtil.eTag(logTag, 'File system error for $fileName: ${e.toString()}');
      return OperationResult.failure('文件访问错误: ${e.message}');
    } on http.ClientException catch (e) {
      LogUtil.eTag(logTag, 'HTTP client error for $fileName: ${e.toString()}');
      return OperationResult.failure('网络请求失败: ${e.message}');
    } catch (e, stackTrace) {
      LogUtil.eTag(
        logTag,
        'Unexpected error sending file $fileName: ${e.toString()}',
        e,
        stackTrace,
      );
      return OperationResult.failure(
        ErrorMessages.unexpectedError(e.toString()),
      );
    }
  }

  /// Stream file data into the HTTP request body with progress tracking.
  ///
  /// **Important**: progress is intentionally capped at [_kStreamingProgressCap]
  /// (99%). The final 1% is only emitted by the caller ([sendFileWithTransferId])
  /// after a successful HTTP 200 response from the receiver. This is necessary
  /// because [request.sink.add] merely hands bytes to the OS TCP send buffer;
  /// the actual on-wire transfer (and the receiver writing to disk) happens
  /// asynchronously afterwards. Without this cap the sender would show 100%
  /// while the receiver has not yet started.
  static const double _kStreamingProgressCap = 0.99;

  Future<void> _streamFileData({
    required File file,
    required int fileSize,
    required http.StreamedRequest request,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
  }) async {
    int bytesSent = 0;
    Stream<List<int>>? fileStream;

    try {
      // Handle empty files (0 bytes): skip streaming, report 0% here and let
      // the caller report 100% after the server ACK.
      if (fileSize == 0) {
        onProgress?.call(0.0, 0, 0);
        await request.sink.close();
        return;
      }

      fileStream = file.openRead();

      await for (final chunk in fileStream) {
        request.sink.add(chunk);
        bytesSent += chunk.length;

        // Cap at 99% — the remaining 1% is awarded by the caller once the
        // receiver has confirmed successful receipt via HTTP 200.
        final rawProgress = bytesSent / fileSize;
        final cappedProgress = rawProgress * _kStreamingProgressCap;
        onProgress?.call(cappedProgress, bytesSent, fileSize);
      }

      await request.sink.close();
    } catch (e) {
      LogUtil.eTag(logTag, 'Error streaming file data: ${e.toString()}');
      try {
        await request.sink.close();
      } catch (closeError) {
        // Ignore close errors
        LogUtil.wTag(
          logTag,
          'Error closing request sink: ${closeError.toString()}',
        );
      }
      rethrow;
    }
  }

  /// Wait for server response after file transfer
  Future<http.StreamedResponse> _waitForServerResponse({
    required Future<http.StreamedResponse> responseFuture,
    required int fileSize,
  }) async {
    final timeout =
        Duration(seconds: fileSize ~/ (AppConstants.bytesPerMB)) +
        Duration(seconds: AppConstants.requestTimeout);
    return await responseFuture.timeout(timeout);
  }

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
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        return OperationResult.failure(data['message'] as String? ?? '文件传输失败');
      } catch (e) {
        LogUtil.eTag(logTag, e.toString());
        return OperationResult.failure('文件传输失败\n状态码: $statusCode');
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
      return OperationResult.failure('无法解析响应\n错误: $e');
    }
  }
}
