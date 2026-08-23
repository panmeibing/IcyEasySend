import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/relay/resume_store.dart';
import 'package:icy_easy_send/utils/constants.dart';
import 'package:path/path.dart' as p;

/// The bookkeeping behind resumable relay transfers.
///
/// What these check is mostly one property stated several ways: the record on
/// disk may lag behind the bytes but must never lead them. Everything a sender
/// is told about a partial file has to be backed by bytes that are actually
/// there, because the sender will skip exactly that much.
void main() {
  late Directory workspace;
  late ResumeStore store;

  const chunkSize = AppConstants.relayChunkSize;
  const fileId = 'a1b2c3d4e5f60718';

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    workspace = await Directory.systemTemp.createTemp('resume_store_test');
    store = ResumeStore(directoryOverride: () => workspace);
  });

  tearDown(() async {
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  });

  Uint8List chunk(int fill) => Uint8List.fromList(List.filled(chunkSize, fill));

  File partFile(String id) =>
      File(p.join(workspace.path, '$id${AppConstants.relayPartialSuffix}'));

  File metaFile(String id) =>
      File(p.join(workspace.path, '$id${AppConstants.relayPartialMetaSuffix}'));

  Future<String> hashOf(List<int> bytes) async {
    return base64Encode((await Sha256().hash(bytes)).bytes);
  }

  group('inspect', () {
    test('offers nothing when there is no partial file', () async {
      final point = await store.inspect(
        fileId: fileId,
        size: chunkSize * 4,
        chunkCount: 4,
      );

      expect(point.resumeFromChunk, 0);
      expect(point.isUsable, isFalse);
    });

    test('offers what an abandoned attempt left behind', () async {
      final writer = await store.openAt(
        fileId: fileId,
        size: chunkSize * 4,
        startChunk: 0,
      );
      await writer!.add(chunk(1));
      await writer.add(chunk(2));
      expect(await writer.abandon(), 2);

      final point = await store.inspect(
        fileId: fileId,
        size: chunkSize * 4,
        chunkCount: 4,
      );

      expect(point.resumeFromChunk, 2);
      expect(point.lastChunkHash, await hashOf(chunk(2)));
      expect(point.isUsable, isTrue);
    });

    test('refuses a record written for a file of another size', () async {
      final writer = await store.openAt(
        fileId: fileId,
        size: chunkSize * 4,
        startChunk: 0,
      );
      await writer!.add(chunk(1));
      await writer.abandon();

      final point = await store.inspect(
        fileId: fileId,
        size: chunkSize * 9,
        chunkCount: 9,
      );

      expect(point.isUsable, isFalse);
      // Nothing about it is reusable, so it should not be left to age out.
      expect(await partFile(fileId).exists(), isFalse);
      expect(await metaFile(fileId).exists(), isFalse);
    });

    test('will not vouch for chunks the partial file does not hold', () async {
      // A record that outlived the bytes it describes: the process died
      // between the two writes, or the page cache lost the tail.
      await partFile(fileId).writeAsBytes(chunk(1));
      await metaFile(fileId).writeAsString(
        jsonEncode({
          'fileId': fileId,
          'size': chunkSize * 4,
          'chunkSize': chunkSize,
          'verifiedChunks': 3,
          'lastChunkHash': await hashOf(chunk(3)),
        }),
      );

      final point = await store.inspect(
        fileId: fileId,
        size: chunkSize * 4,
        chunkCount: 4,
      );

      expect(point.isUsable, isFalse);
    });

    test('never offers the final chunk, however much it holds', () async {
      final writer = await store.openAt(
        fileId: fileId,
        size: chunkSize * 2,
        startChunk: 0,
      );
      await writer!.add(chunk(1));
      await writer.add(chunk(2));
      await writer.abandon();

      // Two chunks are on disk and the file is two chunks long, but the last
      // frame is what proves the stream ended where it should, so it always
      // travels again.
      final point = await store.inspect(
        fileId: fileId,
        size: chunkSize * 2,
        chunkCount: 2,
      );

      expect(point.isUsable, isFalse);
    });

    test('ignores a record with no hash to check against', () async {
      await partFile(fileId).writeAsBytes(chunk(1));
      await metaFile(fileId).writeAsString(
        jsonEncode({
          'fileId': fileId,
          'size': chunkSize * 4,
          'chunkSize': chunkSize,
          'verifiedChunks': 1,
        }),
      );

      final point = await store.inspect(
        fileId: fileId,
        size: chunkSize * 4,
        chunkCount: 4,
      );

      expect(point.isUsable, isFalse);
    });

    test('survives a corrupt record', () async {
      await partFile(fileId).writeAsBytes(chunk(1));
      await metaFile(fileId).writeAsString('{ this is not json');

      final point = await store.inspect(
        fileId: fileId,
        size: chunkSize * 4,
        chunkCount: 4,
      );

      expect(point.isUsable, isFalse);
    });
  });

  group('file ids', () {
    test('accepts only plain hex', () {
      expect(ResumeStore.isValidFileId('abc123'), isTrue);
      expect(ResumeStore.isValidFileId('../../etc/passwd'), isFalse);
      expect(ResumeStore.isValidFileId('ABC123'), isFalse);
      expect(ResumeStore.isValidFileId('a'), isFalse);
      expect(ResumeStore.isValidFileId('a1/b2'), isFalse);
    });

    test('refuses to open a file id that could name a path', () async {
      final writer = await store.openAt(
        fileId: '../escape',
        size: chunkSize,
        startChunk: 0,
      );

      expect(writer, isNull);
    });
  });

  group('openAt', () {
    test('drops anything past the chunk the sender chose', () async {
      final first = await store.openAt(
        fileId: fileId,
        size: chunkSize * 4,
        startChunk: 0,
      );
      await first!.add(chunk(1));
      await first.add(chunk(2));
      await first.add(chunk(3));
      await first.abandon();

      // The sender ruled that this attempt starts at chunk 1, so chunks 2 and
      // 3 belong to an attempt whose numbering may not line up with this one.
      final second = await store.openAt(
        fileId: fileId,
        size: chunkSize * 4,
        startChunk: 1,
      );
      expect(second, isNotNull);
      expect(await partFile(fileId).length(), chunkSize);

      await second!.add(chunk(9));
      await second.complete();

      final written = await partFile(fileId).readAsBytes();
      expect(written.length, chunkSize * 2);
      expect(written.sublist(0, chunkSize), chunk(1));
      expect(written.sublist(chunkSize), chunk(9));
    });

    test('refuses a start further along than it ever received', () async {
      final writer = await store.openAt(
        fileId: fileId,
        size: chunkSize * 4,
        startChunk: 0,
      );
      await writer!.add(chunk(1));
      await writer.abandon();

      expect(
        await store.openAt(
          fileId: fileId,
          size: chunkSize * 4,
          startChunk: 3,
        ),
        isNull,
      );
    });

    test('counts what an earlier attempt wrote towards progress', () async {
      final first = await store.openAt(
        fileId: fileId,
        size: chunkSize * 3,
        startChunk: 0,
      );
      await first!.add(chunk(1));
      await first.abandon();

      final second = await store.openAt(
        fileId: fileId,
        size: chunkSize * 3,
        startChunk: 1,
      );

      expect(second!.bytesWritten, chunkSize);
      await second.add(chunk(2));
      expect(second.bytesWritten, chunkSize * 2);
      await second.abandon();
    });
  });

  group('lifecycle', () {
    test('discard removes both files', () async {
      final writer = await store.openAt(
        fileId: fileId,
        size: chunkSize,
        startChunk: 0,
      );
      await writer!.add(chunk(1));
      await writer.discard();

      expect(await partFile(fileId).exists(), isFalse);
      expect(await metaFile(fileId).exists(), isFalse);
    });

    test('sweep removes stale leftovers and keeps fresh ones', () async {
      const stale = 'dead00000000beef';
      await partFile(stale).writeAsBytes([1, 2, 3]);
      await metaFile(stale).writeAsString('{}');
      final old = DateTime.now().subtract(const Duration(days: 30));
      await partFile(stale).setLastModified(old);
      await metaFile(stale).setLastModified(old);

      final fresh = await store.openAt(
        fileId: fileId,
        size: chunkSize,
        startChunk: 0,
      );
      await fresh!.add(chunk(1));
      await fresh.abandon();

      expect(await store.sweep(), 2);
      expect(await partFile(stale).exists(), isFalse);
      expect(await partFile(fileId).exists(), isTrue);
    });

    test('sweep leaves files it does not recognise alone', () async {
      final stranger = File(p.join(workspace.path, 'notes.txt'));
      await stranger.writeAsString('hello');
      await stranger.setLastModified(
        DateTime.now().subtract(const Duration(days: 30)),
      );

      expect(await store.sweep(), 0);
      expect(await stranger.exists(), isTrue);
    });
  });
}
