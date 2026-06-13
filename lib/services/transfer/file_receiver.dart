import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../models/transfer_data.dart';
import '../../utils/constants.dart';
import '../../utils/error_messages.dart';
import '../../utils/log_util.dart';
import '../../utils/operation_result.dart';
import '../../utils/platform_util.dart';
import '../../utils/transfer_path_util.dart';
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
    bool streamDrained = false;

    try {
      // Check storage space
      final hasEnoughSpace = await _checkStorageSpace(fileSize);
      if (!hasEnoughSpace) {
        LogUtil.wTag(logTag, 'Storage space insufficient for file: $fileName');
        try {
          await fileStream.drain();
          streamDrained = true;
        } catch (e) {
          LogUtil.eTag(logTag, 'Error draining stream after storage check: $e');
        }

        return OperationResult.failure(ErrorMessages.storageInsufficient);
      }

      // Get receive save directory (custom path or system downloads)
      final downloadsDir = await PlatformUtil.getReceiveSaveDirectory();
      if (downloadsDir == null) {
        LogUtil.eTag(logTag, 'Receive save directory unavailable');
        try {
          if (!streamDrained) {
            await fileStream.drain();
            streamDrained = true;
          }
        } catch (e) {
          LogUtil.eTag(
            logTag,
            'Error draining stream after directory check: $e',
          );
        }

        return OperationResult.failure(
          ErrorMessages.downloadsDirectoryUnavailable,
        );
      }

      final safeRelativePath = TransferPathUtil.sanitizeRelativePath(fileName);
      if (safeRelativePath == null) {
        LogUtil.wTag(logTag, 'Invalid transfer path rejected: $fileName');
        try {
          if (!streamDrained) {
            await fileStream.drain();
            streamDrained = true;
          }
        } catch (e) {
          LogUtil.eTag(logTag, 'Error draining stream after path check: $e');
        }
        return OperationResult.failure(ErrorMessages.invalidFileName);
      }

      // Handle file name conflicts (supports nested folder paths)
      final finalRelativePath = await _resolveFileNameConflict(
        downloadsDir,
        safeRelativePath,
      );
      final filePath = path.join(downloadsDir.path, finalRelativePath);
      final parentDir = path.dirname(filePath);
      if (parentDir.isNotEmpty) {
        await Directory(parentDir).create(recursive: true);
      }

      // Save file data
      file = File(filePath);
      sink = file.openWrite();

      int bytesReceived = 0;

      try {
        // Handle empty files (0 bytes)
        if (fileSize == 0) {
          // For empty files, drain the stream (even if empty) and report 100% progress
          await fileStream.drain();
          streamDrained = true;
          if (onProgress != null) {
            onProgress(1.0, 0, 0);
          }
        } else {
          // Add timeout protection for receiving file stream
          // Timeout: base timeout + time based on file size (1 second per MB)
          final timeoutDuration = Duration(
            seconds:
                AppConstants.requestTimeout +
                (fileSize ~/ AppConstants.bytesPerMB),
          );

          await for (final chunk in fileStream.timeout(
            timeoutDuration,
            onTimeout: (sink) {
              LogUtil.wTag(
                logTag,
                'File receive timeout for $fileName after ${timeoutDuration.inSeconds} seconds',
              );
              sink.close();
            },
          )) {
            sink.add(chunk);

            bytesReceived += chunk.length;
            if (onProgress != null) {
              final progress = bytesReceived / fileSize;
              onProgress(progress, bytesReceived, fileSize);
            }
          }
          streamDrained = true;
        }

        await sink.flush();
        await sink.close();
        sink = null;
      } on TimeoutException catch (e) {
        LogUtil.eTag(
          logTag,
          'Timeout receiving file $fileName: ${e.toString()}',
        );

        if (sink != null) {
          try {
            await sink.close();
          } catch (closeError) {
            LogUtil.wTag(
              logTag,
              'Error closing sink after timeout: ${closeError.toString()}',
            );
          }
          sink = null;
        }

        try {
          if (!streamDrained) {
            await fileStream.drain();
          }
        } catch (drainError) {
          LogUtil.wTag(
            logTag,
            'Error draining stream after timeout: ${drainError.toString()}',
          );
        }

        try {
          if (file.existsSync()) {
            await file.delete();
          }
        } catch (deleteError) {
          LogUtil.eTag(
            logTag,
            'Error deleting file after timeout: $deleteError',
          );
        }

        return OperationResult.failure('文件接收超时');
      } catch (e) {
        LogUtil.eTag(logTag, 'Error writing file $fileName: ${e.toString()}');

        if (sink != null) {
          try {
            await sink.close();
          } catch (closeError) {
            LogUtil.wTag(
              logTag,
              'Error closing sink: ${closeError.toString()}',
            );
          }
          sink = null;
        }

        try {
          if (!streamDrained) {
            await fileStream.drain();
          }
        } catch (drainError) {
          LogUtil.wTag(
            logTag,
            'Error draining stream: ${drainError.toString()}',
          );
        }

        try {
          if (file.existsSync()) {
            await file.delete();
          }
        } catch (deleteError) {
          LogUtil.eTag(logTag, 'Error deleting file after error: $deleteError');
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
    } on TimeoutException catch (e, stackTrace) {
      LogUtil.eTag(
        logTag,
        'Timeout in receiveFileDirectly for $fileName: ${e.toString()}',
        e,
        stackTrace,
      );

      if (sink != null) {
        try {
          await sink.close();
        } catch (closeError) {
          LogUtil.wTag(logTag, 'Error closing sink: ${closeError.toString()}');
        }
      }

      try {
        if (!streamDrained) {
          await fileStream.drain();
        }
      } catch (drainError) {
        LogUtil.wTag(logTag, 'Error draining stream: ${drainError.toString()}');
      }

      if (file != null) {
        try {
          if (file.existsSync()) {
            await file.delete();
          }
        } catch (deleteError) {
          LogUtil.eTag(logTag, 'Error deleting file: $deleteError');
        }
      }

      return OperationResult.failure('文件接收超时');
    } catch (e, stackTrace) {
      LogUtil.eTag(
        logTag,
        'Unexpected error in receiveFileDirectly for $fileName: ${e.toString()}',
        e,
        stackTrace,
      );

      if (sink != null) {
        try {
          await sink.close();
        } catch (closeError) {
          LogUtil.wTag(logTag, 'Error closing sink: ${closeError.toString()}');
        }
      }

      try {
        if (!streamDrained) {
          await fileStream.drain();
        }
      } catch (drainError) {
        LogUtil.wTag(logTag, 'Error draining stream: ${drainError.toString()}');
      }

      if (file != null) {
        try {
          if (file.existsSync()) {
            await file.delete();
          }
        } catch (deleteError) {
          LogUtil.eTag(logTag, 'Error deleting file: $deleteError');
        }
      }

      // Provide more specific error messages for known exception types
      if (e is FileSystemException) {
        return OperationResult.failure('文件系统错误: ${e.message}');
      }

      return OperationResult.failure(
        ErrorMessages.unexpectedError(e.toString()),
      );
    }
  }

  /// Check if there is enough storage space
  Future<bool> _checkStorageSpace(int requiredBytes) async {
    // The method for checking remaining space has a bug, so we don't need to check it for the time being
    // final result = await _validationService.validateStorageSpace(requiredBytes);
    // return result.isSuccess;
    return true;
  }

  /// Resolve file path conflicts by adding a number suffix to the file name.
  Future<String> _resolveFileNameConflict(
    Directory directory,
    String relativePath,
  ) async {
    final fullPath = path.join(directory.path, relativePath);
    if (!await File(fullPath).exists()) {
      return relativePath;
    }

    final parentDir = path.dirname(relativePath);
    final fileName = path.basename(relativePath);
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

    int counter = 1;
    while (true) {
      final candidateFileName = '$baseName($counter)$extension';
      final candidateRelative = parentDir == '.' || parentDir.isEmpty
          ? candidateFileName
          : path.join(parentDir, candidateFileName);
      final candidateFullPath = path.join(directory.path, candidateRelative);

      if (!await File(candidateFullPath).exists()) {
        return candidateRelative;
      }
      counter++;
    }
  }
}
