import 'dart:io';

import 'package:path/path.dart' as path;

import '../../models/transfer_data.dart';
import '../../utils/error_messages.dart';
import '../../utils/log_util.dart';
import '../../utils/operation_result.dart';
import '../../utils/platform_util.dart';
import '../validation_service.dart';

/// Service for receiving files from sender devices
class FileReceiver {
  final ValidationService _validationService;
  final String logTag = LogTags.transfer;

  FileReceiver({ValidationService? validationService})
    : _validationService = validationService ?? ValidationService();

  /// Receive a file directly without user confirmation
  ///
  /// Note: This method does NOT save transfer history.
  /// The caller is responsible for collecting results and saving history in batch.
  Future<OperationResult<TransferData>> receiveFileDirectly({
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
          LogUtil.eTag(logTag, 'Error draining stream: $e');
        }

        return OperationResult.failure(ErrorMessages.storageInsufficient);
      }

      // Get downloads directory
      final downloadsDir = await PlatformUtil.getDownloadsDirectory();
      if (downloadsDir == null) {
        try {
          await fileStream.drain();
        } catch (e) {
          LogUtil.eTag(logTag, 'Error draining stream: $e');
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
      final filePath = path.join(downloadsDir.path, finalFileName);

      // Save file data
      file = File(filePath);
      sink = file.openWrite();

      int bytesReceived = 0;

      try {
        // Handle empty files (0 bytes)
        if (fileSize == 0) {
          // For empty files, drain the stream (even if empty) and report 100% progress
          await fileStream.drain();
          if (onProgress != null) {
            onProgress(1.0, 0, 0);
          }
        } else {
          await for (final chunk in fileStream) {
            sink.add(chunk);

            bytesReceived += chunk.length;
            if (onProgress != null) {
              final progress = bytesReceived / fileSize;
              onProgress(progress, bytesReceived, fileSize);
            }
          }
        }

        await sink.flush();
        await sink.close();
        sink = null;
      } catch (e) {
        LogUtil.eTag(logTag, 'Error writing file: $e');

        if (sink != null) {
          try {
            await sink.close();
          } catch (closeError) {
            LogUtil.eTag(logTag, 'Error closing sink: $closeError');
          }
          sink = null;
        }

        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (deleteError) {
          LogUtil.eTag(logTag, 'Error deleting file: $deleteError');
        }

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
          LogUtil.eTag(logTag, 'Error deleting invalid file: $deleteError');
        }

        return OperationResult.failure(verifyResult.errorMessage!);
      }

      return OperationResult.success(
        data: TransferData(savedPath: filePath, bytesTransferred: fileSize),
      );
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, 'Unexpected error in receiveFileDirectly: $e');
      LogUtil.eTag(logTag, 'Stack trace: $stackTrace');

      if (sink != null) {
        try {
          await sink.close();
        } catch (closeError) {
          LogUtil.eTag(logTag, 'Error closing sink: $closeError');
        }
      }

      if (file != null) {
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } catch (deleteError) {
          LogUtil.eTag(logTag, 'Error deleting file: $deleteError');
        }
      }

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

    while (await File(path.join(directory.path, candidateName)).exists()) {
      candidateName = '$baseName($counter)$extension';
      counter++;
    }

    return candidateName;
  }
}
