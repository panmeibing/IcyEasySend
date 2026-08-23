import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/relay/relay_crypto.dart';
import 'package:icy_easy_send/services/relay/relay_crypto_worker.dart';
import 'package:icy_easy_send/services/relay/relay_frame_codec.dart';
import 'package:icy_easy_send/services/relay/relay_protocol.dart';
import 'package:icy_easy_send/utils/constants.dart';

/// The bulk encryption layer.
///
/// A relay that wants to corrupt a transfer has exactly three moves: change
/// bytes, stop early, or add more. Each has a test here, because "the file
/// arrived" and "the file arrived intact" have to be the same statement.
void main() {
  late RelayCryptoWorker worker;
  late RelayFrameCodec codec;
  late RelayFileKey fileKey;

  setUp(() async {
    worker = await RelayCryptoWorker.spawn();
    codec = RelayFrameCodec(worker: worker);
    fileKey = RelayFileKey(
      fileId: '0123456789abcdef0123456789abcdef',
      key: Uint8List.fromList(List.generate(32, (i) => i)),
      noncePrefix: Uint8List.fromList([1, 2, 3, 4]),
    );
  });

  tearDown(() async {
    await worker.dispose();
  });

  Uint8List payload(int size) {
    return Uint8List.fromList(List.generate(size, (i) => (i * 31 + 7) % 256));
  }

  Future<Uint8List> collect(Stream<List<int>> stream) async {
    final builder = BytesBuilder(copy: true);
    await for (final piece in stream) {
      builder.add(piece);
    }
    return builder.takeBytes();
  }

  Future<Uint8List> encryptAll(Uint8List plaintext, {int? pieceSize}) {
    return collect(
      codec.encrypt(_asStream(plaintext, pieceSize ?? plaintext.length), fileKey),
    );
  }

  group('round trip', () {
    const sizes = <int>[
      0,
      1,
      1024,
      AppConstants.relayChunkSize - 1,
      AppConstants.relayChunkSize,
      AppConstants.relayChunkSize + 1,
      AppConstants.relayChunkSize * 3 + 17,
    ];

    for (final size in sizes) {
      test('$size bytes survive encryption and decryption', () async {
        final plaintext = payload(size);
        final ciphertext = await encryptAll(plaintext);

        final decrypted = await collect(
          codec.decrypt(
            _asStream(ciphertext, 7777),
            fileKey,
            chunkCount: FileBegin.chunkCountFor(size),
          ),
        );

        expect(decrypted, plaintext);
      });
    }

    test('the ciphertext length is known before encrypting', () async {
      for (final size in sizes) {
        final ciphertext = await encryptAll(payload(size));
        expect(
          ciphertext.length,
          RelayFrameCodec.encryptedLength(size),
          reason: 'size $size',
        );
      }
    });

    test('input arriving in odd pieces is regrouped into full chunks',
        () async {
      final plaintext = payload(AppConstants.relayChunkSize * 2 + 123);

      // Same bytes, different arrival pattern: the frames must be identical,
      // or the receiver's chunk indices would not line up.
      final whole = await encryptAll(plaintext);
      final dribbled = await encryptAll(plaintext, pieceSize: 1000);

      expect(dribbled, whole);
    });

    test('an empty file still produces one authenticated frame', () async {
      final ciphertext = await encryptAll(payload(0));

      expect(ciphertext.length, AppConstants.relayFrameOverhead);
      expect(
        await collect(
          codec.decrypt(_asStream(ciphertext, 4), fileKey, chunkCount: 1),
        ),
        isEmpty,
      );
    });
  });

  group('resuming', () {
    const chunkSize = AppConstants.relayChunkSize;

    test('the tail of a file decrypts to the tail of the plaintext', () async {
      const size = chunkSize * 4 + 500;
      final plaintext = payload(size);
      const startChunk = 2;

      final ciphertext = await collect(
        codec.encrypt(
          _asStream(
            Uint8List.sublistView(plaintext, startChunk * chunkSize),
            9999,
          ),
          fileKey,
          startChunk: startChunk,
        ),
      );

      final decrypted = await collect(
        codec.decrypt(
          _asStream(ciphertext, 3333),
          fileKey,
          chunkCount: FileBegin.chunkCountFor(size),
          startChunk: startChunk,
        ),
      );

      expect(decrypted, Uint8List.sublistView(plaintext, startChunk * chunkSize));
    });

    test('a resumed frame is byte-identical to the same frame sent whole',
        () async {
      // Chunk numbering is part of the nonce and the additional data, so the
      // two paths have to agree on it exactly. If they ever diverge, a resumed
      // transfer produces a file that will not decrypt.
      const size = chunkSize * 3;
      final plaintext = payload(size);

      final whole = await encryptAll(plaintext);
      final tail = await collect(
        codec.encrypt(
          _asStream(Uint8List.sublistView(plaintext, chunkSize * 2), chunkSize),
          fileKey,
          startChunk: 2,
        ),
      );

      final frameLength = chunkSize + AppConstants.relayFrameOverhead;
      expect(tail, Uint8List.sublistView(whole, frameLength * 2));
    });

    test('the length of a resumed upload is known before it starts', () async {
      const size = chunkSize * 4 + 77;
      final plaintext = payload(size);

      for (var startChunk = 0; startChunk < 5; startChunk++) {
        final ciphertext = await collect(
          codec.encrypt(
            _asStream(
              Uint8List.sublistView(plaintext, startChunk * chunkSize),
              chunkSize,
            ),
            fileKey,
            startChunk: startChunk,
          ),
        );

        expect(
          ciphertext.length,
          RelayFrameCodec.encryptedLengthFrom(size, startChunk),
          reason: 'startChunk $startChunk',
        );
      }
    });

    test('frames numbered from the wrong chunk do not decrypt', () async {
      const size = chunkSize * 3;
      final plaintext = payload(size);

      final ciphertext = await collect(
        codec.encrypt(
          _asStream(Uint8List.sublistView(plaintext, chunkSize * 2), chunkSize),
          fileKey,
          startChunk: 2,
        ),
      );

      // A receiver that resumed from somewhere else reads the same bytes under
      // a different nonce, and the tag stops it.
      expect(
        collect(
          codec.decrypt(
            _asStream(ciphertext, 1024),
            fileKey,
            chunkCount: 3,
            startChunk: 1,
          ),
        ),
        throwsA(isA<RelayCryptoException>()),
      );
    });

    test('a resume that starts past the end of the file is refused', () async {
      expect(
        collect(
          codec.encrypt(
            const Stream<List<int>>.empty(),
            fileKey,
            startChunk: 3,
          ),
        ),
        throwsA(isA<RelayCryptoException>()),
      );
    });
  });

  group('tampering', () {
    test('a flipped ciphertext bit fails the frame', () async {
      final ciphertext = await encryptAll(payload(4096));
      ciphertext[10] ^= 0x01;

      expect(
        collect(
          codec.decrypt(_asStream(ciphertext, 512), fileKey, chunkCount: 1),
        ),
        throwsA(isA<RelayCryptoException>()),
      );
    });

    test('a truncated stream is not mistaken for a complete file', () async {
      final size = AppConstants.relayChunkSize * 2;
      final ciphertext = await encryptAll(payload(size));

      // Exactly what a relay closing the connection early looks like: whole
      // frames, just fewer of them.
      final firstFrameOnly = Uint8List.sublistView(
        ciphertext,
        0,
        AppConstants.relayChunkSize + AppConstants.relayFrameOverhead,
      );

      expect(
        collect(
          codec.decrypt(
            _asStream(firstFrameOnly, 8192),
            fileKey,
            chunkCount: FileBegin.chunkCountFor(size),
          ),
        ),
        throwsA(isA<RelayCryptoException>()),
      );
    });

    test('a half frame at the end is not accepted', () async {
      final ciphertext = await encryptAll(payload(2048));
      final clipped = Uint8List.sublistView(
        ciphertext,
        0,
        ciphertext.length - 4,
      );

      expect(
        collect(
          codec.decrypt(_asStream(clipped, 512), fileKey, chunkCount: 1),
        ),
        throwsA(isA<RelayCryptoException>()),
      );
    });

    test('data appended after the final frame is rejected', () async {
      final ciphertext = await encryptAll(payload(1024));
      final extended = Uint8List.fromList([...ciphertext, ...ciphertext]);

      expect(
        collect(
          codec.decrypt(_asStream(extended, 512), fileKey, chunkCount: 1),
        ),
        throwsA(isA<RelayCryptoException>()),
      );
    });

    test('two frames swapped around fail their chunk index', () async {
      final plaintext = payload(AppConstants.relayChunkSize * 2);
      final ciphertext = await encryptAll(plaintext);

      const frameLength =
          AppConstants.relayChunkSize + AppConstants.relayFrameOverhead;
      final swapped = Uint8List(ciphertext.length)
        ..setRange(0, frameLength, ciphertext, frameLength)
        ..setRange(frameLength, ciphertext.length, ciphertext);

      expect(
        collect(
          codec.decrypt(_asStream(swapped, 8192), fileKey, chunkCount: 2),
        ),
        throwsA(isA<RelayCryptoException>()),
      );
    });

    test('a frame claiming an impossible length is rejected', () async {
      final bogus = Uint8List(64);
      ByteData.view(bogus.buffer).setUint32(0, 1 << 30);

      expect(
        collect(codec.decrypt(_asStream(bogus, 64), fileKey, chunkCount: 1)),
        throwsA(isA<RelayCryptoException>()),
      );
    });

    test('the wrong key cannot read the frames', () async {
      final ciphertext = await encryptAll(payload(1024));
      final otherKey = RelayFileKey(
        fileId: fileKey.fileId,
        key: Uint8List.fromList(List.generate(32, (i) => 255 - i)),
        noncePrefix: fileKey.noncePrefix,
      );

      expect(
        collect(
          codec.decrypt(_asStream(ciphertext, 512), otherKey, chunkCount: 1),
        ),
        throwsA(isA<RelayCryptoException>()),
      );
    });
  });

  group('the worker', () {
    test('encryption runs in its own isolate', () {
      // If this ever fails, transfers still work but the UI stutters, so it
      // is worth knowing about.
      expect(worker.isOffloaded, isTrue);
    });

    test('an inline worker produces identical frames', () async {
      final inline = RelayCryptoWorker.inlineForTesting();
      final inlineCodec = RelayFrameCodec(worker: inline);
      final plaintext = payload(AppConstants.relayChunkSize + 5);

      expect(
        await collect(inlineCodec.encrypt(_asStream(plaintext, 4096), fileKey)),
        await encryptAll(plaintext),
      );
      await inline.dispose();
    });

    test('progress is reported per chunk of plaintext', () async {
      final observed = <int>[];
      await collect(
        codec.encrypt(
          _asStream(payload(AppConstants.relayChunkSize * 2 + 10), 4096),
          fileKey,
          onChunkEncrypted: observed.add,
        ),
      );

      expect(observed, [
        AppConstants.relayChunkSize,
        AppConstants.relayChunkSize,
        10,
      ]);
    });
  });
}

/// Emits [data] in pieces, the way a socket would.
Stream<List<int>> _asStream(Uint8List data, int pieceSize) async* {
  if (data.isEmpty) {
    return;
  }
  for (var offset = 0; offset < data.length; offset += pieceSize) {
    final end = (offset + pieceSize).clamp(0, data.length);
    yield Uint8List.sublistView(data, offset, end);
  }
}
