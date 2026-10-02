import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../transactions/view_models/transactions_view_model.dart';

final profileProvider = StreamProvider<Profile>(
  (ref) => ref.watch(financeRepositoryProvider).watchProfile(),
);
final totalsProvider = StreamProvider<Totals>((ref) {
  final profile = ref.watch(profileProvider).value;
  if (profile == null) return const Stream.empty();
  return ref
      .watch(financeRepositoryProvider)
      .watchTotals(profile, ref.watch(nowProvider));
});
final pocketsProvider = StreamProvider<List<Pocket>>(
  (ref) =>
      ref.watch(financeRepositoryProvider).watchPockets(ref.watch(nowProvider)),
);

typedef HomeMonthSelection = ({DateTime selected, DateTime start});

/// Month picked in the chart or in 00.8 (first of month, up to now + 2 for a
/// predicted peek) and the first month of the 6-month chart window.
class HomeMonth extends Notifier<HomeMonthSelection> {
  DateTime get _now {
    final now = ref.read(nowProvider);
    return DateTime(now.year, now.month);
  }

  @override
  HomeMonthSelection build() {
    final now = _now;
    return (selected: now, start: DateTime(now.year, now.month - 3));
  }

  void select(DateTime month) => state = (
    selected: DateTime(month.year, month.month),
    start: chartStart(now: _now, start: state.start, picked: month),
  );
}

final homeMonthProvider = NotifierProvider<HomeMonth, HomeMonthSelection>(
  HomeMonth.new,
);

typedef HomeChart = ({List<MonthBalance> months, DateTime selected, int now});

/// Chart inputs only (totals + pick), so the chart reacts the moment a month
/// is picked instead of waiting for that month's pockets and rows to load.
final homeChartProvider = Provider<HomeChart?>((ref) {
  final now = ref.watch(nowProvider);
  final pick = ref.watch(homeMonthProvider);
  final totals = ref.watch(totalsProvider).value;
  if (totals == null) return null;
  return (
    months: balanceSeries(
      now: now,
      start: pick.start,
      balance: totals.balance,
      nets: totals.nets,
    ),
    selected: pick.selected,
    now:
        (now.year * 12 + now.month) - (pick.start.year * 12 + pick.start.month),
  );
});

/// "baru aja" shows at most this many rows.
const homeRecentLimit = 5;

class HomeState {
  const HomeState({
    required this.month,
    required this.selected,
    required this.isCurrent,
    required this.balance,
    required this.months,
    required this.nowIndex,
    required this.pockets,
    required this.groups,
    required this.count,
    required this.today,
    required this.safeToSpendToday,
    required this.monthLeft,
    required this.noEntries,
  });

  /// Month the screen shows (never after the current one).
  final DateTime month;

  /// Month picked in the chart; after [month] = predicted peek only.
  final DateTime selected;
  final bool isCurrent;
  final int balance; // now, or at the end of [month]
  final List<MonthBalance> months; // the 6-month window
  final int nowIndex; // of the current month in [months]; ≥ 6 = past the window
  final List<Pocket> pockets; // that month, most used first
  final List<DayGroup> groups; // newest day first, ≤ 5 rows; empty "today" ok
  final int count; // entries in [month]
  final DateTime today;
  final int safeToSpendToday; // negative = overspent today
  final int? monthLeft; // past months: budget − spent; null = no budget
  final bool noEntries; // nothing ever logged

  int get selectedIndex => months.indexWhere((m) => m.month == selected);
  bool get selectedIsPrediction => selected.isAfter(month);

  /// Net of today's entries; shown beside "baru aja".
  int get todayNet =>
      groups.where((g) => g.day == today).fold(0, (sum, g) => sum + g.total);
}

/// 02.1 beranda state. Errors come back as [AsyncError] so the view can
/// show them — rethrowing here crash-looped (drift stack traces are
/// package:stack_trace chains Flutter can't demangle).
final homeProvider = Provider<AsyncValue<HomeState>>((ref) {
  final now = ref.watch(nowProvider);
  final cur = DateTime(now.year, now.month);
  final pick = ref.watch(homeMonthProvider);
  final month = pick.selected.isAfter(cur) ? cur : pick.selected;
  final isCurrent = month == cur;
  final prev = DateTime(cur.year, cur.month - 1);

  final profile = ref.watch(profileProvider);
  final totals = ref.watch(totalsProvider);
  final chart = ref.watch(homeChartProvider);
  final pockets = ref.watch(pocketsInMonthProvider(month));
  final own = ref.watch(monthTransactionsProvider(month));
  // Early in the month "baru aja" reaches back into the last one.
  final spill =
      isCurrent && (own.value?.length ?? homeRecentLimit) < homeRecentLimit
      ? ref.watch(monthTransactionsProvider(prev))
      : null;
  final first = ref.watch(firstMonthProvider);

  for (final s in [profile, totals, pockets, own, ?spill, first]) {
    if (s case AsyncError(:final error, :final stackTrace)) {
      debugPrint('beranda: $error\n$stackTrace');
      return AsyncError(error, stackTrace);
    }
  }
  if ((profile.value, totals.value, pockets.value, own.value, chart) case (
    final profile?,
    final totals?,
    final pockets?,
    final own?,
    final chart?,
  )) {
    if (spill != null && !spill.hasValue) return const AsyncLoading();
    if (!first.hasValue) return const AsyncLoading();
    final rows = [...own, ...?spill?.value];
    final today = dateOnly(now);
    final noEntries = first.value == null;

    var left = homeRecentLimit;
    final groups = <DayGroup>[];
    for (final g in groupByDay(rows)) {
      if (left == 0) break;
      final shown = g.rows.take(left).toList();
      left -= shown.length;
      groups.add((day: g.day, total: g.total, rows: shown));
    }
    if (isCurrent && !noEntries && !groups.any((g) => g.day == today)) {
      groups.insert(0, (day: today, total: 0, rows: const []));
    }

    final balance = isCurrent
        ? totals.balance
        : monthEndBalance(
            now: now,
            balance: totals.balance,
            nets: totals.nets,
            month: month,
          );
    return AsyncData(
      HomeState(
        month: month,
        selected: pick.selected,
        isCurrent: isCurrent,
        balance: balance,
        months: chart.months,
        nowIndex: chart.now,
        pockets: ([...pockets]..sort((a, b) => b.usedPct.compareTo(a.usedPct))),
        groups: groups,
        count: own.length,
        today: today,
        safeToSpendToday: safeToSpendToday(
          balance: totals.balance,
          spentToday: totals.spentToday,
          payday: profile.payday,
          now: now,
        ),
        monthLeft: profile.monthlyBudget == null
            ? null
            : profile.monthlyBudget! - (totals.spent[month] ?? 0),
        noEntries: noEntries,
      ),
    );
  }
  return const AsyncLoading();
});
