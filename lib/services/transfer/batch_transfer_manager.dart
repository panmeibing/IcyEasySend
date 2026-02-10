import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

import '../../models/transfer_data.dart';
import '../../models/transfer_history.dart';
import '../../utils/constants.dart';
import '../../utils/http_helper.dart';
import '../../utils/log_util.dart';
import '../../utils/network_util.dart';
import '../../utils/operation_result.dart';
import '../preferences_service.dart';
import '../validation_service.dart';
import 'file_sender.dart' as sender;
import 'health_checker.dart';
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

  final String logTag = LogTags.transfer;

  BatchTransferManager({
    HealthChecker? healthChecker,
    sender.FileSender? fileSender,
    ValidationService? validationService,
    PreferencesService? preferencesService,
    TransferRequestBuilder? requestBuilder,
    TransferHistoryManager? historyManager,
  }) : _healthChecker = healthChecker ?? HealthChecker(),
       _fileSender = fileSender ?? sender.FileSender(),
       _validationService = validationService ?? ValidationService(),
       _preferencesService = preferencesService ?? PreferencesService(),
       _requestBuilder = requestBuilder ?? TransferRequestBuilder(),
       _historyManager = historyManager ?? TransferHistoryManager();

  /// Send multiple files with batch confirmation
  Future<Map<String, OperationResult<TransferData>>> sendFilesWithBatchConfirm({
    required String targetIP,
    required List<File> files,
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
  }) async {
    final results = <String, OperationResult<TransferData>>{};

    if (files.isEmpty) {
      return results;
    }

    try {
      // Step 1: Health check
      onStatusChange?.call('正在检查目标设备...');
      final healthResult = await _healthChecker.checkHealth(targetIP);
      if (!healthResult.isSuccess) {
        for (final file in files) {
          final fileName = path.basename(file.path);
          results[fileName] = OperationResult.failure(
            '目标设备不可用\n错误: ${healthResult.errorMessage}',
          );
        }
        return results;
      }

      // Step 2: Prepare sender info
      onStatusChange?.call('准备传输信息...');
      final senderIP = await NetworkUtil.getLocalIPAddress();
      String? deviceName = await _preferencesService.getDeviceName();
      if (deviceName == null || deviceName.isEmpty) {
        deviceName = await NetworkUtil.getDeviceName();
      }

      // Step 3: Validate files and prepare file list
      final fileList = <Map<String, dynamic>>[];
      int totalBytes = 0;

      final validationResults = await _validationService
          .validateFilesForSending(files);

      for (final entry in validationResults.entries) {
        final fileName = entry.key;
        final validationResult = entry.value;

        if (!validationResult.isSuccess) {
          results[fileName] = OperationResult.failure(
            validationResult.errorMessage!,
          );
          continue;
        }

        final fileData = validationResult.data!;
        totalBytes += fileData.fileSize;
        fileList.add({
          'fileName': fileData.fileName,
          'fileSize': fileData.fileSize,
        });
      }

      if (fileList.isEmpty) {
        return results;
      }

      // Step 4: Send batch confirmation request
      onStatusChange?.call('等待接收方确认 ${fileList.length} 个文件...');

      final confirmUrl = _requestBuilder.buildBatchConfirmationUrl(targetIP);
      final confirmBody = jsonEncode({
        'files': fileList,
        'senderIP': senderIP,
        'senderDeviceName': deviceName,
      });

      LogUtil.iTag(
        logTag,
        "sendFilesWithBatchConfirm() confirmUrl: [$confirmUrl], confirmBody: [$confirmBody]",
      );

      final confirmResult = await HttpHelper.post(
        confirmUrl,
        headers: {'Content-Type': 'application/json'},
        body: confirmBody,
        timeout: AppConstants.confirmTimeout,
      );

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
          '接收方拒绝接收\n状态码: ${confirmResponse.statusCode}',
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
        final errorMsg = confirmData['message'] as String? ?? '接收方拒绝接收';
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

      // Step 5: Send files with concurrent control
      await _sendFilesWithConcurrency(
        files: files,
        transferIds: transferIds,
        targetIP: targetIP,
        senderIP: senderIP,
        deviceName: deviceName,
        totalBytes: totalBytes,
        results: results,
        onProgress: onProgress,
        onFileProgress: onFileProgress,
        onStatusChange: onStatusChange,
      );

      // Step 6: Save all transfer histories in batch after all transfers complete
      await _saveBatchTransferHistories(
        files: files,
        results: results,
        targetIP: targetIP,
        deviceName: deviceName,
      );

      // Step 7: Trigger history refresh callback
      onHistoryUpdated?.call();

      return results;
    } catch (e) {
      LogUtil.eTag(logTag, "sendFilesWithBatchConfirm() ${e.toString()}");
      for (final file in files) {
        final fileName = path.basename(file.path);
        if (!results.containsKey(fileName)) {
          results[fileName] = OperationResult.failure(
            'Unexpected error: ${e.toString()}',
          );
        }
      }
      return results;
    }
  }

  /// Send files with concurrency control
  Future<void> _sendFilesWithConcurrency({
    required List<File> files,
    required Map<String, String> transferIds,
    required String targetIP,
    required String senderIP,
    String? deviceName,
    required int totalBytes,
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
  }) async {
    final concurrentCount = await _preferencesService.getConcurrentTransfers();

    final Map<int, double> fileProgress = {};
    final Map<int, int> fileBytes = {};

    // Initialize fileBytes for valid files
    for (int i = 0; i < files.length; i++) {
      final fileName = path.basename(files[i].path);
      if (transferIds.containsKey(fileName)) {
        fileBytes[i] = 0;
      }
    }

    // Create list of valid file indices
    final validFileIndices = <int>[];
    for (int i = 0; i < files.length; i++) {
      final fileName = path.basename(files[i].path);
      if (transferIds.containsKey(fileName)) {
        validFileIndices.add(i);
      }
    }

    // Function to send a single file
    Future<OperationResult<TransferData>> sendFile(int fileIndex) async {
      final file = files[fileIndex];
      final fileName = path.basename(file.path);

      if (results.containsKey(fileName)) {
        return results[fileName]!;
      }

      final transferId = transferIds[fileName];
      if (transferId == null) {
        return OperationResult.failure('未找到传输ID');
      }

      onStatusChange?.call(
        '正在传输文件 ${fileIndex + 1}/${files.length}: $fileName',
      );

      final result = await _fileSender.sendFileWithTransferId(
        targetIP: targetIP,
        file: file,
        transferId: transferId,
        senderIP: senderIP,
        deviceName: deviceName,
        onProgress: (progress, bytes, total) {
          fileProgress[fileIndex] = progress;
          fileBytes[fileIndex] = bytes;
          onFileProgress?.call(fileIndex, progress, bytes, total);

          int overallBytes = 0;
          for (final entry in fileBytes.entries) {
            overallBytes += entry.value;
          }
          final overallProgress = totalBytes > 0
              ? overallBytes / totalBytes
              : 0.0;
          onProgress?.call(overallProgress, overallBytes, totalBytes);
        },
      );

      return result;
    }

    // Process files with concurrent control
    for (int i = 0; i < validFileIndices.length; i += concurrentCount) {
      final batchEnd = (i + concurrentCount < validFileIndices.length)
          ? i + concurrentCount
          : validFileIndices.length;

      final batch = <Future<void>>[];
      for (int j = i; j < batchEnd; j++) {
        final fileIndex = validFileIndices[j];
        batch.add(
          sendFile(fileIndex).then((result) {
            final fileName = path.basename(files[fileIndex].path);
            results[fileName] = result;
          }),
        );
      }

      await Future.wait(batch, eagerError: false);
    }
  }

  /// Save all transfer histories in batch after transfers complete
  /// This prevents concurrent write conflicts to the history file
  Future<void> _saveBatchTransferHistories({
    required List<File> files,
    required Map<String, OperationResult<TransferData>> results,
    required String targetIP,
    String? deviceName,
  }) async {
    try {
      final histories = <TransferHistory>[];

      for (final file in files) {
        final fileName = path.basename(file.path);
        final result = results[fileName];

        if (result != null) {
          final fileSize = await file.length();
          final history = _historyManager.createTransferHistory(
            fileName: fileName,
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
}
