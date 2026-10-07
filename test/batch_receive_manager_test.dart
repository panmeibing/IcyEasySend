import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/batch_receive_manager.dart';
import 'package:icy_easy_send/services/batch_receive_prompter.dart';

/// Stands in for the dialog: records the batch and lets the test decide.
class _FakePrompter extends BatchReceivePrompter {
  IncomingBatch? shown;
  final List<IncomingBatch> closed = [];
  late Future<void> Function(IncomingBatch batch) onPresent;

  @override
  Future<void> present(BuildContext context, IncomingBatch batch) async {
    shown = batch;
    await onPresent(batch);
    closed.add(batch);
  }
}

void main() {
  late _FakePrompter prompter;
  late BatchReceiveManager manager;
  late BuildContext context;

  List<PendingFileInfo> files(String prefix, int count) => [
    for (var i = 0; i < count; i++)
      PendingFileInfo(
        fileName: '$prefix$i.txt',
        fileSize: 100,
        transferId: '$prefix-$i',
      ),
  ];

  setUp(() {
    prompter = _FakePrompter();
    manager = BatchReceiveManager.forTesting(prompter: prompter);
  });

  Future<void> pumpContext(WidgetTester tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (ctx) {
          context = ctx;
          return const SizedBox();
        },
      ),
    );
  }

  group('IncomingBatch', () {
    test('decides once; later answers are ignored', () async {
      final batch = IncomingBatch(senderKey: 'a', files: files('f', 2));
      batch.accept();
      batch.reject();

      expect(await batch.decision, isTrue);
      expect(batch.files.every((f) => f.isAccepted), isTrue);
      expect(batch.files.any((f) => f.isCompleted), isFalse);
    });

    test('rejecting completes every outstanding file as rejected', () async {
      final batch = IncomingBatch(senderKey: 'a', files: files('f', 2));
      batch.reject();

      expect(await batch.decision, isFalse);
      expect(batch.files.every((f) => f.isRejected), isTrue);
      expect(batch.isFinished, isTrue);
    });

    test('a sender giving up before the answer ends the question', () async {
      final batch = IncomingBatch(senderKey: 'a', files: files('f', 2));
      batch.markFailed(batch.files[0], 'gone');
      expect(batch.isDecided, isFalse);

      batch.markFailed(batch.files[1], 'gone');
      expect(await batch.decision, isFalse);
      expect(batch.files.every((f) => f.isFailed), isTrue);
    });

    test('tracks totals and completion from progress', () {
      final batch = IncomingBatch(senderKey: 'a', files: files('f', 2))
        ..accept();
      batch.updateProgress(batch.files[0], 1.0, 100);
      batch.updateProgress(batch.files[1], 0.5, 50);

      expect(batch.totalBytes, 200);
      expect(batch.bytesReceived, 150);
      expect(batch.files[0].isReceived, isTrue);
      expect(batch.isFinished, isFalse);
    });
  });

  group('BatchReceiveManager', () {
    testWidgets('resolves with the user\'s answer and runs onComplete after '
        'the prompt closes', (tester) async {
      await pumpContext(tester);
      prompter.onPresent = (batch) async => batch.accept();
      var completed = false;

      final accepted = await manager.requestBatchReceiveConfirmation(
        context: context,
        files: files('f', 2),
        senderIP: '10.0.0.2',
        onComplete: () async => completed = true,
      );
      await tester.pump();

      expect(accepted, isTrue);
      expect(completed, isTrue);
    });

    testWidgets('a prompt that closes without an answer is a refusal', (
      tester,
    ) async {
      await pumpContext(tester);
      prompter.onPresent = (_) async {};

      final accepted = await manager.requestBatchReceiveConfirmation(
        context: context,
        files: files('f', 1),
        senderIP: '10.0.0.2',
      );

      expect(accepted, isFalse);
    });

    testWidgets('progress and failures reach the right batch', (tester) async {
      await pumpContext(tester);
      final release = <void Function()>[];
      prompter.onPresent = (batch) async {
        batch.accept();
        final done = Completer<void>();
        release.add(done.complete);
        await done.future;
      };

      final first = files('a', 1);
      final second = files('b', 1);
      await manager.requestBatchReceiveConfirmation(
        context: context,
        files: first,
        senderIP: 'peer-1',
      );
      await manager.requestBatchReceiveConfirmation(
        context: context,
        files: second,
        senderIP: 'peer-1',
      );

      manager.updateProgress('a-0', 1.0, 100, 100);
      manager.markTransferFailed('b-0', 'disk full');

      expect(first.single.isReceived, isTrue);
      expect(second.single.isFailed, isTrue);
      expect(second.single.errorMessage, 'disk full');

      for (final r in release) {
        r();
      }
      await tester.pump();
    });

    test(
      'headless batches are accepted at once and dropped on clear',
      () async {
        final batch = files('h', 1);
        final accepted = await manager.acceptBatchHeadless(
          files: batch,
          senderIP: 'peer-2',
        );
        expect(accepted, isTrue);
        expect(batch.single.isAccepted, isTrue);

        manager.clearPendingForSender('peer-2');
        manager.updateProgress('h-0', 0.5, 50, 100);
        expect(batch.single.progress, 0.0, reason: 'no longer tracked');
      },
    );
  });
}
