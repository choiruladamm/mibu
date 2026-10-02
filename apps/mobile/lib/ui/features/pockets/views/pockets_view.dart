import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/router.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/tab_bar.dart';
import '../../budget/views/budget_sheet.dart';
import '../view_models/pockets_view_model.dart';

/// 02.2 kantong. Isi ulang and impian are post-MVP.
class PocketsView extends ConsumerWidget {
  const PocketsView({super.key});

  static final _monthFull = DateFormat.MMMM('id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PocketsState s;
    switch (ref.watch(pocketsScreenProvider)) {
      case AsyncData(:final value):
        s = value;
      case AsyncError(:final error):
        // ponytail: no error state in the design yet; plain text for now.
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.gutter),
              child: Text('$error', style: AppText.caption),
            ),
          ),
        );
      default:
        return const Scaffold();
    }
    final l = AppLocalizations.of(context)!;
    final muted = AppText.label.copyWith(fontSize: 14, color: AppColors.muted);
    final selected = s.selected;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              0,
              AppSpace.gutter,
              AppSpace.tabBarClearance,
            ),
            child: SafeArea(
              bottom: false,
              minimum: const EdgeInsets.only(top: AppSpace.contentTop),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(l.tabPockets, style: AppText.title),
                        ),
                      ),
                      _NewButton(label: l.pocketsNew, onTap: () {}), // → 03.4
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l.pocketsLeftTitle(
                            _monthFull.format(s.month).toLowerCase(),
                          ),
                          style: muted,
                        ),
                      ),
                      _DaysChip(l.pocketsDaysLeft(s.daysLeft)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _Amount(s.left),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _BudgetLine(
                      state: s,
                      onTap: () => editBudget(context, ref),
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (selected == null)
                    Text(l.pocketsEmpty, style: muted)
                  else ...[
                    _Jars(
                      pockets: s.pockets,
                      selected: selected,
                      onSelect: ref
                          .read(selectedPocketProvider.notifier)
                          .select,
                    ),
                    const SizedBox(height: 18),
                    _Detail(pocket: selected, daysLeft: s.daysLeft),
                  ],
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AppTabBar(
              active: AppTab.pockets,
              onSelect: (tab) => goTab(context, tab),
              onAdd: () => context.push(Routes.addEntry),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaysChip extends StatelessWidget {
  const _DaysChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        text,
        style: AppText.caption.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// "Rp2,34jt dari Rp7,4jt kepake · budget Rp8jt ›" — opens 00.16.
class _BudgetLine extends StatelessWidget {
  const _BudgetLine({required this.state, required this.onTap});

  final PocketsState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final budget = state.budget;
    final muted = AppText.label.copyWith(fontSize: 14, color: AppColors.muted);
    return Transform.translate(
      offset: const Offset(-8, 0),
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      text: l.pocketsSpentOf(
                        rupiahCompact(state.spent),
                        rupiahCompact(state.limit),
                      ),
                      children: [
                        TextSpan(
                          text: budget == null
                              ? l.pocketsSetBudget
                              : l.pocketsBudget(rupiahCompact(budget)),
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: budget == null
                                ? FontWeight.w600
                                : FontWeight.w400,
                            decoration: budget == null
                                ? TextDecoration.underline
                                : null,
                            decorationColor: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                ),
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 14,
                  strokeWidth: AppStroke.iconOnInkSmall,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewButton extends StatelessWidget {
  const _NewButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.only(left: 12, right: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.ink, width: AppStroke.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                size: 16,
                strokeWidth: AppStroke.iconOnInkSmall,
                color: AppColors.ink,
              ),
              Text(label, style: AppText.label.copyWith(fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero "Rp 5.060.000", long values shrink.
class _Amount extends StatelessWidget {
  const _Amount(this.value);

  final int value;

  @override
  Widget build(BuildContext context) {
    final rp = AppText.sheetTitle.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: AppColors.muted,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(value < 0 ? '-Rp' : 'Rp', style: rp),
          ),
          Text(
            rupiah(value.abs()).replaceFirst('Rp', ''),
            style: AppText.display.copyWith(height: 1),
          ),
        ],
      ),
    );
  }
}

/// Toples per kantong: fill = % kepake.
class _Jars extends StatelessWidget {
  const _Jars({
    required this.pockets,
    required this.selected,
    required this.onSelect,
  });

  static const _width = 50.0;

  final List<Pocket> pockets;
  final Pocket selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, box) {
        // Spread like the design; scroll sideways once they don't fit.
        final n = pockets.length;
        final gap = n < 2
            ? 0.0
            : ((box.maxWidth - n * _width) / (n - 1)).clamp(12.0, 80.0);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            spacing: gap,
            children: [
              for (final p in pockets)
                _Jar(
                  pocket: p,
                  on: p.id == selected.id,
                  label: l.pocketJarLabel(p.name, p.usedPct),
                  onTap: () => onSelect(p.id),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Jar extends StatelessWidget {
  const _Jar({
    required this.pocket,
    required this.on,
    required this.label,
    required this.onTap,
  });

  final Pocket pocket;
  final bool on;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const w = _Jars._width, h = 176.0;
    return Semantics(
      button: true,
      selected: on,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          spacing: 8,
          children: [
            Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(w / 2),
                boxShadow: on
                    ? const [
                        BoxShadow(color: AppColors.ink, spreadRadius: 4.5),
                        BoxShadow(color: AppColors.paper, spreadRadius: 3),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: AppMotion.fill,
                      curve: AppMotion.ease,
                      width: w,
                      height: h * (pocket.usedPct.clamp(0, 100) / 100),
                      color: AppColors.ink,
                    ),
                  ),
                  Positioned(
                    left: 7,
                    top: 7,
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.paper,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        pocket.emoji,
                        style: const TextStyle(fontSize: 19),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${pocket.usedPct}%',
              style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu kantong yang dipilih.
class _Detail extends StatelessWidget {
  const _Detail({required this.pocket, required this.daysLeft});

  final Pocket pocket;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final muted = AppText.label.copyWith(fontSize: 14, color: AppColors.muted);
    final (status, ink) = switch (pocket.status) {
      PocketStatus.safe => (l.pocketStatusSafe, false),
      PocketStatus.almostOut => (l.pocketStatusAlmostOut, true),
      PocketStatus.unused => (l.pocketStatusUnused, false),
    };
    final left = pocket.left;

    return Semantics(
      container: true,
      label: l.pocketSelected,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.groupCard),
          border: Border.all(color: AppColors.ink, width: AppStroke.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Row(
              spacing: 8,
              children: [
                Text(pocket.emoji, style: const TextStyle(fontSize: 20)),
                Expanded(
                  child: Text(
                    pocket.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ink ? AppColors.ink : AppColors.paper,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: ink
                        ? null
                        : Border.all(
                            color: AppColors.ink,
                            width: AppStroke.outline,
                          ),
                  ),
                  child: Text(
                    status,
                    style: AppText.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: ink ? AppColors.paper : AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              spacing: 8,
              children: [
                Text(
                  rupiahCompact(left),
                  style: AppText.headline.copyWith(
                    fontSize: 36,
                    height: 1,
                    letterSpacing: -1.08,
                  ),
                ),
                Flexible(
                  child: Text(
                    l.pocketLeftOf(rupiahCompact(pocket.budget)),
                    style: muted,
                  ),
                ),
              ],
            ),
            Text(
              left < 0
                  ? l.pocketOver(rupiahCompact(-left))
                  : l.pocketDaily(rupiahCompact(left ~/ daysLeft), daysLeft),
              style: muted,
            ),
            const SizedBox(height: 2),
            _OutlineButton(label: l.pocketManage, onTap: () {}), // → 03.5
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: AppSpace.minTouch,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.ink, width: AppStroke.outline),
          ),
          child: Text(
            label,
            style: AppText.label.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
