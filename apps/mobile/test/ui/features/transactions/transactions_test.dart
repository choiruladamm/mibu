import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/transactions/views/transactions_view.dart';

void main() {
  testWidgets('04.1: month tiles, day groups, filter, month switch', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final now = DateTime(2026, 10, 14, 14, 50);
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
      () => now,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TransactionsView(),
        ),
      ),
    );
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await settle();
    expect(find.text('oktober'), findsOneWidget);
    expect(find.text('7 catatan'), findsNWidgets(2)); // header + filter row
    expect(find.text('Rp0'), findsOneWidget); // no income yet
    expect(find.text('-Rp4,06jt'), findsNWidgets(2)); // pengeluaran, selisih
    expect(find.text('hari ini · rab 14 okt'), findsOneWidget);
    expect(find.text('kemarin · sel 13 okt'), findsOneWidget);
    expect(find.text('-Rp1,02jt'), findsOneWidget); // 13 okt total
    expect(find.bySemanticsLabel('november belum kejadian'), findsOneWidget);

    await tester.tap(find.text('pemasukan').last);
    await settle();
    expect(find.text('0 catatan'), findsNWidgets(2));
    expect(find.text('belum ada catatan di oktober'), findsOneWidget);

    await tester.tap(find.text('sep'));
    await settle();
    expect(find.text('september'), findsOneWidget);
    // filter stays on pemasukan: tile, day total, row
    expect(find.text('+Rp8,5jt'), findsNWidgets(3));
    await tester.scrollUntilVisible(find.text('liat agu'), 200);
    expect(find.text('udah semua buat september'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
