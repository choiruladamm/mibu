import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/finance.dart';
import '../../../core/clock.dart';
import '../../home/view_models/home_view_model.dart';

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
  });

  final DateTime month;
  final List<Pocket> pockets;
  final Pocket? selected; // null = no pockets yet
  final int daysLeft; // in this month, today included
  final int? budget; // budget bulanan; null = not set

  int get limit => pockets.fold(0, (sum, p) => sum + p.budget);
  int get spent => pockets.fold(0, (sum, p) => sum + p.spent);
  int get left => limit - spent; // "sisa jajan"
}

/// 02.2 kantong state.
final pocketsScreenProvider = Provider<AsyncValue<PocketsState>>((ref) {
  final now = ref.watch(nowProvider);
  final budget = ref.watch(profileProvider).value?.monthlyBudget;
  return switch (ref.watch(pocketsProvider)) {
    AsyncData(:final value) => AsyncData(
      PocketsState(
        month: now,
        pockets: value,
        selected:
            value
                .where((p) => p.id == ref.watch(selectedPocketProvider))
                .firstOrNull ??
            value.firstOrNull,
        daysLeft: daysLeftInMonth(now),
        budget: budget,
      ),
    ),
    AsyncError(:final error, :final stackTrace) => () {
      debugPrint('kantong: $error\n$stackTrace');
      return AsyncError<PocketsState>(error, stackTrace);
    }(),
    _ => const AsyncLoading(),
  };
});
