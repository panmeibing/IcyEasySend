import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../../utils/constants.dart';
import '../../utils/error_messages.dart';
import '../../utils/log_util.dart';
import '../../utils/operation_result.dart';
import '../preferences_service.dart';
import '../validation_service.dart';
import '../transfer_history_service.dart';
import 'health_checker.dart';
import 'transfer_history_manager.dart';
import 'transfer_request_builder.dart';

/// Service for sending files to target devices
class FileSender {
  final TransferHistoryManager _historyManager;
  final TransferRequestBuilder _requestBuilder;
  final String logTag = LogTags.transfer;

  FileSender({
    TransferHistoryService? historyService,
    TransferRequestBuilder? requestBuilder,
    // Keep these parameters for backward compatibility but don't use them
    HealthChecker? healthChecker,
    ValidationService? validationService,
    PreferencesService? preferencesService,
  }) : _historyManager = TransferHistoryManager(historyService: historyService),
       _requestBuilder = requestBuilder ?? TransferRequestBuilder();

  /// Send a file with a pre-obtained transfer ID
  ///
  /// When saveHistory is false, the caller is responsible for saving history
  /// (useful for batch transfers to avoid concurrent writes)
  Future<OperationResult<TransferData>> sendFileWithTransferId({
    required String targetIP,
    required File file,
    required String transferId,
    required String senderIP,
    String? deviceName,
    void Function(double progress, int bytesTransferred, int totalBytes)?
    onProgress,
    bool saveHistory = true,
  }) async {
    final fileName = path.basename(file.path);
    final fileSize = await file.length();

    LogUtil.iTag(
      logTag,
      "sendFileWithTransferId() transferId: [$transferId], targetIP: [$targetIP], fileSize: [$fileSize], fileName: [$fileName], saveHistory: [$saveHistory]",
    );

    try {
      final request = _requestBuilder.buildTransferRequest(
        targetIP: targetIP,
        fileName: fileName,
        fileSize: fileSize,
        senderIP: senderIP,
        deviceName: deviceName,
        transferId: transferId,
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
        saveHistory: saveHistory,
      );
    } on TimeoutException {
      if (saveHistory) {
        await _historyManager.saveTransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          targetIP: targetIP,
          success: false,
          isReceived: false,
          deviceName: deviceName,
        );
      }
      return OperationResult.failure('文件传输超时');
    } on SocketException catch (e) {
      LogUtil.eTag(logTag, e.toString());
      if (saveHistory) {
        await _historyManager.saveTransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          targetIP: targetIP,
          success: false,
          isReceived: false,
          deviceName: deviceName,
        );
      }
      return OperationResult.failure('网络连接失败\n错误: ${e.message}');
    } catch (e) {
      LogUtil.eTag(logTag, e.toString());
      if (saveHistory) {
        await _historyManager.saveTransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          targetIP: targetIP,
          success: false,
          isReceived: false,
          deviceName: deviceName,
        );
      }
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
    final fileStream = file.openRead();

    try {
      await for (final chunk in fileStream) {
        request.sink.add(chunk);
        bytesSent += chunk.length;

        final progress = bytesSent / fileSize;
        onProgress?.call(progress, bytesSent, fileSize);
      }

      await request.sink.close();
    } catch (e) {
      LogUtil.eTag(logTag, e.toString());
      try {
        await request.sink.close();
      } catch (_) {
        // Ignore close errors
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

  /// Handle server response and save to history
  Future<OperationResult<TransferData>> _handleTransferResponse({
    required int statusCode,
    required String responseBody,
    required String fileName,
    required int fileSize,
    required String targetIP,
    String? deviceName,
    bool saveHistory = true,
  }) async {
    if (statusCode != 200) {
      if (saveHistory) {
        await _historyManager.saveTransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          targetIP: targetIP,
          success: false,
          isReceived: false,
          deviceName: deviceName,
        );
      }

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

      if (saveHistory) {
        await _historyManager.saveTransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          targetIP: targetIP,
          success: true,
          isReceived: false,
          deviceName: deviceName,
        );
      }

      return OperationResult.success(
        data: TransferData(savedPath: savedPath, bytesTransferred: fileSize),
      );
    } catch (e) {
      LogUtil.eTag(logTag, e.toString());
      if (saveHistory) {
        await _historyManager.saveTransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          targetIP: targetIP,
          success: false,
          isReceived: false,
          deviceName: deviceName,
        );
      }
      return OperationResult.failure('无法解析响应\n错误: $e');
    }
  }
}

/// Transfer data result
class TransferData {
  final String? savedPath;
  final int bytesTransferred;

  TransferData({this.savedPath, required this.bytesTransferred});
}
