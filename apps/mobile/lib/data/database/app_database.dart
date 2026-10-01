import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

@DataClassName('MonthBalanceRow')
class MonthBalances extends Table {
  DateTimeColumn get month => dateTime()(); // first day of month
  IntColumn get amount => integer()();

  @override
  Set<Column> get primaryKey => {month};
}

@DataClassName('PocketRow')
class Pockets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get emoji => text()();
  TextColumn get name => text()();
  IntColumn get budget => integer()();
  IntColumn get spent => integer().withDefault(const Constant(0))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('TransactionRow')
class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get emoji => text()();
  TextColumn get category => text()();
  TextColumn get place => text()();
  DateTimeColumn get at => dateTime()();
  IntColumn get amount => integer()(); // negative = pengeluaran
}

@DriftDatabase(tables: [MonthBalances, Pockets, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'mibu'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      if (details.wasCreated) await _seed();
    },
  );

  // ponytail: sample data from the design board so screens aren't empty;
  // drop once onboarding/setup (01.4) writes real data.
  Future<void> _seed() => batch((b) {
    b.insertAll(monthBalances, [
      for (final (m, v) in [
        (7, 3546000),
        (8, 2701500),
        (9, 8589000),
        (10, 4530000),
        (11, 7020000),
        (12, 2820000),
      ])
        MonthBalancesCompanion.insert(month: DateTime(2026, m), amount: v),
    ]);
    b.insertAll(pockets, [
      for (final (i, (e, n, budget, spent)) in [
        ('🐶', 'anabul', 1000000, 900000),
        ('☕', 'ngopi', 300000, 180000),
        ('🛵', 'ojol', 500000, 190000),
        ('🍜', 'makan', 1500000, 390000),
      ].indexed)
        PocketsCompanion.insert(
          emoji: e,
          name: n,
          budget: budget,
          spent: Value(spent),
          sortOrder: Value(i),
        ),
    ]);
    b.insertAll(transactions, [
      TransactionsCompanion.insert(
        emoji: '🐶',
        category: 'anabul',
        place: 'petshop',
        at: DateTime(2026, 10, 14, 14, 32),
        amount: -450000,
      ),
      TransactionsCompanion.insert(
        emoji: '🛵',
        category: 'ojol',
        place: 'gojek',
        at: DateTime(2026, 10, 14, 11, 5),
        amount: -27000,
      ),
    ]);
  });
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
