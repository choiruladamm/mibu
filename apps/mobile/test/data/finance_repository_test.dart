import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/repositories/finance_repository.dart';

void main() {
  late AppDatabase db;
  late FinanceRepository repo;

  setUp(() {
    db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    repo = FinanceRepository(db);
  });
  tearDown(() => db.close());

  test('fresh db is seeded; streams map rows to domain models', () async {
    final months = await repo.watchMonths().first;
    expect(months.map((m) => m.month.month), [7, 8, 9, 10, 11, 12]);

    final pockets = await repo.watchPockets().first;
    expect(pockets.map((p) => '${p.emoji}${p.usedPct}'), [
      '🐶90',
      '☕60',
      '🛵38',
      '🍜26',
    ]);

    final recent = await repo.watchRecent().first;
    expect(recent.map((t) => t.place), ['petshop', 'gojek']); // newest first
  });
}
