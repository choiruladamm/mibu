import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/finance.dart';

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
  AppDatabase([QueryExecutor? executor, this._now = DateTime.now])
    : super(executor ?? driftDatabase(name: 'mibu'));

  final DateTime Function() _now;

  // Pre-release: schema edited in place; wipe app data on dev devices.
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      if (details.wasCreated && kDebugMode) await _seed(_now());
    },
  );

  // ponytail: design sample data (debug only) so screens aren't empty;
  // drop once 01.4 atur awal writes real data. Dates are relative to [now]
  // so nothing lands in the future: 3 past months + this month.
  Future<void> _seed(DateTime now) async {
    DateTime thisMonth(int day, int h, int m) {
      final at = DateTime(now.year, now.month, day.clamp(1, now.day), h, m);
      return at.isAfter(now) ? now : at;
    }

    final cats = <String, String>{}; // name → id
    await batch((b) {
      b.insert(
        profiles,
        ProfilesCompanion.insert(
          openingBalance: 3000000,
          openingAt: DateTime(now.year, now.month - 3),
          payday: 25,
          monthlyBudget: const Value(8000000),
          onboardedAt: Value(now),
        ),
      );
      for (final (i, (emoji, name, kind, limit)) in [
        ('🐶', 'anabul', CategoryKind.expense, 1000000),
        ('☕', 'ngopi', CategoryKind.expense, 300000),
        ('🛵', 'ojol', CategoryKind.expense, 500000),
        ('🍜', 'makan', CategoryKind.expense, 1500000),
        ('🛍️', 'belanja', CategoryKind.expense, null),
        ('💰', 'gajian', CategoryKind.income, null),
      ].indexed) {
        final id = _uuid.v4();
        cats[name] = id;
        b.insert(
          categories,
          CategoriesCompanion.insert(
            id: Value(id),
            emoji: emoji,
            name: name,
            kind: kind,
            monthlyLimit: Value(limit),
            sortOrder: Value(i),
          ),
        );
      }

      TransactionsCompanion tx(
        String cat,
        String place,
        DateTime at,
        int amount, {
        String note = '',
      }) => TransactionsCompanion.insert(
        amount: amount,
        categoryId: Value(cats[cat]),
        place: Value(place),
        note: Value(note),
        at: at,
      );

      b.insertAll(transactions, [
        // Past months: gajian in, belanja out → design's month balances.
        for (final (offset, out) in [
          (-3, 7954000),
          (-2, 9344500),
          (-1, 2612500),
        ]) ...[
          tx(
            'gajian',
            'kantor',
            DateTime(now.year, now.month + offset, 25, 9),
            8500000,
          ),
          tx(
            'belanja',
            'tokopedia',
            DateTime(now.year, now.month + offset, 5, 20),
            -out,
          ),
        ],
        // This month: pockets at 90 / 60 / 38 / 26 %.
        tx(
          'belanja',
          'tokopedia',
          thisMonth(now.day - 3, 20, 0),
          -2399000,
          note: 'titip beliin ibu',
        ),
        tx(
          'makan',
          'warteg',
          thisMonth(now.day - 1, 12, 30),
          -390000,
          note: 'makan siang bareng tim',
        ),
        tx('ojol', 'gojek', thisMonth(now.day - 3, 8, 15), -163000),
        tx('anabul', 'dokter hewan', thisMonth(now.day - 2, 17, 0), -450000),
        tx('ngopi', 'kopi kenangan', thisMonth(now.day - 1, 9, 0), -180000),
        tx('anabul', 'petshop', thisMonth(now.day - 1, 14, 32), -450000),
        tx('ojol', 'gojek', thisMonth(now.day, 11, 5), -27000),
      ]);
    });
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
