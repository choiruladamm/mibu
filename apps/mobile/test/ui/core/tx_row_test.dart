import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mibu/domain/models/finance.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/widgets/tx_row.dart';

/// 00.4: two symmetric columns, always 64.
void main() {
  setUpAll(() => initializeDateFormatting('id'));

  Transaction tx({String note = '', List<String> tags = const []}) =>
      Transaction(
        id: 't',
        emoji: '🐶',
        category: 'anabul',
        place: 'petshop',
        at: DateTime(2026, 10, 3, 14, 32),
        amount: -450000,
        note: note,
        tags: tags,
      );

  Future<List<String>> pump(
    WidgetTester tester,
    Transaction t, {
    List<String>? taps,
    List<int>? opened,
  }) async {
    final tagTaps = taps ?? [];
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 700, // test font is wider than Instrument Sans
                child: TxRow(
                  tx: t,
                  onTap: () => opened?.add(1),
                  onTagTap: tagTaps.add,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return tagTaps;
  }

  double height(WidgetTester tester) =>
      tester.getSize(find.byType(TxRow)).height;

  Finder rich(String s) => find.textContaining(s, findRichText: true);

  testWidgets('plain row: tempat left, jam right, 64', (tester) async {
    await pump(tester, tx());
    expect(height(tester), 64);
    expect(rich('petshop'), findsOneWidget);
    expect(rich('14:32'), findsOneWidget);
  });

  testWidgets('no tempat, no catatan: buat apa sits on the row center', (
    tester,
  ) async {
    final t = tx();
    await pump(
      tester,
      Transaction(
        id: t.id,
        emoji: t.emoji,
        category: t.category,
        place: '',
        at: t.at,
        amount: t.amount,
      ),
    );
    final row = tester.getRect(find.byType(TxRow));
    expect(tester.getCenter(find.text('anabul')).dy, closeTo(row.center.dy, 1));
    expect(rich('14:32'), findsOneWidget); // jam stays on the right
  });

  testWidgets('note and tag never change the 64', (tester) async {
    await pump(tester, tx(note: 'obat kutu mochi'));
    expect(height(tester), 64);
    expect(rich('obat kutu mochi'), findsOneWidget);

    await pump(tester, tx(tags: ['#kantor']));
    expect(height(tester), 64);
    expect(find.text('#kantor'), findsOneWidget);

    await pump(tester, tx(tags: ['gajian'])); // stored without the #
    expect(find.text('#gajian'), findsOneWidget);
  });

  testWidgets('first tag + "+n"; chip tap skips the row tap', (tester) async {
    final opened = <int>[];
    final taps = await pump(
      tester,
      tx(note: 'x' * 80, tags: ['#splitbill', '#hadiah', '#langganan']),
      opened: opened,
    );
    expect(find.text('#splitbill'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
    expect(find.text('#hadiah'), findsNothing);
    expect(height(tester), 64);
    expect(tester.takeException(), isNull); // long note ellipsizes, no overflow

    await tester.tap(find.text('#splitbill'));
    expect(taps, ['#splitbill']);
    expect(opened, isEmpty);

    await tester.tap(find.text('anabul'));
    expect(opened, [1]);
  });
}
