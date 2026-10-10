import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';

/// v1 = the baseline that shipped (tag release-baseline): the schema exactly
/// as created on the phone. Never edit it; add v2, v3 … next to it when a
/// table changes (copy the previous list, apply the change).
const v1 = [
  '''CREATE TABLE "budgets" ("id" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "period_start" INTEGER NOT NULL, "period_end" INTEGER NOT NULL, "amount" INTEGER NULL, PRIMARY KEY ("id"))''',
  '''CREATE TABLE "categories" ("id" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "emoji" TEXT NOT NULL, "name" TEXT NOT NULL, "kind" TEXT NOT NULL, "sort_order" INTEGER NOT NULL DEFAULT 0, "is_payday" INTEGER NOT NULL DEFAULT 0 CHECK ("is_payday" IN (0, 1)), PRIMARY KEY ("id"))''',
  '''CREATE TABLE "limits" ("id" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "category_id" TEXT NOT NULL REFERENCES categories (id), "period_start" INTEGER NOT NULL, "period_end" INTEGER NOT NULL, "amount" INTEGER NULL, PRIMARY KEY ("id"))''',
  '''CREATE TABLE "period_rules" ("id" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "effective_from" INTEGER NOT NULL, "mode" TEXT NOT NULL, "payday_day" INTEGER NOT NULL, "shift" TEXT NOT NULL DEFAULT 'none', PRIMARY KEY ("id"))''',
  '''CREATE TABLE "profiles" ("id" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "payday" INTEGER NOT NULL, "hide_amounts" INTEGER NOT NULL DEFAULT 0, "onboarded_at" INTEGER NULL, "recent_searches" TEXT NOT NULL DEFAULT '', "pockets_intro_seen" INTEGER NOT NULL DEFAULT 0 CHECK ("pockets_intro_seen" IN (0, 1)), PRIMARY KEY ("id"))''',
  '''CREATE TABLE "transactions" ("id" TEXT NOT NULL, "created_at" INTEGER NOT NULL, "updated_at" INTEGER NOT NULL, "deleted_at" INTEGER NULL, "amount" INTEGER NOT NULL, "category_id" TEXT NULL REFERENCES categories (id), "place" TEXT NOT NULL DEFAULT '', "note" TEXT NOT NULL DEFAULT '', "tags" TEXT NOT NULL DEFAULT '', "at" INTEGER NOT NULL, PRIMARY KEY ("id"))''',
  'CREATE INDEX limits_category ON limits (category_id)',
  'CREATE INDEX transactions_at ON transactions (at)',
  'CREATE INDEX transactions_category ON transactions (category_id)',
];

AppDatabase _open([void Function(dynamic raw)? setup]) => AppDatabase(
  DatabaseConnection(
    NativeDatabase.memory(setup: setup),
    closeStreamsSynchronously: true,
  ),
  DateTime.now,
  (_, _) async {},
);

/// Columns of every table + index columns, to compare a migrated database
/// with a fresh one.
Future<Map<String, List<String>>> _shape(AppDatabase db) async {
  final shape = <String, List<String>>{};
  final entities = await db
      .customSelect(
        "SELECT type, name FROM sqlite_master WHERE name NOT LIKE 'sqlite_%' "
        'ORDER BY name',
      )
      .get();
  for (final e in entities) {
    final name = e.read<String>('name');
    shape[name] = e.read<String>('type') == 'table'
        ? [
            for (final c
                in await db.customSelect('PRAGMA table_info("$name")').get())
              [
                c.read<String>('name'),
                c.read<String>('type'),
                c.read<int>('notnull'),
                c.read<String?>('dflt_value'),
                c.read<int>('pk'),
              ].join(' '),
          ]
        : [
            for (final c
                in await db.customSelect('PRAGMA index_info("$name")').get())
              c.read<String>('name'),
          ];
  }
  for (final cols in shape.values) {
    cols.sort(); // ALTER appends columns; order does not matter to Drift
  }
  return shape;
}

/// An old database holding one category and one entry.
AppDatabase _old(List<String> schema, int version) => _open((raw) {
  for (final sql in schema) {
    raw.execute(sql);
  }
  raw.execute(
    "INSERT INTO categories (id, created_at, updated_at, emoji, name, kind) "
    "VALUES ('c1', 1790000000, 1790000000, 'x', 'makan', 'expense')",
  );
  raw.execute(
    "INSERT INTO transactions (id, created_at, updated_at, amount, "
    "category_id, at) VALUES ('t1', 1790000000, 1790000000, -25000, 'c1', "
    '1790000000)',
  );
  raw.execute('PRAGMA user_version = $version');
});

void main() {
  // Add (2, v2) … here with every schema bump.
  for (final (version, schema) in [(1, v1)]) {
    test(
      'v$version → now: same schema as a fresh install, data kept',
      () async {
        final migrated = _old(schema, version);
        final fresh = _open();
        addTearDown(migrated.close);
        addTearDown(fresh.close);

        final tx = await migrated.select(migrated.transactions).getSingle();
        expect(tx.amount, -25000);
        expect(tx.categoryId, 'c1');
        expect(
          await migrated.select(migrated.categories).getSingle(),
          isNotNull,
        );
        expect(await _shape(migrated), await _shape(fresh));
      },
    );
  }
}
