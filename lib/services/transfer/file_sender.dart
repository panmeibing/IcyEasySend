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
  Future<OperationResult<TransferData>> sendFileWithTransferId({
    required String targetIP,
    required File file,
    required String transferId,
    required String senderIP,
    String? deviceName,
    String? secretKey,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
  }) async {
    final fileName = path.basename(file.path);
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

      await _streamFileData(
        file: file,
        fileSize: fileSize,
        request: request,
        onProgress: onProgress,
      );

      final streamedResponse = await _waitForServerResponse(
        responseFuture: responseFuture,
        fileSize: fileSize,
      );

      final responseBody = await streamedResponse.stream.bytesToString();
      return await _handleTransferResponse(
        statusCode: streamedResponse.statusCode,
        responseBody: responseBody,
        fileName: fileName,
        fileSize: fileSize,
        targetIP: targetIP,
        deviceName: deviceName,
      );
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

  /// Stream file data to server with progress tracking
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
      // Handle empty files (0 bytes)
      if (fileSize == 0) {
        // For empty files, immediately report 100% progress
        onProgress?.call(1.0, 0, 0);
        await request.sink.close();
        return;
      }

      fileStream = file.openRead();

      await for (final chunk in fileStream) {
        request.sink.add(chunk);
        bytesSent += chunk.length;

        final progress = bytesSent / fileSize;
        onProgress?.call(progress, bytesSent, fileSize);
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
