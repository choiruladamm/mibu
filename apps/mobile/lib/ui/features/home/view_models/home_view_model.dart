import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';

/// Overridable clock (tests pin it).
final nowProvider = Provider<DateTime>((ref) => DateTime.now());

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
final recentTransactionsProvider = StreamProvider<List<Transaction>>(
  (ref) => ref.watch(financeRepositoryProvider).watchRecent(),
);

/// Month tapped in the chart; null = current month.
class SelectedMonth extends Notifier<int?> {
  @override
  int? build() => null;

  void select(int index) => state = index;
}

final selectedMonthProvider = NotifierProvider<SelectedMonth, int?>(
  SelectedMonth.new,
);

class HomeState {
  const HomeState({
    required this.balance,
    required this.months,
    required this.selected,
    required this.pockets,
    required this.recent,
    required this.safeToSpendToday,
  });

  static const nowIndex = 3; // balanceSeries: 3 past, now, 2 predicted

  final int balance;
  final List<MonthBalance> months;
  final int selected;
  final List<Pocket> pockets; // top 4 by usage
  final List<Transaction> recent;
  final int safeToSpendToday; // negative = overspent today

  bool get selectedIsPrediction => selected > nowIndex;
  MonthBalance get selectedMonth => months[selected];
}

/// 02.1 beranda state. Errors come back as [AsyncError] so the view can
/// show them — rethrowing here crash-looped (drift stack traces are
/// package:stack_trace chains Flutter can't demangle).
final homeProvider = Provider<AsyncValue<HomeState>>((ref) {
  final (profile, totals, pockets, recent) = (
    ref.watch(profileProvider),
    ref.watch(totalsProvider),
    ref.watch(pocketsProvider),
    ref.watch(recentTransactionsProvider),
  );
  for (final s in [profile, totals, pockets, recent]) {
    if (s case AsyncError(:final error, :final stackTrace)) {
      debugPrint('beranda: $error\n$stackTrace');
      return AsyncError(error, stackTrace);
    }
  }
  if ((profile.value, totals.value, pockets.value, recent.value) case (
    final profile?,
    final totals?,
    final pockets?,
    final recent?,
  )) {
    return AsyncData(_homeState(ref, profile, totals, pockets, recent));
  }
  return const AsyncLoading();
});

HomeState _homeState(
  Ref ref,
  Profile profile,
  Totals totals,
  List<Pocket> pockets,
  List<Transaction> recent,
) {
  final now = ref.watch(nowProvider);
  return HomeState(
    balance: totals.balance,
    months: balanceSeries(now: now, balance: totals.balance, nets: totals.nets),
    selected: ref.watch(selectedMonthProvider) ?? HomeState.nowIndex,
    pockets: ([
      ...pockets,
    ]..sort((a, b) => b.usedPct.compareTo(a.usedPct))).take(4).toList(),
    recent: recent,
    safeToSpendToday: safeToSpendToday(
      balance: totals.balance,
      spentToday: totals.spentToday,
      payday: profile.payday,
      now: now,
    ),
  );
}
