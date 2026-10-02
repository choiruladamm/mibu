import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../core/clock.dart';

/// Live entries without a buat apa: the "lain-lain" tile in 03.3.
// ponytail: counts the full entry list in Dart, like stats and search do.
final uncategorizedCountProvider = Provider<int>(
  (ref) => [
    for (final t in ref.watch(allTransactionsProvider).value ?? const [])
      if (t.categoryId == null && !t.deleted) t,
  ].length,
);

/// Per category id: entries + this year's expense ("12 catatan · Rp840K").
final categoryUsageProvider =
    StreamProvider<Map<String, ({int count, int spentThisYear})>>(
      (ref) => ref
          .watch(financeRepositoryProvider)
          .watchCategoryUsage(ref.watch(nowProvider)),
    );
