import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/csv.dart';
import '../../../../domain/models/finance.dart';
import '../../../core/clock.dart';
import '../../../core/finance_providers.dart';

class SettingsState {
  const SettingsState({
    required this.budget,
    required this.hideAmounts,
    required this.categories,
    required this.limits,
    required this.limitTotal,
    required this.payday,
    required this.paydayInfo,
  });

  final int? budget; // budget bulanan; null = not set
  final bool hideAmounts;
  final int categories, limits; // all categories / those with a limit
  final int limitTotal; // Σ monthly limits
  final int payday; // 1–31, 31 = akhir
  final PaydayInfo paydayInfo; // "gajian lagi n hari" / hari ini / telat
}

/// 02.4 pengaturan state.
final settingsProvider = Provider<AsyncValue<SettingsState>>((ref) {
  final profile = ref.watch(profileProvider);
  final categories = ref.watch(categoriesProvider);
  final pockets = ref.watch(pocketsProvider);
  if (profile.value == null || categories.value == null) {
    return const AsyncLoading();
  }
  final limits = [...?pockets.value];
  return AsyncData(
    SettingsState(
      budget: profile.value!.monthlyBudget,
      hideAmounts: profile.value!.hideAmounts,
      categories: categories.value!.length,
      limits: limits.length,
      limitTotal: limits.fold(0, (sum, p) => sum + p.budget),
      payday: profile.value!.payday == 0 ? 31 : profile.value!.payday,
      paydayInfo: paydayInfo(
        now: ref.watch(nowProvider),
        payday: profile.value!.payday,
        salaries: ref.watch(salaryDatesProvider).value ?? const [],
      ),
    ),
  );
});

final appVersionProvider = FutureProvider<String>(
  (ref) async => (await PackageInfo.fromPlatform()).version,
);

/// 02.4 ekspor ke csv: every live entry → share sheet as `mibu-yyyyMMdd.csv`.
Future<void> exportCsv(WidgetRef ref) async {
  final entries = await ref.read(financeRepositoryProvider).allTransactions();
  final bytes = Uint8List.fromList(utf8.encode(transactionsCsv(entries)));
  await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'text/csv')],
      fileNameOverrides: [csvFileName(ref.read(clockProvider)())],
    ),
  );
}
