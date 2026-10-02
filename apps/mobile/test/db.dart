import 'package:drift/drift.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/repositories/finance_repository.dart';
import 'package:mibu/domain/period.dart';

/// The pinned clock most tests use (seedFixture lines up with it).
final fixtureNow = DateTime(2026, 10, 14, 14, 50);

/// Calendar budget period of [d] (v1).
Period cal(DateTime d) => const CalendarMonthResolver().periodOf(d);

// Futures, not watch().first: drift stream queries need timers that never
// fire inside testWidgets' fake clock. The lookup mirrors the repository's
// (latest periodStart ≤ the period's), checking it from the outside.

/// The limit in force for [name] in [now]'s period (null = none).
Future<int?> limitOf(AppDatabase db, String name, [DateTime? now]) async {
  final c = await (db.select(
    db.categories,
  )..where((r) => r.name.equals(name))).getSingle();
  final p = cal(now ?? fixtureNow);
  final row =
      await (db.select(db.limits)
            ..where(
              (r) =>
                  r.deletedAt.isNull() &
                  r.categoryId.equals(c.id) &
                  r.periodStart.isSmallerOrEqualValue(p.start),
            )
            ..orderBy([
              (r) => OrderingTerm.desc(r.periodStart),
              (r) => OrderingTerm.desc(r.updatedAt),
            ])
            ..limit(1))
          .getSingleOrNull();
  return row?.amount;
}

/// Sets [name]'s limit from [now]'s period on, like 02.2 / 03.5 do.
Future<void> setLimitOf(
  AppDatabase db,
  String name,
  int? limit, [
  DateTime? now,
]) async {
  final c = await (db.select(
    db.categories,
  )..where((r) => r.name.equals(name))).getSingle();
  await FinanceRepository(db).setLimit(c.id, limit, cal(now ?? fixtureNow));
}

/// The budget in force for [now]'s period.
Future<int?> budgetOf(AppDatabase db, [DateTime? now]) async {
  final p = cal(now ?? fixtureNow);
  final row =
      await (db.select(db.budgets)
            ..where(
              (r) =>
                  r.deletedAt.isNull() &
                  r.periodStart.isSmallerOrEqualValue(p.start),
            )
            ..orderBy([
              (r) => OrderingTerm.desc(r.periodStart),
              (r) => OrderingTerm.desc(r.updatedAt),
            ])
            ..limit(1))
          .getSingleOrNull();
  return row?.amount;
}

Future<void> setBudgetOf(AppDatabase db, int? budget, [DateTime? now]) =>
    FinanceRepository(db).setMonthlyBudget(budget, cal(now ?? fixtureNow));
