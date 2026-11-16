import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../data/repositories/app_lock_repository.dart';
import '../../home/view_models/export_reminder.dart';
import '../../../../domain/csv.dart';
import '../../../../domain/models/finance.dart';
import '../../../core/clock.dart';
import '../../../core/finance_providers.dart';
import '../../categories/view_models/categories_view_model.dart';

class SettingsState {
  const SettingsState({
    required this.budget,
    required this.hideAmounts,
    required this.topIcons,
    required this.moreCategories,
    required this.limits,
    required this.limitTotal,
    required this.payday,
    required this.paydayInfo,
  });

  final int? budget; // budget bulanan; null = not set
  final HideAmounts hideAmounts;
  final List<String> topIcons; // 3 most used buat apa, for the row's stack
  final int moreCategories; // the rest: "+8"
  final int limits; // those with a limit
  final int limitTotal; // Σ monthly limits
  final int payday; // 1–31, 31 = akhir
  final PaydayInfo paydayInfo; // "gajian lagi n hari" / hari ini / telat
}

/// 05.1 pengaturan state.
final settingsProvider = Provider<AsyncValue<SettingsState>>((ref) {
  final profile = ref.watch(profileProvider);
  final categories = ref.watch(categoriesProvider);
  final pockets = ref.watch(pocketsProvider);
  final usageState = ref.watch(categoryUsageProvider);
  final salaries = ref.watch(salaryDatesProvider);
  final rules = ref.watch(periodRulesProvider);
  final states = <AsyncValue<Object?>>[
    profile,
    categories,
    pockets,
    usageState,
    salaries,
    rules,
  ];
  for (final state in states) {
    if (state.hasError) return AsyncError(state.error!, state.stackTrace!);
  }
  if (states.any((state) => !state.hasValue)) {
    return const AsyncLoading();
  }
  final limits = pockets.value!;
  // Most used first (entries, all time); ties keep the list order.
  final usage = usageState.value!;
  final byUse = [...categories.value!]
    ..sort(
      (a, b) => (usage[b.id]?.count ?? 0).compareTo(usage[a.id]?.count ?? 0),
    );
  return AsyncData(
    SettingsState(
      budget: profile.value!.monthlyBudget,
      hideAmounts: profile.value!.hideAmounts,
      topIcons: [for (final c in byUse.take(3)) c.emoji],
      moreCategories: byUse.length > 3 ? byUse.length - 3 : 0,
      limits: limits.length,
      limitTotal: limits.fold(0, (sum, p) => sum + p.limit),
      payday: profile.value!.payday == 0 ? 31 : profile.value!.payday,
      paydayInfo: paydayInfo(
        now: ref.watch(nowProvider),
        payday: ref.watch(activePaydayProvider),
        shift: ref.watch(activeShiftProvider),
        salaries: salaries.value!,
      ),
    ),
  );
});

final appVersionProvider = FutureProvider<String>(
  (ref) async => (await PackageInfo.fromPlatform()).version,
);

/// 05.1 ekspor ke csv: every live entry → share sheet as `mibu-yyyyMMdd.csv`.
Future<void> exportCsv(WidgetRef ref) async {
  try {
    final entries = await ref.read(financeRepositoryProvider).allTransactions();
    final bytes = Uint8List.fromList(utf8.encode(transactionsCsv(entries)));
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'text/csv')],
        fileNameOverrides: [csvFileName(ref.read(clockProvider)())],
      ),
    );
    if (result.status == ShareResultStatus.success) {
      await ref
          .read(lockStoreProvider)
          .write(
            exportReminderKey,
            ref.read(clockProvider)().toIso8601String(),
          );
      ref.invalidate(exportReminderProvider);
    }
  } on Exception {
    if (ref.context.mounted) {
      ScaffoldMessenger.of(ref.context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(ref.context)!.saveError)),
      );
    }
  }
}
