import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/relay/resume_store.dart';
import 'package:icy_easy_send/services/transfer/file_receiver.dart';
import 'package:icy_easy_send/utils/constants.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// The last step of a resumed transfer: turning a partial file into the file
/// the user asked for.
///
/// This is where a resumable download rejoins the path every other transfer
/// takes, so it has to make the same decisions — where the file goes, what
/// happens to a name already in use, what counts as arrived — or a resumed
/// file would behave differently from the same file sent in one go.
void main() {
  late Directory workspace;
  late Directory saveDir;
  late Directory partialDir;
  late FileReceiver receiver;
  late ResumeStore store;

  const chunkSize = AppConstants.relayChunkSize;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    workspace = await Directory.systemTemp.createTemp('adopt_test');
    saveDir = await Directory(p.join(workspace.path, 'downloads')).create();
    partialDir = await Directory(p.join(workspace.path, 'partial')).create();

    // A custom save path is the one way to resolve a destination without the
    // platform channel, which is unavailable to tests.
    SharedPreferences.setMockInitialValues({
      'custom_receive_save_path': saveDir.path,
    });

    receiver = FileReceiver();
    store = ResumeStore(directoryOverride: () => partialDir);
  });

  tearDown(() async {
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  });

  Future<File> partialWith(List<int> bytes) async {
    final file = File(p.join(workspace.path, 'source.part'));
    await file.writeAsBytes(bytes);
    return file;
  }

  test('moves the finished file into the save directory', () async {
    final bytes = List<int>.generate(2048, (i) => i % 256);
    final source = await partialWith(bytes);

    final result = await receiver.adoptReceivedFile(
      source: source,
      fileName: 'report.pdf',
      fileSize: bytes.length,
    );

    expect(result.isSuccess, isTrue, reason: result.errorMessage);
    final saved = File(p.join(saveDir.path, 'report.pdf'));
    expect(await saved.readAsBytes(), bytes);
    expect(result.data!.savedPath, saved.path);
    // The partial file is gone, not merely copied.
    expect(await source.exists(), isFalse);
  });

  test('gives a second file of the same name its own place', () async {
    await File(p.join(saveDir.path, 'notes.txt')).writeAsString('original');

    final result = await receiver.adoptReceivedFile(
      source: await partialWith([1, 2, 3]),
      fileName: 'notes.txt',
      fileSize: 3,
    );

    expect(result.isSuccess, isTrue, reason: result.errorMessage);
    expect(result.data!.savedPath, p.join(saveDir.path, 'notes(1).txt'));
    expect(
      await File(p.join(saveDir.path, 'notes.txt')).readAsString(),
      'original',
    );
  });

  test('creates the folders a nested transfer name asks for', () async {
    final result = await receiver.adoptReceivedFile(
      source: await partialWith([7, 7, 7]),
      fileName: p.join('photos', '2026', 'trip.jpg'),
      fileSize: 3,
    );

    expect(result.isSuccess, isTrue, reason: result.errorMessage);
    expect(
      await File(p.join(saveDir.path, 'photos', '2026', 'trip.jpg')).exists(),
      isTrue,
    );
  });

  test('refuses a name that would escape the save directory', () async {
    final source = await partialWith([1]);

    final result = await receiver.adoptReceivedFile(
      source: source,
      fileName: p.join('..', '..', 'escaped.txt'),
      fileSize: 1,
    );

    expect(result.isSuccess, isFalse);
    // The bytes stay where they were rather than landing somewhere unintended.
    expect(await source.exists(), isTrue);
  });

  test('discards a file whose size does not match what was promised', () async {
    final result = await receiver.adoptReceivedFile(
      source: await partialWith([1, 2, 3]),
      fileName: 'short.bin',
      fileSize: 9999,
    );

    expect(result.isSuccess, isFalse);
    expect(await File(p.join(saveDir.path, 'short.bin')).exists(), isFalse);
  });

  test('a file written chunk by chunk arrives whole', () async {
    const fileId = 'beef0000cafe1234';
    final head = Uint8List.fromList(List.filled(chunkSize, 3));
    final tail = Uint8List.fromList(List.filled(1000, 4));

    // First attempt: one chunk, then the connection drops.
    final first = await store.openAt(
      fileId: fileId,
      size: chunkSize + tail.length,
      startChunk: 0,
    );
    await first!.add(head);
    expect(await first.abandon(), 1);

    // Second attempt picks up where the record says, and finishes.
    final second = await store.openAt(
      fileId: fileId,
      size: chunkSize + tail.length,
      startChunk: 1,
    );
    await second!.add(tail);
    final part = await second.complete();

    final result = await receiver.adoptReceivedFile(
      source: part,
      fileName: 'resumed.bin',
      fileSize: chunkSize + tail.length,
    );

    expect(result.isSuccess, isTrue, reason: result.errorMessage);
    expect(
      await File(p.join(saveDir.path, 'resumed.bin')).readAsBytes(),
      [...head, ...tail],
    );
  });
}
