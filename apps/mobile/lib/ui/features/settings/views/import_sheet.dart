import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/csv.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/finance_providers.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_emoji.dart';
import '../../../core/widgets/meta_line.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/toast.dart';

final _day = DateFormat('d MMM y', 'id');

/// 02.4l import dari csv: pick a file → ImportSheet 00.30 (ringkasan 02.4m,
/// semua udah ada 02.4n, bukan dari mibu 02.4o) → import → toast + batalin.
Future<void> importCsv(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(financeRepositoryProvider);
  while (true) {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
    );
    if (file == null || !context.mounted) return;
    final parsed = parseTransactionsCsv(
      utf8.decode(await file.readAsBytes(), allowMalformed: true),
    );
    final plan = parsed == null || parsed.entries.isEmpty
        ? null
        : planImport(
            parsed,
            existing: await repo.allTransactions(),
            categories: await ref.read(categoriesProvider.future),
          );
    if (!context.mounted) return;
    // true = import, false = pilih file lain, null = closed.
    final go = await showAppSheet<bool>(
      context,
      _ImportSheet(
        fileName: file.name,
        plan: plan,
        total: parsed?.entries.length ?? 0,
      ),
    );
    if (go == false) continue;
    if (go != true || plan == null || !context.mounted) return;
    final wrote = await repo.importCsv(plan);
    if (!context.mounted) return;
    final l = AppLocalizations.of(context)!;
    final names = [for (final c in plan.newCategories) c.name];
    showToast(
      context,
      icon: ToastIcon.check,
      title: l.importToast(plan.entries.length),
      sub: names.isEmpty
          ? _range(plan.entries)
          : l.importToastSub(
              names.length == 1
                  ? names.single
                  : '${names.take(names.length - 1).join(', ')} & ${names.last}',
            ),
      onUndo: () => repo.undoImport(wrote.txIds, wrote.categoryIds),
    );
    return;
  }
}

/// "1 jan 2026 – 3 okt 2026": first and last day of [entries].
String _range(List<CsvEntry> entries) {
  final days = [for (final e in entries) e.at]..sort();
  return '${_day.format(days.first)} – ${_day.format(days.last)}'.toLowerCase();
}

/// ImportSheet 00.30. [plan] null = not a mibu export (02.4o); no entries
/// left = all [total] are in mibu already (02.4n); else ringkasan (02.4m).
class _ImportSheet extends StatelessWidget {
  const _ImportSheet({
    required this.fileName,
    required this.plan,
    required this.total,
  });

  final String fileName;
  final CsvImport? plan;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final plan = this.plan;
    if (plan == null) {
      return _Message(
        fileName: fileName,
        icon: HugeIcons.strokeRoundedFileRemove,
        title: l.importWrongTitle,
        sub: l.importWrongSub,
        action: l.importPickAgain,
        result: false,
      );
    }
    if (plan.entries.isEmpty) {
      return _Message(
        fileName: fileName,
        icon: HugeIcons.strokeRoundedTick02,
        title: l.importSameTitle,
        sub: l.importSameSub(total),
        action: l.importOk,
      );
    }
    final muted = AppText.caption.copyWith(color: AppColors.muted);
    final spent = plan.entries.where((e) => e.amount < 0).length;
    final cats = plan.newCategories;
    return SheetFrame(
      title: l.settingsImport,
      sub: fileName,
      titleSize: 22,
      height: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(AppRadius.groupCard),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(l.importNew, style: muted),
                Text('${plan.entries.length}', style: AppText.displayS),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_range(plan.entries), style: muted),
                ),
                MetaLine([
                  if (spent > 0) l.importExpenses(spent),
                  if (plan.entries.length > spent)
                    l.importIncomes(plan.entries.length - spent),
                ], style: muted),
              ],
            ),
          ),
          if (cats.isNotEmpty) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Expanded(
                    child: Text(
                      l.importAdded,
                      style: AppText.label.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(l.importAddedInfo, style: muted),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(AppRadius.statTile),
              ),
              child: Column(
                children: [
                  for (final (i, c) in cats.indexed)
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        border: i < cats.length - 1
                            ? const Border(
                                bottom: BorderSide(
                                  color: AppColors.divider,
                                  width: AppStroke.hairline,
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        spacing: 12,
                        children: [
                          AppEmoji(c.emoji, size: 28),
                          Expanded(
                            child: Text(
                              c.name,
                              style: AppText.label.copyWith(fontSize: 15),
                            ),
                          ),
                          Text(l.importCount(c.count), style: muted),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (plan.dupes > 0 || plan.bad > 0) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: MetaLine([
                if (plan.dupes > 0) l.importDupes(plan.dupes),
                if (plan.bad > 0) l.importBad(plan.bad),
              ], style: muted),
            ),
          ],
          const Spacer(),
          const SizedBox(height: 18),
          PrimaryButton(
            label: l.importButton(plan.entries.length),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
  }
}

/// 02.4n / 02.4o: mist disc + title + sub, one button popping [result].
class _Message extends StatelessWidget {
  const _Message({
    required this.fileName,
    required this.icon,
    required this.title,
    required this.sub,
    required this.action,
    this.result,
  });

  final String fileName, title, sub, action;
  final List<List<dynamic>> icon;
  final bool? result;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SheetFrame(
      title: l.settingsImport,
      sub: fileName,
      titleSize: 22,
      height: 440,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 28),
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.mist,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  size: 28,
                  strokeWidth: AppStroke.icon,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.label.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Text(
                sub,
                textAlign: TextAlign.center,
                style: AppText.label.copyWith(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.muted,
                ),
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(height: 28),
          PrimaryButton(
            label: action,
            onPressed: () => Navigator.of(context).pop(result),
          ),
        ],
      ),
    );
  }
}
