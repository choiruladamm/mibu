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
final _periodsStream = StreamProvider<PeriodResolver>(
  (ref) => ref.watch(financeRepositoryProvider).watchPeriods(),
);
final periodsProvider = Provider<PeriodResolver>(
  (ref) => ref.watch(_periodsStream).value ?? const CalendarMonthResolver(),
);

/// The budget period [nowProvider] falls in: "bulan ini" everywhere.
final currentPeriodProvider = Provider<Period>(
  (ref) => ref.watch(periodsProvider).periodOf(ref.watch(nowProvider)),
);

final totalsProvider = StreamProvider<Totals>((ref) {
  final profile = ref.watch(profileProvider).value;
  if (profile == null) return const Stream.empty();
  return ref
      .watch(financeRepositoryProvider)
      .watchTotals(profile, ref.watch(nowProvider));
});
final pocketsProvider = StreamProvider<List<Pocket>>(
  (ref) => ref
      .watch(financeRepositoryProvider)
      .watchPockets(ref.watch(currentPeriodProvider)),
);

/// 02.4 sembunyiin nominal: tap a hero amount to peek; routing resets it.
class Peek extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
  void reset() => state = false;
}

final peekProvider = NotifierProvider<Peek, bool>(Peek.new);
