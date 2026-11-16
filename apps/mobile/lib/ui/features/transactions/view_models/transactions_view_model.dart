import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../../domain/period.dart';
import '../../../../domain/search.dart';
import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/finance_providers.dart';

/// An exact statistics selection; null category means all or uncategorized.
typedef TxDrill = ({
  DateTime start,
  DateTime end,
  DateTime today,
  bool categoryOnly,
  String? categoryId,
  String label,
});

List<Transaction> drillTransactions(List<Transaction> rows, TxDrill drill) => [
  for (final t in rows)
    if (!t.deleted &&
        t.amount < 0 &&
        !t.at.isBefore(drill.start) &&
        t.at.isBefore(drill.end) &&
        t.at.isBefore(
          DateTime(drill.today.year, drill.today.month, drill.today.day + 1),
        ) &&
        (!drill.categoryOnly || t.categoryId == drill.categoryId))
      t,
];

enum TxFilter { all, expenses, income }

/// Month shown in 09.1; starts at [initial] (a deep link from 02.1) or the
/// current month.
class TxMonth extends Notifier<DateTime> {
  TxMonth([this.initial, this.exact = false]);

  final DateTime? initial;
  final bool exact;

  @override
  DateTime build() => initial == null
      ? ref.read(currentPeriodProvider).start
      : exact
      ? initial!
      : ref.read(periodsProvider).periodForMonth(initial!).start;

  void select(DateTime month) => state = month;
}

// `dependencies` scope the router's per-route override (a deep link's month)
// to this screen. Without them [transactionsProvider] lives in the root scope
// and keeps watching the un-overridden month, so the month can't be changed.
final txMonthProvider = NotifierProvider.autoDispose<TxMonth, DateTime>(
  TxMonth.new,
  dependencies: const [],
);

class TxFilterNotifier extends Notifier<TxFilter> {
  TxFilterNotifier([this.initial = TxFilter.all]);

  final TxFilter initial;

  @override
  TxFilter build() => initial;

  void select(TxFilter f) => state = f;
}

final txFilterProvider =
    NotifierProvider.autoDispose<TxFilterNotifier, TxFilter>(
      TxFilterNotifier.new,
      dependencies: const [],
    );

/// 08.1 "liat N lagi": 09.1 narrowed to a search term (and one day of the
/// month); null = no search.
typedef TxSearch = ({String q, int? day});

final txSearchProvider = Provider.autoDispose<TxSearch?>(
  (_) => null,
  dependencies: const [],
);

final monthTransactionsProvider =
    StreamProvider.family<List<Transaction>, DateTime>(
      (ref, month) => ref
          .watch(financeRepositoryProvider)
          .watchPeriod(ref.watch(periodsProvider).periodOf(month)),
    );

final periodTransactionsProvider =
    StreamProvider.family<List<Transaction>, Period>(
      (ref, period) => ref.watch(financeRepositoryProvider).watchPeriod(period),
    );

final periodSpendingProvider = Provider<Map<Period, int>>((ref) {
  final resolver = ref.watch(periodsProvider);
  final spending = <Period, int>{};
  for (final t in ref.watch(allTransactionsProvider).value ?? <Transaction>[]) {
    if (t.amount < 0) {
      final period = resolver.periodOf(t.at);
      spending[period] = (spending[period] ?? 0) - t.amount;
    }
  }
  return spending;
});

final firstMonthProvider = StreamProvider<DateTime?>(
  (ref) => ref
      .watch(financeRepositoryProvider)
      .watchFirstMonth(periods: ref.watch(periodsProvider), exact: true),
);

/// [income]: a pemasukan is in it, so [total] gives it away (05.1h).
typedef DayGroup = ({
  DateTime day,
  int total,
  bool income,
  List<Transaction> rows,
});

class TransactionsState {
  const TransactionsState({
    required this.months,
    required this.selected,
    required this.today,
    required this.period,
    required this.income,
    required this.expense,
    required this.prevIncome,
    required this.prevExpense,
    required this.groups,
    required this.count,
  });

  /// First entry's month … this month, plus next month (not yet).
  final List<Period> months;
  final int selected;
  final DateTime today;
  final Period period; // the budget period [month] is named after
  final int income, expense; // whole period, filter ignored; expense ≤ 0
  final int prevIncome, prevExpense; // the period before; expense ≥ 0
  final List<DayGroup> groups; // newest day first, filter applied
  final int count;

  DateTime get month => months[selected].key;

  /// The month label of the period we're in now (the last before the future
  /// one).
  Period get current => months[months.length - 2];
  bool get hasPrev => selected > 0;
  bool get nextIsFuture => selected + 1 >= months.length - 1;
}

/// Month labels from [first] to [now]'s (a month label: first of the month a
/// budget period is named after), plus one future one.
List<Period> txPeriods(
  DateTime? first,
  Period current,
  PeriodResolver resolver,
) {
  var p = first == null ? current : resolver.periodOf(first);
  if (p.start.isAfter(current.start)) p = current;
  final periods = <Period>[];
  while (!p.start.isAfter(current.start)) {
    periods.add(p);
    p = resolver.next(p);
  }
  return [...periods, resolver.next(current)];
}

/// Entries grouped per day (input is newest first), with each day's net.
List<DayGroup> groupByDay(List<Transaction> rows) {
  final groups = <DayGroup>[];
  for (final t in rows) {
    final day = dateOnly(t.at);
    if (groups.isNotEmpty && groups.last.day == day) {
      final g = groups.removeLast();
      groups.add((
        day: day,
        total: g.total + t.amount,
        income: g.income || t.amount > 0,
        rows: [...g.rows, t],
      ));
    } else {
      groups.add((day: day, total: t.amount, income: t.amount > 0, rows: [t]));
    }
  }
  return groups;
}

/// 09.1 semua transaksi.
final transactionsProvider =
    Provider.autoDispose<AsyncValue<TransactionsState>>(
      dependencies: [txMonthProvider, txFilterProvider, txSearchProvider],
      (ref) {
        final month = ref.watch(txMonthProvider);
        final rows = ref.watch(monthTransactionsProvider(month));
        final first = ref.watch(firstMonthProvider);
        if (rows.error ?? first.error case final e?) {
          return AsyncError(e, rows.stackTrace ?? first.stackTrace!);
        }
        if (!rows.hasValue || !first.hasValue) return const AsyncLoading();

        final now = ref.watch(nowProvider);
        final periods = ref.watch(periodsProvider);
        final period = periods.periodOf(month);
        var months = txPeriods(
          first.value,
          ref.watch(currentPeriodProvider),
          periods,
        );
        if (!months.contains(period)) {
          months = [period, ...months]
            ..sort((a, b) => a.start.compareTo(b.start));
        }
        final filter = ref.watch(txFilterProvider);
        final search = ref.watch(txSearchProvider);
        final shown = [
          for (final t
              in search == null
                  ? rows.value!
                  : searchEntries(rows.value!, search.q))
            // search.day = day number within the period (1 = its first day).
            if (search?.day == null ||
                daysBetween(period.start, t.at) + 1 == search!.day)
              if (switch (filter) {
                TxFilter.all => true,
                TxFilter.expenses => t.amount < 0,
                TxFilter.income => t.amount > 0,
              })
                t,
        ];
        final previous = ref.watch(
          periodTransactionsProvider(periods.prev(period)),
        );
        if (previous.hasError) {
          return AsyncError(previous.error!, previous.stackTrace!);
        }
        if (!previous.hasValue) return const AsyncLoading();
        int sum(bool Function(int) test) => rows.value!
            .map((t) => t.amount)
            .where(test)
            .fold(0, (a, b) => a + b);
        return AsyncData(
          TransactionsState(
            months: months,
            selected: months.indexOf(period),
            today: dateOnly(now),
            period: period,
            income: sum((v) => v > 0),
            expense: sum((v) => v < 0),
            prevIncome: previous.value!
                .where((t) => t.amount > 0)
                .fold(0, (sum, t) => sum + t.amount),
            prevExpense: previous.value!
                .where((t) => t.amount < 0)
                .fold(0, (sum, t) => sum - t.amount),
            groups: groupByDay(shown),
            count: shown.length,
          ),
        );
      },
    );
