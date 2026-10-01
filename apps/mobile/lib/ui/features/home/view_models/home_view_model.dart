import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';

/// Overridable clock (tests pin it).
final nowProvider = Provider<DateTime>((ref) => DateTime.now());

final monthBalancesProvider = StreamProvider<List<MonthBalance>>(
  (ref) => ref.watch(financeRepositoryProvider).watchMonths(),
);
final pocketsProvider = StreamProvider<List<Pocket>>(
  (ref) => ref.watch(financeRepositoryProvider).watchPockets(),
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
    required this.months,
    required this.nowIndex,
    required this.selected,
    required this.pockets,
    required this.recent,
    required this.safeToSpendToday,
  });

  final List<MonthBalance> months;
  final int nowIndex; // -1 when there's no data yet
  final int selected;
  final List<Pocket> pockets;
  final List<Transaction> recent;
  final int safeToSpendToday;

  int get balance => nowIndex < 0 ? 0 : months[nowIndex].amount;
  bool get selectedIsPrediction => selected > nowIndex;
  MonthBalance? get selectedMonth => months.isEmpty ? null : months[selected];
}

/// 02.1 beranda state; null while the streams are loading.
final homeProvider = Provider<HomeState?>((ref) {
  final months = ref.watch(monthBalancesProvider).value;
  final pockets = ref.watch(pocketsProvider).value;
  final recent = ref.watch(recentTransactionsProvider).value;
  if (months == null || pockets == null || recent == null) return null;

  final now = ref.watch(nowProvider);
  final nowIndex = months.lastIndexWhere((m) => !m.month.isAfter(now));
  return HomeState(
    months: months,
    nowIndex: nowIndex,
    selected: ref.watch(selectedMonthProvider) ?? (nowIndex < 0 ? 0 : nowIndex),
    pockets: pockets,
    recent: recent,
    // ponytail: mock until the daily-allowance calc exists.
    safeToSpendToday: 580000,
  );
});
