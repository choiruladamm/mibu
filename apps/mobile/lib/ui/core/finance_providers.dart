import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/finance_repository.dart';
import '../../domain/models/finance.dart';
import 'clock.dart';

/// Finance data several features read (beranda, kantong, catat, budget, …);
/// lives here so features don't import each other's view models.
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
