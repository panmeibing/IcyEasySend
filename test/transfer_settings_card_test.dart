import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/l10n/app_localizations.dart';
import 'package:icy_easy_send/l10n/app_localizations_en.dart';
import 'package:icy_easy_send/pages/settings/widgets/transfer_settings_card.dart';

void main() {
  final l10n = AppLocalizationsEn();
  final calls = <String>[];
  late TextEditingController history;
  late TextEditingController clipboard;
  late TextEditingController secret;

  setUp(() {
    calls.clear();
    history = TextEditingController();
    clipboard = TextEditingController();
    secret = TextEditingController();
  });

  tearDown(() {
    history.dispose();
    clipboard.dispose();
    secret.dispose();
  });

  Future<void> pumpCard(
    WidgetTester tester, {
    bool editingHistory = false,
    bool ipValidation = true,
    String secretKey = '',
  }) async {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: TransferSettingsCard(
              receiveSavePathDisplay: '/downloads',
              isCustomReceiveSavePath: false,
              onSelectSavePath: () => calls.add('selectPath'),
              onResetSavePathToDefault: () => calls.add('resetPath'),
              concurrentTransfers: 3,
              tempConcurrentTransfers: 3,
              maxConcurrentTransfers: 10,
              onConcurrentTransfersChanged: (_) {},
              onConcurrentTransfersChangeEnd: (_) {},
              maxHistoryItems: 120,
              isEditingMaxHistory: editingHistory,
              allowMaxHisCount: 1000,
              allowMinHisCount: 10,
              maxHistoryController: history,
              onEditMaxHistory: () => calls.add('editHistory'),
              onSaveMaxHistory: () => calls.add('saveHistory'),
              onCancelMaxHistory: () => calls.add('cancelHistory'),
              maxClipboardSizeMB: 5,
              isEditingMaxClipboardSize: false,
              maxClipboardSizeController: clipboard,
              onEditMaxClipboardSize: () => calls.add('editClipboard'),
              onSaveMaxClipboardSize: () {},
              onCancelMaxClipboardSize: () {},
              enableIPValidation: ipValidation,
              onIPValidationChanged: (v) => calls.add('ip:$v'),
              deviceSecretKey: secretKey,
              isEditingSecretKey: false,
              secretKeyController: secret,
              onEditSecretKey: () => calls.add('editSecret'),
              onSaveSecretKey: () {},
              onCancelSecretKey: () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('shows current values and routes edit buttons', (tester) async {
    await pumpCard(tester);

    expect(find.text(l10n.historyItemsCount(120)), findsOneWidget);
    expect(find.text('5 MB'), findsOneWidget);
    expect(find.text(l10n.notSet), findsOneWidget);

    final edits = find.byTooltip(l10n.edit);
    expect(edits, findsNWidgets(3));
    for (var i = 0; i < 3; i++) {
      await tester.tap(edits.at(i));
    }
    expect(calls, ['editHistory', 'editClipboard', 'editSecret']);
  });

  testWidgets('editing swaps the value for a field and save/cancel', (
    tester,
  ) async {
    await pumpCard(tester, editingHistory: true);

    expect(find.text(l10n.historyItemsCount(120)), findsNothing);
    await tester.enterText(find.byType(TextField), '12a3');
    expect(history.text, '123');

    await tester.tap(find.byTooltip(l10n.save));
    await tester.tap(find.byTooltip(l10n.cancel));
    expect(calls, ['saveHistory', 'cancelHistory']);
  });

  testWidgets('a secret key is masked and a disabled IP check warns', (
    tester,
  ) async {
    await pumpCard(tester, ipValidation: false, secretKey: 'abcd');

    expect(find.text('●●●●'), findsOneWidget);
    expect(find.text('abcd'), findsNothing);
    expect(find.text(l10n.ipValidationDisabledHint), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

    await tester.tap(find.byType(Switch).last);
    expect(calls, ['ip:true']);
  });
}
