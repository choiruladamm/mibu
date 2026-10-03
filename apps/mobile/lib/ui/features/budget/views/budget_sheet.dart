import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/amount.dart';
import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/amount_keypad.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/finance_providers.dart';

/// Opens 00.16 and applies the result: saved → toast, hapus → toast with
/// batalin. Entry points: 02.2 hero, 00.15 PocketLimit, 02.3, 02.4.
Future<void> editBudget(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context)!;
  final repo = ref.read(financeRepositoryProvider);
  final period = ref.read(currentPeriodProvider);
  final prev = ref.read(profileProvider).value?.monthlyBudget;
  final total = [...?ref.read(pocketsProvider).value]
      .fold(0, (sum, p) => sum + p.limit);
  // A hint from what was really spent, never from income.
  final last = ref.read(periodsProvider).prev(period).key;
  final lastSpent = ref.read(totalsProvider).value?.spent[last];

  final v = await showAppSheet<int>(
    context,
    BudgetSheet(budget: prev, pocketsTotal: total, lastSpent: lastSpent),
    enableDrag: false,
  );
  if (v == null || !context.mounted) return;
  if (v == 0) {
    await repo.setMonthlyBudget(null, period);
    if (!context.mounted) return;
    showToast(
      context,
      icon: ToastIcon.trash,
      title: l.budgetDeletedTitle,
      sub: l.budgetDeletedSub,
      onUndo: () => repo.setMonthlyBudget(prev, period),
    );
  } else {
    await repo.setMonthlyBudget(v, period);
    if (!context.mounted) return;
    showToast(
      context,
      icon: ToastIcon.check,
      title: l.budgetSavedTitle(rupiahCompact(v)),
      sub: l.budgetSavedSub,
    );
  }
}

/// 00.16 budget bulanan. Pops the new budget, 0 for "hapus budget", or
/// null when closed.
class BudgetSheet extends StatefulWidget {
  const BudgetSheet({
    super.key,
    required this.budget,
    required this.pocketsTotal,
    this.lastSpent,
  });

  final int? budget; // null = not set → prefill from the pockets
  final int pocketsTotal; // Σ pocket limits
  final int? lastSpent; // spent last period; null = nothing logged then

  @override
  State<BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends State<BudgetSheet> {
  static const _maxDigits = 12;

  bool get _edit => (widget.budget ?? 0) > 0;

  late AmountDraft _draft = (
    parts: const [],
    digits: '${_edit ? widget.budget : budgetPrefill(widget.pocketsTotal)}'
        .replaceFirst(RegExp('^0+'), ''),
  );
  bool _fresh = true; // first key replaces the prefilled value

  void _set(AmountDraft d) => setState(() {
    _draft = d;
    _fresh = false;
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final v = draftTotal(_draft);
    final total = rupiahCompact(widget.pocketsTotal);
    final short = v > 0 && v < widget.pocketsTotal;

    return SheetFrame(
      title: l.budgetTitle,
      height: 640,
      scrollable: false, // the keypad stays pinned; the top scrolls
      handleDrag: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.budgetSub,
                    style: AppText.label.copyWith(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                  if (widget.lastSpent case final spent? when spent > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      l.budgetLastSpent(rupiahCompact(spent)),
                      style: AppText.caption.copyWith(color: AppColors.muted),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _AmountField(
                      label: _edit ? l.budgetLabelNow : l.budgetLabelSuggest,
                      hint: !_edit && _fresh && v > 0 ? l.budgetAutoFilled : '',
                      value: v,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(minHeight: 36),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.mist,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    // total limit left · ketik / belum dijatah / kurang right.
                    child: Semantics(
                      liveRegion: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        spacing: 8,
                        children: [
                          Flexible(
                            child: Text(
                              l.budgetInfoTotal(total),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              v == 0
                                  ? l.budgetInfoType
                                  : short
                                  ? l.budgetInfoShort(
                                      rupiahCompact(widget.pocketsTotal - v),
                                    )
                                  : l.limitFree(
                                      rupiahCompact(v - widget.pocketsTotal),
                                    ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: AppText.caption.copyWith(
                                fontWeight: short
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: short ? AppColors.ink : AppColors.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          AmountKeypad(
            variant: KeypadVariant.budget,
            onKey: (k) => _set(
              draftPress(
                _fresh ? emptyDraft : _draft,
                k,
                maxDigits: _maxDigits,
              ),
            ),
            onBackspace: () => _set(draftBack(_draft)),
            onClear: () => _set(emptyDraft),
            onSave: () => Navigator.of(context).pop(v),
            saveLabel: v == 0
                ? l.budgetFillFirst
                : l.budgetPerMonth(rupiahCompact(v)),
            canClear: !draftIsEmpty(_draft),
            canSave: v > 0,
          ),
          if (_edit)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(0),
                style: TextButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSpace.minTouch),
                  foregroundColor: AppColors.ink,
                ),
                child: Text(
                  l.budgetDelete,
                  style: AppText.label.copyWith(
                    fontSize: 15,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.ink,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 00.10 AmountField, display only (the keypad types). Shrinks
/// 56 → 48 → 40 → 32 so 12 digits fit.
class _AmountField extends StatelessWidget {
  const _AmountField({
    required this.label,
    required this.hint,
    required this.value,
  });

  final String label, hint;
  final int value;

  @override
  Widget build(BuildContext context) {
    final shown = value == 0 ? '0' : rupiah(value).replaceFirst('Rp', '');
    final n = shown.length;
    final size = n > 14
        ? 32.0
        : n > 11
        ? 40.0
        : n > 9
        ? 48.0
        : 56.0;
    final caption = AppText.caption.copyWith(color: AppColors.muted);
    return Semantics(
      label: label,
      value: 'Rp$shown',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 8,
              children: [
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: caption,
                  ),
                ),
                Text(hint, style: caption),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 78,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.ink,
                  width: AppStroke.outline,
                ),
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                spacing: 4,
                children: [
                  Text(
                    'Rp',
                    style: AppText.label.copyWith(
                      fontSize: size > 48
                          ? 26
                          : size > 32
                          ? 22
                          : 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.muted,
                    ),
                  ),
                  Text(
                    shown,
                    style: AppText.displayXl.copyWith(
                      fontSize: size,
                      height: 1,
                      color: value == 0 ? AppColors.grey400 : AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
