import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../models/transfer_data.dart';
import '../../models/transfer_file_item.dart';
import '../../models/transfer_history.dart';
import '../../utils/constants.dart';
import '../../utils/http_helper.dart';
import '../../utils/log_util.dart';
import '../../utils/network_util.dart';
import '../../utils/operation_result.dart';
import '../../utils/transfer_status_provider.dart';
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
      onStatusChange?.call(
        _statusProvider.waitingForReceiverConfirmFiles(fileList.length),
      );

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

      // Add secret key to headers if provided
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (secretKey != null && secretKey.isNotEmpty) {
        headers['X-Secret-Key'] = secretKey;
      }

      final confirmResult = await HttpHelper.post(
        confirmUrl,
        headers: headers,
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
        final errorMsg =
            confirmData['message'] as String? ??
            _statusProvider.receiverRejected;
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
        secretKey: secretKey,
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
      if (transferIds.containsKey(files[i].transferName)) {
        fileBytes[i] = 0;
      }
    }

    // Create list of valid file indices
    final validFileIndices = <int>[];
    for (int i = 0; i < files.length; i++) {
      if (transferIds.containsKey(files[i].transferName)) {
        validFileIndices.add(i);
      }
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

      onStatusChange?.call(
        _statusProvider.transferringFile(fileIndex + 1, files.length, fileName),
      );

      try {
        // Add timeout protection for each file transfer
        final fileSize = await file.length();
        // Calculate timeout: base timeout + time based on file size (1 second per MB)
        final timeoutDuration = Duration(
          seconds:
              AppConstants.requestTimeout +
              (fileSize ~/ AppConstants.bytesPerMB),
        );

        final result = await _fileSender
            .sendFileWithTransferId(
              targetIP: targetIP,
              file: file,
              transferId: transferId,
              senderIP: senderIP,
              deviceName: deviceName,
              secretKey: secretKey,
              transferName: fileName,
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
            )
            .timeout(
              timeoutDuration,
              onTimeout: () {
                LogUtil.wTag(
                  logTag,
                  'File transfer timeout for $fileName after ${timeoutDuration.inSeconds} seconds',
                );
                return OperationResult.failure(
                  '文件传输超时 (${timeoutDuration.inSeconds}秒)',
                );
              },
            );

        return result;
      } catch (e) {
        // Catch any unexpected errors to prevent Future from hanging
        LogUtil.eTag(logTag, 'Unexpected error sending file $fileName: $e');
        return OperationResult.failure('文件传输失败: ${e.toString()}');
      }
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
          sendFile(fileIndex)
              .then((result) {
                results[files[fileIndex].transferName] = result;
              })
              .catchError((error) {
                final fileName = files[fileIndex].transferName;
                LogUtil.eTag(
                  logTag,
                  'Error in batch transfer for $fileName: $error',
                );
                results[fileName] = OperationResult.failure(
                  '传输失败: ${error.toString()}',
                );
              }),
        );
      }

      // Wait for all files in this batch to complete (success or failure)
      await Future.wait(batch, eagerError: false);
    }
  }

  /// Save all transfer histories in batch after transfers complete
  /// This prevents concurrent write conflicts to the history file
  Future<void> _saveBatchTransferHistories({
    required List<TransferFileItem> files,
    required Map<String, OperationResult<TransferData>> results,
    required String targetIP,
    String? deviceName,
  }) async {
    try {
      final histories = <TransferHistory>[];

      for (final item in files) {
        final result = results[item.transferName];

        if (result != null) {
          final fileSize = await item.file.length();
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
}
