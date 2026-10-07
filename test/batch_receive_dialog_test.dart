import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/l10n/app_localizations.dart';
import 'package:icy_easy_send/models/incoming_batch.dart';
import 'package:icy_easy_send/pages/receive/batch_receive_dialog.dart';
import 'package:icy_easy_send/utils/constants.dart';

/// The receive dialog only reflects an [IncomingBatch]: it asks, shows
/// progress, and gets out of the way when the batch is over.
void main() {
  late BuildContext appContext;

  Future<void> pumpApp(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
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

  IncomingBatch newBatch({bool autoAccept = false, int count = 2}) =>
      IncomingBatch(
        senderKey: '192.168.1.5',
        senderDeviceName: 'Laptop',
        autoAccept: autoAccept,
        files: [
          for (var i = 0; i < count; i++)
            PendingFileInfo(
              fileName: 'file$i.bin',
              fileSize: 1000,
              transferId: 't$i',
            ),
        ],
      );

  // Receiving shows endless progress animations, so settling never finishes;
  // a few fixed pumps cover the dialog route transitions.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> show(WidgetTester tester, IncomingBatch batch) async {
    const DialogBatchReceivePrompter().present(appContext, batch);
    await settle(tester);
  }

  testWidgets('accepting decides the batch and switches to progress', (
    tester,
  ) async {
    await pumpApp(tester);
    final batch = newBatch();
    await show(tester, batch);

    await tester.tap(find.text('Accept All'));
    await tester.pump();

    expect(await batch.decision, isTrue);
    expect(find.text('Accept All'), findsNothing);
    expect(find.byType(BatchReceiveDialog), findsOneWidget);
  });

  testWidgets('rejecting decides the batch and closes the dialog', (
    tester,
  ) async {
    await pumpApp(tester);
    final batch = newBatch();
    await show(tester, batch);

    await tester.tap(find.text('Reject All'));
    await settle(tester);

    expect(await batch.decision, isFalse);
    expect(find.byType(BatchReceiveDialog), findsNothing);
  });

  testWidgets('the countdown running out rejects and closes', (tester) async {
    await pumpApp(tester);
    final batch = newBatch();
    await show(tester, batch);

    for (var i = 0; i <= AppConstants.receiveConfirmationCountdown; i++) {
      await tester.pump(AppConstants.countdownInterval);
    }
    await settle(tester);

    expect(await batch.decision, isFalse);
    expect(find.byType(BatchReceiveDialog), findsNothing);
  });

  testWidgets('back rejects while undecided but cannot abandon a transfer', (
    tester,
  ) async {
    await pumpApp(tester);
    final undecided = newBatch();
    await show(tester, undecided);

    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(await undecided.decision, isFalse);
    expect(find.byType(BatchReceiveDialog), findsNothing);

    final receiving = newBatch()..accept();
    await show(tester, receiving);
    await tester.binding.handlePopRoute();
    await settle(tester);
    expect(find.byType(BatchReceiveDialog), findsOneWidget);

    for (final file in receiving.files) {
      receiving.updateProgress(file, 1.0, file.fileSize);
    }
    await tester.pump(AppConstants.autoCloseDelay);
    await settle(tester);
  });

  testWidgets('closes on its own once every file has landed', (tester) async {
    await pumpApp(tester);
    final batch = newBatch(autoAccept: true);
    await show(tester, batch);
    expect(await batch.decision, isTrue);

    batch.updateProgress(batch.files[0], 1.0, 1000);
    batch.markFailed(batch.files[1], 'disk full');
    await tester.pump();
    expect(find.byType(BatchReceiveDialog), findsOneWidget);

    await tester.pump(AppConstants.autoCloseDelay);
    await settle(tester);
    expect(find.byType(BatchReceiveDialog), findsNothing);
  });

  testWidgets('a failed file is marked as failed in any language', (
    tester,
  ) async {
    await pumpApp(tester, locale: const Locale('de'));
    final batch = newBatch(autoAccept: true, count: 1);
    await show(tester, batch);
    // Inspected before the auto-close delay elapses.
    batch.markFailed(batch.files.single, 'boom');
    await tester.pump();

    final icon = tester.widget<Icon>(find.byIcon(Icons.insert_drive_file));
    expect(icon.color, Colors.red);
    expect(find.textContaining('boom'), findsOneWidget);

    await tester.pump(AppConstants.autoCloseDelay);
    await settle(tester);
  });
}
