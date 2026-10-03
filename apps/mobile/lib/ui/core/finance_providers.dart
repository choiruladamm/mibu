import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/finance_repository.dart';
import '../../domain/models/finance.dart';
import '../../domain/period.dart';
import 'clock.dart';

/// Finance data several features read (beranda, kantong, catat, budget, …);
/// lives here so features don't import each other's view models.
final profileProvider = StreamProvider<Profile>(
  (ref) => ref
      .watch(financeRepositoryProvider)
      .watchProfile(ref.watch(currentPeriodProvider)),
);

/// Categories with this period's limits ([Category.monthlyLimit]).
final categoriesProvider = StreamProvider<List<Category>>(
  (ref) => ref
      .watch(financeRepositoryProvider)
      .watchCategories(ref.watch(currentPeriodProvider)),
);
final recentPicksProvider = StreamProvider<List<RecentPick>>(
  // ponytail: last 30 combos also feed the per-category "di mana" hint; a
  // per-category query if heavy users miss their places.
  (ref) => ref
      .watch(financeRepositoryProvider)
      .watchRecentPicks(ref.watch(currentPeriodProvider), limit: 30),
);

/// Budget periods (fase 0). Calendar months until the rules load, so screens
/// never wait on it.
final periodRulesProvider = StreamProvider<List<PeriodRule>>(
  (ref) => ref.watch(financeRepositoryProvider).watchPeriodRules(),
);
final periodsProvider = Provider<PeriodResolver>((ref) {
  final rules = ref.watch(periodRulesProvider).value;
  if (rules == null) return const CalendarMonthResolver();
  return SegmentedResolver([
    calendarBase,
    ...rules,
  ], salaries: ref.watch(salaryDatesProvider).value ?? const []);
});

/// Payday rules, oldest first; with [today], only those in force by then.
List<PeriodRule> _paydayRules(Ref ref, {DateTime? today}) => [
  for (final r in ref.watch(periodRulesProvider).value ?? const <PeriodRule>[])
    if (r.mode == PeriodMode.payday &&
        (today == null || !r.effectiveFrom.isAfter(today)))
      r,
]..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));

/// The payday rule the periods run on today (a change queued for the next
/// period doesn't count yet); null = none saved.
final _activePaydayRule = Provider<PeriodRule?>((ref) {
  final now = ref.watch(nowProvider);
  return _paydayRules(
    ref,
    today: DateTime(now.year, now.month, now.day),
  ).lastOrNull;
});

/// The gajian day the periods run on today: the rule in force, else the
/// profile's.
final activePaydayProvider = Provider<int>(
  (ref) =>
      ref.watch(_activePaydayRule)?.paydayDay ??
      ref.watch(profileProvider).value?.payday ??
      25,
);

/// Weekend handling in force today (jumat by default).
final activeShiftProvider = Provider<PaydayShift>(
  (ref) => ref.watch(_activePaydayRule)?.shift ?? PaydayShift.previousWorkday,
);

/// Weekend handling as last set, a queued change included: what 00.24 edits.
final paydayShiftProvider = Provider<PaydayShift>(
  (ref) => _paydayRules(ref).lastOrNull?.shift ?? PaydayShift.previousWorkday,
);

/// The month label of the budget period now falls in ("oktober" while it's
/// 25 sep – 24 okt): what the beranda, 04.1 and the menus start on.
final currentMonthProvider = Provider<DateTime>(
  (ref) => ref.watch(currentPeriodProvider).key,
);

/// The budget period [nowProvider] falls in: "bulan ini" everywhere.
final currentPeriodProvider = Provider<Period>(
  (ref) => ref.watch(periodsProvider).periodOf(ref.watch(nowProvider)),
);

/// The budget for [period] (any month; null = none), prorated on a
/// transition period. The budget as set is [Profile.monthlyBudget].
final budgetInPeriodProvider = StreamProvider.family<int?, Period>(
  (ref, period) => ref
      .watch(financeRepositoryProvider)
      .watchBudget(period)
      .map((b) => b == null ? null : prorate(b, period)),
);

/// Dates of logged gajian, for [paydayInfo] (cair duluan, telat).
final salaryDatesProvider = StreamProvider<List<DateTime>>(
  (ref) => ref.watch(financeRepositoryProvider).watchSalaryDates(),
);

final totalsProvider = StreamProvider<Totals>(
  (ref) => ref
      .watch(financeRepositoryProvider)
      .watchTotals(ref.watch(nowProvider), periods: ref.watch(periodsProvider)),
);
final pocketsProvider = StreamProvider<List<Pocket>>(
  (ref) => ref
      .watch(financeRepositoryProvider)
      .watchPockets(ref.watch(currentPeriodProvider)),
);

/// 02.4 sembunyiin nominal: tap a hero amount or "intip 5 detik" (04.1g) to
/// peek; it closes after 5s, on another tap, or when routing resets it.
class Peek extends Notifier<bool> {
  static const window = Duration(seconds: 5);
  Timer? _timer;

  @override
  bool build() {
    ref.onDispose(() => _timer?.cancel());
    return false;
  }

  void toggle() => state ? reset() : _open();

  void _open() {
    state = true;
    _timer = Timer(window, reset);
  }

  void reset() {
    _timer?.cancel();
    state = false;
  }
}

final peekProvider = NotifierProvider<Peek, bool>(Peek.new);
