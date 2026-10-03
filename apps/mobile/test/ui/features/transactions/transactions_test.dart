import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/core/widgets/month_menu.dart';
import 'package:mibu/ui/features/transactions/view_models/transactions_view_model.dart';
import 'package:mibu/ui/features/transactions/views/transactions_view.dart';

import '../../../meta.dart';

void main() {
  testWidgets('04.1: period card, day groups, filter, month switch', (
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
    expect(find.text('1 okt – 31 okt'), findsWidgets); // title + card
    // No income yet: "—" + a nudge to log the salary, not a negative figure.
    expect(find.text('catat gajian dulu'), findsOneWidget);
    expect(find.text('belum ada'), findsOneWidget);
    expect(find.text('Rp4,06jt'), findsOneWidget); // pengeluaran
    expect(find.text('naik Rp1,45jt dari september'), findsOneWidget);
    expect(
      find.text('dihitung per periode, sisa september nggak kebawa'),
      findsOneWidget,
    );
    expect(findMeta(['hari ini', 'rab 14 okt']), findsOneWidget);
    expect(findMeta(['kemarin', 'sel 13 okt']), findsOneWidget);
    expect(find.text('-Rp1,02jt'), findsOneWidget); // 13 okt total
    expect(find.bySemanticsLabel('bulan depan belum kejadian'), findsOneWidget);

    await tester.tap(find.text('pemasukan').last);
    await settle();
    expect(find.text('0 catatan'), findsNWidgets(2));
    expect(find.text('belum ada catatan di oktober'), findsOneWidget);

    await tester.tap(find.text('sep'));
    await settle();
    expect(find.text('september'), findsOneWidget);
    // sisa pemasukan = 8,5jt − 2.612.500
    expect(find.text('Rp5,89jt'), findsOneWidget);
    expect(find.text('Rp8,5jt'), findsOneWidget); // pemasukan in the card
    // filter stays on pemasukan: day total, row
    expect(find.text('+Rp8,5jt'), findsNWidgets(2));
    await tester.scrollUntilVisible(find.text('liat agu'), 200);
    expect(find.text('udah semua di september'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('04.1 opens on the month from a 02.1 deep link', (tester) async {
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
          txMonthProvider.overrideWith(() => TxMonth(DateTime(2026, 9))),
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
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('september'), findsOneWidget);
    expect(find.text('2 catatan'), findsWidgets);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('04.1b/c: title opens the month menu, chip goes back to now', (
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
      // The chip's AnimatedSize starts a frame after the data lands.
      await tester.pump(const Duration(milliseconds: 400));
    }

    final menu = find.byType(MonthMenu);
    Finder inMenu(String text) =>
        find.descendant(of: menu, matching: find.text(text));

    await settle();
    expect(menu, findsNothing);
    expect(find.textContaining('balik ke'), findsNothing); // already on now

    // Title opens the menu; the scrim closes it again.
    await tester.tap(find.text('oktober'));
    await settle();
    expect(menu, findsOneWidget);
    await tester.tapAt(const Offset(20, 800));
    await settle();
    expect(menu, findsNothing);

    // Months before the first entry are locked, and so is the year step.
    await tester.tap(find.text('oktober'));
    await settle();
    await tester.tap(inMenu('jan'));
    await settle();
    expect(menu, findsOneWidget);
    expect(find.text('oktober'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('tahun sebelumnya'));
    await tester.pump();
    expect(inMenu('2026'), findsOneWidget);

    // Picking a month closes the menu and swaps the data.
    await tester.tap(inMenu('sep'));
    await settle();
    expect(menu, findsNothing);
    expect(find.text('september'), findsOneWidget);
    expect(find.text('balik ke okt 2026'), findsOneWidget);

    // The chip goes back to now and goes away.
    await tester.tap(find.text('balik ke okt 2026'));
    await settle();
    expect(find.text('oktober'), findsOneWidget);
    expect(find.textContaining('balik ke'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
