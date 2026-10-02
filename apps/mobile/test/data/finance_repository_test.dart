import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/repositories/finance_repository.dart';
import 'package:mibu/domain/models/finance.dart';
import 'package:mibu/domain/period.dart';

Period cal(DateTime d) => const CalendarMonthResolver().periodOf(d);

void main() {
  final now = DateTime(2026, 10, 14, 14, 50);
  late AppDatabase db;
  late FinanceRepository repo;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
      () => now,
    );
    repo = FinanceRepository(db);
  });
  tearDown(() => db.close());

  test(
    'limits & budget per period: carried forward, old periods untouched',
    () async {
      final oct = cal(now), nov = cal(DateTime(2026, 11, 3));
      Future<Map<String, int?>> limits(Period p) async => {
        for (final c in await repo.watchCategories(p).first)
          c.name: c.monthlyLimit,
      };
      final anabul = (await repo.watchCategories(oct).first).firstWhere(
        (c) => c.name == 'anabul',
      );

      // Nothing saved for nov: the seeded rows carry on.
      expect((await limits(nov))['anabul'], 1000000);
      expect((await repo.watchProfile(nov).first).monthlyBudget, 8000000);

      // Changed in nov → nov's own row; okt keeps its number.
      await repo.setLimit(anabul.id, 1200000, nov);
      await repo.setMonthlyBudget(9000000, nov);
      expect((await limits(nov))['anabul'], 1200000);
      expect((await limits(oct))['anabul'], 1000000);
      expect((await repo.watchProfile(oct).first).monthlyBudget, 8000000);
      expect((await repo.watchProfile(nov).first).monthlyBudget, 9000000);

      // Copot in nov: gone from nov's jars, still a jar in okt.
      await repo.setLimit(anabul.id, null, nov);
      expect(
        (await repo.watchPockets(nov).first).map((p) => p.name),
        isNot(contains('anabul')),
      );
      expect(
        (await repo.watchPockets(oct).first).map((p) => p.name),
        contains('anabul'),
      );

      // Saving the same limit again (an icon swap) writes no row.
      final rows = (await db.select(db.limits).get()).length;
      await repo.updateCategory(
        anabul.id,
        emoji: '🐕',
        name: 'anabul',
        kind: CategoryKind.expense,
        monthlyLimit: 1000000,
        period: oct,
      );
      expect((await db.select(db.limits).get()).length, rows);
    },
  );

  test('gajian is the payday category (seed + atur awal)', () async {
    final payday = await (db.select(
      db.categories,
    )..where((c) => c.isPayday.equals(true))).get();
    expect(payday.map((c) => c.name), ['gajian']);
  });

  test('periods: calendar months until a rule says otherwise', () async {
    final none = await repo.watchPeriods().first;
    expect(none.periodOf(now).start, DateTime(2026, 10));

    await db
        .into(db.periodRules)
        .insert(
          PeriodRulesCompanion.insert(
            effectiveFrom: DateTime(2026, 11),
            mode: PeriodMode.payday,
            paydayDay: 25,
          ),
        );
    final r = await repo.watchPeriods().first;
    expect(r.periodOf(now).start, DateTime(2026, 10)); // before the rule
    expect(r.periodOf(DateTime(2026, 12, 1)).start, DateTime(2026, 11, 25));
  });

  test(
    'seed: balance, nets and pockets are derived from transactions',
    () async {
      final profile = await repo.watchProfile(cal(now)).first;
      expect(profile.payday, 25);
      expect(profile.monthlyBudget, 8000000);

      final totals = await repo.watchTotals(profile, now).first;
      expect(totals.balance, 4530000);
      expect(totals.nets, {
        DateTime(2026, 7): 546000,
        DateTime(2026, 8): -844500,
        DateTime(2026, 9): 5887500,
        DateTime(2026, 10): -4059000,
      });
      expect(totals.spent[DateTime(2026, 10)], greaterThan(0));
      expect(totals.spentToday, 27000);

      final pockets = await repo.watchPockets(cal(now)).first;
      expect(pockets.map((p) => '${p.emoji}${p.usedPct}'), [
        '🐶90',
        '☕60',
        '🛵38',
        '🍜26',
      ]);

      final recent = await repo.watchRecent().first;
      expect(recent.map((t) => t.place), ['gojek', 'petshop']); // newest first
      expect(recent.first.id, hasLength(36)); // uuid
    },
  );

  test('soft-deleted and uncategorized transactions', () async {
    final profile = await repo.watchProfile(cal(now)).first;
    final petshop = await (db.select(
      db.transactions,
    )..where((t) => t.place.equals('petshop'))).getSingle();
    await (db.update(db.transactions)..where((t) => t.id.equals(petshop.id)))
        .write(TransactionsCompanion(deletedAt: Value(now)));
    await db
        .into(db.transactions)
        .insert(TransactionsCompanion.insert(amount: -10000, at: now));

    final totals = await repo.watchTotals(profile, now).first;
    expect(totals.balance, 4530000 + 450000 - 10000);
    expect(totals.spentToday, 37000);

    final pockets = await repo.watchPockets(cal(now)).first;
    expect(pockets.first.spent, 450000); // anabul back to one entry

    final recent = await repo.watchRecent().first;
    expect(recent.first.category, isNull);
    expect(recent.first.emoji, '🧾');
  });

  test('add, recent picks / notes, per-day counts', () async {
    final makan = await (db.select(
      db.categories,
    )..where((c) => c.name.equals('makan'))).getSingle();
    await repo.addTransaction(
      amount: -25000,
      categoryId: makan.id,
      place: ' warteg ',
      note: 'makan siang',
      tags: const ['#kantor'],
      at: now,
    );

    final picks = await repo.watchRecentPicks(cal(now)).first;
    expect(picks.first.place, 'warteg'); // trimmed, newest first
    expect(picks.first.category.name, 'makan');
    expect(
      picks.map((p) => '${p.category.name}/${p.place}').toSet().length,
      picks.length,
    ); // distinct

    final notes = await repo.watchRecentNotes().first;
    expect(notes.map((n) => n.text), [
      'makan siang', // newest first, limit 2
      'makan siang bareng tim',
    ]);

    final days = await repo
        .watchDays(DateTime(2026, 10), DateTime(2026, 11))
        .first;
    expect(days[DateTime(2026, 10, 14)], (count: 2, net: -52000)); // + gojek
  });

  Future<String> idOf(String name) async => (await (db.select(
    db.categories,
  )..where((c) => c.name.equals(name))).getSingle()).id;

  test(
    'add / update category: trimmed lowercase, last, income drops limit',
    () async {
      final id = await repo.addCategory(
        emoji: '🏋️',
        name: ' Gym ',
        kind: CategoryKind.expense,
        monthlyLimit: 300000,
        period: cal(now),
      );
      var cats = await repo.watchCategories(cal(now)).first;
      expect(cats.last.id, id);
      expect(cats.last.name, 'gym');
      expect(
        (await repo.watchPockets(cal(now)).first).map((p) => p.name),
        contains('gym'),
      );

      await repo.updateCategory(
        id,
        emoji: '🧘',
        name: 'yoga',
        kind: CategoryKind.income,
        monthlyLimit: 300000,
        period: cal(now),
      );
      cats = await repo.watchCategories(cal(now)).first;
      expect(cats.last.name, 'yoga');
      expect(cats.last.monthlyLimit, isNull);
    },
  );

  test('pasang limit: this month\'s entries count right away', () async {
    final belanja = await idOf('belanja');
    final free = await repo.watchFreeCategories(cal(now)).first;
    expect(free.map((f) => f.category.name), ['belanja']); // income left out
    final before = free.single;

    await repo.setLimit(belanja, 600000, cal(now));
    final pocket = (await repo.watchPockets(cal(now)).first).firstWhere(
      (p) => p.id == belanja,
    );
    expect(pocket.spent, before.spent); // nothing moved, already counted
    expect(await repo.watchFreeCategories(cal(now)).first, isEmpty);

    // copot limit sheet: this month's count + spend match the jar.
    expect(await repo.periodUsage(belanja, cal(now)), (
      count: before.count,
      spent: before.spent,
    ));

    // copot limit: category + entries stay, it just leaves the jars.
    await repo.setLimit(belanja, null, cal(now));
    expect(
      (await repo.watchPockets(cal(now)).first).map((p) => p.id),
      isNot(contains(belanja)),
    );
    expect(
      (await repo.watchCategories(cal(now)).first).map((c) => c.id),
      contains(belanja),
    );
    final back = (await repo.watchFreeCategories(cal(now)).first).single;
    expect(
      (back.category.id, back.spent, back.count),
      (belanja, before.spent, before.count),
    );

    // Income never gets a limit.
    final gajian = await idOf('gajian');
    await repo.setLimit(gajian, 500000, cal(now));
    expect(
      (await repo.watchCategories(cal(now)).first)
          .firstWhere((c) => c.id == gajian)
          .monthlyLimit,
      isNull,
    );
  });

  test('free categories: count, most spent then most used', () async {
    final a = await repo.addCategory(
      emoji: '🎮',
      name: 'game',
      kind: CategoryKind.expense,
      monthlyLimit: null,
      period: cal(now),
    );
    final b = await repo.addCategory(
      emoji: '📚',
      name: 'buku',
      kind: CategoryKind.expense,
      monthlyLimit: null,
      period: cal(now),
    );
    for (final (id, amount) in [(a, -5000), (b, -2500), (b, -2500)]) {
      await repo.addTransaction(
        amount: amount,
        categoryId: id,
        place: '',
        note: '',
        tags: const [],
        at: now,
      );
    }
    final free = await repo.watchFreeCategories(cal(now)).first;
    final tail = free.where((f) => f.category.id == a || f.category.id == b);
    expect(tail.map((f) => '${f.category.name}${f.spent}/${f.count}'), [
      'buku5000/2', // same spending, more entries first
      'game5000/1',
    ]);
  });

  test('uncategorized: in totals, in no pocket, counts once edited', () async {
    final profile = await repo.watchProfile(cal(now)).first;
    final pocketsBefore = await repo.watchPockets(cal(now)).first;
    final spentBefore =
        (await repo.watchTotals(profile, now).first).spent[DateTime(2026, 10)]!;
    await repo.addTransaction(
      amount: -20000,
      categoryId: null,
      place: '',
      note: '',
      tags: const [],
      at: now,
    );
    expect(
      (await repo.watchTotals(profile, now).first).spent[DateTime(2026, 10)],
      spentBefore + 20000,
    );
    expect(
      (await repo.watchPockets(cal(now)).first).map((p) => p.spent),
      pocketsBefore.map((p) => p.spent),
    );

    final t = (await repo.watchRecent().first).first;
    final makan = await idOf('makan');
    await repo.updateTransaction(
      t.id,
      amount: t.amount,
      categoryId: makan,
      place: t.place,
      note: t.note,
      at: t.at,
    );
    int spentOf(List<Pocket> ps) => ps.firstWhere((p) => p.id == makan).spent;
    expect(
      spentOf(await repo.watchPockets(cal(now)).first),
      spentOf(pocketsBefore) + 20000,
    );
  });

  test('reorder categories', () async {
    final ids = [
      for (final c in await repo.watchCategories(cal(now)).first) c.id,
    ];
    await repo.reorderCategories(ids.reversed.toList());
    final after = [
      for (final c in await repo.watchCategories(cal(now)).first) c.id,
    ];
    expect(after, ids.reversed);
  });

  test('usage: all-time count, this year\'s expense', () async {
    final usage = await repo.watchCategoryUsage(now).first;
    expect(usage[await idOf('anabul')], (count: 2, spentThisYear: 900000));
    expect(usage[await idOf('gajian')]?.count, 3);
    expect(usage[await idOf('gajian')]?.spentThisYear, 0);
  });

  test('delete category moves entries, undo restores both', () async {
    final anabul = await idOf('anabul');
    final makan = await idOf('makan');
    final moved = await repo.deleteCategory(anabul, moveTo: makan);
    expect(moved, hasLength(2));

    expect(
      (await repo.watchCategories(cal(now)).first).map((c) => c.name),
      isNot(contains('anabul')),
    );
    var pockets = await repo.watchPockets(cal(now)).first;
    expect(pockets.firstWhere((p) => p.name == 'makan').spent, 390000 + 900000);

    await repo.undoDeleteCategory(anabul, moved);
    pockets = await repo.watchPockets(cal(now)).first;
    expect(pockets.firstWhere((p) => p.name == 'anabul').spent, 900000);
    expect(pockets.firstWhere((p) => p.name == 'makan').spent, 390000);
  });

  test('delete to tanpa kategori', () async {
    final ngopi = await idOf('ngopi');
    await repo.deleteCategory(ngopi, moveTo: null);
    final usage = await repo.watchCategoryUsage(now).first;
    expect(usage[ngopi], isNull);
    final recent = await repo.watchRecent(limit: 10).first;
    expect(
      recent.firstWhere((t) => t.place == 'kopi kenangan').category,
      isNull,
    );
  });

  test('month list, first month, edit, delete + restore', () async {
    expect(await repo.watchFirstMonth().first, DateTime(2026, 7));
    var oct = await repo.watchPeriod(cal(DateTime(2026, 10, 20))).first;
    expect(oct, hasLength(7));
    expect(oct.first.place, 'gojek'); // newest first
    expect(
      (await repo.watchPeriod(cal(DateTime(2026, 9))).first),
      hasLength(2),
    );

    final warteg = oct.firstWhere((t) => t.place == 'warteg');
    expect(warteg.note, 'makan siang bareng tim');
    expect(warteg.kind, CategoryKind.expense);

    final ngopi = await idOf('ngopi');
    await repo.updateTransaction(
      warteg.id,
      amount: -30000,
      categoryId: ngopi,
      place: ' kopken ',
      note: '',
      at: DateTime(2026, 10, 2, 8),
    );
    var t = (await repo.watchTransaction(warteg.id).first)!;
    expect(
      (t.amount, t.category, t.place, t.note),
      (-30000, 'ngopi', 'kopken', ''),
    );
    expect(t.at, DateTime(2026, 10, 2, 8));

    await repo.deleteTransaction(warteg.id);
    t = (await repo.watchTransaction(warteg.id).first)!;
    expect(t.deleted, isTrue); // still readable for the 04.3c stamp
    oct = await repo.watchPeriod(cal(DateTime(2026, 10))).first;
    expect(oct, hasLength(6));

    await repo.restoreTransaction(warteg.id);
    expect((await repo.watchTransaction(warteg.id).first)!.deleted, isFalse);
    expect(await repo.watchPeriod(cal(DateTime(2026, 10))).first, hasLength(7));
  });

  test(
    '01.4 completeSetup: profile, presets, pockets; seeded db keeps its own',
    () async {
      final fresh = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
        () => now,
        (_, _) async {},
      );
      addTearDown(fresh.close);
      final r = FinanceRepository(fresh);
      expect((await r.watchProfile(cal(now)).first).onboarded, isFalse);

      await r.completeSetup(
        openingBalance: 2500000,
        payday: 0,
        pockets: {'makan', 'ngopi'},
        now: now,
        period: cal(now),
      );
      final p = await r.watchProfile(cal(now)).first;
      expect(
        (p.onboarded, p.openingBalance, p.payday, p.monthlyBudget),
        (true, 2500000, 0, null),
      );
      final cats = await r.watchCategories(cal(now)).first;
      expect(cats.map((c) => c.name), [
        ...setupPockets.map((p) => p.$2),
        'gajian',
      ]);
      expect(cats.last.kind, CategoryKind.income);
      expect(
        (await fresh.select(fresh.categories).get())
            .where((c) => c.isPayday)
            .map((c) => c.name),
        ['gajian'],
      );
      expect(
        (await r.watchPockets(cal(now)).first).map(
          (p) => '${p.name}${p.budget}',
        ),
        ['makan1500000', 'ngopi300000'],
      );

      // Already has categories (seeded): only the profile changes.
      await repo.completeSetup(
        openingBalance: 1,
        payday: 10,
        pockets: {'makan'},
        now: now,
        period: cal(now),
      );
      expect((await repo.watchProfile(cal(now)).first).openingBalance, 1);
      expect(await repo.watchCategories(cal(now)).first, hasLength(6));
    },
  );
}
