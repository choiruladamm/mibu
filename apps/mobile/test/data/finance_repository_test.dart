import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/repositories/finance_repository.dart';

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
}
