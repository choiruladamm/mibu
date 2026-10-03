import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/finance.dart';
import '../../domain/period.dart';
import '../database/app_database.dart';

/// Balance-related sums; everything derived from `transactions`.
/// Per budget period, keyed by its month label. No saldo: nothing carries
/// over between periods (docs/PERIOD_LEDGER_PLAN.md).
class Totals {
  const Totals({
    required this.income,
    required this.spent,
    required this.spentToday,
  });

  final Map<DateTime, int> income; // month label → income
  final Map<DateTime, int> spent; // month label → expenses, positive
  final int spentToday; // positive

  /// Sisa pemasukan per period: income − spending.
  Map<DateTime, int> get nets => {
    for (final m in {...income.keys, ...spent.keys})
      m: (income[m] ?? 0) - (spent[m] ?? 0),
  };
}

/// An expense category without a limit, with this month's spending and
/// entry count ("belum ada limit" + "pasang limit ke…" in 02.2).
typedef FreeCategory = ({Category category, int spent, int count});

const _uuid = Uuid();

class FinanceRepository {
  FinanceRepository(this._db);

  final AppDatabase _db;

  $TransactionsTable get _tx => _db.transactions;

  /// The profile, with the budget in force for [period].
  Stream<Profile> watchProfile(Period period) {
    final budget = _budgetIn(period);
    final q = _db.select(_db.profiles).join([])
      ..addColumns([budget])
      ..where(_db.profiles.deletedAt.isNull())
      ..limit(1);
    return q.watchSingleOrNull().map((row) {
      final r = row?.readTable(_db.profiles);
      return r == null
          ? Profile.empty
          : Profile(
              payday: r.payday,
              monthlyBudget: row!.read(budget),
              hideAmounts: r.hideAmounts,
              onboarded: r.onboardedAt != null,
              onboardedAt: r.onboardedAt,
              recentSearches: r.recentSearches.isEmpty
                  ? const []
                  : r.recentSearches.split('\n'),
              pocketsIntroSeen: r.pocketsIntroSeen,
            );
    });
  }

  /// The row in force for [p]: latest start ≤ the period's (its own row, or
  /// the last one before it). Reads never write a row.
  Expression<int> _budgetIn(Period p) {
    final b = _db.budgets;
    return subqueryExpression<int>(
      _db.selectOnly(b)
        ..addColumns([b.amount])
        ..where(
          b.deletedAt.isNull() & b.periodStart.isSmallerOrEqualValue(p.start),
        )
        ..orderBy([
          OrderingTerm.desc(b.periodStart),
          OrderingTerm.desc(b.updatedAt),
        ])
        ..limit(1),
    );
  }

  /// A category's limit in force for [p], same lookup as [_budgetIn].
  Expression<int> _limitIn(Expression<String> categoryId, Period p) {
    final l = _db.limits;
    return subqueryExpression<int>(
      _db.selectOnly(l)
        ..addColumns([l.amount])
        ..where(
          l.deletedAt.isNull() &
              l.categoryId.equalsExp(categoryId) &
              l.periodStart.isSmallerOrEqualValue(p.start),
        )
        ..orderBy([
          OrderingTerm.desc(l.periodStart),
          OrderingTerm.desc(l.updatedAt),
        ])
        ..limit(1),
    );
  }

  /// Writes [period]'s own row: updates it, or adds it the first time.
  Future<void> _setBudgetRow(Period period, int? amount) async {
    final b = _db.budgets;
    final n =
        await (_db.update(b)..where(
              (r) =>
                  r.deletedAt.isNull() &
                  r.periodStart.equals(period.start) &
                  r.periodEnd.equals(period.end),
            ))
            .write(
              BudgetsCompanion(
                amount: Value(amount),
                updatedAt: Value(DateTime.now()),
              ),
            );
    if (n == 0) {
      await _db
          .into(b)
          .insert(
            BudgetsCompanion.insert(
              periodStart: period.start,
              periodEnd: period.end,
              amount: Value(amount),
            ),
          );
    }
  }

  Future<void> _setLimitRow(
    String categoryId,
    Period period,
    int? amount,
  ) async {
    final l = _db.limits;
    final n =
        await (_db.update(l)..where(
              (r) =>
                  r.deletedAt.isNull() &
                  r.categoryId.equals(categoryId) &
                  r.periodStart.equals(period.start) &
                  r.periodEnd.equals(period.end),
            ))
            .write(
              LimitsCompanion(
                amount: Value(amount),
                updatedAt: Value(DateTime.now()),
              ),
            );
    if (n == 0) {
      await _db
          .into(l)
          .insert(
            LimitsCompanion.insert(
              categoryId: categoryId,
              periodStart: period.start,
              periodEnd: period.end,
              amount: Value(amount),
            ),
          );
    }
  }

  /// The limit in force for [period] (null = none).
  Future<int?> _limitNow(String categoryId, Period period) async {
    final row =
        await (_db.select(_db.limits)
              ..where(
                (r) =>
                    r.deletedAt.isNull() &
                    r.categoryId.equals(categoryId) &
                    r.periodStart.isSmallerOrEqualValue(period.start),
              )
              ..orderBy([
                (r) => OrderingTerm.desc(r.periodStart),
                (r) => OrderingTerm.desc(r.updatedAt),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.amount;
  }

  /// The saved period rules (01.4 writes the first; a payday change adds
  /// one). The calendar base before them is [periodRulesWithBase]'s job.
  Stream<List<PeriodRule>> watchPeriodRules() =>
      (_db.select(
        _db.periodRules,
      )..where((r) => r.deletedAt.isNull())).watch().map(
        (rows) => [
          for (final r in rows)
            (
              effectiveFrom: r.effectiveFrom,
              mode: r.mode,
              paydayDay: r.paydayDay,
              shift: r.shift,
            ),
        ],
      );

  /// Budget periods in force: calendar months until the first rule, then
  /// each saved rule from its date on. [salaries] = logged gajian, which
  /// pull a payday period's start forward when it came in early.
  Stream<PeriodResolver> watchPeriods({List<DateTime> salaries = const []}) =>
      watchPeriodRules().map(
        (rules) =>
            SegmentedResolver([calendarBase, ...rules], salaries: salaries),
      );

  /// 01.4 / 01.4b: writes the profile, the [budget] if one was typed (none
  /// is required) and the starter categories — every preset (picked ones
  /// become kantong with their limit) plus 💰 gajian. Categories are only
  /// added to an empty table.
  Future<void> completeSetup({
    int? budget,
    required int payday,
    required Set<String> pockets,
    required DateTime now,
  }) => _db.transaction(() async {
    final p = _db.profiles;
    // The period gajian puts [now] in: where the starter limits are stamped,
    // so they're in force right away (not under a calendar month).
    final period = PaydayCycleResolver(
      payday,
      shift: PaydayShift.previousWorkday,
    ).periodOf(now);
    final row = ProfilesCompanion(
      payday: Value(payday),
      onboardedAt: Value(now),
      updatedAt: Value(now),
    );
    final updated = await (_db.update(
      p,
    )..where((r) => r.deletedAt.isNull())).write(row);
    if (updated == 0) await _db.into(p).insert(row);
    if (budget != null && budget > 0) {
      await _db
          .into(_db.budgets)
          .insert(
            BudgetsCompanion.insert(
              periodStart: period.start,
              periodEnd: period.end,
              amount: Value(budget),
            ),
          );
    }

    // Periods follow gajian from the start of time, so a back-filled entry
    // lands in the right period. Re-running setup keeps the rule it has.
    final rules = _db.periodRules;
    if (await (_db.selectOnly(rules)..addColumns([rules.id.count()]))
            .map((r) => r.read(rules.id.count()))
            .getSingle() ==
        0) {
      await _db
          .into(rules)
          .insert(
            PeriodRulesCompanion.insert(
              effectiveFrom: periodsFromStart,
              mode: PeriodMode.payday,
              paydayDay: payday,
              shift: const Value(PaydayShift.previousWorkday),
            ),
          );
    }

    final c = _db.categories;
    if (await (_db.selectOnly(c)..addColumns([c.id.count()]))
            .map((r) => r.read(c.id.count()))
            .getSingle() !=
        0) {
      return;
    }
    await _db.batch((b) {
      for (final (i, (emoji, name, limit)) in setupPockets.indexed) {
        final id = _uuid.v4();
        b.insert(
          c,
          CategoriesCompanion.insert(
            id: Value(id),
            emoji: emoji,
            name: name,
            kind: CategoryKind.expense,
            sortOrder: Value(i),
          ),
        );
        if (pockets.contains(name)) {
          b.insert(
            _db.limits,
            LimitsCompanion.insert(
              categoryId: id,
              periodStart: period.start,
              periodEnd: period.end,
              amount: Value(limit),
            ),
          );
        }
      }
      b.insert(
        c,
        CategoriesCompanion.insert(
          emoji: '💰',
          name: 'gajian',
          kind: CategoryKind.income,
          sortOrder: Value(setupPockets.length),
          isPayday: const Value(true),
        ),
      );
    });
  });

  /// Income and spending per period, plus today's spending. Every live
  /// entry counts in the period its date falls in, whenever it was logged
  /// (a gajian back-filled to 25 sep is still that period's income).
  // ponytail: reads every entry and sums in Dart (local-time periods; SQL
  // strftime is UTC). Fine for years of daily use; move to a cached
  // per-period table if it ever shows.
  Stream<Totals> watchTotals(
    DateTime now, {
    PeriodResolver periods = const CalendarMonthResolver(),
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final q = _db.selectOnly(_tx)
      ..addColumns([_tx.at, _tx.amount])
      ..where(_tx.deletedAt.isNull());
    return q.watch().map((rows) {
      var spentToday = 0;
      final income = <DateTime, int>{}, spent = <DateTime, int>{};
      for (final r in rows) {
        final at = r.read(_tx.at)!, v = r.read(_tx.amount)!;
        // Keyed by the period's month label ("oktober" = 25 sep – 24 okt).
        final month = periods.periodOf(at).key;
        if (v < 0) {
          spent[month] = (spent[month] ?? 0) - v;
          if (!at.isBefore(today)) spentToday -= v;
        } else {
          income[month] = (income[month] ?? 0) + v;
        }
      }
      return Totals(income: income, spent: spent, spentToday: spentToday);
    });
  }

  /// Entries dated inside [p] (local dates, [start, end)).
  Expression<bool> _inPeriod(Period p) =>
      _tx.at.isBiggerOrEqualValue(p.start) & _tx.at.isSmallerThanValue(p.end);

  /// Categories with a limit, plus what's spent in [period].
  Stream<List<Pocket>> watchPockets(Period period) {
    final c = _db.categories;
    final spent = _tx.amount.sum();
    final limit = _limitIn(c.id, period);
    final q =
        _db.select(c).join([
            leftOuterJoin(
              _tx,
              _tx.categoryId.equalsExp(c.id) &
                  _tx.deletedAt.isNull() &
                  _tx.amount.isSmallerThanValue(0) &
                  _inPeriod(period),
            ),
          ])
          ..addColumns([spent, limit])
          ..where(c.deletedAt.isNull() & limit.isNotNull())
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
              budget: prorate(r.read(limit)!, period),
              limit: r.read(limit)!,
              spent: -(r.read(spent) ?? 0),
            ),
      ],
    );
  }

  /// "belum ada limit" (02.2): expense categories without a limit plus their
  /// spending and entry count in [period], most spent (then most used)
  /// first. Income never shows up here.
  Stream<List<FreeCategory>> watchFreeCategories(Period period) {
    final c = _db.categories;
    final limit = _limitIn(c.id, period);
    final spent = _tx.amount.sum();
    final count = _tx.id.count();
    final q =
        _db.select(c).join([
            leftOuterJoin(
              _tx,
              _tx.categoryId.equalsExp(c.id) &
                  _tx.deletedAt.isNull() &
                  _tx.amount.isSmallerThanValue(0) &
                  _inPeriod(period),
            ),
          ])
          ..addColumns([spent, count])
          ..where(
            c.deletedAt.isNull() &
                limit.isNull() &
                c.kind.equalsValue(CategoryKind.expense),
          )
          ..groupBy([c.id])
          ..orderBy([OrderingTerm.asc(c.sortOrder)]);
    return q.watch().map(
      (rows) =>
          [
            for (final r in rows)
              (
                category: _category(r.readTable(c), null),
                spent: -(r.read(spent) ?? 0),
                count: r.read(count) ?? 0,
              ),
          ]..sort(
            (a, b) => b.spent != a.spent
                ? b.spent.compareTo(a.spent)
                : b.count.compareTo(a.count),
          ), // stable: ties keep order
    );
  }

  /// Entries joined with their category, newest first.
  JoinedSelectStatement<HasResultSet, dynamic> _joined(Expression<bool> where) {
    final c = _db.categories;
    return _db.select(_tx).join([
        leftOuterJoin(c, c.id.equalsExp(_tx.categoryId)),
      ])
      ..where(where)
      ..orderBy([OrderingTerm.desc(_tx.at)]);
  }

  Transaction _transaction(TypedResult r) {
    final t = r.readTable(_tx);
    final cat = r.readTableOrNull(_db.categories);
    return Transaction(
      id: t.id,
      emoji: cat?.emoji ?? '🧾',
      category: cat?.name,
      categoryId: t.categoryId,
      place: t.place,
      note: t.note,
      tags: t.tags.isEmpty ? const [] : t.tags.split(','),
      at: t.at,
      amount: t.amount,
      deleted: t.deletedAt != null,
    );
  }

  Stream<List<Transaction>> watchRecent({int limit = 2}) => (_joined(
    _tx.deletedAt.isNull(),
  )..limit(limit)).watch().map((rows) => rows.map(_transaction).toList());

  /// 04.1 / 04.2: every entry in [period].
  Stream<List<Transaction>> watchPeriod(Period period) =>
      _joined(_tx.deletedAt.isNull() & _inPeriod(period))
          .watch()
          .map((rows) => rows.map(_transaction).toList());

  /// 04.2 cari di semua bulan: every live entry, newest first.
  Stream<List<Transaction>> watchAll() =>
      _joined(_tx.deletedAt.isNull())
          .watch()
          .map((rows) => rows.map(_transaction).toList());

  /// Ekspor CSV: every live entry, newest first.
  Future<List<Transaction>> allTransactions() async =>
      (await _joined(_tx.deletedAt.isNull()).get()).map(_transaction).toList();

  /// 04.3: one entry, soft-deleted included (stamped "dihapus" + batalin).
  Stream<Transaction?> watchTransaction(String id) =>
      _joined(_tx.id.equals(id))
          .watchSingleOrNull()
          .map((r) => r == null ? null : _transaction(r));

  /// First month with an entry (04.1 carousel start); null = none yet.
  Stream<DateTime?> watchFirstMonth({
    PeriodResolver periods = const CalendarMonthResolver(),
  }) {
    final first = _tx.at.min();
    final q = _db.selectOnly(_tx)
      ..addColumns([first])
      ..where(_tx.deletedAt.isNull());
    return q.watchSingle().map(
      (r) => switch (r.read(first)) {
        final at? => periods.periodOf(at).key,
        null => null,
      },
    );
  }

  static Category _category(CategoryRow r, int? limit) => Category(
    id: r.id,
    emoji: r.emoji,
    name: r.name,
    kind: r.kind,
    monthlyLimit: limit,
    isPayday: r.isPayday,
  );

  /// Categories, each with its limit in force for [period].
  Stream<List<Category>> watchCategories(Period period) {
    final c = _db.categories;
    final limit = _limitIn(c.id, period);
    final q = _db.select(c).join([])
      ..addColumns([limit])
      ..where(c.deletedAt.isNull())
      ..orderBy([OrderingTerm.asc(c.sortOrder)]);
    return q.watch().map(
      (rows) => [
        for (final r in rows) _category(r.readTable(c), r.read(limit)),
      ],
    );
  }

  /// Amount of the newest live gajian income (null = never logged), the
  /// starting suggestion when logging the next one.
  Future<int?> lastSalary() async {
    final c = _db.categories;
    final row =
        await (_db.select(_tx).join([
                innerJoin(c, c.id.equalsExp(_tx.categoryId)),
              ])
              ..where(
                _tx.deletedAt.isNull() &
                    _tx.amount.isBiggerThanValue(0) &
                    c.isPayday.equals(true),
              )
              ..orderBy([OrderingTerm.desc(_tx.at)])
              ..limit(1))
            .getSingleOrNull();
    return row?.readTable(_tx).amount;
  }

  /// Dates of live gajian income (payday categories), newest first.
  Stream<List<DateTime>> watchSalaryDates() {
    final c = _db.categories;
    final q =
        _db.selectOnly(_tx).join([innerJoin(c, c.id.equalsExp(_tx.categoryId))])
          ..addColumns([_tx.at])
          ..where(
            _tx.deletedAt.isNull() &
                _tx.amount.isBiggerThanValue(0) &
                c.isPayday.equals(true),
          )
          ..orderBy([OrderingTerm.desc(_tx.at)]);
    return q.watch().map((rows) => [for (final r in rows) r.read(_tx.at)!]);
  }

  /// Latest distinct category + place combos ("terakhir" in 03.2).
  Stream<List<RecentPick>> watchRecentPicks(Period period, {int limit = 6}) {
    final c = _db.categories;
    final last = _tx.at.max();
    final cap = _limitIn(c.id, period);
    final q =
        _db.select(_tx).join([innerJoin(c, c.id.equalsExp(_tx.categoryId))])
          ..addColumns([last, cap])
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
            category: _category(r.readTable(c), r.read(cap)),
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

  /// 04.4: kind stays; [amount] is signed. [tags] null = keep.
  Future<void> updateTransaction(
    String id, {
    required int amount,
    required String? categoryId,
    required String place,
    required String note,
    required DateTime at,
    List<String>? tags,
  }) => (_db.update(_tx)..where((t) => t.id.equals(id))).write(
    TransactionsCompanion(
      amount: Value(amount),
      categoryId: Value(categoryId),
      place: Value(place.trim()),
      note: Value(note.trim()),
      tags: tags == null ? const Value.absent() : Value(tags.join(',')),
      at: Value(at),
      updatedAt: Value(DateTime.now()),
    ),
  );

  /// 04.3b soft delete; [restoreTransaction] is its batalin.
  Future<void> deleteTransaction(String id) => _setDeleted(id, DateTime.now());

  Future<void> restoreTransaction(String id) => _setDeleted(id, null);

  Future<void> _setDeleted(String id, DateTime? at) =>
      (_db.update(_tx)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          deletedAt: Value(at),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Budget bulanan (00.16) from [period] on; null = hapus budget.
  Future<void> setMonthlyBudget(int? budget, Period period) =>
      _setBudgetRow(period, budget);

  /// The budget in force for [period] (null = none), for any month.
  Stream<int?> watchBudget(Period period) {
    final b = _db.budgets;
    return (_db.select(b)
          ..where(
            (r) =>
                r.deletedAt.isNull() &
                r.periodStart.isSmallerOrEqualValue(period.start),
          )
          ..orderBy([
            (r) => OrderingTerm.desc(r.periodStart),
            (r) => OrderingTerm.desc(r.updatedAt),
          ])
          ..limit(1))
        .watchSingleOrNull()
        .map((r) => r?.amount);
  }

  /// 02.4 tanggal gajian (00.24): 1–31, 31 = akhir. Periods already lived
  /// stay as they were: the new day starts with the next period. Right after
  /// 01.4 (still in the first period, or no payday rule yet) it applies at
  /// once, so a wrong pick at setup is a one-tap fix. Returns the date it
  /// starts on, null = applies now.
  Future<DateTime?> setPayday(
    int day, {
    PaydayShift shift = PaydayShift.previousWorkday,
    required PeriodResolver periods,
    required DateTime now,
  }) => _db.transaction(() async {
    await (_db.update(_db.profiles)..where((p) => p.deletedAt.isNull())).write(
      ProfilesCompanion(payday: Value(day), updatedAt: Value(DateTime.now())),
    );
    final today = DateTime(now.year, now.month, now.day);
    final opening = await (_db.select(
      _db.profiles,
    )..limit(1)).getSingleOrNull();
    final rules = _db.periodRules;
    final rows =
        await (_db.select(rules)
              ..where((r) => r.deletedAt.isNull())
              ..orderBy([(r) => OrderingTerm.asc(r.effectiveFrom)]))
            .get();
    final payday = rows.where((r) => r.mode == PeriodMode.payday).toList();
    final current = periods.periodOf(today);

    void write(PeriodRuleRow? row, DateTime from) => row != null
        ? (_db.update(rules)..where((r) => r.id.equals(row.id))).write(
            PeriodRulesCompanion(
              paydayDay: Value(day),
              shift: Value(shift),
              updatedAt: Value(DateTime.now()),
            ),
          )
        : _db
              .into(rules)
              .insert(
                PeriodRulesCompanion.insert(
                  effectiveFrom: from,
                  mode: PeriodMode.payday,
                  paydayDay: day,
                  shift: Value(shift),
                ),
              );

    final at = opening?.onboardedAt;
    final from = paydayChangeFrom(
      [
        for (final r in payday)
          (
            effectiveFrom: r.effectiveFrom,
            mode: r.mode,
            paydayDay: r.paydayDay,
            shift: r.shift,
          ),
      ],
      current: current,
      today: today,
      setUpOn: at == null ? today : DateTime(at.year, at.month, at.day),
    );
    if (from == null) {
      await Future.sync(() => write(payday.firstOrNull, today));
      return null;
    }
    final queued = payday.where((r) => r.effectiveFrom == from).firstOrNull;
    await Future.sync(() => write(queued, from));
    return from;
  });

  /// 02.2l kenalan kantong: "oke" retires the card for good.
  Future<void> markPocketsIntroSeen() =>
      (_db.update(_db.profiles)..where((p) => p.deletedAt.isNull())).write(
        ProfilesCompanion(
          pocketsIntroSeen: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// 02.4 sembunyiin nominal.
  Future<void> setHideAmounts(HideAmounts hide) =>
      (_db.update(_db.profiles)..where((p) => p.deletedAt.isNull())).write(
        ProfilesCompanion(
          hideAmounts: Value(hide),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// 04.2b terakhir dicari.
  Future<void> setRecentSearches(List<String> recent) =>
      (_db.update(_db.profiles)..where((p) => p.deletedAt.isNull())).write(
        ProfilesCompanion(
          recentSearches: Value(recent.join('\n')),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Entries and expense (positive) of one category in [period], for the
  /// copot limit sheet.
  Future<({int count, int spent})> periodUsage(String id, Period period) async {
    final count = _tx.id.count();
    final spent = _tx.amount.sum(filter: _tx.amount.isSmallerThanValue(0));
    final r =
        await (_db.selectOnly(_tx)
              ..addColumns([count, spent])
              ..where(
                _tx.deletedAt.isNull() &
                    _tx.categoryId.equals(id) &
                    _inPeriod(period),
              ))
            .getSingle();
    return (count: r.read(count) ?? 0, spent: -(r.read(spent) ?? 0));
  }

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
    required Period period,
  }) => _db.transaction(() async {
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
            sortOrder: Value((row.read(last) ?? -1) + 1),
          ),
        );
    if (_limitFor(kind, monthlyLimit) case final limit?) {
      await _setLimitRow(inserted.id, period, limit);
    }
    return inserted.id;
  });

  Future<void> updateCategory(
    String id, {
    required String emoji,
    required String name,
    required CategoryKind kind,
    required int? monthlyLimit,
    required Period period,
  }) => _db.transaction(() async {
    await (_db.update(_db.categories)..where((c) => c.id.equals(id))).write(
      CategoriesCompanion(
        emoji: Value(emoji),
        name: Value(name.trim().toLowerCase()),
        kind: Value(kind),
        updatedAt: Value(DateTime.now()),
      ),
    );
    // Only a changed limit gets a row (an icon swap writes none).
    final limit = _limitFor(kind, monthlyLimit);
    if (await _limitNow(id, period) != limit) {
      await _setLimitRow(id, period, limit);
    }
  });

  /// Pasang / atur / copot limit (02.2, 03.5) from [period] on; null =
  /// copot. Income categories are left alone.
  Future<void> setLimit(String id, int? limit, Period period) async {
    final c = await (_db.select(
      _db.categories,
    )..where((r) => r.id.equals(id))).getSingleOrNull();
    if (c == null || c.kind != CategoryKind.expense) return;
    await _setLimitRow(id, period, limit);
  }

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

final allTransactionsProvider = StreamProvider<List<Transaction>>(
  (ref) => ref.watch(financeRepositoryProvider).watchAll(),
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

/// Expense categories without a limit, with spending in [period].
final freeCategoriesProvider =
    StreamProvider.family<List<FreeCategory>, Period>(
      (ref, period) =>
          ref.watch(financeRepositoryProvider).watchFreeCategories(period),
    );

/// Pockets with spending in [period].
final pocketsInPeriodProvider = StreamProvider.family<List<Pocket>, Period>(
  (ref, period) => ref.watch(financeRepositoryProvider).watchPockets(period),
);
