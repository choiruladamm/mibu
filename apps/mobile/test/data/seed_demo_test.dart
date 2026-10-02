import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';
import 'package:mibu/data/repositories/finance_repository.dart';
import 'package:mibu/domain/models/finance.dart';

void main() {
  for (final now in [
    DateTime(2026, 10, 1, 0, 30), // 1st, just after midnight
    DateTime(2026, 10, 2, 15),
    DateTime(2026, 10, 31, 23),
  ]) {
    test(
      'demo seed on $now: nothing ahead, every pocket state shows',
      () async {
        final db = AppDatabase(
          DatabaseConnection(
            NativeDatabase.memory(),
            closeStreamsSynchronously: true,
          ),
          () => now,
          seedDemo,
        );
        addTearDown(db.close);

        final txs = await db.select(db.transactions).get();
        final catIds = {
          for (final c in await db.select(db.categories).get()) c.id,
        };
        expect(txs.length, greaterThan(200));
        expect(txs.where((t) => t.at.isAfter(now)), isEmpty);
        expect(
          txs.map((t) => t.categoryId).nonNulls.toSet().difference(catIds),
          isEmpty,
        );
        expect(txs.where((t) => t.categoryId == null), isNotEmpty);

        final pockets = {
          for (final p in await FinanceRepository(db).watchPockets(now).first)
            p.name: p,
        };
        expect(pockets['ngopi']!.status, PocketStatus.almostOut);
        expect(pockets['ngopi']!.usedPct, lessThanOrEqualTo(100));
        expect(pockets['ojol']!.usedPct, greaterThan(100));
        expect(pockets['hiburan']!.status, PocketStatus.unused);
      },
    );
  }
}
