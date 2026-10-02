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
                    monthlyBudget: r.monthlyBudget,
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

  static Category _category(CategoryRow r) => Category(
    id: r.id,
    emoji: r.emoji,
    name: r.name,
    kind: r.kind,
    monthlyLimit: r.monthlyLimit,
  );

  Stream<List<Category>> watchCategories() =>
      (_db.select(_db.categories)
            ..where((c) => c.deletedAt.isNull())
            ..orderBy([(c) => OrderingTerm.asc(c.sortOrder)]))
          .watch()
          .map((rows) => rows.map(_category).toList());

  /// Latest distinct category + place combos ("terakhir" in 03.2).
  Stream<List<RecentPick>> watchRecentPicks({int limit = 6}) {
    final c = _db.categories;
    final last = _tx.at.max();
    final q =
        _db.select(_tx).join([innerJoin(c, c.id.equalsExp(_tx.categoryId))])
          ..addColumns([last])
          ..where(
            _tx.deletedAt.isNull() &
                c.deletedAt.isNull() &
                _tx.place.equals('').not(),
          )
          ..groupBy([_tx.categoryId, _tx.place])
          ..orderBy([OrderingTerm.desc(last)])
          ..limit(limit);
    return q.watch().map(
      (rows) => [
        for (final r in rows)
          RecentPick(
            category: _category(r.readTable(c)),
            place: r.readTable(_tx).place,
          ),
      ],
    );
  }

  /// Latest distinct notes ("pernah kamu tulis" in 00.13).
  Stream<List<({String text, DateTime at})>> watchRecentNotes({int limit = 2}) {
    final last = _tx.at.max();
    final q = _db.selectOnly(_tx)
      ..addColumns([_tx.note, last])
      ..where(_tx.deletedAt.isNull() & _tx.note.equals('').not())
      ..groupBy([_tx.note])
      ..orderBy([OrderingTerm.desc(last)])
      ..limit(limit);
    return q.watch().map(
      (rows) => [
        for (final r in rows) (text: r.read(_tx.note)!, at: r.read(last)!),
      ],
    );
  }

  /// Entries per local day in [from, to) — DateSheet dots + "jangan dobel".
  Stream<Map<DateTime, ({int count, int net})>> watchDays(
    DateTime from,
    DateTime to,
  ) {
    final q = _db.selectOnly(_tx)
      ..addColumns([_tx.at, _tx.amount])
      ..where(
        _tx.deletedAt.isNull() &
            _tx.at.isBiggerOrEqualValue(from) &
            _tx.at.isSmallerThanValue(to),
      );
    return q.watch().map((rows) {
      final days = <DateTime, ({int count, int net})>{};
      for (final r in rows) {
        final at = r.read(_tx.at)!;
        final day = DateTime(at.year, at.month, at.day);
        final d = days[day] ?? (count: 0, net: 0);
        days[day] = (count: d.count + 1, net: d.net + r.read(_tx.amount)!);
      }
      return days;
    });
  }

  Future<void> addTransaction({
    required int amount,
    required String? categoryId,
    required String place,
    required String note,
    required List<String> tags,
    required DateTime at,
  }) => _db
      .into(_tx)
      .insert(
        TransactionsCompanion.insert(
          amount: amount,
          categoryId: Value(categoryId),
          place: Value(place.trim()),
          note: Value(note.trim()),
          tags: Value(tags.join(',')),
          at: at,
        ),
      );

  /// Budget bulanan (00.16); null = hapus budget.
  // ponytail: no-op before 01.4 atur awal creates the profile row (M5).
  Future<void> setMonthlyBudget(int? budget) =>
      (_db.update(_db.profiles)..where((p) => p.deletedAt.isNull())).write(
        ProfilesCompanion(
          monthlyBudget: Value(budget),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Per category: entries (all time) and expense this year, positive.
  /// "12 catatan · Rp840K tahun ini" in 03.3 / 03.5 / 03.6.
  Stream<Map<String, ({int count, int spentThisYear})>> watchCategoryUsage(
    DateTime now,
  ) {
    final count = _tx.id.count();
    final spent = _tx.amount.sum(
      filter:
          _tx.amount.isSmallerThanValue(0) &
          _tx.at.isBiggerOrEqualValue(DateTime(now.year)) &
          _tx.at.isSmallerThanValue(DateTime(now.year + 1)),
    );
    final q = _db.selectOnly(_tx)
      ..addColumns([_tx.categoryId, count, spent])
      ..where(_tx.deletedAt.isNull() & _tx.categoryId.isNotNull())
      ..groupBy([_tx.categoryId]);
    return q.watch().map(
      (rows) => {
        for (final r in rows)
          r.read(_tx.categoryId)!: (
            count: r.read(count)!,
            spentThisYear: -(r.read(spent) ?? 0),
          ),
      },
    );
  }

  /// New category at the end of the list; returns its id.
  Future<String> addCategory({
    required String emoji,
    required String name,
    required CategoryKind kind,
    required int? monthlyLimit,
  }) async {
    final c = _db.categories;
    final last = c.sortOrder.max();
    final row = await (_db.selectOnly(c)..addColumns([last])).getSingle();
    final inserted = await _db
        .into(c)
        .insertReturning(
          CategoriesCompanion.insert(
            emoji: emoji,
            name: name.trim().toLowerCase(),
            kind: kind,
            monthlyLimit: Value(_limitFor(kind, monthlyLimit)),
            sortOrder: Value((row.read(last) ?? -1) + 1),
          ),
        );
    return inserted.id;
  }

  Future<void> updateCategory(
    String id, {
    required String emoji,
    required String name,
    required CategoryKind kind,
    required int? monthlyLimit,
  }) => (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
    CategoriesCompanion(
      emoji: Value(emoji),
      name: Value(name.trim().toLowerCase()),
      kind: Value(kind),
      monthlyLimit: Value(_limitFor(kind, monthlyLimit)),
      updatedAt: Value(DateTime.now()),
    ),
  );

  /// Pockets track spending only, so income categories never keep a limit.
  static int? _limitFor(CategoryKind kind, int? limit) =>
      kind == CategoryKind.income ? null : limit;

  /// 03.3 "tahan & geser": [ids] in their new order.
  Future<void> reorderCategories(List<String> ids) => _db.batch((b) {
    final now = DateTime.now();
    for (final (i, id) in ids.indexed) {
      b.update(
        _db.categories,
        CategoriesCompanion(sortOrder: Value(i), updatedAt: Value(now)),
        where: (c) => c.id.equals(id),
      );
    }
  });

  /// 03.6: moves the category's entries to [moveTo] (null = tanpa kategori),
  /// then soft-deletes it. Returns the moved entry ids for [undoDeleteCategory].
  Future<List<String>> deleteCategory(String id, {required String? moveTo}) =>
      _db.transaction(() async {
        final now = DateTime.now();
        final moved =
            await (_db.update(
              _tx,
            )..where((t) => t.categoryId.equals(id))).writeReturning(
              TransactionsCompanion(
                categoryId: Value(moveTo),
                updatedAt: Value(now),
              ),
            );
        await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
          CategoriesCompanion(deletedAt: Value(now), updatedAt: Value(now)),
        );
        return [for (final t in moved) t.id];
      });

  /// "batalin" on 03.6: restores the category and moves [txIds] back.
  Future<void> undoDeleteCategory(String id, List<String> txIds) =>
      _db.transaction(() async {
        final now = DateTime.now();
        await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
          CategoriesCompanion(
            deletedAt: const Value(null),
            updatedAt: Value(now),
          ),
        );
        await (_db.update(_tx)..where((t) => t.id.isIn(txIds))).write(
          TransactionsCompanion(categoryId: Value(id), updatedAt: Value(now)),
        );
      });
}

final financeRepositoryProvider = Provider<FinanceRepository>(
  (ref) => FinanceRepository(ref.watch(appDatabaseProvider)),
);

final categoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref.watch(financeRepositoryProvider).watchCategories(),
);
final recentPicksProvider = StreamProvider<List<RecentPick>>(
  (ref) => ref.watch(financeRepositoryProvider).watchRecentPicks(),
);
final recentNotesProvider = StreamProvider<List<({String text, DateTime at})>>(
  (ref) => ref.watch(financeRepositoryProvider).watchRecentNotes(),
);

/// Per-day counts for the month starting at [month].
final daysProvider =
    StreamProvider.family<Map<DateTime, ({int count, int net})>, DateTime>(
      (ref, month) => ref
          .watch(financeRepositoryProvider)
          .watchDays(month, DateTime(month.year, month.month + 1)),
    );

/// Pockets with spending in the month containing [month].
final pocketsInMonthProvider = StreamProvider.family<List<Pocket>, DateTime>(
  (ref, month) => ref.watch(financeRepositoryProvider).watchPockets(month),
);
