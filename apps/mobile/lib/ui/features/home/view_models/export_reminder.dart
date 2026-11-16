import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/app_lock_repository.dart';
import '../../../../data/repositories/finance_repository.dart';
import '../../../core/clock.dart';

const exportReminderKey = 'export.reminder.v1';

bool exportReminderDue(DateTime baseline, DateTime now) =>
    now.difference(baseline) >= const Duration(days: 14);

final exportReminderDismissedProvider =
    NotifierProvider<ExportReminderDismissed, bool>(
      ExportReminderDismissed.new,
    );

class ExportReminderDismissed extends Notifier<bool> {
  @override
  bool build() => false;

  void dismiss() => state = true;
}

final exportReminderProvider = FutureProvider<bool>((ref) async {
  if (ref.watch(exportReminderDismissedProvider)) return false;
  final entries = await ref.watch(allTransactionsProvider.future);
  if (entries.isEmpty) return false;
  final store = ref.read(lockStoreProvider);
  final now = ref.watch(nowProvider);
  final raw = await store.read(exportReminderKey);
  final baseline = raw == null ? null : DateTime.tryParse(raw);
  if (baseline == null) {
    await store.write(exportReminderKey, now.toIso8601String());
    return false;
  }
  return exportReminderDue(baseline, now);
});
