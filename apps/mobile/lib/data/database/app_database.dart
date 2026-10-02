import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/finance.dart';
import 'seed.dart';

part 'app_database.g.dart';

const _uuid = Uuid();

/// UUID id + timestamps on every table so a backend can sync rows later
/// (upload where updatedAt > lastSync, deletedAt included). See MVP_PLAN.md.
mixin SyncColumns on Table {
  TextColumn get id => text().clientDefault(_uuid.v4)();
  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProfileRow')
class Profiles extends Table with SyncColumns {
  IntColumn get openingBalance => integer()();
  DateTimeColumn get openingAt => dateTime()();
  IntColumn get payday => integer()(); // 1–28, 0 = last day of month
  IntColumn get monthlyBudget => integer().nullable()(); // null = not set
  BoolColumn get hideAmounts => boolean().withDefault(const Constant(false))();
  DateTimeColumn get onboardedAt => dateTime().nullable()();
}

@DataClassName('CategoryRow')
class Categories extends Table with SyncColumns {
  TextColumn get emoji => text()();
  TextColumn get name => text()();
  TextColumn get kind => textEnum<CategoryKind>()();
  IntColumn get monthlyLimit => integer().nullable()(); // set = kantong
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DataClassName('TransactionRow')
@TableIndex(name: 'transactions_at', columns: {#at})
@TableIndex(name: 'transactions_category', columns: {#categoryId})
class Transactions extends Table with SyncColumns {
  IntColumn get amount => integer()(); // negative = pengeluaran
  TextColumn get categoryId =>
      text().nullable().references(Categories, #id)(); // null = tanpa kategori
  TextColumn get place => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get tags =>
      text().withDefault(const Constant(''))(); // comma-separated, ≤ 3
  DateTimeColumn get at => dateTime()();
}

@DriftDatabase(tables: [Profiles, Categories, Transactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([
    QueryExecutor? executor,
    this._now = DateTime.now,
    this._seed = seedFixture,
    this._reset = false,
  ]) : super(executor ?? driftDatabase(name: 'mibu'));

  final DateTime Function() _now;

  // Sample data, debug only (see MIBU_SEED below); a release build starts
  // empty and goes through 01.4 atur awal.
  final Seed _seed;

  // Debug: wipe every row on open, then seed again (MIBU_RESET below).
  final bool _reset;

  // Pre-release: schema edited in place; wipe app data on dev devices.
  @override
  int get schemaVersion => 1;

  /// Soft-deleted rows older than a day are gone for good (undo is over).
  /// A category stays while any entry still points at it.
  Future<void> purgeDeleted() async {
    final cutoff = _now().subtract(const Duration(days: 1));
    await (delete(
      transactions,
    )..where((t) => t.deletedAt.isSmallerThanValue(cutoff))).go();
    final used = selectOnly(transactions)
      ..addColumns([transactions.categoryId])
      ..where(transactions.categoryId.isNotNull());
    await (delete(categories)..where(
          (c) =>
              c.deletedAt.isSmallerThanValue(cutoff) & c.id.isNotInQuery(used),
        ))
        .go();
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (!details.wasCreated) await purgeDeleted();
      if (!kDebugMode || !(details.wasCreated || _reset)) return;
      if (!details.wasCreated) {
        await transaction(() async {
          await delete(transactions).go(); // FK order: entries first
          await delete(categories).go();
          await delete(profiles).go();
        });
      }
      await _seed(this, _now());
    },
  );
}

/// Debug sample data: `--dart-define=MIBU_SEED=demo|fixture|none`
/// (none = a real first run through 01.1 → 01.4).
/// `--dart-define=MIBU_RESET=true` wipes the data on every launch first, so
/// a dev device behaves like a fresh install (see `make fresh`).
const _seedMode = String.fromEnvironment('MIBU_SEED', defaultValue: 'demo');
const _resetOnOpen = bool.fromEnvironment('MIBU_RESET');

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(null, DateTime.now, switch (_seedMode) {
    'fixture' => seedFixture,
    'none' => (_, _) async {},
    _ => seedDemo,
  }, _resetOnOpen);
  ref.onDispose(db.close);
  return db;
});
