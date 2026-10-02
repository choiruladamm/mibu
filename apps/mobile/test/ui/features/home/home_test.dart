import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/core/widgets/month_menu.dart';
import 'package:mibu/ui/core/finance_providers.dart';
import 'package:mibu/ui/features/home/view_models/home_view_model.dart';
import 'package:mibu/ui/features/home/views/home_view.dart';

void main() {
  final now = DateTime(2026, 10, 14, 14, 50);

  AppDatabase memoryDb({Seed? seed}) => AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
    () => now,
    seed ?? seedFixture,
  );

  /// Pumps 02.1 on a phone-sized screen over [db].
  Future<void> pump(WidgetTester tester, AppDatabase db) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await db.close();
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
          home: const HomeView(),
        ),
      ),
    );
    // Drift runs queries off the fake clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  /// Lets Drift deliver the next stream events after a UI change.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('beranda: hero, pills, entries grouped by day, 5 rows max', (
    tester,
  ) async {
    await pump(tester, memoryDb());

    expect(find.text('4.530.000'), findsOneWidget);
    expect(find.text('saldo kamu'), findsOneWidget);
    expect(find.text('oktober'), findsOneWidget);
    // (4.530.000 + 27.000) ÷ 11 days to payday − 27.000
    expect(find.textContaining('Rp387K', findRichText: true), findsOneWidget);

    expect(find.text('kantong · paling kepake duluan'), findsOneWidget);
    expect(find.text('🐶 90%'), findsOneWidget);
    expect(find.text('☕ 60%'), findsOneWidget);

    expect(find.text('baru aja'), findsOneWidget);
    expect(find.text('-Rp27K hari ini'), findsOneWidget);
    expect(find.text('hari ini · rab 14 okt'), findsOneWidget);
    expect(find.text('kemarin · sel 13 okt'), findsOneWidget);
    expect(find.text('sen 12 okt'), findsOneWidget);
    expect(find.text('-Rp1,02jt'), findsOneWidget); // kemarin: 3 entries
    expect(find.text('gojek · 11.05'), findsOneWidget);
    expect(find.text('dokter hewan · 17.00'), findsOneWidget);
    // 7 this month, 5 shown: the 11th stays behind the button.
    expect(find.text('liat semua transaksi (7)'), findsOneWidget);
    expect(find.textContaining('tokopedia'), findsNothing);
  });

  testWidgets('beranda: tapping a future month peeks ±, screen stays on now', (
    tester,
  ) async {
    await pump(tester, memoryDb());

    await tester.tap(find.text('nov'));
    await tester.pumpAndSettle();

    expect(find.text('prediksi · nov'), findsOneWidget);
    expect(find.text('± Rp6,39jt'), findsOneWidget);
    expect(find.text('november'), findsOneWidget);
    expect(find.text('saldo kamu'), findsOneWidget);
    expect(find.text('baru aja'), findsOneWidget);
  });

  testWidgets('beranda: a past month swaps hero, pills and entries', (
    tester,
  ) async {
    await pump(tester, memoryDb());

    await tester.tap(find.text('sep'));
    await settle(tester);

    expect(find.text('saldo akhir september'), findsOneWidget);
    expect(find.text('8.589.000'), findsOneWidget);
    // budget Rp8jt − Rp2.612.500 spent
    expect(
      find.textContaining('sisa akhir bulan · Rp5,39jt', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('terakhir di september'), findsOneWidget);
    expect(find.text('liat semua di september (2)'), findsOneWidget);
    expect(find.text('🐶 0%'), findsOneWidget); // no anabul that month
    expect(find.text('hari ini'), findsNothing);
    expect(find.textContaining('hari ini ·'), findsNothing);
  });

  testWidgets('beranda: month menu follows data, locks the future', (
    tester,
  ) async {
    await pump(tester, memoryDb());

    await tester.tap(find.text('oktober'));
    await tester.pumpAndSettle();
    expect(find.text('pilih bulan'), findsOneWidget);
    Finder cell(String m) =>
        find.descendant(of: find.byType(MonthMenu), matching: find.text(m));

    // des is after the current month: locked, tapping does nothing.
    await tester.tap(cell('des'));
    await tester.pumpAndSettle();
    expect(find.text('pilih bulan'), findsOneWidget);

    await tester.tap(cell('agu'));
    await settle(tester);

    expect(find.text('pilih bulan'), findsNothing);
    expect(find.text('agustus'), findsOneWidget);
    expect(find.text('saldo akhir agustus'), findsOneWidget);
    expect(find.text('2.701.500'), findsOneWidget);
    expect(find.text('terakhir di agustus'), findsOneWidget);

    // "bulan ini" brings everything back.
    await tester.tap(find.text('agustus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bulan ini'));
    await settle(tester);
    expect(find.text('saldo kamu'), findsOneWidget);
    expect(find.text('baru aja'), findsOneWidget);
  });

  testWidgets('beranda: header turns compact once the hero scrolls away', (
    tester,
  ) async {
    await pump(tester, memoryDb());
    expect(find.text('saldo kamu'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(find.text('saldo kamu'), findsNWidgets(2)); // hero + compact
    expect(find.text('oktober'), findsNWidgets(2)); // picker stays reachable

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text('saldo kamu'), findsOneWidget);
  });

  testWidgets('beranda: nothing logged yet shows the big catat card', (
    tester,
  ) async {
    await pump(tester, memoryDb(seed: (_, _) async {}));

    expect(find.text('belum ada catatan'), findsOneWidget);
    expect(
      find.text('catat jajan pertama kamu, cuma 3 detik.'),
      findsOneWidget,
    );
    expect(find.text('baru aja'), findsNothing);
    expect(find.textContaining('liat semua'), findsNothing);
  });

  testWidgets('beranda: today empty keeps the group with a thin catat row', (
    tester,
  ) async {
    final db = memoryDb();
    await db.customStatement('SELECT 1'); // run the seed
    await (db.update(db.transactions)..where((t) => t.place.equals('gojek')))
        .write(TransactionsCompanion(deletedAt: Value(now)));
    await pump(tester, db);

    expect(find.text('hari ini · rab 14 okt'), findsOneWidget);
    expect(find.text('belum ada catatan hari ini'), findsOneWidget);
    expect(find.text('Rp0 hari ini'), findsOneWidget);
    expect(find.text('kemarin · sel 13 okt'), findsOneWidget);
    expect(find.text('belum ada catatan'), findsNothing); // not the big card
  });

  testWidgets('beranda: a month without entries says so, no button', (
    tester,
  ) async {
    await pump(tester, memoryDb());

    await tester.tap(find.text('oktober'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(MonthMenu), matching: find.text('jun')),
    );
    await settle(tester);

    expect(find.text('saldo akhir juni'), findsOneWidget);
    expect(find.text('terakhir di juni'), findsOneWidget);
    expect(find.text('belum ada catatan di juni'), findsOneWidget);
    expect(find.textContaining('liat semua'), findsNothing);
  });

  // Regression: a failing query (e.g. stale dev DB missing a table) used to
  // leave a blank screen with nothing in the console.
  test('stream errors surface instead of a blank beranda', () async {
    // homeProvider logs the injected error + stack; keep test output clean.
    final print = debugPrint;
    debugPrint = (_, {wrapWidth}) {};
    addTearDown(() => debugPrint = print);
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    addTearDown(db.close);
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        profileProvider.overrideWith((ref) => Stream.error(StateError('boom'))),
      ],
    );
    addTearDown(container.dispose);
    container.listen(profileProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(container.read(homeProvider), isA<AsyncError<HomeState>>());
  });
}
