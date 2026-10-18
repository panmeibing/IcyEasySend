import 'dart:async';
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

  test('keeps a slow stream that is still delivering bytes', () async {
    Stream<List<int>> paced() async* {
      yield List<int>.filled(40, 1);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      yield List<int>.filled(40, 1);
    }

    final result = await receiver.receiveFileDirectly(
      fileStream: paced(),
      fileName: 'paced.bin',
      fileSize: 80,
      senderIP: '192.168.1.9',
      idleTimeout: const Duration(milliseconds: 200),
    );

    expect(result.isSuccess, isTrue, reason: result.errorMessage);
    expect(await saved('paced.bin').length(), 80);
  });

  test(
    'fails a stream that goes silent and removes the partial file',
    () async {
      final controller = StreamController<List<int>>();
      addTearDown(controller.close);

      final started = DateTime.now();
      final result = await receiver.receiveFileDirectly(
        fileStream: controller.stream,
        fileName: 'quiet.bin',
        fileSize: 10,
        senderIP: '192.168.1.9',
        idleTimeout: const Duration(milliseconds: 200),
      );

      expect(result.isSuccess, isFalse);
      expect(
        DateTime.now().difference(started),
        lessThan(const Duration(seconds: 2)),
      );
      expect(await saved('quiet.bin').exists(), isFalse);
    },
  );

  test('rejects a transfer that stops short of the declared size', () async {
    final result = await receiver.receiveFileDirectly(
      fileStream: Stream.fromIterable([List<int>.filled(100, 3)]),
      fileName: 'short.bin',
      fileSize: 9999,
      senderIP: '192.168.1.9',
    );

    expect(result.isSuccess, isFalse);
    expect(await saved('short.bin').exists(), isFalse);
    expect(await saved('short.bin.part').exists(), isFalse);
  });

  test('bytes only appear under the real name once the file is complete, '
      'so a crash cannot leave a truncated file that looks finished', () async {
    final controller = StreamController<List<int>>();
    final pending = receiver.receiveFileDirectly(
      fileStream: controller.stream,
      fileName: 'photo.jpg',
      fileSize: 200,
      senderIP: '192.168.1.9',
    );

    controller.add(List<int>.filled(100, 1));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(await saved('photo.jpg').exists(), isFalse);
    expect(await saved('photo.jpg.part').exists(), isTrue);

    controller.add(List<int>.filled(100, 2));
    await controller.close();
    final result = await pending;

    expect(result.isSuccess, isTrue, reason: result.errorMessage);
    expect(result.data?.savedPath, saved('photo.jpg').path);
    expect(await saved('photo.jpg').length(), 200);
    expect(await saved('photo.jpg.part').exists(), isFalse);
  });

  test('two receives of the same name at once land in two files', () async {
    final first = StreamController<List<int>>();
    final second = StreamController<List<int>>();
    final a = receiver.receiveFileDirectly(
      fileStream: first.stream,
      fileName: 'same.txt',
      fileSize: 3,
      senderIP: '192.168.1.9',
    );
    final b = receiver.receiveFileDirectly(
      fileStream: second.stream,
      fileName: 'same.txt',
      fileSize: 3,
      senderIP: '192.168.1.10',
    );

    first.add([1, 1, 1]);
    second.add([2, 2, 2]);
    await Future.wait([first.close(), second.close()]);
    final results = await Future.wait([a, b]);

    final paths = results.map((r) => r.data?.savedPath).toSet();
    expect(paths, hasLength(2));
    expect(
      paths,
      containsAll([saved('same.txt').path, saved('same(1).txt').path]),
    );
    final contents = {
      for (final path in paths) (await File(path!).readAsBytes()).first,
    };
    expect(contents, {1, 2});
  });

  test('a name already on disk is kept and the new file is numbered', () async {
    await saved('notes.txt').writeAsString('old');

    final result = await receiver.receiveFileDirectly(
      fileStream: Stream.fromIterable([
        [1, 2, 3],
      ]),
      fileName: 'notes.txt',
      fileSize: 3,
      senderIP: '192.168.1.9',
    );

    expect(result.data?.savedPath, saved('notes(1).txt').path);
    expect(await saved('notes.txt').readAsString(), 'old');
  });

  test('a cancel that lands after the last byte still cancels', () async {
    final controller = StreamController<List<int>>();
    final cancel = Completer<void>();
    final pending = receiver.receiveFileDirectly(
      fileStream: controller.stream,
      fileName: 'late.bin',
      fileSize: 4,
      senderIP: '192.168.1.9',
      cancel: cancel.future,
      onProgress: (progress, _, _) {
        // The user presses cancel as the bar reaches the end.
        if (progress >= 1.0 && !cancel.isCompleted) cancel.complete();
      },
    );

    controller.add([1, 2, 3, 4]);
    await controller.close();
    final result = await pending;

    expect(result.isSuccess, isFalse);
    expect(await saved('late.bin').exists(), isFalse);
    expect(await saved('late.bin.part').exists(), isFalse);
  });
}
