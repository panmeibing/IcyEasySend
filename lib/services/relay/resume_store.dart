import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as path;

import '../../utils/constants.dart';
import '../../utils/log_util.dart';
import '../../utils/platform_util.dart';

/// What a half-received file is worth to the next attempt.
class ResumePoint {
  /// Chunks already on disk and vouched for. Zero means start over.
  final int resumeFromChunk;

  /// Base64 SHA-256 of the plaintext of chunk `resumeFromChunk - 1`, for the
  /// sender to check its own copy against. Null when there is nothing to
  /// resume from.
  final String? lastChunkHash;

  const ResumePoint(this.resumeFromChunk, this.lastChunkHash);

  static const ResumePoint none = ResumePoint(0, null);

  bool get isUsable => resumeFromChunk > 0 && lastChunkHash != null;
}

/// Half-received files, kept so an interrupted transfer need not start over.
///
/// A file in flight is two files on disk: `{fileId}.part` holding the bytes and
/// `{fileId}.meta` describing how many of them are trustworthy. They live in a
/// hidden folder inside the save directory rather than in the app's own
/// storage, so finishing a file is a rename rather than a copy of every byte —
/// on Android those two locations are routinely different mounts.
///
/// The record may lag behind the bytes; it may never lead them. Everything
/// here is arranged so that a process killed mid-write loses at most the
/// unflushed tail, never the integrity of what came before.
class ResumeStore {
  final Directory? Function()? _directoryOverride;
  final String logTag = LogTags.transfer;

  /// [directoryOverride] exists for tests, which cannot write to the real
  /// save directory.
  ResumeStore({Directory? Function()? directoryOverride})
    : _directoryOverride = directoryOverride;

  /// File ids name files on disk, so anything but plain hex is refused.
  ///
  /// The id comes from a paired and authenticated peer, but "authenticated"
  /// is not "trusted with a path".
  static final RegExp _validFileId = RegExp(r'^[0-9a-f]{4,64}$');

  static bool isValidFileId(String fileId) => _validFileId.hasMatch(fileId);

  /// The folder holding partial files, created on first use.
  ///
  /// Null when there is nowhere to save to, in which case resuming is simply
  /// unavailable and transfers behave as they did before.
  Future<Directory?> directory() async {
    final override = _directoryOverride?.call();
    if (override != null) {
      if (!await override.exists()) {
        await override.create(recursive: true);
      }
      return override;
    }

    final saveDir = await PlatformUtil.getReceiveSaveDirectory();
    if (saveDir == null) {
      return null;
    }

    final partialDir = Directory(
      path.join(saveDir.path, AppConstants.relayPartialDirName),
    );
    try {
      if (!await partialDir.exists()) {
        await partialDir.create(recursive: true);
      }
      return partialDir;
    } catch (e) {
      LogUtil.wTag(logTag, '无法创建断点续传目录: $e');
      return null;
    }
  }

  /// Where a previous attempt at [fileId] left off.
  ///
  /// [chunkCount] caps the answer at one chunk short of the whole file: the
  /// final frame carries the flag that proves the stream was not truncated, so
  /// it is always re-sent even when the bytes are already here.
  Future<ResumePoint> inspect({
    required String fileId,
    required int size,
    required int chunkCount,
  }) async {
    if (!isValidFileId(fileId)) {
      return ResumePoint.none;
    }

    final dir = await directory();
    if (dir == null) {
      return ResumePoint.none;
    }

    try {
      final meta = await _readMeta(dir, fileId);
      final part = _partFile(dir, fileId);
      if (meta == null || !await part.exists()) {
        return ResumePoint.none;
      }

      // The id already covers the path, size and modification time, so a
      // mismatch here means the record belongs to a different file that
      // happens to have collided. Trusting it would splice two files together.
      if (meta.size != size || meta.chunkSize != AppConstants.relayChunkSize) {
        await discard(fileId);
        return ResumePoint.none;
      }

      // The bytes are the authority. A record claiming more than the file
      // holds is one that was written before the process died.
      final onDisk = await part.length() ~/ AppConstants.relayChunkSize;
      final usable = [
        meta.verifiedChunks,
        onDisk,
        chunkCount - 1,
      ].reduce((a, b) => a < b ? a : b);

      if (usable <= 0 || meta.lastChunkHash == null) {
        return ResumePoint.none;
      }
      // The hash describes the chunk the record ends at; it says nothing about
      // an earlier point, so a record trimmed by the file's actual length can
      // no longer be resumed from.
      if (usable != meta.verifiedChunks) {
        return ResumePoint.none;
      }

      return ResumePoint(usable, meta.lastChunkHash);
    } catch (e) {
      LogUtil.wTag(logTag, '读取断点续传状态失败 $fileId: $e');
      return ResumePoint.none;
    }
  }

  /// Opens the partial file for writing, positioned at [startChunk].
  ///
  /// Anything already past that point is dropped: the sender has ruled on
  /// where this attempt begins, and bytes beyond it belong to an attempt whose
  /// chunks may not line up with this one's.
  Future<ResumeWriter?> openAt({
    required String fileId,
    required int size,
    required int startChunk,
  }) async {
    if (!isValidFileId(fileId)) {
      return null;
    }

    final dir = await directory();
    if (dir == null) {
      return null;
    }

    final offset = startChunk * AppConstants.relayChunkSize;
    final part = _partFile(dir, fileId);

    try {
      if (!await part.exists()) {
        if (startChunk > 0) {
          return null;
        }
        await part.create(recursive: true);
      } else if (await part.length() < offset) {
        // The sender is resuming from further along than this device ever
        // received. Nothing here can be reused.
        return null;
      }

      final handle = await part.open(mode: FileMode.append);
      await handle.truncate(offset);
      await handle.setPosition(offset);

      return ResumeWriter._(
        store: this,
        fileId: fileId,
        size: size,
        part: part,
        meta: _metaFile(dir, fileId),
        handle: handle,
        startChunk: startChunk,
      );
    } catch (e) {
      LogUtil.wTag(logTag, '无法打开断点续传文件 $fileId: $e');
      return null;
    }
  }

  /// Removes both files of one transfer, if they are there.
  Future<void> discard(String fileId) async {
    if (!isValidFileId(fileId)) {
      return;
    }
    final dir = await directory();
    if (dir == null) {
      return;
    }

    for (final file in [_partFile(dir, fileId), _metaFile(dir, fileId)]) {
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        LogUtil.wTag(logTag, '无法删除断点续传文件 ${file.path}: $e');
      }
    }
  }

  /// Deletes leftovers older than [maxAge], returning how many files went.
  ///
  /// A transfer that is never retried would otherwise keep its bytes forever,
  /// and the user has no way to see the folder, let alone clean it.
  Future<int> sweep({Duration maxAge = AppConstants.relayPartialMaxAge}) async {
    final dir = await directory();
    if (dir == null) {
      return 0;
    }

    var removed = 0;
    try {
      final now = DateTime.now();
      await for (final entry in dir.list(followLinks: false)) {
        if (entry is! File) {
          continue;
        }
        final name = path.basename(entry.path);
        if (!name.endsWith(AppConstants.relayPartialSuffix) &&
            !name.endsWith(AppConstants.relayPartialMetaSuffix)) {
          continue;
        }
        final stat = await entry.stat();
        if (now.difference(stat.modified) <= maxAge) {
          continue;
        }
        await entry.delete();
        removed++;
      }
    } catch (e) {
      LogUtil.wTag(logTag, '清理断点续传目录失败: $e');
    }

    if (removed > 0) {
      LogUtil.iTag(logTag, '清理了 $removed 个过期的断点续传文件');
    }
    return removed;
  }

  File _partFile(Directory dir, String fileId) =>
      File(path.join(dir.path, '$fileId${AppConstants.relayPartialSuffix}'));

  File _metaFile(Directory dir, String fileId) => File(
    path.join(dir.path, '$fileId${AppConstants.relayPartialMetaSuffix}'),
  );

  Future<_ResumeMeta?> _readMeta(Directory dir, String fileId) async {
    final file = _metaFile(dir, fileId);
    if (!await file.exists()) {
      return null;
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      return decoded is Map<String, dynamic>
          ? _ResumeMeta.tryParse(decoded)
          : null;
    } catch (_) {
      // A record written half way through a crash is simply not a record.
      return null;
    }
  }
}

/// Writes one file's chunks, keeping the on-disk record honest as it goes.
///
/// Chunks must arrive whole and in order, which is what the frame codec emits:
/// one yielded element is one decrypted chunk. That is what lets the record
/// count in chunks rather than bytes, and a chunk count is what the sender
/// needs to know where to start.
class ResumeWriter {
  final ResumeStore _store;
  final String fileId;
  final int size;
  final File part;
  final File _meta;
  final RandomAccessFile _handle;
  final int startChunk;

  int _chunksWritten;
  int _bytesWritten;

  /// Held so the hash is computed once per flush rather than once per chunk.
  Uint8List? _lastChunk;

  int _flushedChunks;
  String? _flushedHash;
  bool _closed = false;

  ResumeWriter._({
    required ResumeStore store,
    required this.fileId,
    required this.size,
    required this.part,
    required File meta,
    required RandomAccessFile handle,
    required this.startChunk,
  }) : _store = store,
       _meta = meta,
       _handle = handle,
       _chunksWritten = startChunk,
       _flushedChunks = startChunk,
       _bytesWritten = startChunk * AppConstants.relayChunkSize;

  /// Total bytes of the file now on disk, including what a previous attempt
  /// left behind.
  int get bytesWritten => _bytesWritten;

  int get chunksWritten => _chunksWritten;

  /// Appends one decrypted chunk.
  Future<void> add(List<int> chunk) async {
    await _handle.writeFrom(chunk);
    _chunksWritten++;
    _bytesWritten += chunk.length;
    _lastChunk = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);

    if (_chunksWritten - _flushedChunks >= AppConstants.relayResumeFlushChunks) {
      await _persist();
    }
  }

  /// Gives up on this attempt but keeps what arrived.
  ///
  /// Returns the chunk a retry may start from, or null when nothing survived
  /// worth resuming from.
  Future<int?> abandon() async {
    if (_closed) {
      return _flushedChunks > 0 ? _flushedChunks : null;
    }
    try {
      await _persist();
    } catch (e) {
      LogUtil.wTag(_store.logTag, '保存断点续传状态失败 $fileId: $e');
    }
    await _close();
    return _flushedChunks > 0 ? _flushedChunks : null;
  }

  /// Closes the file after the last chunk, leaving it ready to be moved.
  Future<File> complete() async {
    await _handle.flush();
    await _close();
    return part;
  }

  /// Drops the partial file and its record.
  Future<void> discard() async {
    await _close();
    await _store.discard(fileId);
  }

  Future<void> _persist() async {
    final chunk = _lastChunk;
    if (chunk == null || _chunksWritten == _flushedChunks) {
      return;
    }

    // Order matters: the record may only describe bytes that are already
    // durable, or a crash between the two would leave it vouching for data
    // that never landed.
    await _handle.flush();
    final digest = await Sha256().hash(chunk);
    _flushedChunks = _chunksWritten;
    _flushedHash = base64Encode(digest.bytes);

    await _meta.writeAsString(
      jsonEncode(
        _ResumeMeta(
          fileId: fileId,
          size: size,
          chunkSize: AppConstants.relayChunkSize,
          verifiedChunks: _flushedChunks,
          lastChunkHash: _flushedHash,
        ).toJson(),
      ),
      flush: true,
    );
  }

  Future<void> _close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    try {
      await _handle.close();
    } catch (e) {
      LogUtil.wTag(_store.logTag, '关闭断点续传文件失败 $fileId: $e');
    }
  }
}

/// The `.meta` record beside a partial file.
class _ResumeMeta {
  final String fileId;
  final int size;
  final int chunkSize;
  final int verifiedChunks;
  final String? lastChunkHash;

  const _ResumeMeta({
    required this.fileId,
    required this.size,
    required this.chunkSize,
    required this.verifiedChunks,
    required this.lastChunkHash,
  });

  Map<String, dynamic> toJson() => {
    'fileId': fileId,
    'size': size,
    'chunkSize': chunkSize,
    'verifiedChunks': verifiedChunks,
    'lastChunkHash': ?lastChunkHash,
    'updatedAt': DateTime.now().millisecondsSinceEpoch ~/ 1000,
  };

  static _ResumeMeta? tryParse(Map<String, dynamic> json) {
    final fileId = json['fileId'];
    final size = json['size'];
    final chunkSize = json['chunkSize'];
    final verifiedChunks = json['verifiedChunks'];
    final hash = json['lastChunkHash'];

    if (fileId is! String || fileId.isEmpty) return null;
    if (size is! int || size < 0) return null;
    if (chunkSize is! int || chunkSize <= 0) return null;
    if (verifiedChunks is! int || verifiedChunks < 0) return null;

    return _ResumeMeta(
      fileId: fileId,
      size: size,
      chunkSize: chunkSize,
      verifiedChunks: verifiedChunks,
      lastChunkHash: hash is String && hash.isNotEmpty ? hash : null,
    );
  }
}
