import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/router.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_emoji.dart';
import '../../../core/widgets/meta_line.dart';
import '../../../core/widgets/tab_bar.dart';
import '../../budget/views/budget_sheet.dart';
import '../../categories/views/category_manage_sheet.dart';
import '../view_models/settings_view_model.dart';
import 'payday_sheet.dart';

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
                      hint: switch (s.paydayInfo.status) {
                        PaydayStatus.today => l.paydayToday,
                        PaydayStatus.late => l.paydayLate(
                          s.paydayInfo.lateDays,
                        ),
                        PaydayStatus.upcoming => l.paydayIn(
                          s.paydayInfo.daysLeft,
                        ),
                      },
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
                      hint: l.settingsHideHint,
                      switchOn: s.hideAmounts,
                      onTap: () => ref
                          .read(financeRepositoryProvider)
                          .setHideAmounts(!s.hideAmounts),
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

/// Ink card: budget bulanan + pencil → 00.16, chip → 02.2.
class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.budget,
    required this.limits,
    required this.onEdit,
    required this.onLimits,
  });

  final int? budget;
  final int limits;
  final VoidCallback onEdit, onLimits;

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
          Semantics(
            button: true,
            child: GestureDetector(
              onTap: onLimits,
              child: Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.onInk12,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  l.settingsLimits(limits),
                  style: AppText.caption.copyWith(color: AppColors.onInk),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A 60px row in a group card: icon disc, title (+ hint), then a trailing
/// value, chevron or switch ([switchOn] non-null).
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

class _Row extends StatelessWidget {
  const _Row({
    required this.icon,
    required this.title,
    required this.onTap,
    this.hint,
    this.trailing,
    this.chevron = true,
    this.switchOn,
  });

  final List<List<dynamic>> icon;
  final String title;
  final String? hint;
  final Widget? trailing;
  final bool chevron;
  final bool? switchOn;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final on = switchOn;
    return Semantics(
      button: on == null,
      toggled: on,
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
                      if (hint != null)
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
                if (on != null)
                  _Switch(on: on)
                else if (chevron)
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

class _Switch extends StatelessWidget {
  const _Switch({required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.select,
      width: 52,
      height: 32,
      padding: const EdgeInsets.all(3),
      alignment: on ? Alignment.centerRight : Alignment.centerLeft,
      decoration: BoxDecoration(
        color: on ? AppColors.ink : AppColors.pressed,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 26,
        height: 26,
        decoration: const BoxDecoration(
          color: AppColors.paper,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
