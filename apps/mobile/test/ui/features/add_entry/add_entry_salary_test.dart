import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/repositories/finance_repository.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/money.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/add_entry/views/add_entry_view.dart';

/// Beranda "catat gajian" opens /catat as a pemasukan under gajian with the
/// last salary suggested.
void main() {
  final now = DateTime(2026, 10, 23, 9); // hari gajian
  late AppDatabase db;
  late int last; // newest gajian in the fixture

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  Future<void> open(WidgetTester tester, {bool noSalary = false}) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
      () => now,
    );
    await tester.runAsync(() async {
      if (noSalary) {
        // Soft-delete every income, so "never logged" holds.
        await (db.update(db.transactions)
              ..where((t) => t.amount.isBiggerThanValue(0)))
            .write(TransactionsCompanion(deletedAt: Value(now)));
      }
      last = await FinanceRepository(db).lastSalary() ?? 0;
    });
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
          home: const AddEntryView(salary: true),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('catat gajian: pemasukan, gajian, last salary as a muted hint', (
    tester,
  ) async {
    await open(tester);
    expect(last, greaterThan(0));
    expect(find.bySemanticsLabel('simpan pemasukan'), findsOneWidget);
    expect(find.textContaining('gajian'), findsWidgets); // category chip
    expect(find.text('kayak gaji terakhir, ketik buat ganti'), findsOneWidget);
    expect(find.text(rupiah(last).replaceFirst('Rp', '')), findsOneWidget);

    // The first digit replaces the suggestion instead of continuing it.
    await tester.tap(find.bySemanticsLabel('9'));
    await tester.pump();
    expect(find.textContaining('sembilan'), findsOneWidget); // = Rp9
    expect(find.text('kayak gaji terakhir, ketik buat ganti'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('catat gajian: saving without typing keeps the suggestion', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.bySemanticsLabel('simpan pemasukan'));
    await settle(tester);

    final rows = (await tester.runAsync(
      () => (db.select(
        db.transactions,
      )..where((t) => t.at.isBiggerOrEqualValue(DateTime(2026, 10, 23)))).get(),
    ))!;
    expect(rows.where((t) => t.amount == last), hasLength(1));

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('catat gajian: never logged → empty amount, no hint', (
    tester,
  ) async {
    await open(tester, noSalary: true);
    expect(last, 0);
    expect(find.bySemanticsLabel('simpan pemasukan'), findsOneWidget);
    expect(find.text('ketik nominal'), findsOneWidget);
    expect(find.text('kayak gaji terakhir, ketik buat ganti'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
