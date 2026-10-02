import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/models/finance.dart';
import 'package:mibu/data/repositories/finance_repository.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/core/widgets/month_menu.dart';
import 'package:mibu/ui/core/finance_providers.dart';
import 'package:mibu/ui/features/home/view_models/home_view_model.dart';
import 'package:mibu/ui/features/home/views/home_view.dart';

import '../../../db.dart';
import '../../../meta.dart';

void main() {
  final now = DateTime(2026, 10, 14, 14, 50);

  AppDatabase memoryDb({Seed? seed, DateTime? at}) => AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
    () => at ?? now,
    seed ?? seedFixture,
  );

  /// Pumps 02.1 on a phone-sized screen over [db].
  Future<void> pump(WidgetTester tester, AppDatabase db, {DateTime? at}) async {
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
          clockProvider.overrideWithValue(() => at ?? now),
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
    expect(find.text('gajian lagi 9 hari'), findsOneWidget); // 25 okt = minggu
    // Budget side of aman jajan wins, it's the smaller one:
    // (8jt − 4.059.000 kepake + 27.000 hari ini) ÷ 18 hari − 27.000.
    // The saldo side would say Rp479K (÷ 9 days to gajian Fri 23).
    expect(find.textContaining('Rp193K', findRichText: true), findsOneWidget);

    expect(find.text('kantong'), findsOneWidget);
    expect(find.text('liat semua'), findsOneWidget);
    expect(findEmojiText('🐶 90%'), findsOneWidget);
    expect(findEmojiText('☕ 60%'), findsOneWidget);

    expect(find.text('baru aja'), findsOneWidget);
    expect(find.text('-Rp27K hari ini'), findsOneWidget);
    expect(findMeta(['hari ini', 'rab 14 okt']), findsOneWidget);
    expect(findMeta(['kemarin', 'sel 13 okt']), findsOneWidget);
    expect(find.text('sen 12 okt'), findsOneWidget);
    expect(find.text('-Rp1,02jt'), findsOneWidget); // kemarin: 3 entries
    expect(findMeta(['gojek', '11.05']), findsOneWidget);
    expect(findMeta(['dokter hewan', '17.00']), findsOneWidget);
    // 7 this month, 5 shown: the 11th stays behind the button.
    expect(find.text('semua transaksi (7)'), findsOneWidget);
    expect(find.textContaining('tokopedia'), findsNothing);
  });

  testWidgets('beranda: tapping a future month peeks ±, screen stays on now', (
    tester,
  ) async {
    await pump(tester, memoryDb());

    await tester.tap(find.text('nov'));
    await tester.pumpAndSettle();

    expect(findMeta(['prediksi', 'nov']), findsOneWidget);
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
    expect(find.text('per 30 sep'), findsOneWidget);
    // Rp2.612.500 spent ÷ 30 days
    expect(findMeta(['rata²/hari', 'Rp87K']), findsOneWidget);
    // The pill follows into past months: budget Rp8jt − Rp2.612.500 spent.
    await tester.tap(find.text('saldo akhir september'));
    await settle(tester);
    expect(find.text('sisa budget akhir september'), findsOneWidget);
    expect(find.text('5.387.500'), findsOneWidget);
    expect(find.text('dari budget Rp8jt'), findsOneWidget);
    await tester.tap(find.text('sisa budget akhir september'));
    await settle(tester);
    expect(find.text('terakhir di september'), findsOneWidget);
    expect(find.text('liat semua di september (2)'), findsOneWidget);
    expect(findEmojiText('🐶 0%'), findsOneWidget); // no anabul that month
    expect(find.text('hari ini'), findsNothing);
    expect(findMeta(['hari ini', 'okt']), findsNothing);
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

    // The compact header flips the mode too, and follows it.
    final sticky = find.byKey(const ValueKey('sticky'));
    await tester.tap(
      find.descendant(of: sticky, matching: find.text('saldo kamu')),
    );
    await settle(tester);
    expect(
      find.descendant(of: sticky, matching: find.text('sisa budget')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: sticky, matching: find.text('Rp3,94jt')),
      findsOneWidget,
    );

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(find.text('sisa budget'), findsOneWidget); // hero kept the pick
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
    expect(find.textContaining('liat semua '), findsNothing);
  });

  testWidgets('beranda: today empty keeps the group with a thin catat row', (
    tester,
  ) async {
    final db = memoryDb();
    await db.customStatement('SELECT 1'); // run the seed
    await (db.update(db.transactions)..where((t) => t.place.equals('gojek')))
        .write(TransactionsCompanion(deletedAt: Value(now)));
    await pump(tester, db);

    expect(findMeta(['hari ini', 'rab 14 okt']), findsOneWidget);
    expect(find.text('belum ada catatan hari ini'), findsOneWidget);
    expect(find.text('Rp0 hari ini'), findsOneWidget);
    expect(findMeta(['kemarin', 'sel 13 okt']), findsOneWidget);
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
    expect(find.textContaining('liat semua '), findsNothing);
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

  Future<Profile> profileOf(WidgetTester tester, AppDatabase db) async =>
      (await tester.runAsync(
        () => FinanceRepository(db).watchProfile(cal(now)).first,
      ))!;

  testWidgets('hero: pill flips saldo ⇄ sisa budget, remembered, hint once', (
    tester,
  ) async {
    final db = memoryDb();
    await pump(tester, db);

    // Default saldo; first time the hint points at the pill.
    expect(find.text('saldo kamu'), findsOneWidget);
    expect(find.text('4.530.000'), findsOneWidget);
    expect(find.text('tap buat liat sisa budget'), findsOneWidget);

    await tester.tap(find.text('saldo kamu'));
    await settle(tester);
    expect(find.text('sisa budget'), findsOneWidget);
    expect(find.text('3.941.000'), findsOneWidget); // 8jt − 4.059.000
    expect(find.text('dari budget Rp8jt'), findsOneWidget);
    expect(find.text('tap buat liat sisa budget'), findsNothing); // used
    // The chip doesn't follow the mode.
    expect(find.textContaining('Rp193K', findRichText: true), findsOneWidget);
    var p = await profileOf(tester, db);
    expect((p.heroMode, p.heroHintSeen), (BalanceMode.budget, true));

    await tester.tap(find.text('sisa budget'));
    await settle(tester);
    expect(find.text('saldo kamu'), findsOneWidget);
    expect((await profileOf(tester, db)).heroMode, BalanceMode.saldo);
  });

  testWidgets('hero: oke retires the hint without flipping', (tester) async {
    final db = memoryDb();
    await pump(tester, db);
    await tester.tap(find.text('oke'));
    await settle(tester);
    expect(find.text('tap buat liat sisa budget'), findsNothing);
    final p = await profileOf(tester, db);
    expect((p.heroMode, p.heroHintSeen), (BalanceMode.saldo, true));
  });

  testWidgets('hero: no budget → plain label, pasang budget link, no hint', (
    tester,
  ) async {
    final db = memoryDb();
    await pump(tester, db);
    await tester.runAsync(() => setBudgetOf(db, null));
    await settle(tester);

    expect(find.text('saldo kamu'), findsOneWidget);
    expect(find.text('pasang budget'), findsOneWidget);
    expect(find.text('tap buat liat sisa budget'), findsNothing);
    expect(find.byType(HugeIcon).evaluate().length, greaterThan(0));
    // aman jajan falls back to the saldo side: ÷ 9 days → Rp479K.
    expect(find.textContaining('Rp479K', findRichText: true), findsOneWidget);
  });

  testWidgets('hero: budget gone → kelewat, rem dulu chip', (tester) async {
    final db = memoryDb();
    await pump(tester, db);
    await tester.runAsync(() => setBudgetOf(db, 1000000));
    await settle(tester);

    expect(find.text('budget bulan ini kelewat Rp3,06jt'), findsOneWidget);
    expect(findMeta(['rem dulu ya', '18 hari lagi']), findsOneWidget);
    expect(find.textContaining('aman jajan', findRichText: true), findsNothing);

    await tester.tap(find.text('saldo kamu'));
    await settle(tester);
    expect(find.text('kelewat budget'), findsOneWidget);
    expect(find.text('3.059.000'), findsOneWidget);
  });

  testWidgets('hero: "?" explains saldo, sisa budget and aman jajan', (
    tester,
  ) async {
    await pump(tester, memoryDb());
    await tester.tap(find.bySemanticsLabel('dari mana angkanya?'));
    await settle(tester);

    expect(find.text('dari mana angkanya?'), findsOneWidget);
    expect(find.textContaining('saldo awal + semua catatan'), findsOneWidget);
    expect(
      find.text('budget Rp8jt − semua pengeluaran Rp4,06jt = Rp3,94jt.'),
      findsOneWidget,
    );
    // The same shares the chip is made of: saldo ÷ 9, budget ÷ 18 (smaller).
    expect(
      find.textContaining(
        'saldo ÷ 9 hari (Rp506K) dan sisa budget ÷ 18 hari (Rp220K)',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('ngerti'));
    await settle(tester);
    expect(find.text('dari mana angkanya?'), findsNothing);
  });

  group('hari gajian (25 okt 2026 is a Sunday → paid Fri 23)', () {
    testWidgets('hari-H, salary not logged: ajak catat, no division', (
      tester,
    ) async {
      final at = DateTime(2026, 10, 23, 9);
      await pump(tester, memoryDb(at: at), at: at);
      expect(find.text('gajian hari ini'), findsOneWidget);
      expect(find.text('udah gajian? catat'), findsOneWidget);
      expect(
        find.textContaining('aman jajan', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('lewat, salary not logged: telat n hari', (tester) async {
      final at = DateTime(2026, 10, 24, 9);
      await pump(tester, memoryDb(at: at), at: at);
      expect(find.text('gajian telat 1 hari'), findsOneWidget);
      expect(find.text('gajian belum masuk? catat'), findsOneWidget);
    });

    testWidgets('logging the salary resets: gajian lagi 29 hari, aman jajan', (
      tester,
    ) async {
      final at = DateTime(2026, 10, 27, 9);
      final db = memoryDb(at: at);
      await pump(tester, db, at: at);
      expect(find.text('gajian telat 4 hari'), findsOneWidget);

      await tester.runAsync(() async {
        final gajian = await (db.select(
          db.categories,
        )..where((c) => c.isPayday.equals(true))).getSingle();
        await FinanceRepository(db).addTransaction(
          amount: 8500000,
          categoryId: gajian.id,
          place: 'kantor',
          note: '',
          tags: const [],
          at: DateTime(2026, 10, 25, 9),
        );
      });
      await settle(tester);
      expect(find.text('gajian lagi 29 hari'), findsOneWidget);
      expect(find.text('udah gajian? catat'), findsNothing);
      expect(find.text('gajian belum masuk? catat'), findsNothing);
      expect(
        find.textContaining('aman jajan', findRichText: true),
        findsOneWidget,
      );
    });
  });
}
