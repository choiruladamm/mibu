import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../core/clock.dart';
import '../../../core/dates.dart';

enum TxFilter { all, expenses, income }

/// Month shown in 04.1; starts at [initial] (a deep link from 02.1) or the
/// current month.
class TxMonth extends Notifier<DateTime> {
  TxMonth([this.initial]);

  final DateTime? initial;

  @override
  DateTime build() {
    final now = ref.read(clockProvider)();
    return initial ?? DateTime(now.year, now.month);
  }

  void select(DateTime month) => state = month;
}

final txMonthProvider = NotifierProvider.autoDispose<TxMonth, DateTime>(
  TxMonth.new,
);

class TxFilterNotifier extends Notifier<TxFilter> {
  @override
  TxFilter build() => TxFilter.all;

  void select(TxFilter f) => state = f;
}

final txFilterProvider =
    NotifierProvider.autoDispose<TxFilterNotifier, TxFilter>(
      TxFilterNotifier.new,
    );

final monthTransactionsProvider =
    StreamProvider.family<List<Transaction>, DateTime>(
      (ref, month) => ref.watch(financeRepositoryProvider).watchMonth(month),
    );

final firstMonthProvider = StreamProvider<DateTime?>(
  (ref) => ref.watch(financeRepositoryProvider).watchFirstMonth(),
);

typedef DayGroup = ({DateTime day, int total, List<Transaction> rows});

class TransactionsState {
  const TransactionsState({
    required this.months,
    required this.selected,
    required this.today,
    required this.income,
    required this.expense,
    required this.groups,
    required this.count,
  });

  /// First entry's month … this month, plus next month (not yet).
  final List<DateTime> months;
  final int selected;
  final DateTime today;
  final int income, expense; // whole month, filter ignored; expense ≤ 0
  final List<DayGroup> groups; // newest day first, filter applied
  final int count;

  DateTime get month => months[selected];
  bool get hasPrev => selected > 0;
  bool get nextIsFuture => selected + 1 >= months.length - 1;
}

/// Months from [first] to [now]'s, plus one future month.
List<DateTime> txMonths(DateTime? first, DateTime now) {
  final last = DateTime(now.year, now.month);
  var m = first ?? last;
  return [
    for (; !m.isAfter(last); m = DateTime(m.year, m.month + 1)) m,
    DateTime(last.year, last.month + 1),
  ];
}

/// Entries grouped per day (input is newest first), with each day's net.
List<DayGroup> groupByDay(List<Transaction> rows) {
  final groups = <DayGroup>[];
  for (final t in rows) {
    final day = dateOnly(t.at);
    if (groups.isNotEmpty && groups.last.day == day) {
      final g = groups.removeLast();
      groups.add((day: day, total: g.total + t.amount, rows: [...g.rows, t]));
    } else {
      groups.add((day: day, total: t.amount, rows: [t]));
    }
  }
  return groups;
}

/// 04.1 semua transaksi.
final transactionsProvider =
    Provider.autoDispose<AsyncValue<TransactionsState>>((ref) {
      final month = ref.watch(txMonthProvider);
      final rows = ref.watch(monthTransactionsProvider(month));
      final first = ref.watch(firstMonthProvider);
      if (rows.error ?? first.error case final e?) {
        return AsyncError(e, rows.stackTrace ?? first.stackTrace!);
      }
      if (!rows.hasValue || !first.hasValue) return const AsyncLoading();

      final now = ref.watch(nowProvider);
      var months = txMonths(first.value, now);
      if (!months.contains(month)) months = [month, ...months]..sort();
      final filter = ref.watch(txFilterProvider);
      final shown = [
        for (final t in rows.value!)
          if (switch (filter) {
            TxFilter.all => true,
            TxFilter.expenses => t.amount < 0,
            TxFilter.income => t.amount > 0,
          })
            t,
      ];
      int sum(bool Function(int) test) =>
          rows.value!.map((t) => t.amount).where(test).fold(0, (a, b) => a + b);
      return AsyncData(
        TransactionsState(
          months: months,
          selected: months.indexOf(month),
          today: dateOnly(now),
          income: sum((v) => v > 0),
          expense: sum((v) => v < 0),
          groups: groupByDay(shown),
          count: shown.length,
        ),
      );
    });
