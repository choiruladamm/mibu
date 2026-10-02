import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';
import 'package:mibu/domain/models/finance.dart';

void main() {
  test(
    'MIBU_RESET: an existing database is wiped, then seeded again',
    () async {
      final dir = await Directory.systemTemp.createTemp('mibu');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/mibu.sqlite');
      final now = DateTime(2026, 10, 14, 14, 50);

      final seeded = AppDatabase(NativeDatabase(file), () => now, seedFixture);
      expect(await seeded.select(seeded.transactions).get(), isNotEmpty);
      await seeded.close();

      // Reopened with reset + no seed: a fresh install.
      final fresh = AppDatabase(
        NativeDatabase(file),
        () => now,
        (_, _) async {},
        true,
      );
      addTearDown(fresh.close);
      expect(await fresh.select(fresh.transactions).get(), isEmpty);
      expect(await fresh.select(fresh.categories).get(), isEmpty);
      expect(await fresh.select(fresh.profiles).get(), isEmpty);
    },
  );

  test('reopen purges rows soft-deleted over a day ago, keeps referenced '
      'categories', () async {
    final dir = await Directory.systemTemp.createTemp('mibu');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/mibu.sqlite');
    final now = DateTime(2026, 10, 14, 14, 50);
    final old = now.subtract(const Duration(days: 2));
    final recent = now.subtract(const Duration(hours: 1));

    final db = AppDatabase(NativeDatabase(file), () => now, seedFixture);
    final txs = await db.select(db.transactions).get();
    final live = txs.length;
    Future<void> deleteTx(String id, DateTime at) =>
        (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
          TransactionsCompanion(deletedAt: Value(at)),
        );
    Future<void> deleteCat(String id, DateTime at) =>
        (db.update(db.categories)..where((c) => c.id.equals(id))).write(
          CategoriesCompanion(deletedAt: Value(at)),
        );
    // Two entries of one category, one gone long ago, one just now.
    final a = txs.firstWhere((t) => t.categoryId != null);
    final b = txs.firstWhere(
      (t) => t.categoryId == a.categoryId && t.id != a.id,
    );
    await deleteTx(a.id, old);
    await deleteTx(b.id, recent);
    await deleteCat(a.categoryId!, old); // still referenced by b
    final free = await db
        .into(db.categories)
        .insertReturning(
          CategoriesCompanion.insert(
            emoji: '🧪',
            name: 'tes',
            kind: CategoryKind.expense,
          ),
        );
    await deleteCat(free.id, old); // referenced by nothing
    await db.close();

    final again = AppDatabase(NativeDatabase(file), () => now, seedFixture);
    addTearDown(again.close);
    final left = await again.select(again.transactions).get();
    expect(left.length, live - 1);
    expect(left.any((t) => t.id == a.id), isFalse);
    expect(left.any((t) => t.id == b.id), isTrue); // inside the undo window
    final keptCats = await again.select(again.categories).get();
    expect(keptCats.any((c) => c.id == a.categoryId), isTrue);
    expect(keptCats.any((c) => c.id == free.id), isFalse);
  });
}
