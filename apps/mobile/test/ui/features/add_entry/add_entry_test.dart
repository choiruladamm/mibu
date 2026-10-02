import 'dart:async';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/repositories/finance_repository.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/add_entry/views/add_entry_view.dart';

void main() {
  testWidgets('catat: type amount, pick a category, save → db', (tester) async {
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
          home: const AddEntryView(),
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

    // Nothing typed: save is disabled.
    final save = find.bySemanticsLabel('simpan pengeluaran');
    expect(tester.getSemantics(save), isSemantics(isEnabled: false));
    expect(find.text('ketik nominal'), findsOneWidget);

    for (final k in ['5', '000']) {
      await tester.tap(
        find.bySemanticsLabel(k == '000' ? 'tambah tiga nol' : k),
      );
      await tester.pump();
    }
    expect(find.text('5.000'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('0'));
    await tester.pump();
    expect(find.text('50.000'), findsOneWidget);
    expect(find.text('lima puluh ribu rupiah'), findsOneWidget);

    // "+" adds another amount: 50.000 + 2.000.
    await tester.tap(find.bySemanticsLabel('tambah nominal lain'));
    await tester.pump();
    expect(find.text('50.000 + …'), findsOneWidget);
    for (final k in ['2', '000']) {
      await tester.tap(
        find.bySemanticsLabel(k == '000' ? 'tambah tiga nol' : k),
      );
      await tester.pump();
    }
    expect(find.text('50.000 + 2.000'), findsOneWidget);
    expect(find.text('52.000'), findsOneWidget);
    expect(find.text('lima puluh dua ribu rupiah'), findsOneWidget);

    // Pick makan in the sheet.
    await tester.tap(find.text('pilih kategori'));
    await settle();
    await tester.tap(find.bySemanticsLabel('makan'));
    await tester.pump();
    expect(find.text('pakai 🍜 makan'), findsOneWidget);
    // Tapping it again unpicks.
    await tester.tap(find.bySemanticsLabel('makan'));
    await tester.pump();
    expect(find.text('pakai 🍜 makan'), findsNothing);
    await tester.tap(find.bySemanticsLabel('makan'));
    await tester.pump();
    await tester.tap(find.text('pakai 🍜 makan'));
    await settle();

    // makan pocket: 1,5jt − 390K − 52K left.
    expect(find.text('🍜 kantong makan abis ini'), findsOneWidget);
    expect(find.text('sisa Rp1,06jt'), findsOneWidget);

    expect(tester.getSemantics(save), isSemantics(isEnabled: true));
    await tester.tap(save);
    await settle();

    final rows = await (db.select(
      db.transactions,
    )..where((t) => t.amount.equals(-52000))).get();
    expect(rows, hasLength(1));
    expect(rows.single.at, now);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('catat + date / note sheets fit a short screen (375×667)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
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
          home: const AddEntryView(),
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
    expect(tester.takeException(), isNull);

    await tester.tap(find.bySemanticsLabel('pilih tanggal lain'));
    await settle();
    expect(find.text('kapan kejadiannya?'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.tap(find.bySemanticsLabel('tutup').last);
    await settle();

    // Keypad is pinned; the chips scroll into view on a short screen.
    await tester.ensureVisible(find.text('catatan'));
    await tester.pump();
    await tester.tap(find.text('catatan'));
    await settle();
    expect(find.text('tag cepet · maks 3'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('picker: switching category clears a prefilled place only', (
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
          home: const AddEntryView(),
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

    String place() =>
        tester.widget<TextField>(find.byType(TextField).last).controller!.text;

    await settle();
    // Recent chip (newest: ojol + gojek) fills both in one tap.
    await tester.tap(find.text('pilih kategori'));
    await settle();
    await tester.tap(find.text('gojek'));
    await settle();
    expect(find.text('ini buat apa?'), findsNothing); // sheet closed
    expect(find.text('gojek'), findsOneWidget); // chip on 03.1

    // Reopen: gojek is prefilled; picking ngopi drops it.
    await tester.tap(find.text('gojek'));
    await settle();
    expect(place(), 'gojek');
    await tester.tap(find.bySemanticsLabel('ngopi'));
    await tester.pump();
    expect(place(), '');

    // A place typed here survives a category change.
    await tester.enterText(find.byType(TextField).last, 'kopken');
    await tester.tap(find.bySemanticsLabel('anabul'));
    await tester.pump();
    expect(place(), 'kopken');

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('catat: a second tap while saving saves nothing', (tester) async {
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
    final repo = _HeldRepository(db);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
          financeRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AddEntryView(),
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
    await tester.tap(find.bySemanticsLabel('5'));
    await tester.pump();

    // Insert held open: the screen hasn't popped yet.
    final save = find.bySemanticsLabel('simpan pengeluaran');
    await tester.tap(save);
    await tester.tap(save, warnIfMissed: false);
    await tester.pump();
    expect(repo.adds, 1);
    expect(tester.getSemantics(save), isSemantics(isEnabled: false));

    repo.hold.complete();
    await settle();
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}

class _HeldRepository extends FinanceRepository {
  _HeldRepository(super.db);

  final hold = Completer<void>();
  int adds = 0;

  @override
  Future<void> addTransaction({
    required int amount,
    required String? categoryId,
    required String place,
    required String note,
    required List<String> tags,
    required DateTime at,
  }) {
    adds++;
    return hold.future;
  }
}
