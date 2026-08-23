import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import '../../utils/constants.dart';
import 'relay_crypto.dart';
import 'relay_crypto_worker.dart';
import 'relay_protocol.dart';

/// The wire format of an encrypted file.
///
/// A file becomes a sequence of self-describing frames:
///
/// ```
/// +--------------+-------------------------------+
/// | u32 frameLen | ciphertext ‖ tag (16 bytes)   |
/// +--------------+-------------------------------+
/// ```
///
/// Each frame holds one 64 KiB chunk of plaintext, encrypted under a key
/// derived for this file alone. The length prefix exists so the receiver can
/// find frame boundaries in a byte stream that arrives in arbitrary pieces,
/// and so the chunk size can change in a later version without a new format.
///
/// Both directions run through [RelayCryptoWorker] with several frames in
/// flight, so encryption overlaps the network instead of taking turns with it.
class RelayFrameCodec {
  final RelayCryptoWorker _worker;
  final int chunkSize;
  final int queueDepth;

  RelayFrameCodec({
    required RelayCryptoWorker worker,
    this.chunkSize = AppConstants.relayChunkSize,
    this.queueDepth = AppConstants.relayCryptoQueueDepth,
  }) : _worker = worker;

  /// Ciphertext length of a plaintext of [size] bytes.
  ///
  /// Needed up front for `Content-Length`: the relay counts bytes against the
  /// stream limit, and a chunked upload would make progress meaningless.
  static int encryptedLength(int size) {
    return size +
        FileBegin.chunkCountFor(size) * AppConstants.relayFrameOverhead;
  }

  /// Ciphertext length of the tail of a file that starts at [startChunk].
  ///
  /// A resumed upload sends fewer frames than the file has, so the length the
  /// relay is told to expect has to be the length of what actually travels.
  static int encryptedLengthFrom(int size, int startChunk) {
    if (startChunk <= 0) {
      return encryptedLength(size);
    }
    final remaining = size - startChunk * AppConstants.relayChunkSize;
    final frames = FileBegin.chunkCountFor(size) - startChunk;
    return remaining + frames * AppConstants.relayFrameOverhead;
  }

  /// Encrypts [plaintext] into frames.
  ///
  /// The chunk being read is always one ahead of the chunk being encrypted,
  /// because the final frame is flagged as final and that is only knowable
  /// after seeing that nothing follows it.
  ///
  /// [startChunk] numbers the first frame. It must match the offset the
  /// [plaintext] stream was opened at, because the chunk index is part of both
  /// the nonce and the additional data: a frame numbered wrongly will not
  /// decrypt, which is the intended outcome for a misaligned resume.
  Stream<List<int>> encrypt(
    Stream<List<int>> plaintext,
    RelayFileKey fileKey, {
    int startChunk = 0,
    void Function(int plaintextBytes)? onChunkEncrypted,
  }) async* {
    final chunks = _rechunk(plaintext, chunkSize);
    final inFlight = Queue<_PendingFrame>();

    try {
      var index = startChunk;
      Uint8List? held;
      var sawAny = false;

      await for (final chunk in chunks) {
        sawAny = true;
        if (held != null) {
          inFlight.add(_submitEncrypt(fileKey, index++, held, isFinal: false));
          while (inFlight.length >= queueDepth) {
            yield* _drainOne(inFlight, onChunkEncrypted);
          }
        }
        held = chunk;
      }

      // An empty file still gets one frame, so the receiver has a final flag
      // to verify rather than an absence of evidence. Past the start of the
      // file there is no such case: a resume that found nothing left to read
      // is reading a different file than the one that was announced.
      if (!sawAny) {
        if (startChunk > 0) {
          throw RelayCryptoException('续传起点已越过文件末尾');
        }
        held = Uint8List(0);
      }

      inFlight.add(_submitEncrypt(fileKey, index, held!, isFinal: true));
      while (inFlight.isNotEmpty) {
        yield* _drainOne(inFlight, onChunkEncrypted);
      }
    } finally {
      _abandon(inFlight);
    }
  }

  /// Decrypts a frame stream back into plaintext.
  ///
  /// Throws [RelayCryptoException] when a frame fails to verify, when the
  /// stream ends early, or when it continues past the frame that claimed to be
  /// the last one. All three are the same thing from the user's point of view:
  /// what arrived is not what was sent.
  Stream<List<int>> decrypt(
    Stream<List<int>> frames,
    RelayFileKey fileKey, {
    required int chunkCount,
    int startChunk = 0,
  }) async* {
    final buffer = _FrameBuffer();
    final inFlight = Queue<_PendingFrame>();

    try {
      var index = startChunk;
      var finished = false;

      await for (final data in frames) {
        buffer.add(data);

        while (true) {
          final frame = buffer.takeFrame();
          if (frame == null) {
            break;
          }
          if (finished) {
            throw RelayCryptoException('中转数据流在结束帧之后仍有数据');
          }

          final isFinal = index == chunkCount - 1;
          finished = isFinal;
          inFlight.add(
            _submitDecrypt(fileKey, index++, frame, isFinal: isFinal),
          );

          while (inFlight.length >= queueDepth) {
            yield await inFlight.removeFirst().bytes;
          }
        }
      }

      while (inFlight.isNotEmpty) {
        yield await inFlight.removeFirst().bytes;
      }

      if (!finished) {
        throw RelayCryptoException('中转数据流在传完之前被截断');
      }
      if (!buffer.isEmpty) {
        throw RelayCryptoException('中转数据流末尾有不完整的帧');
      }
    } finally {
      _abandon(inFlight);
    }
  }

  /// Drops frames still being worked on after the stream gave up.
  ///
  /// Their results are no longer wanted, but a future nobody looks at turns
  /// its failure into an unhandled error that surfaces somewhere unrelated.
  static void _abandon(Queue<_PendingFrame> inFlight) {
    while (inFlight.isNotEmpty) {
      inFlight.removeFirst().bytes.ignore();
    }
  }

  Stream<List<int>> _drainOne(
    Queue<_PendingFrame> inFlight,
    void Function(int plaintextBytes)? onChunkEncrypted,
  ) async* {
    final pending = inFlight.removeFirst();
    final body = await pending.bytes;

    final header = Uint8List(AppConstants.relayFrameHeaderBytes);
    ByteData.view(header.buffer).setUint32(0, body.length, Endian.big);

    yield header;
    yield body;
    onChunkEncrypted?.call(pending.plaintextBytes);
  }

  _PendingFrame _submitEncrypt(
    RelayFileKey fileKey,
    int index,
    Uint8List chunk, {
    required bool isFinal,
  }) {
    return _PendingFrame(
      plaintextBytes: chunk.length,
      bytes: _worker.encrypt(
        key: fileKey.key,
        nonce: fileKey.nonceFor(index),
        aad: fileKey.aadFor(index, isFinal: isFinal),
        data: chunk,
      ),
    );
  }

  _PendingFrame _submitDecrypt(
    RelayFileKey fileKey,
    int index,
    Uint8List frame, {
    required bool isFinal,
  }) {
    return _PendingFrame(
      plaintextBytes: 0,
      bytes: _worker.decrypt(
        key: fileKey.key,
        nonce: fileKey.nonceFor(index),
        aad: fileKey.aadFor(index, isFinal: isFinal),
        data: frame,
      ),
    );
  }

  /// Regroups a stream of arbitrary pieces into fixed-size chunks.
  static Stream<Uint8List> _rechunk(
    Stream<List<int>> source,
    int chunkSize,
  ) async* {
    final builder = BytesBuilder(copy: true);

    await for (final piece in source) {
      builder.add(piece);
      while (builder.length >= chunkSize) {
        final taken = builder.takeBytes();
        var offset = 0;
        while (taken.length - offset >= chunkSize) {
          yield Uint8List.sublistView(taken, offset, offset + chunkSize);
          offset += chunkSize;
        }
        if (offset < taken.length) {
          builder.add(Uint8List.sublistView(taken, offset));
        }
      }
    }

    if (builder.length > 0) {
      yield builder.takeBytes();
    }
  }
}

class _PendingFrame {
  final int plaintextBytes;
  final Future<Uint8List> bytes;

  const _PendingFrame({required this.plaintextBytes, required this.bytes});
}

/// Reassembles length-prefixed frames from a stream of arbitrary pieces.
class _FrameBuffer {
  final BytesBuilder _builder = BytesBuilder(copy: true);
  Uint8List _pending = Uint8List(0);

  bool get isEmpty => _pending.isEmpty;

  void add(List<int> data) {
    if (data.isEmpty) {
      return;
    }
    _builder
      ..clear()
      ..add(_pending)
      ..add(data);
    _pending = _builder.takeBytes();
  }

  /// Returns the next complete frame body, or null when more bytes are needed.
  Uint8List? takeFrame() {
    if (_pending.length < AppConstants.relayFrameHeaderBytes) {
      return null;
    }

    final length = ByteData.view(
      _pending.buffer,
      _pending.offsetInBytes,
    ).getUint32(0, Endian.big);

    if (length < AppConstants.relayAeadTagBytes ||
        length >
            AppConstants.relayChunkSize + AppConstants.relayAeadTagBytes) {
      throw RelayCryptoException('中转数据流的帧长度不合法: $length');
    }

    final total = AppConstants.relayFrameHeaderBytes + length;
    if (_pending.length < total) {
      return null;
    }

    final frame = Uint8List.sublistView(
      _pending,
      AppConstants.relayFrameHeaderBytes,
      total,
    );
    _pending = Uint8List.sublistView(_pending, total);
    return Uint8List.fromList(frame);
  }
}
