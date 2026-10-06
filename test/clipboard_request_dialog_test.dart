import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/l10n/app_localizations.dart';
import 'package:icy_easy_send/pages/clipboard/clipboard_request_dialog.dart';
import 'package:icy_easy_send/utils/constants.dart';

/// The clipboard prompt must answer exactly once and take itself down when it
/// does, whatever else is on screen by then.
void main() {
  late BuildContext appContext;

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            appContext = context;
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Future<bool> ask() => const DialogClipboardRequestPrompter().confirm(
    appContext,
    requesterDeviceName: 'Phone',
  );

  testWidgets('allowing answers true and closes the prompt', (tester) async {
    await pumpApp(tester);
    final answer = ask();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Allow'));
    await tester.pumpAndSettle();

    expect(await answer, isTrue);
    expect(find.byType(ClipboardRequestDialog), findsNothing);
  });

  testWidgets('running out the countdown answers false and closes the prompt', (
    tester,
  ) async {
    await pumpApp(tester);
    final answer = ask();
    await tester.pumpAndSettle();

    for (var i = 0; i <= AppConstants.receiveConfirmationCountdown; i++) {
      await tester.pump(AppConstants.countdownInterval);
    }
    await tester.pumpAndSettle();

    expect(await answer, isFalse);
    expect(find.byType(ClipboardRequestDialog), findsNothing);
  });

  testWidgets('timing out underneath another dialog leaves that dialog alone', (
    tester,
  ) async {
    await pumpApp(tester);
    final answer = ask();
    await tester.pumpAndSettle();

    showDialog<void>(
      context: appContext,
      builder: (_) => const AlertDialog(content: Text('unrelated')),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i <= AppConstants.receiveConfirmationCountdown; i++) {
      await tester.pump(AppConstants.countdownInterval);
    }
    await tester.pumpAndSettle();

    expect(await answer, isFalse);
    expect(find.byType(ClipboardRequestDialog), findsNothing);
    expect(find.text('unrelated'), findsOneWidget);
  });
}
