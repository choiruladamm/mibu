import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/repositories/finance_repository.dart';
import 'package:mibu/domain/models/finance.dart';

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
    'seed: balance, nets and pockets are derived from transactions',
    () async {
      final profile = await repo.watchProfile().first;
      expect(profile.payday, 25);
      expect(profile.monthlyBudget, 8000000);

      final totals = await repo.watchTotals(profile, now).first;
      expect(totals.balance, 4530000);
      expect(totals.nets, [546000, -844500, 5887500, -4059000]);
      expect(totals.spentToday, 27000);

      final pockets = await repo.watchPockets(now).first;
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
    final profile = await repo.watchProfile().first;
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

    final pockets = await repo.watchPockets(now).first;
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

    final picks = await repo.watchRecentPicks().first;
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
      );
      var cats = await repo.watchCategories().first;
      expect(cats.last.id, id);
      expect(cats.last.name, 'gym');
      expect(
        (await repo.watchPockets(now).first).map((p) => p.name),
        contains('gym'),
      );

      await repo.updateCategory(
        id,
        emoji: '🧘',
        name: 'yoga',
        kind: CategoryKind.income,
        monthlyLimit: 300000,
      );
      cats = await repo.watchCategories().first;
      expect(cats.last.name, 'yoga');
      expect(cats.last.monthlyLimit, isNull);
    },
  );

  test('reorder categories', () async {
    final ids = [for (final c in await repo.watchCategories().first) c.id];
    await repo.reorderCategories(ids.reversed.toList());
    final after = [for (final c in await repo.watchCategories().first) c.id];
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
      (await repo.watchCategories().first).map((c) => c.name),
      isNot(contains('anabul')),
    );
    var pockets = await repo.watchPockets(now).first;
    expect(pockets.firstWhere((p) => p.name == 'makan').spent, 390000 + 900000);

    await repo.undoDeleteCategory(anabul, moved);
    pockets = await repo.watchPockets(now).first;
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
    var oct = await repo.watchMonth(DateTime(2026, 10, 20)).first;
    expect(oct, hasLength(7));
    expect(oct.first.place, 'gojek'); // newest first
    expect((await repo.watchMonth(DateTime(2026, 9)).first), hasLength(2));

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
    oct = await repo.watchMonth(DateTime(2026, 10)).first;
    expect(oct, hasLength(6));

    await repo.restoreTransaction(warteg.id);
    expect((await repo.watchTransaction(warteg.id).first)!.deleted, isFalse);
    expect(await repo.watchMonth(DateTime(2026, 10)).first, hasLength(7));
  });
}
