import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/transfer/file_receiver.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// What the receiving side will and will not write to disk.
///
/// The declared size is the only budget a sender ever agrees to, and it is
/// what the user saw when they accepted the transfer. Everything here is about
/// holding the sender to it: the bytes are under the other device's control,
/// so the size in the request is a claim rather than a fact.
void main() {
  late Directory workspace;
  late Directory saveDir;
  late FileReceiver receiver;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    workspace = await Directory.systemTemp.createTemp('receive_test');
    saveDir = await Directory(p.join(workspace.path, 'downloads')).create();

    // A custom save path is the one way to resolve a destination without the
    // platform channel, which is unavailable to tests.
    SharedPreferences.setMockInitialValues({
      'custom_receive_save_path': saveDir.path,
    });

    receiver = FileReceiver();
  });

  tearDown(() async {
    if (await workspace.exists()) {
      await workspace.delete(recursive: true);
    }
  });

  File saved(String name) => File(p.join(saveDir.path, name));

  test('writes a transfer that matches what was declared', () async {
    final bytes = List<int>.generate(3000, (i) => i % 256);

    final result = await receiver.receiveFileDirectly(
      fileStream: Stream.fromIterable([
        bytes.sublist(0, 1500),
        bytes.sublist(1500),
      ]),
      fileName: 'report.bin',
      fileSize: bytes.length,
      senderIP: '192.168.1.9',
    );

    expect(result.isSuccess, isTrue, reason: result.errorMessage);
    expect(await saved('report.bin').readAsBytes(), bytes);
  });

  test('accepts an empty file', () async {
    final result = await receiver.receiveFileDirectly(
      fileStream: const Stream<List<int>>.empty(),
      fileName: 'empty.txt',
      fileSize: 0,
      senderIP: '192.168.1.9',
    );

    expect(result.isSuccess, isTrue, reason: result.errorMessage);
    expect(await saved('empty.txt').length(), 0);
  });

  test('stops a sender that keeps writing past the declared size', () async {
    // A sender that just keeps going. Capped at 10 MB rather than left
    // genuinely infinite so that a regression fails this test quickly instead
    // of hanging CI — which is what an unbounded read actually does here.
    const chunkLimit = 10000;
    var chunksPulled = 0;
    Stream<List<int>> greedy() async* {
      while (chunksPulled < chunkLimit) {
        chunksPulled++;
        yield List<int>.filled(1024, 7);
      }
    }

    final result = await receiver.receiveFileDirectly(
      fileStream: greedy(),
      // Four chunks' worth; the fifth is where the sender breaks its promise.
      fileSize: 4096,
      fileName: 'liar.bin',
      senderIP: '192.168.1.9',
    );

    expect(result.isSuccess, isFalse);
    // Nothing partial is left behind for the user to find.
    expect(await saved('liar.bin').exists(), isFalse);
    // The point: the sender is cut off near its declared size, rather than
    // getting to write until something else happens to give way.
    expect(chunksPulled, lessThan(64));
  });

  test('refuses the overflow rather than truncating to the limit', () async {
    final result = await receiver.receiveFileDirectly(
      fileStream: Stream.fromIterable([
        List<int>.filled(50, 1),
        List<int>.filled(50, 2),
      ]),
      fileName: 'overflow.bin',
      fileSize: 60,
      senderIP: '192.168.1.9',
    );

    // A 60-byte prefix of a file the sender lied about is not a useful file.
    expect(result.isSuccess, isFalse);
    expect(await saved('overflow.bin').exists(), isFalse);
  });

  test('rejects a transfer that stops short of the declared size', () async {
    final result = await receiver.receiveFileDirectly(
      fileStream: Stream.fromIterable([
        List<int>.filled(100, 3),
      ]),
      fileName: 'short.bin',
      fileSize: 9999,
      senderIP: '192.168.1.9',
    );

    expect(result.isSuccess, isFalse);
    expect(await saved('short.bin').exists(), isFalse);
  });
}
