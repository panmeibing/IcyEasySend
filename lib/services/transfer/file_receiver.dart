import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../../models/transfer_data.dart';
import '../../utils/constants.dart';
import '../../utils/disk_space_error.dart';
import '../../utils/error_messages.dart';
import '../../utils/log_util.dart';
import '../../utils/operation_result.dart';
import '../../utils/platform_util.dart';
import '../../utils/transfer_path_util.dart';
import '../validation_service.dart';

/// Raised when a sender keeps writing past the size it declared.
///
/// Private because it never leaves this file: the receive path turns it into
/// a size-mismatch failure like any other.
class _OversizeTransferException implements Exception {
  const _OversizeTransferException({
    required this.declared,
    required this.received,
  });

  final int declared;
  final int received;

  @override
  String toString() => 'declared $declared bytes, received at least $received';
}

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
    File? file;
    IOSink? sink;
    // A request body can be listened to once. Until then it is drained on
    // failure so the sender gets a response instead of a stalled upload.
    var streamListened = false;

    Future<void> abort() async {
      final openSink = sink;
      sink = null;
      if (openSink != null) {
        try {
          await openSink.close();
        } catch (e) {
          LogUtil.wTag(logTag, 'Error closing sink: $e');
        }
      }
      if (!streamListened) {
        streamListened = true;
        try {
          await fileStream.drain<void>();
        } catch (e) {
          LogUtil.wTag(logTag, 'Error draining stream: $e');
        }
      }
      final written = file;
      if (written != null) {
        await _deleteQuietly(written);
      }
    }

    try {
      // There is deliberately no free-space pre-flight check here: the plugin
      // that reports remaining space returns numbers that cannot be trusted.
      // Running out of room is detected from the write error instead — see
      // [_failureFor].
      final destination = await _resolveDestination(fileName);
      if (destination.isFailure) {
        await abort();
        return OperationResult.failure(destination.errorMessage!);
      }

      file = File(destination.data!);
      final openSink = file.openWrite();
      sink = openSink;

      // An IOSink buffers, so a failed write surfaces on flush/close rather
      // than on add(). Watching done lets the loop below stop as soon as the
      // disk fills, instead of pulling the remaining gigabytes over the
      // network only to discard them.
      Object? writeFailure;
      unawaited(
        openSink.done.catchError((Object error) {
          writeFailure ??= error;
        }),
      );

      streamListened = true;
      if (fileSize == 0) {
        await fileStream.drain<void>();
        onProgress?.call(1.0, 0, 0);
      } else {
        // Idle timeout between chunks, so a stalled sender cannot hold the
        // file open forever while a slow but live one is never cut off.
        final idleTimeout = Duration(
          seconds:
              AppConstants.requestTimeout +
              (fileSize ~/ AppConstants.bytesPerMB),
        );

        var bytesReceived = 0;
        await for (final chunk in fileStream.timeout(idleTimeout)) {
          if (writeFailure != null) {
            throw writeFailure!;
          }

          // The declared size is the only budget the sender agreed to, and
          // the user confirmed the transfer on the strength of it. Anything
          // past it is refused before it reaches the disk rather than after,
          // so a sender that simply never stops cannot fill the volume.
          if (bytesReceived + chunk.length > fileSize) {
            throw _OversizeTransferException(
              declared: fileSize,
              received: bytesReceived + chunk.length,
            );
          }

          openSink.add(chunk);
          bytesReceived += chunk.length;
          onProgress?.call(bytesReceived / fileSize, bytesReceived, fileSize);
        }
      }

      await openSink.flush();
      await openSink.close();
      sink = null;
    } on TimeoutException catch (e) {
      LogUtil.eTag(logTag, 'Timeout receiving file $fileName: $e');
      await abort();
      return OperationResult.failure(ErrorMessages.transferTimeout);
    } on _OversizeTransferException catch (e) {
      LogUtil.wTag(logTag, '发送方超出声明大小，已中止接收 $fileName: $e');
      await abort();
      return OperationResult.failure(ErrorMessages.fileSizeMismatch);
    } catch (e, stackTrace) {
      LogUtil.eTag(logTag, 'Error receiving file $fileName: $e', e, stackTrace);
      await abort();
      return _failureFor(e);
    }

    return _verifySaved(file, fileSize);
  }

  /// Moves an already-written file into the save directory under [fileName].
  ///
  /// The resumable relay path writes its bytes to a partial file first, so the
  /// last step is a move rather than a stream. Everything the direct path
  /// decides about the destination — path sanitizing, name conflicts, the size
  /// check — is decided here too, so a resumed file lands exactly where the
  /// same file would have landed had it arrived in one go.
  Future<OperationResult<TransferData>> adoptReceivedFile({
    required File source,
    required String fileName,
    required int fileSize,
  }) async {
    try {
      final destination = await _resolveDestination(fileName);
      if (destination.isFailure) {
        return OperationResult.failure(destination.errorMessage!);
      }

      final file = await _move(source, destination.data!);
      return _verifySaved(file, fileSize);
    } catch (e, stackTrace) {
      LogUtil.eTag(
        logTag,
        'Error adopting received file $fileName: $e',
        e,
        stackTrace,
      );
      return _failureFor(e);
    }
  }

  /// Absolute path [fileName] should be saved under, with its parent created.
  ///
  /// The containment check repeats what [TransferPathUtil.sanitizeRelativePath]
  /// already guarantees, so a future gap in sanitizing cannot by itself turn
  /// into a write outside the save directory.
  Future<OperationResult<String>> _resolveDestination(String fileName) async {
    final saveDir = await PlatformUtil.getReceiveSaveDirectory();
    if (saveDir == null) {
      LogUtil.eTag(logTag, 'Receive save directory unavailable');
      return OperationResult.failure(
        ErrorMessages.downloadsDirectoryUnavailable,
      );
    }

    final safeRelativePath = TransferPathUtil.sanitizeRelativePath(fileName);
    if (safeRelativePath == null) {
      LogUtil.wTag(logTag, 'Invalid transfer path rejected: $fileName');
      return OperationResult.failure(ErrorMessages.invalidFileName);
    }

    final finalRelativePath = await _resolveFileNameConflict(
      saveDir,
      safeRelativePath,
    );
    final filePath = path.join(saveDir.path, finalRelativePath);
    if (!path.isWithin(saveDir.path, filePath)) {
      LogUtil.wTag(logTag, 'Transfer path escapes save directory: $fileName');
      return OperationResult.failure(ErrorMessages.invalidFileName);
    }

    await Directory(path.dirname(filePath)).create(recursive: true);
    return OperationResult.success(data: filePath);
  }

  Future<OperationResult<TransferData>> _verifySaved(
    File file,
    int fileSize,
  ) async {
    final verifyResult = await _validationService.validateSavedFile(
      file,
      fileSize,
    );
    if (!verifyResult.isSuccess) {
      await _deleteQuietly(file);
      return OperationResult.failure(verifyResult.errorMessage!);
    }

    return OperationResult.success(
      data: TransferData(savedPath: file.path, bytesTransferred: fileSize),
    );
  }

  OperationResult<TransferData> _failureFor(Object error) {
    if (DiskSpaceError.isDiskFull(error)) {
      LogUtil.eTag(logTag, '磁盘空间不足，已中止接收');
      return OperationResult.failure(
        ErrorMessages.storageInsufficient,
        metadata: DiskSpaceError.metadata,
      );
    }
    final detail = error is FileSystemException ? error.message : '$error';
    return OperationResult.failure('${ErrorMessages.fileSaveFailed}\n$detail');
  }

  Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      LogUtil.wTag(logTag, 'Error deleting ${file.path}: $e');
    }
  }

  /// Renames [source] to [destination], copying when that is not possible.
  ///
  /// A rename cannot cross a filesystem boundary, and on Android the save
  /// directory regularly sits on a different mount than app storage. The copy
  /// is the slow path and only runs when the fast one is unavailable.
  Future<File> _move(File source, String destination) async {
    try {
      return await source.rename(destination);
    } on FileSystemException {
      final copied = await source.copy(destination);
      try {
        await source.delete();
      } catch (e) {
        LogUtil.wTag(logTag, 'Error deleting source after copy: $e');
      }
      return copied;
    }
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
