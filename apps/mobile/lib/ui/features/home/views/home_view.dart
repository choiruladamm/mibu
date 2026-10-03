import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/router.dart';
import '../../../core/clock.dart';
import '../../../core/dashed.dart';
import '../../../core/dates.dart';
import '../../../core/finance_providers.dart';
import '../../../core/money.dart';
import '../../../core/widgets/peek_tap.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/month_menu.dart';
import '../../../core/widgets/month_picker.dart';
import '../../../core/widgets/tab_bar.dart';
import '../../../core/widgets/tx_row.dart';
import '../../transactions/view_models/transactions_view_model.dart';
import '../view_models/home_view_model.dart';
import '../../budget/views/budget_sheet.dart';
import '../../../core/widgets/info_dialog.dart';
import '../../../core/widgets/meta_line.dart';
import '../../../core/widgets/app_emoji.dart';

final _monthFull = DateFormat.MMMM('id');
final _dayTitle = DateFormat('EEE d MMM', 'id');

String _name(DateTime m) => _monthFull.format(m).toLowerCase();

/// 02.1 beranda.
class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  /// Scrolled past the hero → 02.1b compact header.
  static const _stickyAt = 140.0;

  final _scroll = ScrollController();
  final _sticky = ValueNotifier(false);
  bool _menuOpen = false;

  /// Last loaded state: shown while a newly picked month's rows load, so the
  /// screen never blanks (and the scroll position survives) between months.
  HomeState? _last;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(
      () => _sticky.value = _scroll.hasClients && _scroll.offset > _stickyAt,
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _sticky.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final HomeState s;
    switch (ref.watch(homeProvider)) {
      case AsyncData(:final value):
        s = _last = value;
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
        final last = _last;
        if (last == null) return const Scaffold();
        s = last;
    }
    final l = AppLocalizations.of(context)!;
    final now = ref.watch(nowProvider);
    final caption = AppText.caption.copyWith(color: AppColors.muted);
    final safeTop = MediaQuery.paddingOf(context).top;
    final top = math.max(safeTop, AppSpace.contentTop);
    final stickyTop = math.max(safeTop, AppSpace.contentTop - 4);
    final label =
        _name(s.selected) +
        (s.selected.year != now.year ? ' ${s.selected.year}' : '');
    final hero = _hero(s, l);
    void toggleMenu() => setState(() => _menuOpen = !_menuOpen);
    Widget picker() =>
        MonthPicker(label: label, open: _menuOpen, onTap: toggleMenu);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.only(bottom: AppSpace.tabBarClearance),
            child: SafeArea(
              bottom: false,
              minimum: const EdgeInsets.only(top: AppSpace.contentTop),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _gutter(
                    Row(
                      children: [
                        Text('mibu', style: AppText.wordmark(30)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: picker(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SearchButton(label: l.search, size: 44),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _Hero(
                    data: hero,
                    onInfo: () => _info(s, l),
                    onSetBudget: () => editBudget(context, ref),
                  ),
                  const SizedBox(height: 18),
                  _gutter(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(l.homeMonthlyBalance, style: caption),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            l.homeTapMonthHint,
                            style: caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (ref.watch(homeChartProvider) case final chart?)
                    _BalanceChart(
                      chart: chart,
                      onSelect: ref.read(homeMonthProvider.notifier).select,
                    )
                  else
                    const SizedBox(height: _BalanceChart._height),
                  const SizedBox(height: 22),
                  _gutter(
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        // Section title: title left, info right, no dot.
                        Flexible(
                          child: Text(
                            l.homePockets,
                            style: AppText.label.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => goTab(context, AppTab.pockets),
                          child: Row(
                            spacing: 2,
                            children: [
                              Text(l.seeAll, style: caption),
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedArrowRight01,
                                size: 14,
                                strokeWidth: AppStroke.iconOnInkSmall,
                                color: AppColors.muted,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Swap(
                    id: s.month,
                    child: s.pockets.isEmpty
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: _PocketPills(pockets: s.pockets),
                          ),
                  ),
                  _Swap(
                    id: (s.month, s.noEntries),
                    child: s.noEntries ? const _NoEntries() : _Recent(state: s),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AppTabBar(
              active: AppTab.home,
              onSelect: (tab) => goTab(context, tab),
              onAdd: () => context.push(Routes.addEntry),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: ValueListenableBuilder(
              valueListenable: _sticky,
              builder: (context, on, _) => AnimatedSwitcher(
                duration: AppMotion.select,
                child: on
                    ? Container(
                        key: const ValueKey('sticky'),
                        height: stickyTop + 40 + 16,
                        padding: EdgeInsets.fromLTRB(
                          AppSpace.gutter,
                          stickyTop,
                          AppSpace.gutter,
                          0,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xF5FFFFFF), // paper 96%
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.divider,
                              width: AppStroke.hairline,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      hero.label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppText.micro.copyWith(
                                        color: AppColors.muted,
                                      ),
                                    ),
                                    Text(
                                      context.rpCompact(hero.amount),
                                      maxLines: 1,
                                      style: AppText.label.copyWith(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            picker(),
                            const SizedBox(width: 8),
                            _SearchButton(label: l.search, size: 40),
                          ],
                        ),
                      )
                    : const SizedBox(
                        key: ValueKey('hero'),
                        width: double.infinity,
                      ),
              ),
            ),
          ),
          if (_menuOpen) ...[
            Positioned.fill(
              child: Semantics(
                button: true,
                label: l.close,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: toggleMenu,
                ),
              ),
            ),
            // Right edge lines up with the picker: gutter + search + gap.
            Positioned(
              right: AppSpace.gutter + 44 + 8,
              top: (_sticky.value ? stickyTop + 40 : top + 44) + 8,
              child: Consumer(
                builder: (context, ref, _) => MonthMenu(
                  selected: s.selected,
                  now: ref.watch(currentMonthProvider),
                  spent: ref.watch(totalsProvider).value?.spent ?? const {},
                  onPick: (month) {
                    ref.read(homeMonthProvider.notifier).select(month);
                    setState(() => _menuOpen = false);
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// "?" next to the hero's small line: how sisa budget and aman jajan are
  /// worked out, with this user's numbers.
  void _info(HomeState s, AppLocalizations l) {
    final rp = context.rpCompact;
    final left = s.budgetLeft;
    showNumbersInfo(
      context,
      lines: [
        (
          title: l.infoBudgetTitle,
          body: left == null
              ? l.infoBudgetNone
              : left < 0
              ? l.infoBudgetBodyOver(
                  rp(s.budget ?? 0),
                  rp(s.monthSpent),
                  rp(-left),
                )
              : l.infoBudgetBody(rp(s.budget ?? 0), rp(s.monthSpent), rp(left)),
        ),
        if (s.isCurrent && s.safe != null)
          (
            title: l.infoSafeTitle,
            body: l.infoSafeBody(s.budgetDaysLeft, rp(s.safe!)),
          ),
      ],
    );
  }

  /// What the hero shows for [s]: label, amount, the small line under it and
  /// the chip (02.1p, 00.23b). Sisa budget; without a budget, what's been
  /// spent and a nudge to set one (docs/PERIOD_LEDGER_PLAN.md).
  _HeroData _hero(HomeState s, AppLocalizations l) {
    final month = _name(s.month);
    final left = s.budgetLeft;
    final negative = (left ?? 0) < 0;

    // label + amount
    final String label;
    final int amount;
    if (left != null) {
      label = s.isCurrent
          ? (negative ? l.heroBudgetOver : l.heroBudgetLeft)
          : (negative
                ? l.heroBudgetOverEnd(month)
                : l.heroBudgetLeftEnd(month));
      amount = left.abs();
    } else {
      label = s.isCurrent ? l.heroSpent : l.heroSpentEnd(month);
      amount = s.monthSpent;
    }

    // small line
    String sub;
    var warn = false;
    if (!s.isCurrent && s.budget != null) {
      sub = l.heroFromBudget(context.rpCompact(s.budget!));
    } else if (!s.isCurrent) {
      // The period's last day (it ends the day before the next payday).
      final last = DateTime(
        s.period.end.year,
        s.period.end.month,
        s.period.end.day - 1,
      );
      sub = l.heroPer(last.day, _monthShort.format(last).toLowerCase());
    } else if (s.overBudget) {
      sub = l.heroBudgetOverSub(context.rpCompact(-(left ?? 0)));
      warn = true;
    } else {
      switch (s.payday.status) {
        case PaydayStatus.today:
          sub = l.paydayToday;
        case PaydayStatus.late:
          sub = l.paydayLate(s.payday.lateDays);
          warn = true;
        case PaydayStatus.upcoming:
          sub = l.paydayIn(s.payday.daysLeft);
      }
    }

    // chip: aman jajan, or what to do instead
    _ChipData? chip;
    if (!s.isCurrent) {
      final avg = (s.monthSpent / s.periodDays / 1000).round() * 1000;
      chip = (
        text: l.heroAvgDay,
        value: context.rpCompact(avg),
        icon: _ChipIcon.tick,
        outline: false,
        onTap: () => goTab(context, AppTab.stats),
      );
    } else if (s.payday.status == PaydayStatus.today ||
        s.payday.status == PaydayStatus.late) {
      // Days left is 0 here: no division, ask for the salary instead.
      chip = (
        text: s.payday.status == PaydayStatus.today
            ? l.heroCatatGajian
            : l.heroCatatGajianLate,
        value: null,
        icon: _ChipIcon.plus,
        outline: true,
        onTap: () => context.push(Routes.addEntry, extra: AddEntryStart.salary),
      );
    } else if (s.budget == null) {
      chip = (
        text: l.heroSetBudgetChip,
        value: null,
        icon: _ChipIcon.plus,
        outline: true,
        onTap: () => editBudget(context, ref),
      );
    } else if (s.overBudget) {
      chip = (
        text: l.heroRemDulu,
        value: l.heroDaysLeft(s.budgetDaysLeft),
        icon: _ChipIcon.alert,
        outline: true,
        onTap: () => goTab(context, AppTab.pockets),
      );
    } else {
      final safe = s.safeToSpendToday ?? 0;
      final over = safe < 0;
      chip = (
        text: over ? l.overspentToday : l.safeToSpendToday,
        value: context.rpCompact(safe.abs()),
        icon: over ? _ChipIcon.alert : _ChipIcon.tick,
        outline: false,
        onTap: () => goTab(context, AppTab.pockets),
      );
    }

    return (
      label: label,
      amount: amount,
      sub: sub,
      subWarn: warn,
      setBudget: s.budget == null && s.isCurrent,
      chip: chip,
    );
  }

  static Widget _gutter(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
    child: child,
  );
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () => context.push(Routes.search),
        child: Container(
          alignment: Alignment.center,
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: AppColors.mist,
            shape: BoxShape.circle,
          ),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedSearch01,
            size: size == 44 ? 20 : 18,
            strokeWidth: AppStroke.icon,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

enum _ChipIcon { tick, alert, plus }

typedef _ChipData = ({
  String text,
  String? value,
  _ChipIcon icon,
  bool outline, // ring instead of filled ink
  VoidCallback onTap,
});

typedef _HeroData = ({
  String label,
  int amount,
  String sub,
  bool subWarn, // "!" in front, ink
  bool setBudget, // "• pasang budget" link after the sub
  _ChipData? chip,
});

final _monthShort = DateFormat.MMM('id');

/// 02.1 hero (HeroSaldo 00.23b): label, amount, one small line, and the
/// chip.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.data,
    required this.onSetBudget,
    required this.onInfo,
  });

  final _HeroData data;
  final VoidCallback onSetBudget, onInfo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final label = _Swap(
      id: data.label,
      child: Text(
        data.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.label.copyWith(fontSize: 14, color: AppColors.muted),
      ),
    );
    return Column(
      children: [
        SizedBox(height: 32, child: Center(child: label)),
        const SizedBox(height: 8),
        // Long balances shrink instead of overflowing.
        _gutterFit(
          PeekTap(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    'Rp',
                    style: AppText.sheetTitle.copyWith(
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                // Counts from the old figure to the new one: after a swipe
                // between months and after the pill flips.
                TweenAnimationBuilder(
                  tween: IntTween(end: data.amount),
                  duration: AppMotion.fill,
                  curve: AppMotion.ease,
                  builder: (context, v, _) => Text(
                    context.rp(v).replaceFirst('Rp', ''),
                    style: AppText.display.copyWith(height: 1),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _Swap(
          id: (data.sub, data.setBudget),
          child: SizedBox(
            height: 28,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 6,
              children: [
                if (data.subWarn)
                  Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.ink,
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedAlert02,
                      size: 10,
                      strokeWidth: 2.4,
                      color: AppColors.paper,
                    ),
                  ),
                Flexible(
                  child: Text(
                    data.sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      color: data.subWarn ? AppColors.ink : AppColors.muted,
                    ),
                  ),
                ),
                InfoDisc(onTap: onInfo, target: 28),
                if (data.setBudget)
                  GestureDetector(
                    onTap: onSetBudget,
                    child: Row(
                      spacing: 6,
                      children: [
                        Container(
                          width: 3,
                          height: 3,
                          decoration: const BoxDecoration(
                            color: AppColors.onInkMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          l.heroSetBudget,
                          style: AppText.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        _Swap(
          id: data.chip?.text,
          child: switch (data.chip) {
            final c? => _chipPill(c),
            null => const SizedBox.shrink(),
          },
        ),
      ],
    );
  }

  /// Aman jajan, rata²/hari: filled ink + ✓. Rem dulu / catat gajian: ring +
  /// disc glyph. Tap goes where the number comes from.
  static Widget _chipPill(_ChipData chip) {
    final ink = chip.outline ? AppColors.paper : AppColors.ink;
    final fg = chip.outline ? AppColors.ink : AppColors.paper;
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: chip.onTap,
          child: Container(
            height: 34,
            padding: const EdgeInsets.only(left: 6, right: 14),
            decoration: BoxDecoration(
              color: ink == AppColors.paper ? AppColors.paper : AppColors.ink,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: chip.outline
                  ? Border.all(color: AppColors.ink, width: AppStroke.outline)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 8,
              children: [
                Container(
                  alignment: Alignment.center,
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: chip.outline ? AppColors.ink : AppColors.paper,
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: switch (chip.icon) {
                      _ChipIcon.tick => HugeIcons.strokeRoundedTick02,
                      _ChipIcon.alert => HugeIcons.strokeRoundedAlert02,
                      _ChipIcon.plus => HugeIcons.strokeRoundedAdd01,
                    },
                    size: 14,
                    strokeWidth: AppStroke.iconOnInkSmall,
                    color: chip.outline ? AppColors.paper : AppColors.ink,
                  ),
                ),
                Flexible(
                  child: MetaLine.rich(
                    [
                      TextSpan(text: chip.text),
                      if (chip.value case final v?)
                        TextSpan(
                          text: v,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                    ],
                    onInk: !chip.outline,
                    style: AppText.label.copyWith(fontSize: 14, color: fg),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Content that fades to its replacement when [id] changes while the height
/// follows the new child, so swapping months doesn't jump.
class _Swap extends StatelessWidget {
  const _Swap({required this.id, required this.child});

  final Object? id;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.select,
      curve: AppMotion.ease,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppMotion.select,
        // Only the new child sets the height; the old one fades out on top.
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [
            for (final p in previous)
              Positioned(top: 0, left: 0, right: 0, child: p),
            ?current,
          ],
        ),
        child: KeyedSubtree(key: ValueKey(id), child: child),
      ),
    );
  }
}

Widget _gutterFit(Widget child) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
  child: FittedBox(fit: BoxFit.scaleDown, child: child),
);

/// Pockets as a row of pills, most used first; > 4 scroll under a fade.
class _PocketPills extends StatelessWidget {
  const _PocketPills({required this.pockets});

  final List<Pocket> pockets;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
            itemCount: pockets.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final p = pockets[i];
              final ink = p.status.ink;
              return Semantics(
                button: true,
                label: l.homePocketPill(p.name, p.usedPct),
                excludeSemantics: true,
                child: GestureDetector(
                  onTap: () => context.go(Routes.pocketsAt(p.id)),
                  child: Container(
                    width: 76,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ink ? AppColors.ink : AppColors.mist,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: EmojiText(
                      '${p.emoji} ${p.usedPct}%',
                      emojiSize: 22,
                      style: AppText.label.copyWith(
                        fontSize: 14,
                        fontWeight: ink ? FontWeight.w600 : FontWeight.w400,
                        color: ink ? AppColors.paper : AppColors.ink,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          if (pockets.length > 4)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              width: 40,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.paper.withValues(alpha: 0),
                        AppColors.paper,
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// "baru aja" / "terakhir di {bulan}": latest 5 entries by day, then the
/// way into 04.1.
class _Recent extends ConsumerWidget {
  const _Recent({required this.state});

  final HomeState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final s = state;
    final month = _name(s.month);
    final muted = AppText.caption.copyWith(color: AppColors.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                s.isCurrent ? l.homeRecent : l.homeRecentIn(month),
                style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
              ),
              if (s.isCurrent)
                Text(
                  l.homeTodayTotal(context.rpSigned(s.todayNet)),
                  style: muted,
                ),
            ],
          ),
        ),
        if (s.groups.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              14,
              AppSpace.gutter,
              0,
            ),
            child: Text(l.homeMonthEmpty(month), style: muted),
          ),
        for (final g in s.groups) ...[
          _DayHeader(group: g, today: s.today),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              4,
              AppSpace.gutter,
              0,
            ),
            child: Column(
              spacing: 2,
              children: [
                if (g.rows.isEmpty) const _TodayEmpty(),
                for (final tx in g.rows)
                  TxRow(
                    tx: tx,
                    onTap: () => context.push(Routes.transaction(tx.id)),
                  ),
              ],
            ),
          ),
        ],
        if (s.count > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.gutter,
              14,
              AppSpace.gutter,
              0,
            ),
            child: Semantics(
              button: true,
              child: GestureDetector(
                onTap: () => context.push(
                  s.isCurrent
                      ? Routes.transactions
                      : Routes.transactionsIn(s.month),
                ),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 4,
                    children: [
                      Flexible(
                        child: Text(
                          s.isCurrent
                              ? l.homeAllCount(s.count)
                              : l.homeAllIn(month, s.count),
                          overflow: TextOverflow.ellipsis,
                          style: AppText.label.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 14,
                        strokeWidth: AppStroke.iconOnInkSmall,
                        color: AppColors.ink,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.group, required this.today});

  final DayGroup group;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final date = _dayTitle.format(group.day).toLowerCase();
    final title = switch (daysBetween(today, group.day)) {
      0 => [l.today, date],
      -1 => [l.yesterday, date],
      _ => [date],
    };
    final style = AppText.caption.copyWith(
      fontSize: 12,
      color: AppColors.muted,
    );
    return Semantics(
      header: true,
      child: Container(
        margin: const EdgeInsets.fromLTRB(
          AppSpace.gutter,
          14,
          AppSpace.gutter,
          0,
        ),
        padding: const EdgeInsets.only(bottom: 6),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.track,
              width: AppStroke.hairline,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: MetaLine(title, style: style)),
            if (group.rows.isNotEmpty)
              Text(context.rpSigned(group.total), style: style),
          ],
        ),
      ),
    );
  }
}

/// 02.1d: today has no entries but other days do.
class _TodayEmpty extends StatelessWidget {
  const _TodayEmpty();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => context.push(Routes.addEntry),
        child: SizedBox(
          height: 52,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l.homeTodayEmpty,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label.copyWith(
                    fontSize: 14,
                    color: AppColors.muted,
                  ),
                ),
              ),
              Row(
                spacing: 2,
                children: [
                  Text(
                    l.addEntry,
                    style: AppText.label.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    size: 14,
                    strokeWidth: AppStroke.iconOnInkSmall,
                    color: AppColors.ink,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 02.1c: a brand-new user, nothing logged yet.
class _NoEntries extends StatelessWidget {
  const _NoEntries();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.gutter,
        26,
        AppSpace.gutter,
        0,
      ),
      child: CustomPaint(
        painter: const DashedCardPainter(AppRadius.groupCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(
                l.homeNoEntriesTitle,
                style: AppText.label.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                l.homeNoEntriesBody,
                style: AppText.label.copyWith(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 6),
              Semantics(
                button: true,
                child: GestureDetector(
                  onTap: () => context.push(Routes.addEntry),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Text(
                      l.addEntry,
                      style: AppText.label.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.paper,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One animated state of the chart: curve heights, the marker's (fractional)
/// month index and height, and where the pill sits.
typedef _Frame = ({List<double> ys, double sel, double y, double pillTop});

/// "sisa pemasukan per bulan" — curve through each period's income − spending,
/// tap a month to peek.
/// Curve, marker and pill share one controller so they always move together,
/// also when the 6-month window slides.
class _BalanceChart extends StatefulWidget {
  const _BalanceChart({required this.chart, required this.onSelect});

  final HomeChart chart;
  final ValueChanged<DateTime> onSelect;

  static const _height = 186.0;
  static const _base = 150.0; // stems end here
  static const _top = 22.0, _bottom = 120.0; // y of max / min balance

  @override
  State<_BalanceChart> createState() => _BalanceChartState();
}

class _BalanceChartState extends State<_BalanceChart>
    with SingleTickerProviderStateMixin {
  static final _monthShort = DateFormat.MMM('id');

  late final _c = AnimationController(
    vsync: this,
    duration: AppMotion.select,
    value: 1,
  );
  late _Frame _from = _frameOf(widget.chart), _to = _from;

  static int _selIndex(HomeChart c) =>
      c.months.indexWhere((m) => m.month == c.selected);

  static _Frame _frameOf(HomeChart c) {
    final amounts = c.months.map((m) => m.amount);
    final lo = amounts.reduce(math.min), hi = amounts.reduce(math.max);
    final ys = [
      for (final m in c.months)
        hi == lo
            ? (_BalanceChart._top + _BalanceChart._bottom) / 2
            : _BalanceChart._bottom -
                  (m.amount - lo) /
                      (hi - lo) *
                      (_BalanceChart._bottom - _BalanceChart._top),
    ];
    final sel = math.max(0, _selIndex(c));
    return (
      ys: ys,
      sel: sel.toDouble(),
      y: ys[sel],
      pillTop: ys[sel] < 60 ? ys[sel] + 18 : ys[sel] - 58,
    );
  }

  _Frame get _now {
    final t = AppMotion.ease.transform(_c.value);
    return (
      ys: [
        for (var i = 0; i < _to.ys.length; i++)
          _lerp(_from.ys[i], _to.ys[i], t),
      ],
      sel: _lerp(_from.sel, _to.sel, t),
      y: _lerp(_from.y, _to.y, t),
      pillTop: _lerp(_from.pillTop, _to.pillTop, t),
    );
  }

  static double _lerp(double a, double b, double t) => a + (b - a) * t;

  @override
  void didUpdateWidget(_BalanceChart old) {
    super.didUpdateWidget(old);
    final next = _frameOf(widget.chart);
    if (next.sel == _to.sel && listEquals(next.ys, _to.ys)) return;
    _from = _now;
    _to = next;
    _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final months = widget.chart.months;
    final now = widget.chart.now;
    final sel = _selIndex(widget.chart);
    if (months.length < 2 || sel < 0) {
      return const SizedBox(height: _BalanceChart._height);
    }
    final pillTop = [
      if (sel == now) l.today,
      if (sel > now) l.prediction,
      _monthShort.format(months[sel].month).toLowerCase(),
    ];
    final pillVal =
        '${sel > now ? '± ' : ''}${context.rpCompact(months[sel].amount)}';

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        // Design: points at x = 33 … 360 on a 390 frame.
        double xAt(double i) => w * (33 + i * 327 / (months.length - 1)) / 390;
        final xs = [for (var i = 0; i < months.length; i++) xAt(i.toDouble())];

        return SizedBox(
          height: _BalanceChart._height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (context, _) {
                    final f = _now;
                    return CustomPaint(
                      painter: _ChartPainter(
                        xs: xs,
                        ys: f.ys,
                        marker: Offset(xAt(f.sel), f.y),
                        now: now,
                      ),
                    );
                  },
                ),
              ),
              for (var i = 0; i < months.length; i++)
                Positioned(
                  left: xs[i] - 28,
                  top: 0,
                  width: 56,
                  height: _BalanceChart._height,
                  child: Semantics(
                    button: true,
                    selected: i == sel,
                    label: _monthShort.format(months[i].month).toLowerCase(),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onSelect(months[i].month),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Text(
                          _monthShort.format(months[i].month).toLowerCase(),
                          style: AppText.label.copyWith(
                            fontSize: 15,
                            fontWeight: i == sel
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: i == sel ? AppColors.ink : AppColors.subtle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              AnimatedBuilder(
                animation: _c,
                builder: (context, child) {
                  final f = _now;
                  return Positioned(
                    left: xAt(f.sel).clamp(60, w - 60),
                    top: f.pillTop,
                    child: child!,
                  );
                },
                child: IgnorePointer(
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.ink,
                          width: AppStroke.outline,
                        ),
                        boxShadow: AppShadows.paper,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MetaLine(
                            pillTop,
                            tight: true,
                            style: AppText.micro.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                          Text(
                            pillVal,
                            style: AppText.label.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.xs,
    required this.ys,
    required this.marker,
    required this.now,
  });

  final List<double> xs, ys;
  final Offset marker; // the selected month; glides between points
  final int now;

  @override
  void paint(Canvas canvas, Size size) {
    // Catmull-Rom through the points, flat to both edges.
    final pts = [
      Offset(0, ys.first),
      for (var i = 0; i < xs.length; i++) Offset(xs[i], ys[i]),
      Offset(size.width, ys.last),
    ];
    final curve = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (var i = 0; i < pts.length - 1; i++) {
      final p0 = pts[math.max(0, i - 1)], p1 = pts[i];
      final p2 = pts[i + 1], p3 = pts[math.min(pts.length - 1, i + 2)];
      final c1 = p1 + (p2 - p0) / 6, c2 = p2 - (p3 - p1) / 6;
      curve.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    canvas.drawPath(
      curve,
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.chart
        ..strokeCap = StrokeCap.round,
    );

    final stem = Paint()..style = PaintingStyle.stroke;
    final fill = Paint();
    for (var i = 0; i < xs.length; i++) {
      final p = Offset(xs[i], ys[i]);
      canvas.drawPath(
        dashPath(
          Path()
            ..moveTo(p.dx, p.dy)
            ..lineTo(p.dx, _BalanceChart._base),
          dash: 3,
          gap: 3,
        ),
        stem
          ..color = AppColors.line
          ..strokeWidth = AppStroke.hairline,
      );
      canvas.drawCircle(
        p,
        4,
        fill..color = i > now ? AppColors.paper : AppColors.ink,
      );
      if (i > now) {
        // prediction: hollow dot
        canvas.drawCircle(
          p,
          3.25,
          stem
            ..color = AppColors.ink
            ..strokeWidth = AppStroke.outline,
        );
      }
    }

    // Selected month, drawn last so it covers the point it lands on.
    canvas.drawPath(
      Path()
        ..moveTo(marker.dx, marker.dy)
        ..lineTo(marker.dx, _BalanceChart._base),
      stem
        ..color = AppColors.ink
        ..strokeWidth = AppStroke.outline,
    );
    canvas.drawCircle(marker, 12, fill..color = AppColors.paper); // 3px ring
    canvas.drawCircle(marker, 9, fill..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.marker != marker ||
      old.now != now ||
      !listEquals(old.xs, xs) ||
      !listEquals(old.ys, ys);
}
