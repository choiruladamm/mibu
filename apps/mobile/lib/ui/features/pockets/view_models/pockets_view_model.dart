import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../core/clock.dart';
import '../../../core/finance_providers.dart';

/// Jar tapped in 02.2; null = first pocket.
class SelectedPocket extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String id) => state = id;
}

final selectedPocketProvider = NotifierProvider<SelectedPocket, String?>(
  SelectedPocket.new,
);

class PocketsState {
  const PocketsState({
    required this.month,
    required this.pockets,
    required this.selected,
    required this.daysLeft,
    required this.budget,
    required this.monthSpent,
    required this.free,
  });

  final DateTime month;
  final List<Pocket> pockets;
  final Pocket? selected; // null = no pockets yet
  final int daysLeft; // in this month, today included
  final int? budget; // budget bulanan; null = not set
  final int monthSpent; // every expense this month, pockets or not
  final List<FreeCategory> free; // tanpa kantong

  int get limit => pockets.fold(0, (sum, p) => sum + p.budget);
  int get spent => pockets.fold(0, (sum, p) => sum + p.spent);
  int get left => limit - spent; // "sisa jajan"
  int get freeSpent => free.fold(0, (sum, f) => sum + f.spent);

  /// budget − every expense this month; negative = kelewat. Null without one.
  int? get budgetLeft => budget == null ? null : budget! - monthSpent;

  /// "sisa jajan" promises more than the budget has left: the two figures
  /// disagree, and the smaller one is the one to trust.
  bool get conflict =>
      pockets.isNotEmpty && budgetLeft != null && left > budgetLeft!;
}

/// 02.2 kantong state.
final pocketsScreenProvider = Provider<AsyncValue<PocketsState>>((ref) {
  final now = ref.watch(nowProvider);
  final period = ref.watch(currentPeriodProvider);
  final budget = ref.watch(profileProvider).value?.monthlyBudget;
  final free = ref.watch(freeCategoriesProvider(period));
  if (free.hasError) debugPrint('kantong: ${free.error}');
  return switch (ref.watch(pocketsProvider)) {
    AsyncData(:final value) when free.hasValue => AsyncData(
      PocketsState(
        month: now,
        pockets: value,
        selected:
            value
                .where((p) => p.id == ref.watch(selectedPocketProvider))
                .firstOrNull ??
            value.firstOrNull,
        daysLeft: period.daysLeft(now),
        budget: budget,
        monthSpent:
            ref.watch(totalsProvider).value?.spent[DateTime(
              now.year,
              now.month,
            )] ??
            0,
        free: free.value!,
      ),
    ),
    AsyncError(:final error, :final stackTrace) => () {
      debugPrint('kantong: $error\n$stackTrace');
      return AsyncError<PocketsState>(error, stackTrace);
    }(),
    _ => const AsyncLoading(),
  };
});
