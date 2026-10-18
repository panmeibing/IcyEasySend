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
class _TransferCancelled implements Exception {
  const _TransferCancelled();
}

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
    Duration? idleTimeout,
    Future<void>? cancel,
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

    // A cancel that lands after the last byte still wins: the user saw the
    // file as unfinished when they pressed it.
    var cancelled = false;
    unawaited(cancel?.whenComplete(() => cancelled = true));

    final _Reservation reservation;
    try {
      // There is deliberately no free-space pre-flight check here: the plugin
      // that reports remaining space returns numbers that cannot be trusted.
      // Running out of room is detected from the write error instead — see
      // [_failureFor].
      final destination = await _reserveDestination(fileName);
      if (destination.isFailure) {
        await abort();
        return OperationResult.failure(destination.errorMessage!);
      }
      reservation = destination.data!;

      file = reservation.part;
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
        // Idle gap between chunks. A slow sender that keeps delivering bytes
        // is never cut off; one that goes silent cannot hold the file open.
        final stall = idleTimeout ?? AppConstants.transferStallTimeout;

        var bytesReceived = 0;
        var unflushed = 0;
        await for (final chunk in _untilCancelled(
          fileStream,
          cancel,
        ).timeout(stall)) {
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
          unflushed += chunk.length;
          onProgress?.call(bytesReceived / fileSize, bytesReceived, fileSize);

          // Pauses the stream, and with it the socket, until the disk has
          // caught up. The idle timeout above is paused along with it.
          if (unflushed >= AppConstants.receiveFlushThresholdBytes) {
            unflushed = 0;
            await openSink.flush();
          }
        }
      }

      await openSink.flush();
      await openSink.close();
      sink = null;
      if (cancelled) throw const _TransferCancelled();
    } on _TransferCancelled {
      LogUtil.iTag(logTag, '接收已取消: $fileName');
      await abort();
      return OperationResult.failure(ErrorMessages.transferCancelled);
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

    return _publish(reservation, fileSize);
  }

  /// Forwards [source] until [cancel] completes, then ends the stream with
  /// [_TransferCancelled]. Cancelling the subscription also drops the socket
  /// the bytes were coming from, so the sender stops instead of finishing.
  Stream<List<int>> _untilCancelled(
    Stream<List<int>> source,
    Future<void>? cancel,
  ) {
    if (cancel == null) return source;
    late StreamSubscription<List<int>> subscription;
    late StreamController<List<int>> controller;
    var closed = false;

    Future<void> stop() async {
      if (closed) return;
      closed = true;
      await subscription.cancel();
      if (!controller.isClosed) {
        controller.addError(const _TransferCancelled());
        await controller.close();
      }
    }

    controller = StreamController<List<int>>(
      onListen: () {
        subscription = source.listen(
          controller.add,
          onError: controller.addError,
          onDone: () {
            if (!closed) controller.close();
          },
          cancelOnError: true,
        );
        cancel.whenComplete(stop);
      },
      onCancel: () => subscription.cancel(),
    );
    return controller.stream;
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
      final destination = await _reserveDestination(fileName);
      if (destination.isFailure) {
        return OperationResult.failure(destination.errorMessage!);
      }
      final reservation = destination.data!;

      try {
        await _move(source, reservation.part.path);
      } catch (_) {
        await _deleteQuietly(reservation.part);
        rethrow;
      }
      return await _publish(reservation, fileSize);
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

  /// Claims a free name in the save directory for [fileName].
  ///
  /// The claim is the partial file next to it, created exclusively: a second
  /// receive of the same name, from this batch or another, sees it and moves
  /// on to the next number instead of writing into the same file. Bytes only
  /// ever appear under the final name once complete, so a crash leaves a
  /// `.part` behind rather than a truncated file that looks finished.
  ///
  /// The containment check repeats what [TransferPathUtil.sanitizeRelativePath]
  /// already guarantees, so a future gap in sanitizing cannot by itself turn
  /// into a write outside the save directory.
  Future<OperationResult<_Reservation>> _reserveDestination(
    String fileName,
  ) async {
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

    final wanted = path.join(saveDir.path, safeRelativePath);
    if (!path.isWithin(saveDir.path, wanted)) {
      LogUtil.wTag(logTag, 'Transfer path escapes save directory: $fileName');
      return OperationResult.failure(ErrorMessages.invalidFileName);
    }

    await Directory(path.dirname(wanted)).create(recursive: true);
    for (final candidate in _candidates(wanted)) {
      if (await File(candidate).exists()) continue;
      final part = File('$candidate$partSuffix');
      try {
        await part.create(exclusive: true);
      } on FileSystemException {
        if (await part.exists()) continue;
        rethrow;
      }
      // Whoever held this claim before may have finished between the check
      // above and taking it.
      if (await File(candidate).exists()) {
        await _deleteQuietly(part);
        continue;
      }
      return OperationResult.success(
        data: _Reservation(finalPath: candidate, part: part),
      );
    }
    throw StateError('unreachable');
  }

  /// Checks the partial file and moves it to its final name.
  Future<OperationResult<TransferData>> _publish(
    _Reservation reservation,
    int fileSize,
  ) async {
    final part = reservation.part;
    final verifyResult = await _validationService.validateSavedFile(
      part,
      fileSize,
    );
    if (!verifyResult.isSuccess) {
      await _deleteQuietly(part);
      return OperationResult.failure(verifyResult.errorMessage!);
    }

    try {
      // The claim keeps other receives off the name, not other programs.
      var target = reservation.finalPath;
      if (await File(target).exists()) {
        target = await _firstUnclaimed(target);
      }
      final saved = await part.rename(target);
      return OperationResult.success(
        data: TransferData(savedPath: saved.path, bytesTransferred: fileSize),
      );
    } catch (e) {
      await _deleteQuietly(part);
      rethrow;
    }
  }

  Future<String> _firstUnclaimed(String wanted) async {
    for (final candidate in _candidates(wanted)) {
      if (!await File(candidate).exists() &&
          !await File('$candidate$partSuffix').exists()) {
        return candidate;
      }
    }
    throw StateError('unreachable');
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

  /// [fullPath], then `name(1).ext`, `name(2).ext`, ... in the same folder.
  static Iterable<String> _candidates(String fullPath) sync* {
    yield fullPath;

    final parentDir = path.dirname(fullPath);
    final fileName = path.basename(fullPath);
    final lastDotIndex = fileName.lastIndexOf('.');
    String baseName;
    String extension;

    if (lastDotIndex > 0 && lastDotIndex < fileName.length - 1) {
      baseName = fileName.substring(0, lastDotIndex);
      extension = fileName.substring(lastDotIndex);
    } else {
      baseName = fileName;
      extension = '';
    }

    for (var counter = 1; ; counter++) {
      yield path.join(parentDir, '$baseName($counter)$extension');
    }
  }

  /// Suffix of a file still being received.
  static const String partSuffix = '.part';
}

/// A name claimed in the save directory, and the partial file holding it.
class _Reservation {
  const _Reservation({required this.finalPath, required this.part});

  final String finalPath;
  final File part;
}
