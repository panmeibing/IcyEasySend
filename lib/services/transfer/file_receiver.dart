import 'dart:io';

import '../../utils/error_messages.dart';
import '../../utils/log_util.dart';
import '../../utils/operation_result.dart';
import '../../utils/platform_util.dart';
import '../transfer_history_service.dart';
import '../validation_service.dart';
import 'transfer_history_manager.dart';

/// Service for receiving files from sender devices
class FileReceiver {
  final ValidationService _validationService;
  final TransferHistoryManager _historyManager;

  FileReceiver({
    ValidationService? validationService,
    TransferHistoryService? historyService,
  }) : _validationService = validationService ?? ValidationService(),
       _historyManager = TransferHistoryManager(historyService: historyService);

  /// Receive a file directly without user confirmation
  Future<OperationResult<FileReceivedData>> receiveFileDirectly({
    required Stream<List<int>> fileStream,
    required String fileName,
    required int fileSize,
    required String senderIP,
    String? senderDeviceName,
    void Function(double progress, int bytesReceived, int totalBytes)?
    onProgress,
  }) async {
    IOSink? sink;
    File? file;

    try {
      // Check storage space
      final hasEnoughSpace = await _checkStorageSpace(fileSize);
      if (!hasEnoughSpace) {
        try {
          await fileStream.drain();
        } catch (e) {
          LogUtil.e('Error draining stream: $e');
        }

        return OperationResult.failure(ErrorMessages.storageInsufficient);
      }

      // Get downloads directory
      final downloadsDir = await PlatformUtil.getDownloadsDirectory();
      if (downloadsDir == null) {
        try {
          await fileStream.drain();
        } catch (e) {
          LogUtil.e('Error draining stream: $e');
        }

        return OperationResult.failure(
          ErrorMessages.downloadsDirectoryUnavailable,
        );
      }

      // Handle file name conflicts
      final finalFileName = await _resolveFileNameConflict(
        downloadsDir,
        fileName,
      );
      final filePath = '${downloadsDir.path}/$finalFileName';

      // Save file data
      file = File(filePath);
      sink = file.openWrite();

      int bytesReceived = 0;

      try {
        await for (final chunk in fileStream) {
          sink.add(chunk);

          bytesReceived += chunk.length;
          if (onProgress != null) {
            final progress = bytesReceived / fileSize;
            onProgress(progress, bytesReceived, fileSize);
          }
        }

        await sink.flush();
        await sink.close();
        sink = null;
      } catch (e) {
        LogUtil.e('Error writing file: $e');

        if (sink != null) {
          try {
            await sink.close();
          } catch (closeError) {
            LogUtil.e('Error closing sink: $closeError');
          }
          sink = null;
        }

        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (deleteError) {
          LogUtil.e('Error deleting file: $deleteError');
        }

        await _historyManager.saveTransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          targetIP: senderIP,
          success: false,
          isReceived: true,
          deviceName: senderDeviceName,
        );

        return OperationResult.failure('文件保存失败\n错误: $e');
      }

      // Verify file was saved correctly
      final verifyResult = await _validationService.validateSavedFile(
        file,
        fileSize,
      );
      if (!verifyResult.isSuccess) {
        try {
          await file.delete();
        } catch (deleteError) {
          LogUtil.e('Error deleting invalid file: $deleteError');
        }

        await _historyManager.saveTransferHistory(
          fileName: fileName,
          fileSize: fileSize,
          targetIP: senderIP,
          success: false,
          isReceived: true,
          deviceName: senderDeviceName,
        );

        return OperationResult.failure(verifyResult.errorMessage!);
      }

      // Save to history
      await _historyManager.saveTransferHistory(
        fileName: fileName,
        fileSize: fileSize,
        targetIP: senderIP,
        success: true,
        isReceived: true,
        deviceName: senderDeviceName,
        savedPath: filePath,
      );

      return OperationResult.success(
        data: FileReceivedData(savedPath: filePath, bytesTransferred: fileSize),
      );
    } catch (e, stackTrace) {
      LogUtil.e('Unexpected error in receiveFileDirectly: $e');
      LogUtil.e('Stack trace: $stackTrace');

      if (sink != null) {
        try {
          await sink.close();
        } catch (closeError) {
          LogUtil.e('Error closing sink: $closeError');
        }
      }

      if (file != null) {
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (deleteError) {
          LogUtil.e('Error deleting file: $deleteError');
        }
      }

      await _historyManager.saveTransferHistory(
        fileName: fileName,
        fileSize: fileSize,
        targetIP: senderIP,
        success: false,
        isReceived: true,
        deviceName: senderDeviceName,
      );

      return OperationResult.failure(
        ErrorMessages.unexpectedError(e.toString()),
      );
    }
  }

  /// Check if there is enough storage space
  Future<bool> _checkStorageSpace(int requiredBytes) async {
    final result = await _validationService.validateStorageSpace(requiredBytes);
    return result.isSuccess;
  }

  /// Resolve file name conflicts by adding a number suffix
  Future<String> _resolveFileNameConflict(
    Directory directory,
    String fileName,
  ) async {
    final lastDotIndex = fileName.lastIndexOf('.');
    String baseName;
    String extension;

    if (lastDotIndex != -1 && lastDotIndex < fileName.length - 1) {
      baseName = fileName.substring(0, lastDotIndex);
      extension = fileName.substring(lastDotIndex);
    } else {
      baseName = fileName;
      extension = '';
    }

    String candidateName = fileName;
    int counter = 1;

    while (await File('${directory.path}/$candidateName').exists()) {
      candidateName = '$baseName($counter)$extension';
      counter++;
    }

    return candidateName;
  }
}

/// File received data result
class FileReceivedData {
  final String savedPath;
  final int bytesTransferred;

  FileReceivedData({required this.savedPath, required this.bytesTransferred});
}
