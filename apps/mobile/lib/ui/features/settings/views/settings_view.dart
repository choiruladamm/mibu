import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/finance.dart';
import '../../../../domain/period.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/router.dart';
import '../../../core/dates.dart';
import '../../../core/finance_providers.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_emoji.dart';
import '../../../core/widgets/meta_line.dart';
import '../../../core/widgets/tab_bar.dart';
import '../../budget/views/budget_sheet.dart';
import '../../categories/views/category_manage_sheet.dart';
import '../view_models/settings_view_model.dart';
import 'hide_sheet.dart';
import 'payday_sheet.dart';

final _payDay = DateFormat('EEE d MMM', 'id');

/// 02.4 pengaturan. Reminder, rekap, face id, mode and backup are post-MVP.
class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider).value;
    if (s == null) return const Scaffold();
    final l = AppLocalizations.of(context)!;
    final version = ref.watch(appVersionProvider).value;

    Widget section(String title, List<Widget> rows) => Padding(
      padding: const EdgeInsets.only(
        top: AppSpace.section - 4,
        left: AppSpace.gutter,
        right: AppSpace.gutter,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 10,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              title,
              style: AppText.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(AppRadius.groupCard),
            ),
            child: Column(
              children: [
                for (final (i, r) in rows.indexed) ...[
                  if (i > 0)
                    const Divider(
                      height: AppStroke.hairline,
                      thickness: AppStroke.hairline,
                      indent: 64,
                      color: AppColors.divider,
                    ),
                  r,
                ],
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpace.tabBarClearance),
            child: SafeArea(
              bottom: false,
              minimum: const EdgeInsets.only(top: AppSpace.contentTop),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.gutter,
                    ),
                    child: Semantics(
                      header: true,
                      child: Text(l.tabSettings, style: AppText.title),
                    ),
                  ),
                  _BudgetCard(
                    budget: s.budget,
                    limits: s.limits,
                    period: ref.watch(currentPeriodProvider),
                    onPeriod: () => editPayday(context, ref),
                    onEdit: () => editBudget(context, ref),
                    onLimits: () => context.go(Routes.pockets),
                  ),
                  section(l.settingsMoney, [
                    _Row(
                      icon: HugeIcons.strokeRoundedTag01,
                      title: l.settingsCategories,
                      hint: l.settingsCategoriesHint,
                      trailing: _IconStack(
                        icons: s.topIcons,
                        more: s.moreCategories,
                      ),
                      onTap: () => showCategoryManage(context),
                    ),
                    _Row(
                      icon: HugeIcons.strokeRoundedWallet01,
                      title: l.settingsLimitMonthly,
                      trailing: Text.rich(
                        TextSpan(
                          children: MetaLine.join([
                            TextSpan(text: l.settingsLimits(s.limits)),
                            if (s.limits > 0)
                              TextSpan(text: context.rpCompact(s.limitTotal)),
                          ]),
                        ),
                      ),
                      onTap: () => context.go(Routes.pockets),
                    ),
                    _Row(
                      icon: HugeIcons.strokeRoundedMoney01,
                      title: l.settingsPayday,
                      // The date is shown because a weekend payday moves to the
                      // Friday before: "tiap tgl 25" alone would look miscounted.
                      hint: switch (s.paydayInfo.status) {
                        PaydayStatus.today => l.paydayToday,
                        PaydayStatus.late => l.paydayLate(
                          s.paydayInfo.lateDays,
                        ),
                        PaydayStatus.upcoming => null,
                      },
                      hintParts: s.paydayInfo.status == PaydayStatus.upcoming
                          ? [
                              _payDay.format(s.paydayInfo.next).toLowerCase(),
                              l.paydayNextIn(s.paydayInfo.daysLeft),
                            ]
                          : null,
                      trailing: Text(
                        s.payday == 31
                            ? l.settingsPaydayEnd
                            : l.settingsPaydayEvery(s.payday),
                      ),
                      onTap: () => editPayday(context, ref),
                    ),
                  ]),
                  section(l.settingsPrivacy, [
                    _Row(
                      icon: HugeIcons.strokeRoundedViewOffSlash,
                      title: l.settingsHide,
                      hint: hideLabel(l, s.hideAmounts),
                      onTap: () => editHideAmounts(context, ref),
                    ),
                  ]),
                  section(l.settingsData, [
                    _Row(
                      icon: HugeIcons.strokeRoundedDownload04,
                      title: l.settingsExport,
                      hint: l.settingsExportHint,
                      chevron: true,
                      onTap: () => exportCsv(ref),
                    ),
                  ]),
                  const SizedBox(height: AppSpace.section),
                  Column(
                    spacing: 4,
                    children: [
                      Text(l.appTitle, style: AppText.wordmark(24)),
                      // Licenses (Fluent Emoji is MIT: its notice lives here).
                      if (version != null)
                        Semantics(
                          button: true,
                          label: l.settingsLicenses,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => showLicensePage(
                              context: context,
                              applicationName: l.appTitle,
                              applicationVersion: version,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: MetaLine(
                                [
                                  l.settingsVersion(version),
                                  l.settingsLicenses,
                                ],
                                style: AppText.caption.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AppTabBar(
              active: AppTab.settings,
              onSelect: (tab) => goTab(context, tab),
              onAdd: () => context.push(Routes.addEntry),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ink card: budget per periode + pencil → 00.16; chips: the running
/// period → tanggal gajian 00.24 (it sets the period), n kantong → 02.2.
class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.limits,
    required this.period,
    required this.onPeriod,
    required this.onEdit,
    required this.onLimits,
  });

  final int? budget;
  final int limits;
  final Period period;
  final VoidCallback onPeriod, onEdit, onLimits;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final set = budget != null;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpace.cardInset,
        AppSpace.s20,
        AppSpace.cardInset,
        0,
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.inkCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Text(
                      l.settingsBudget,
                      style: AppText.caption.copyWith(
                        color: AppColors.onInkMuted,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      spacing: 6,
                      children: [
                        Flexible(
                          child: Text(
                            !set
                                ? l.settingsBudgetEmpty
                                : context.rpCompact(budget!),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: (set ? AppText.displayS : AppText.title)
                                .copyWith(color: AppColors.onInk, height: 1),
                          ),
                        ),
                        if (set)
                          Text(
                            l.settingsBudgetUnit,
                            style: AppText.label.copyWith(
                              color: AppColors.onInkMuted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Semantics(
                button: true,
                label: set ? l.settingsBudgetEdit : l.settingsBudgetSet,
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: onEdit,
                  child: Container(
                    width: AppSpace.minTouch,
                    height: AppSpace.minTouch,
                    decoration: const BoxDecoration(
                      color: AppColors.paper,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedPencilEdit02,
                        size: 20,
                        strokeWidth: AppStroke.icon,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            spacing: 8,
            children: [
              Flexible(
                child: _chip(
                  l.settingsPeriod(periodRange(period.start, period.end)),
                  onPeriod,
                ),
              ),
              _chip(l.settingsLimits(limits), onLimits),
            ],
          ),
        ],
      ),
    );
  }
}

/// A translucent pill on the budget card.
Widget _chip(String label, VoidCallback onTap) => Semantics(
  button: true,
  child: GestureDetector(
    onTap: onTap,
    child: Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.onInk12,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.caption.copyWith(color: AppColors.onInk),
      ),
    ),
  ),
);

/// "buat apa aja" trailing: the 3 most used icons overlapping, then "+8".
class _IconStack extends StatelessWidget {
  const _IconStack({required this.icons, required this.more});

  final List<String> icons;
  final int more;

  static const _size = 28.0, _overlap = 8.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        if (icons.isNotEmpty)
          ExcludeSemantics(
            child: SizedBox(
              width: _size + (_size - _overlap) * (icons.length - 1),
              height: _size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final (i, e) in icons.indexed)
                    Positioned(
                      left: i * (_size - _overlap),
                      child: Container(
                        width: _size,
                        height: _size,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.paper,
                          shape: BoxShape.circle,
                          // Ring in the card's own mist so they read as stacked.
                          boxShadow: [
                            BoxShadow(color: AppColors.mist, spreadRadius: 2),
                          ],
                        ),
                        child: AppEmoji(e, size: 20),
                      ),
                    ),
                ],
              ),
            ),
          ),
        if (more > 0) Text(l.settingsCategoriesMore(more)),
      ],
    );
  }
}

/// A 60px row in a group card: icon disc, title (+ hint), then a trailing
/// value and/or chevron.
class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.onTap,
    this.hint,
    this.hintParts,
    this.trailing,
    this.chevron = true,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String? hint;
  final List<String>? hintParts; // hint as a MetaLine (dot-separated)
  final Widget? trailing;
  final bool chevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: AppSpace.settingsRow,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.s16),
            child: Row(
              spacing: 12,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.paper,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: icon,
                      size: 20,
                      strokeWidth: AppStroke.icon,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 1,
                    children: [
                      Text(title, style: AppText.label),
                      if (hintParts case final parts?)
                        MetaLine(
                          parts,
                          tight: true,
                          style: AppText.caption.copyWith(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        )
                      else if (hint != null)
                        Text(
                          hint!,
                          style: AppText.caption.copyWith(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing != null)
                  DefaultTextStyle(
                    style: AppText.label.copyWith(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                    child: trailing!,
                  ),
                if (chevron)
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    size: 18,
                    strokeWidth: AppStroke.icon,
                    color: AppColors.subtle,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
