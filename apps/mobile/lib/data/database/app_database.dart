import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/finance.dart';
import '../../domain/period.dart';
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
  IntColumn get payday =>
      integer()(); // 1–31, 31 = akhir; past month end = last day
  BoolColumn get hideAmounts => boolean().withDefault(const Constant(false))();
  DateTimeColumn get onboardedAt => dateTime().nullable()();
  TextColumn get recentSearches =>
      text().withDefault(const Constant(''))(); // newline-separated, ≤ 5
  // 02.2l kenalan kantong: shown until "oke".
  BoolColumn get pocketsIntroSeen =>
      boolean().withDefault(const Constant(false))();
}

@DataClassName('CategoryRow')
class Categories extends Table with SyncColumns {
  TextColumn get emoji => text()();
  TextColumn get name => text()();
  TextColumn get kind => textEnum<CategoryKind>()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  // Salary income: will start payday cycles and auto-detect (fase 1+).
  BoolColumn get isPayday => boolean().withDefault(const Constant(false))();
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

/// Budget bulanan per period (00.16). The one in force for a period is the
/// row with the latest [periodStart] ≤ the period's start, so a period
/// without its own row keeps the last one; old rows are never touched.
/// [amount] null = hapus budget from that period on.
@DataClassName('BudgetRow')
class Budgets extends Table with SyncColumns {
  DateTimeColumn get periodStart => dateTime()(); // date-only
  DateTimeColumn get periodEnd => dateTime()(); // exclusive
  IntColumn get amount => integer().nullable()();
}

/// A category's monthly limit per period, same lookup as [Budgets]. A
/// category with a limit in force = kantong; [amount] null = copot limit.
@DataClassName('LimitRow')
@TableIndex(name: 'limits_category', columns: {#categoryId})
class Limits extends Table with SyncColumns {
  TextColumn get categoryId => text().references(Categories, #id)();
  DateTimeColumn get periodStart => dateTime()();
  DateTimeColumn get periodEnd => dateTime()();
  IntColumn get amount => integer().nullable()();
}

/// Budget period settings, append-only: a change is a new row from the end
/// of the running period, so past periods keep their rules. Empty = calendar
/// months (v1). See [SegmentedResolver].
@DataClassName('PeriodRuleRow')
class PeriodRules extends Table with SyncColumns {
  DateTimeColumn get effectiveFrom => dateTime()(); // date-only
  TextColumn get mode => textEnum<PeriodMode>()();
  IntColumn get paydayDay => integer()(); // as Profiles.payday
  TextColumn get shift =>
      textEnum<PaydayShift>().withDefault(Constant(PaydayShift.none.name))();
}

@DriftDatabase(
  tables: [Profiles, Categories, Transactions, PeriodRules, Budgets, Limits],
)
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
    final gone = selectOnly(categories)
      ..addColumns([categories.id])
      ..where(
        categories.deletedAt.isSmallerThanValue(cutoff) &
            categories.id.isNotInQuery(used),
      );
    await (delete(limits)..where((l) => l.categoryId.isInQuery(gone))).go();
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
          await delete(limits).go();
          await delete(categories).go();
          await delete(budgets).go();
          await delete(profiles).go();
          await delete(periodRules).go();
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
