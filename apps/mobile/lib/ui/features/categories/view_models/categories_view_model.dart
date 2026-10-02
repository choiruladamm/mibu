import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../core/clock.dart';

/// Per category id: entries + this year's expense ("12 catatan · Rp840K").
final categoryUsageProvider =
    StreamProvider<Map<String, ({int count, int spentThisYear})>>(
      (ref) => ref
          .watch(financeRepositoryProvider)
          .watchCategoryUsage(ref.watch(nowProvider)),
    );
