import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/period.dart';
import 'package:mibu/data/repositories/finance_repository.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/money.dart';
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

    expect(find.text('3.941.000'), findsOneWidget); // 8jt − 4.059.000
    expect(find.text('sisa budget'), findsOneWidget);
    expect(find.text('oktober'), findsOneWidget);
    // 25 okt = minggu → paid Fri 23.
    expect(
      findMeta(['dari budget Rp8jt', 'gajian lagi 9 hari']),
      findsOneWidget,
    );
    // Aman jajan from the budget only:
    // (8jt − 4.059.000 kepake + 27.000 hari ini) ÷ 18 hari − 27.000.
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
    // 00.4: tempat left, jam right
    expect(findMeta(['gojek']), findsOneWidget);
    expect(findMeta(['11:05']), findsOneWidget);
    expect(findMeta(['dokter hewan']), findsOneWidget);
    expect(findMeta(['17:00']), findsOneWidget);
    // 7 this month, 5 shown: the 11th stays behind the button.
    expect(find.text('semua transaksi (7)'), findsOneWidget);
    expect(find.textContaining('tokopedia'), findsNothing);
  });

  testWidgets('beranda: chart = kepake per periode, budget line, no future', (
    tester,
  ) async {
    await pump(tester, memoryDb());

    expect(find.text('kepake per periode'), findsOneWidget);
    expect(find.text('budget Rp8jt'), findsOneWidget);
    // mei … okt: the running period is the last point, nothing ahead.
    expect(findMeta(['berjalan', 'okt']), findsOneWidget);
    expect(find.text('Rp4,06jt'), findsOneWidget);
    expect(find.text('mei'), findsOneWidget);
    expect(find.text('nov'), findsNothing);
  });

  testWidgets('beranda: a past month swaps hero, pills and entries', (
    tester,
  ) async {
    await pump(tester, memoryDb());

    await tester.tap(find.text('sep'));
    await settle(tester);

    // Budget Rp8jt − Rp2.612.500 spent; the period's dates instead of
    // "gajian lagi" (fixture: calendar months).
    expect(find.text('sisa budget september'), findsOneWidget);
    expect(find.text('5.387.500'), findsOneWidget);
    expect(findMeta(['dari budget Rp8jt', '1 sep – 30 sep']), findsOneWidget);
    // Rp2.612.500 spent ÷ 30 days
    expect(findMeta(['rata²/hari', 'Rp87K']), findsOneWidget);
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
    expect(find.textContaining('budget agustus'), findsOneWidget);
    expect(find.text('terakhir di agustus'), findsOneWidget);

    // "bulan ini" brings everything back.
    await tester.tap(find.text('agustus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bulan ini'));
    await settle(tester);
    expect(find.text('sisa budget'), findsOneWidget);
    expect(find.text('baru aja'), findsOneWidget);
  });

  testWidgets('beranda: header turns compact once the hero scrolls away', (
    tester,
  ) async {
    await pump(tester, memoryDb());
    expect(find.text('sisa budget'), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -300),
    );
    await tester.pumpAndSettle();

    expect(find.text('sisa budget'), findsNWidgets(2)); // hero + compact
    expect(find.text('oktober'), findsNWidgets(2)); // picker stays reachable
    final sticky = find.byKey(const ValueKey('sticky'));
    expect(
      find.descendant(of: sticky, matching: find.text('Rp3,94jt')),
      findsOneWidget,
    );
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

    // No budget before jul in the fixture: what was spent (nothing).
    expect(find.text('kepake juni'), findsOneWidget);
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

  testWidgets('hero: sisa budget, no saldo, no toggle', (tester) async {
    final db = memoryDb();
    await pump(tester, db);

    expect(find.text('sisa budget'), findsOneWidget);
    expect(find.text('3.941.000'), findsOneWidget); // 8jt − 4.059.000
    expect(find.text('saldo kamu'), findsNothing);
    expect(find.text('tap buat liat sisa budget'), findsNothing);
    // aman jajan from the budget only: 3.941.000 ÷ 18 days, less today.
    expect(find.textContaining('Rp193K', findRichText: true), findsOneWidget);
  });

  testWidgets('hero: no budget → dashed card + chip ask for one (02.1g)', (
    tester,
  ) async {
    final db = memoryDb();
    await pump(tester, db);
    await tester.runAsync(() => setBudgetOf(db, null));
    await settle(tester);

    expect(find.text('atur budget periode ini'), findsOneWidget);
    expect(
      findMeta(['oktober', '1 okt – 31 okt', 'gajian lagi 9 hari']),
      findsOneWidget,
    );
    expect(find.textContaining('kepake periode ini Rp4,06jt'), findsOneWidget);
    // Never guessed from income: no figure, the chip asks for a budget.
    expect(
      find.textContaining('aman jajan hari ini', findRichText: true),
      findsNothing,
    );
    expect(
      find.textContaining(
        'isi budget biar dapet aman jajan',
        findRichText: true,
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('atur budget'));
    await tester.pumpAndSettle();
    expect(find.text('budget per periode'), findsOneWidget); // 00.16
  });

  testWidgets('hero: budget gone → kelewat, rem dulu chip', (tester) async {
    final db = memoryDb();
    await pump(tester, db);
    await tester.runAsync(() => setBudgetOf(db, 1000000));
    await settle(tester);

    expect(findMeta(['rem dulu ya', '18 hari lagi']), findsOneWidget);
    expect(find.textContaining('aman jajan', findRichText: true), findsNothing);
    expect(find.text('kelewat budget'), findsOneWidget);
    expect(find.text('3.059.000'), findsOneWidget);
  });

  testWidgets('hero: "?" explains sisa budget and aman jajan, no saldo', (
    tester,
  ) async {
    await pump(tester, memoryDb());
    await tester.tap(find.bySemanticsLabel('dari mana angkanya?'));
    await settle(tester);

    expect(find.text('dari mana angkanya?'), findsOneWidget);
    expect(find.textContaining('saldo'), findsNothing);
    expect(findMeta(['oktober', '1 okt – 31 okt']), findsOneWidget);
    expect(find.text('budget Rp8jt − kepake Rp4,06jt'), findsOneWidget);
    expect(find.text('Rp3,94jt'), findsOneWidget);
    // The same share the chip is made of: (3.941.000 + 27.000 today) ÷ 18.
    expect(
      find.text('sisa budget Rp3,97jt ÷ 18 hari sampai gajian'),
      findsOneWidget,
    );
    expect(find.text('Rp220K'), findsOneWidget);
    expect(
      find.text(
        'udah kepake Rp27K hari ini, jadi aman jajan hari ini tinggal Rp193K.',
      ),
      findsOneWidget,
    );
    expect(find.text('sisa jajan (kantong)'), findsOneWidget);
    await tester.tap(find.text('oke, ngerti'));
    await settle(tester);
    expect(find.text('dari mana angkanya?'), findsNothing);
  });

  group('hari gajian (25 okt 2026 is a Sunday → paid Fri 23)', () {
    testWidgets('hari-H, salary not logged: ajak catat, no division', (
      tester,
    ) async {
      final at = DateTime(2026, 10, 23, 9);
      await pump(tester, memoryDb(at: at), at: at);
      expect(
        find.textContaining('gajian hari ini', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('udah gajian? catat'), findsOneWidget);
      expect(
        find.textContaining('aman jajan', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('lewat, salary not logged: telat n hari', (tester) async {
      final at = DateTime(2026, 10, 24, 9);
      await pump(tester, memoryDb(at: at), at: at);
      expect(
        find.textContaining('gajian telat 1 hari', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('gajian belum masuk? catat'), findsOneWidget);
    });

    testWidgets('logging the salary resets: gajian lagi 29 hari, aman jajan', (
      tester,
    ) async {
      final at = DateTime(2026, 10, 27, 9);
      final db = memoryDb(at: at);
      await pump(tester, db, at: at);
      expect(
        find.textContaining('gajian telat 4 hari', findRichText: true),
        findsOneWidget,
      );

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
      expect(
        find.textContaining('gajian lagi 29 hari', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('udah gajian? catat'), findsNothing);
      expect(find.text('gajian belum masuk? catat'), findsNothing);
      expect(
        find.textContaining('aman jajan', findRichText: true),
        findsOneWidget,
      );
    });
  });

  group(
    'periode gajian (gajian tgl 25; okt: 25 sep – 22 okt, jum 23 = gajian)',
    () {
      /// Fixture db with a payday rule, plus Rp100K spent on 27 sep: inside the
      /// "oktober" period, outside the calendar October.
      Future<AppDatabase> paydayDb(WidgetTester tester) async {
        final db = memoryDb();
        await tester.runAsync(() async {
          await db
              .into(db.periodRules)
              .insert(
                PeriodRulesCompanion.insert(
                  effectiveFrom: DateTime(2026, 1, 1),
                  mode: PeriodMode.payday,
                  paydayDay: 25,
                  shift: const Value(PaydayShift.previousWorkday),
                ),
              );
          final makan = await (db.select(
            db.categories,
          )..where((c) => c.name.equals('makan'))).getSingle();
          await FinanceRepository(db).addTransaction(
            amount: -100000,
            categoryId: makan.id,
            place: 'warteg',
            note: '',
            tags: const [],
            at: DateTime(2026, 9, 27, 12),
          );
        });
        return db;
      }

      testWidgets('sisa budget counts from the last payday, not the 1st', (
        tester,
      ) async {
        final db = await paydayDb(tester);
        await pump(tester, db);
        // Every expense since 25 sep, not just October's.
        final spent = (await tester.runAsync(
          () =>
              (db.select(db.transactions)..where(
                    (t) =>
                        t.amount.isSmallerThanValue(0) &
                        t.at.isBiggerOrEqualValue(DateTime(2026, 9, 25)) &
                        t.at.isSmallerThanValue(DateTime(2026, 10, 23)),
                  ))
                  .get(),
        ))!.fold<int>(0, (a, t) => a - t.amount);
        expect(spent, greaterThan(4159000 - 1)); // october's + the 27 sep one

        final left = 8000000 - spent;
        expect(find.text(rupiah(left).replaceFirst('Rp', '')), findsOneWidget);
        expect(find.text('oktober'), findsWidgets); // still "oktober"
      });

      testWidgets('04.1 oktober includes the 27 sep entry', (tester) async {
        final db = await paydayDb(tester);
        await pump(tester, db);
        final rows = (await tester.runAsync(() async {
          final repo = FinanceRepository(db);
          final period = (await repo.watchPeriods().first).periodForMonth(
            DateTime(2026, 10),
          );
          return repo.watchPeriod(period).first;
        }))!;
        expect(rows.any((t) => t.at == DateTime(2026, 9, 27, 12)), isTrue);
        expect(
          rows.every((t) => !t.at.isBefore(DateTime(2026, 9, 25))),
          isTrue,
        );
      });
    },
  );
}
