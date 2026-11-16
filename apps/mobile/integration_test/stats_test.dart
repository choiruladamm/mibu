import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';
import 'package:mibu/data/repositories/finance_repository.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/domain/csv.dart';
import 'package:mibu/routing/router.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/stats/views/stats_view.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('statistics navigation and live database updates on device', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 14, 14, 50);
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
      () => now,
      seedFixture,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await db.close();
    });
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider)..go(Routes.stats);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    Future<void> settle() async {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await settle();
    expect(find.text('Rp4,06jt'), findsWidgets);
    expect(find.text('sejauh ini vs total periode sebelumnya'), findsOneWidget);
    for (final tab in ['minggu', 'tahun', 'bulan']) {
      await tester.tap(find.text(tab));
      await settle();
      if (tab == 'tahun') {
        expect(find.textContaining('2026', findRichText: true), findsWidgets);
        continue;
      }
      await tester.tap(find.bySemanticsLabel('periode sebelumnya'));
      await settle();
      expect(
        find.text(tab == 'minggu' ? 'Rp2,56jt' : 'Rp2,61jt'),
        findsWidgets,
      );
      await tester.tap(find.bySemanticsLabel('periode berikutnya'));
      await settle();
    }
    await FinanceRepository(db).addTransaction(
      amount: -10000000,
      categoryId: null,
      place: '',
      note: '',
      tags: [],
      at: now,
    );
    await settle();
    expect(find.text('Rp14,06jt'), findsWidgets);
    expect(find.text('Rp4,06jt'), findsNothing);
    await tester.tap(find.bySemanticsLabel(RegExp('^8 – 14 okt,')));
    await settle();
    expect(
      find.textContaining('8 okt – 14 okt', findRichText: true),
      findsWidgets,
    );
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await settle();
    expect(find.text('larinya ke mana'), findsOneWidget);
    await tester.ensureVisible(find.text('lain-lain').last);
    await settle();
    await tester.tap(find.text('lain-lain').last);
    await settle();
    expect(find.text('transaksi'), findsOneWidget);
    expect(
      find.textContaining('lain-lain', findRichText: true),
      findsWidgets,
    );
    await tester.tap(find.bySemanticsLabel('balik ke statistik'));
    await settle();
    expect(find.text('larinya ke mana'), findsOneWidget);
    await tester.drag(find.byType(ListView).first, const Offset(0, 800));
    await settle();
    expect(
      find.textContaining('8 okt – 14 okt', findRichText: true),
      findsWidgets,
    );
  });
  testWidgets('imported future expense appears after date advances', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 14, 23, 59, 50);
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
      () => now,
      seedFixture,
    );
    final repo = FinanceRepository(db);
    final parsed = parseTransactionsCsv(
      '$csvHeader\n2026-10-15,12:00,pengeluaran,1000000,,,,,\n',
    )!;
    final plan = planImport(
      parsed,
      existing: await repo.allTransactions(),
      categories: [],
    );
    final wrote = await repo.importCsv(plan);
    expect(wrote.txIds, hasLength(1));
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await db.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const StatsView(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
    expect(find.text('Rp4,06jt'), findsWidgets);
    expect(
      (await repo.allTransactions())
          .where((t) => t.id == wrote.txIds.single)
          .single
          .at
          .day,
      15,
    );
    now = DateTime(2026, 10, 15);
    await tester.pump(const Duration(seconds: 11));
    await tester.pumpAndSettle();
    expect(find.text('Rp5,06jt'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
