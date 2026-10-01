import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/finance.dart';
import '../database/app_database.dart';

/// Balance-related sums; everything derived from `transactions`.
class Totals {
  const Totals({
    required this.balance,
    required this.nets,
    required this.spentToday,
  });

  final int balance;
  final List<int> nets; // net change of months now-3 … now
  final int spentToday; // positive
}

class FinanceRepository {
  FinanceRepository(this._db);

  final AppDatabase _db;

  $TransactionsTable get _tx => _db.transactions;

  Stream<Profile> watchProfile() =>
      (_db.select(_db.profiles)
            ..where((p) => p.deletedAt.isNull())
            ..limit(1))
          .watchSingleOrNull()
          .map(
            (r) => r == null
                ? Profile.empty
                : Profile(
                    openingBalance: r.openingBalance,
                    openingAt: r.openingAt,
                    payday: r.payday,
                    hideAmounts: r.hideAmounts,
                  ),
          );

  /// One query: balance, the 4 monthly nets and today's spending.
  Stream<Totals> watchTotals(Profile profile, DateTime now) {
    DateTime month(int offset) => DateTime(now.year, now.month + offset);
    final today = DateTime(now.year, now.month, now.day);

    Expression<bool> between(DateTime from, DateTime to) =>
        _tx.at.isBiggerOrEqualValue(from) & _tx.at.isSmallerThanValue(to);

    final balance = _tx.amount.sum();
    final nets = [
      for (var i = -3; i <= 0; i++)
        _tx.amount.sum(filter: between(month(i), month(i + 1))),
    ];
    final spentToday = _tx.amount.sum(
      filter:
          _tx.at.isBiggerOrEqualValue(today) & _tx.amount.isSmallerThanValue(0),
    );

    final q = _db.selectOnly(_tx)
      ..addColumns([balance, ...nets, spentToday])
      ..where(
        _tx.deletedAt.isNull() & _tx.at.isBiggerOrEqualValue(profile.openingAt),
      );
    return q.watchSingle().map(
      (r) => Totals(
        balance: profile.openingBalance + (r.read(balance) ?? 0),
        nets: [for (final n in nets) r.read(n) ?? 0],
        spentToday: -(r.read(spentToday) ?? 0),
      ),
    );
  }

  /// Categories with a monthly limit, plus this month's spending.
  Stream<List<Pocket>> watchPockets(DateTime now) {
    final c = _db.categories;
    final spent = _tx.amount.sum();
    final q =
        _db.select(c).join([
            leftOuterJoin(
              _tx,
              _tx.categoryId.equalsExp(c.id) &
                  _tx.deletedAt.isNull() &
                  _tx.amount.isSmallerThanValue(0) &
                  _tx.at.isBiggerOrEqualValue(DateTime(now.year, now.month)) &
                  _tx.at.isSmallerThanValue(DateTime(now.year, now.month + 1)),
            ),
          ])
          ..addColumns([spent])
          ..where(c.deletedAt.isNull() & c.monthlyLimit.isNotNull())
          ..groupBy([c.id])
          ..orderBy([OrderingTerm.asc(c.sortOrder)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          if (r.readTable(c) case final cat)
            Pocket(
              id: cat.id,
              emoji: cat.emoji,
              name: cat.name,
              budget: cat.monthlyLimit!,
              spent: -(r.read(spent) ?? 0),
            ),
      ],
    );
  }

  Stream<List<Transaction>> watchRecent({int limit = 2}) {
    final c = _db.categories;
    final q =
        _db.select(_tx).join([leftOuterJoin(c, c.id.equalsExp(_tx.categoryId))])
          ..where(_tx.deletedAt.isNull())
          ..orderBy([OrderingTerm.desc(_tx.at)])
          ..limit(limit);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          if ((r.readTable(_tx), r.readTableOrNull(c)) case (
            final t,
            final cat,
          ))
            Transaction(
              id: t.id,
              emoji: cat?.emoji ?? '🧾',
              category: cat?.name,
              place: t.place,
              at: t.at,
              amount: t.amount,
            ),
      ],
    );
  }
}

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => FinanceRepository(ref.watch(appDatabaseProvider)),
);
