import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/finance_providers.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_emoji.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/toast.dart';

/// 99.5 sembunyiin nominal: 3 choices → save → toast with batalin.
Future<void> editHideAmounts(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(financeRepositoryProvider);
  final saved =
      ref.read(profileProvider).value?.hideAmounts ?? HideAmounts.none;
  final pick = await showAppSheet<HideAmounts>(
    context,
    _HideSheet(saved: saved),
  );
  if (pick == null || pick == saved || !context.mounted) return;
  await repo.setHideAmounts(pick);
  if (!context.mounted) return;
  final l = AppLocalizations.of(context)!;
  showToast(
    context,
    icon: ToastIcon.check,
    title: switch (pick) {
      HideAmounts.none => l.hideToastNone,
      HideAmounts.income => l.hideToastIncome,
      HideAmounts.all => l.hideToastAll,
    },
    sub: switch (pick) {
      HideAmounts.none => l.hideToastNoneSub,
      HideAmounts.income => l.hideToastIncomeSub,
      HideAmounts.all => l.hideToastAllSub,
    },
    onUndo: () => repo.setHideAmounts(saved),
  );
}

String hideLabel(AppLocalizations l, HideAmounts h) => switch (h) {
  HideAmounts.none => l.hideNone,
  HideAmounts.income => l.hideIncome,
  HideAmounts.all => l.hideAll,
};

class _HideSheet extends StatefulWidget {
  const _HideSheet({required this.saved});

  final HideAmounts saved;

  @override
  State<_HideSheet> createState() => _HideSheetState();
}

class _HideSheetState extends State<_HideSheet> {
  late HideAmounts _sel = widget.saved;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final muted = AppText.caption.copyWith(color: AppColors.muted);
    final row = AppText.label.copyWith(fontSize: 15);
    // Live example: the picked mode applied to three made-up rows.
    final examples = [
      ('💰', l.hideExSalary, 20000000),
      ('🍜', l.hideExFood, -25000),
      ('🛵', l.hideExRide, -35000),
    ];
    return SheetFrame(
      title: l.settingsHide,
      sub: l.hideSheetSub,
      height: 700,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 18),
          for (final h in HideAmounts.values) ...[
            _Option(
              label: hideLabel(l, h),
              sub: switch (h) {
                HideAmounts.none => l.hideNoneSub,
                HideAmounts.income => l.hideIncomeSub,
                HideAmounts.all => l.hideAllSub,
              },
              isNew: h == HideAmounts.income,
              selected: h == _sel,
              onTap: () => setState(() => _sel = h),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(AppRadius.statTile),
            ),
            child: AmountMask(
              hide: _sel,
              child: Builder(
                builder: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(l.hideExample, style: muted.copyWith(fontSize: 12)),
                    for (final (i, (emoji, name, v)) in examples.indexed)
                      Container(
                        height: AppSpace.row,
                        decoration: BoxDecoration(
                          border: i < examples.length - 1
                              ? const Border(
                                  bottom: BorderSide(
                                    color: AppColors.divider,
                                    width: AppStroke.hairline,
                                  ),
                                )
                              : null,
                        ),
                        child: Row(
                          spacing: 10,
                          children: [
                            AppEmoji(emoji, size: 24),
                            Expanded(child: Text(name, style: row)),
                            Text(
                              context.rpSigned(v, income: v > 0),
                              style: row.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              _sel == HideAmounts.none ? l.hideLaterNote : l.hidePeekNote,
              style: muted,
            ),
          ),
          const Spacer(),
          const SizedBox(height: 18),
          PrimaryButton(
            label: _sel == widget.saved ? l.hideOk : l.hideSave,
            onPressed: () => Navigator.of(context).pop(_sel),
          ),
        ],
      ),
    );
  }
}

/// A radio card: picked = paper + ink ring, dot filled ink.
class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.sub,
    required this.isNew,
    required this.selected,
    required this.onTap,
  });

  final String label, sub;
  final bool isNew, selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.select,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: selected ? AppColors.paper : AppColors.mist,
            borderRadius: BorderRadius.circular(AppRadius.statTile),
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.mist,
              width: AppStroke.outline,
            ),
          ),
          child: Row(
            spacing: 12,
            children: [
              AnimatedContainer(
                duration: AppMotion.select,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? AppColors.ink : AppColors.grey400,
                    width: selected ? 7 : AppStroke.outline,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Row(
                      spacing: 6,
                      children: [
                        Text(
                          label,
                          style: AppText.label.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (isNew)
                          Container(
                            height: 18,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              l.hideNew,
                              style: AppText.micro.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.paper,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      sub,
                      style: AppText.caption.copyWith(
                        color: AppColors.muted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
