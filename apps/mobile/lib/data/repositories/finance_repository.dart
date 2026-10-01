import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/finance.dart';
import '../database/app_database.dart';

class FinanceRepository {
  FinanceRepository(this._db);

  final AppDatabase _db;

  Stream<List<MonthBalance>> watchMonths() =>
      (_db.select(
        _db.monthBalances,
      )..orderBy([(t) => OrderingTerm.asc(t.month)])).watch().map(
        (rows) => [
          for (final r in rows) MonthBalance(month: r.month, amount: r.amount),
        ],
      );

  Stream<List<Pocket>> watchPockets() =>
      (_db.select(
        _db.pockets,
      )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).watch().map(
        (rows) => [
          for (final r in rows)
            Pocket(
              emoji: r.emoji,
              name: r.name,
              budget: r.budget,
              spent: r.spent,
            ),
        ],
      );

  Stream<List<Transaction>> watchRecent({int limit = 2}) =>
      (_db.select(_db.transactions)
            ..orderBy([(t) => OrderingTerm.desc(t.at)])
            ..limit(limit))
          .watch()
          .map(
            (rows) => [
              for (final r in rows)
                Transaction(
                  emoji: r.emoji,
                  category: r.category,
                  place: r.place,
                  at: r.at,
                  amount: r.amount,
                ),
            ],
          );
}

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => FinanceRepository(ref.watch(appDatabaseProvider)),
);
