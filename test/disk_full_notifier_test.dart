import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/services/disk_full_notifier.dart';
import 'package:icy_easy_send/services/user_notifier.dart';

class _FakeNotifier extends UserNotifier {
  int diskFullShown = 0;
  Completer<void> dismissed = Completer<void>();

  @override
  void showSuccess(BuildContext context, String message) {}

  @override
  Future<void> showDiskFull(BuildContext context) {
    diskFullShown++;
    return dismissed.future;
  }
}

void main() {
  late _FakeNotifier fake;
  final previous = UserNotifier.instance;

  setUp(() {
    fake = _FakeNotifier();
    UserNotifier.instance = fake;
    DiskFullNotifier().reset();
  });

  tearDown(() {
    UserNotifier.instance = previous;
    DiskFullNotifier().reset();
  });

  Future<BuildContext> pumpContext(WidgetTester tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          captured = context;
          return const SizedBox();
        },
      ),
    );
    return captured;
  }

  testWidgets('a failing batch raises a single alert', (tester) async {
    final context = await pumpContext(tester);

    await tester.runAsync(() async {
      final first = DiskFullNotifier().notify(context);
      await DiskFullNotifier().notify(context);
      expect(fake.diskFullShown, 1);

      fake.dismissed.complete();
      await first;
      // Still inside the cooldown that starts at dismissal.
      await DiskFullNotifier().notify(context);
      expect(fake.diskFullShown, 1);
    });
  });

  test('no context means no alert', () async {
    await DiskFullNotifier().notify(null);
    expect(fake.diskFullShown, 0);
  });
}
