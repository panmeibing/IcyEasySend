import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:icy_easy_send/pages/tv/tv_widgets.dart';

void main() {
  testWidgets('selecting a TvButton keeps focus on that button', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Row(
              children: [
                for (var i = 0; i < 3; i++)
                  TvButton(
                    label: 'filter$i',
                    primary: selected == i,
                    minWidth: 72,
                    onPressed: () => setState(() => selected = i),
                  ),
              ],
            );
          },
        ),
      ),
    );

    final sent = Focus.of(tester.element(find.text('filter1')));
    sent.requestFocus();
    await tester.pump();
    expect(sent.hasPrimaryFocus, isTrue);

    tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'filter1'),
    ).onPressed!();
    await tester.pump();

    expect(sent.hasPrimaryFocus, isTrue);
    expect(
      Focus.of(tester.element(find.text('filter0'))).hasPrimaryFocus,
      isFalse,
    );
  });

  testWidgets('choice dialog paints its title and actions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return TvButton(
              label: 'delete',
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (dialogContext) {
                    return TvChoiceDialog(
                      title: '删除记录',
                      message: 'notes.txt',
                      primaryLabel: '取消',
                      secondaryLabel: '确定',
                      onPrimary: () => Navigator.of(dialogContext).pop(),
                      onSecondary: () => Navigator.of(dialogContext).pop(),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('delete'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('删除记录'), findsOneWidget);
    expect(find.text('notes.txt'), findsOneWidget);
    expect(find.text('取消'), findsOneWidget);
    expect(find.text('确定'), findsOneWidget);
  });
}
