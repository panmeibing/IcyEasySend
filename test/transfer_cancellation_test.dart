import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/transfer/transfer_cancellation.dart';

void main() {
  test('cancelFile runs the attached hook once', () {
    final cancellation = TransferCancellation();
    var calls = 0;
    cancellation.attach('a.jpg', () => calls++);

    cancellation.cancelFile('a.jpg');
    cancellation.cancelFile('a.jpg');

    expect(calls, 1);
    expect(cancellation.isCancelled('a.jpg'), isTrue);
  });

  test('cancelAll closes in-flight files and skips later ones', () {
    final cancellation = TransferCancellation();
    final closed = <String>[];
    cancellation.attach('a.jpg', () => closed.add('a.jpg'));

    cancellation.cancelAll(['a.jpg', 'b.jpg']);
    cancellation.attach('b.jpg', () => closed.add('b.jpg'));

    expect(closed, ['a.jpg', 'b.jpg']);
    expect(cancellation.isCancelled('b.jpg'), isTrue);
  });

  test('a finished file is left out of cancelAll and its notification', () {
    final cancellation = TransferCancellation();
    final notified = <Set<String>>[];
    cancellation.onChanged = notified.add;
    var doneHookCalls = 0;
    cancellation.attach('done.jpg', () => doneHookCalls++);
    cancellation.markFinished('done.jpg');

    cancellation.cancelAll(['done.jpg', 'next.jpg']);

    expect(doneHookCalls, 0);
    expect(cancellation.isCancelled('done.jpg'), isFalse);
    expect(cancellation.isSettled('done.jpg'), isTrue);
    expect(notified, [
      {'next.jpg'},
    ]);
  });

  test('cancelFile on a finished file does nothing', () {
    final cancellation = TransferCancellation();
    final notified = <Set<String>>[];
    cancellation.onChanged = notified.add;
    cancellation.markFinished('done.jpg');

    cancellation.cancelFile('done.jpg');

    expect(cancellation.isCancelled('done.jpg'), isFalse);
    expect(notified, isEmpty);
  });

  test(
    'cancelAll aborts the batch and releases anything waiting on it',
    () async {
      final cancellation = TransferCancellation();
      final never = Completer<String>();

      final waiting = cancellation.unlessAborted(never.future);
      cancellation.cancelAll(['a.jpg']);

      expect(cancellation.isAborted, isTrue);
      expect(await waiting, isNull);
      expect(await cancellation.unlessAborted(Future.value('late')), isNull);
    },
  );

  test('cancelling one file does not abort the batch', () async {
    final cancellation = TransferCancellation();
    cancellation.cancelFile('a.jpg');

    expect(cancellation.isAborted, isFalse);
    expect(await cancellation.unlessAborted(Future.value('ok')), 'ok');
  });

  test('cancelAll with only finished files sends no notification', () {
    final cancellation = TransferCancellation();
    var notifications = 0;
    cancellation.onChanged = (_) => notifications++;
    cancellation.markFinished('a.jpg');

    cancellation.cancelAll(['a.jpg']);

    expect(notifications, 0);
  });
}
