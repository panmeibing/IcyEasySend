import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:icy_easy_send/utils/constants.dart';

import '../models/transfer_data.dart';
import '../utils/log_util.dart';
import '../utils/operation_result.dart';
import 'preferences_service.dart';
import 'transfer/batch_transfer_manager.dart';
import 'transfer/file_receiver.dart';
import 'transfer/file_sender.dart' as sender;
import 'transfer/health_checker.dart' as checker;
import 'transfer_history_service.dart';
import 'validation_service.dart';

class FileTransferService {
  final FileReceiver _fileReceiver;
  final BatchTransferManager _batchTransferManager;
  final String logTag = LogTags.transfer;

  FileTransferService({
    TransferHistoryService? historyService,
    PreferencesService? preferencesService,
    ValidationService? validationService,
    checker.HealthChecker? healthChecker,
    sender.FileSender? fileSender,
    FileReceiver? fileReceiver,
    BatchTransferManager? batchTransferManager,
  }) : _fileReceiver =
           fileReceiver ?? FileReceiver(validationService: validationService),
       _batchTransferManager =
           batchTransferManager ??
           BatchTransferManager(
             preferencesService: preferencesService,
             validationService: validationService,
           );

  Future<Map<String, OperationResult<TransferData>>> sendFilesWithBatchConfirm({
    required String targetIP,
    required List<File> files,
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
    LogUtil.iTag(logTag, '开始批量文件传输: 目标IP=$targetIP, 文件数=${files.length}');

    try {
      final results = await _batchTransferManager.sendFilesWithBatchConfirm(
        targetIP: targetIP,
        files: files,
        secretKey: secretKey,
        onProgress: onProgress,
        onFileProgress: onFileProgress,
        onStatusChange: onStatusChange,
        onHistoryUpdated: onHistoryUpdated,
      );

      final convertedResults = <String, OperationResult<TransferData>>{};
      int successCount = 0;
      int failureCount = 0;

      for (final entry in results.entries) {
        if (entry.value.isSuccess) {
          successCount++;
          convertedResults[entry.key] = OperationResult.success(
            data: TransferData(
              savedPath: entry.value.data!.savedPath,
              bytesTransferred: entry.value.data!.bytesTransferred,
            ),
          );
        } else {
          failureCount++;
          convertedResults[entry.key] = OperationResult.failure(
            entry.value.errorMessage!,
          );
          LogUtil.wTag(
            logTag,
            '文件传输失败: ${entry.key}, 原因: ${entry.value.errorMessage}',
          );
        }
      }

      LogUtil.iTag(
        logTag,
        '批量传输完成: 成功=$successCount, 失败=$failureCount, 总数=${files.length}',
      );

      return convertedResults;
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '批量文件传输异常: $e', e, stackTrace);
      rethrow;
    }
  }

  Future<OperationResult<TransferData>> receiveFileDirectly({
    required Stream<List<int>> fileStream,
    required String fileName,
    required int fileSize,
    required String senderIP,
    String? senderDeviceName,
    void Function(double progress, int bytesReceived, int totalBytes)?
    onProgress,
  }) async {
    LogUtil.iTag(
      logTag,
      '开始接收文件: $fileName, 大小=${(fileSize / AppConstants.bytesPerMB).toStringAsFixed(2)}MB, 来自=$senderIP',
    );

    try {
      final result = await _fileReceiver.receiveFileDirectly(
        fileStream: fileStream,
        fileName: fileName,
        fileSize: fileSize,
        senderIP: senderIP,
        senderDeviceName: senderDeviceName,
        onProgress: onProgress,
      );

      if (result.isSuccess) {
        LogUtil.iTag(
          logTag,
          '文件接收成功: $fileName, 保存路径=${result.data!.savedPath}',
        );
        return OperationResult.success(
          data: TransferData(
            savedPath: result.data!.savedPath,
            bytesTransferred: result.data!.bytesTransferred,
          ),
        );
      } else {
        LogUtil.wTag(logTag, '文件接收失败: $fileName, 原因=${result.errorMessage}');
        return OperationResult.failure(result.errorMessage!);
      }
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, '文件接收异常: $fileName, 错误=$e', e, stackTrace);
      rethrow;
    }
  }
}
