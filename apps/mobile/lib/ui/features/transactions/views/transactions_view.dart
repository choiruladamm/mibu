import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/finance_providers.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/month_menu.dart';
import '../../../core/widgets/nav_header.dart';
import '../../../core/widgets/tx_row.dart';
import '../view_models/transactions_view_model.dart';
import '../../../core/widgets/meta_line.dart';

final _monthName = DateFormat('MMMM', 'id');
final _monthShort = DateFormat('MMM', 'id');
final _dayTitle = DateFormat('EEE d MMM', 'id');

String _name(DateTime m) => _monthName.format(m).toLowerCase();
String _short(DateTime m) => _monthShort.format(m).toLowerCase();

/// 04.1 semua transaksi.
class TransactionsView extends ConsumerStatefulWidget {
  const TransactionsView({super.key, this.onOpen, this.onSearch});

  /// Row tap → 04.3 struk.
  final ValueChanged<Transaction>? onOpen;

  /// Search button → 04.2 cari in the month being viewed.
  final ValueChanged<DateTime>? onSearch;

  @override
  ConsumerState<TransactionsView> createState() => _TransactionsViewState();
}

class _TransactionsViewState extends ConsumerState<TransactionsView> {
  /// Last loaded state: shown while a newly picked month loads, so the list
  /// doesn't blank (and lose its scroll position) between months.
  TransactionsState? _last;

  /// 04.1b: 00.8 MonthMenu under the month title.
  bool _menuOpen = false;
  final _titleLink = LayerLink();

  void _toggleMenu() => setState(() => _menuOpen = !_menuOpen);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = _last = ref.watch(transactionsProvider).value ?? _last;
    final onOpen = widget.onOpen;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            minimum: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                NavHeader(
                  title: l.txTitle,
                  sub: [if (s != null) l.txCount(s.count)],
                  backLabel: l.home,
                  actionIcon: HugeIcons.strokeRoundedSearch01,
                  actionLabel: l.search,
                  onAction: s == null || widget.onSearch == null
                      ? null
                      : () => widget.onSearch!(s.month),
                ),
                Expanded(
                  child: s == null
                      ? const SizedBox()
                      : _Body(
                          state: s,
                          onOpen: onOpen,
                          titleLink: _titleLink,
                          menuOpen: _menuOpen,
                          onToggleMenu: _toggleMenu,
                        ),
                ),
              ],
            ),
          ),
          if (_menuOpen && s != null) ...[
            Positioned.fill(
              child: Semantics(
                button: true,
                label: l.close,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleMenu,
                  child: const ColoredBox(color: AppColors.scrim),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topLeft,
              child: CompositedTransformFollower(
                link: _titleLink,
                showWhenUnlinked: false,
                targetAnchor: Alignment.bottomCenter,
                followerAnchor: Alignment.topCenter,
                offset: const Offset(0, 6),
                child: MonthMenu(
                  selected: s.month,
                  now: ref.watch(nowProvider),
                  spent: ref.watch(totalsProvider).value?.spent ?? const {},
                  min: s.months.first,
                  onPick: (month) {
                    ref.read(txMonthProvider.notifier).select(month);
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
}

class _Body extends ConsumerWidget {
  const _Body({
    required this.state,
    required this.onOpen,
    required this.titleLink,
    required this.menuOpen,
    required this.onToggleMenu,
  });

  final TransactionsState state;
  final ValueChanged<Transaction>? onOpen;
  final LayerLink titleLink;
  final bool menuOpen;
  final VoidCallback onToggleMenu;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final s = state;
    final month = _name(s.month);
    void go(int i) => ref.read(txMonthProvider.notifier).select(s.months[i]);
    void prev() {
      if (s.hasPrev) go(s.selected - 1);
    }

    final muted = AppText.caption.copyWith(color: AppColors.muted);

    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        const SizedBox(height: 18),
        GestureDetector(
          // Swipe the month like a carousel.
          onHorizontalDragEnd: (d) {
            final v = d.primaryVelocity ?? 0;
            if (v > 200) prev();
            if (v < -200 && !s.nextIsFuture) go(s.selected + 1);
          },
          child: _MonthCarousel(
            state: s,
            onPick: go,
            onBackToNow: () => ref
                .read(txMonthProvider.notifier)
                .select(DateTime(s.today.year, s.today.month)),
            titleLink: titleLink,
            menuOpen: menuOpen,
            onToggleMenu: onToggleMenu,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            spacing: 8,
            children: [
              _Tile(label: l.income, value: context.rpSigned(s.income)),
              _Tile(label: l.expense, value: context.rpSigned(s.expense)),
              _Tile(
                label: l.txNet,
                value: context.rpSigned(s.income + s.expense),
                ink: true,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Row(
            spacing: 12,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _Filter(
                    selected: ref.watch(txFilterProvider),
                    labels: {
                      TxFilter.all: l.txAll,
                      TxFilter.expenses: l.expense,
                      TxFilter.income: l.income,
                    },
                    onPick: ref.read(txFilterProvider.notifier).select,
                  ),
                ),
              ),
              Text(l.txCount(s.count), style: muted),
            ],
          ),
        ),
        for (final g in s.groups)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: _DayGroup(group: g, today: s.today, onOpen: onOpen),
          ),
        const SizedBox(height: 28),
        Column(
          spacing: 12,
          children: [
            if (s.count == 0)
              Text(
                l.txEmpty(month),
                style: AppText.label.copyWith(color: AppColors.muted),
              )
            else
              Text(l.txAllShown(month), style: muted),
            if (s.hasPrev)
              _OutlinePill(
                label: l.txSeeMonth(_label(s.months[s.selected - 1], s.month)),
                onTap: prev,
              ),
          ],
        ),
      ],
    );
  }
}

/// "sep", or "des 24" when [m] is in another year than [around].
String _label(DateTime m, DateTime around) => m.year == around.year
    ? _short(m)
    : '${_short(m)} ${(m.year % 100).toString().padLeft(2, '0')}';

class _MonthCarousel extends StatelessWidget {
  const _MonthCarousel({
    required this.state,
    required this.onPick,
    required this.onBackToNow,
    required this.titleLink,
    required this.menuOpen,
    required this.onToggleMenu,
  });

  final TransactionsState state;
  final ValueChanged<int> onPick;
  final VoidCallback onBackToNow;
  final LayerLink titleLink;
  final bool menuOpen;
  final VoidCallback onToggleMenu;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = state;
    final i = s.selected;
    final notNow = s.month != DateTime(s.today.year, s.today.month);

    Widget side({
      required String label,
      required String semantics,
      required VoidCallback? onTap,
      required bool left,
    }) => Semantics(
      button: true,
      enabled: onTap != null,
      label: semantics,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 76,
          height: 64,
          padding: EdgeInsets.only(left: left ? 12 : 0, right: left ? 0 : 12),
          alignment: left ? Alignment.centerLeft : Alignment.centerRight,
          child: Text(
            label,
            style: AppText.body.copyWith(
              fontWeight: FontWeight.w400,
              color: onTap == null && label.isNotEmpty
                  ? AppColors.line
                  : AppColors.subtle,
            ),
          ),
        ),
      ),
    );

    final next = s.months[i + 1];
    return Column(
      children: [
        CompositedTransformTarget(
          link: titleLink,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                side(
                  label: s.hasPrev ? _label(s.months[i - 1], s.month) : '',
                  semantics: s.hasPrev
                      ? l.txSeeMonth(_name(s.months[i - 1]))
                      : l.txNoPrev,
                  onTap: s.hasPrev ? () => onPick(i - 1) : null,
                  left: true,
                ),
                Expanded(
                  child: Center(
                    child: _Title(
                      month: s.month,
                      open: menuOpen,
                      onTap: onToggleMenu,
                    ),
                  ),
                ),
                side(
                  label: _label(next, s.month),
                  semantics: s.nextIsFuture
                      ? l.txNotYet
                      : l.txSeeMonth(_name(next)),
                  onTap: s.nextIsFuture ? null : () => onPick(i + 1),
                  left: false,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: AppMotion.select,
          curve: AppMotion.ease,
          alignment: Alignment.topCenter,
          child: notNow
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _BackToNow(
                    label: l.txBackToNow(_short(s.today), s.today.year),
                    onTap: onBackToNow,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Month name + year; tap opens 00.8 MonthMenu. The caret goes ink while open.
class _Title extends StatelessWidget {
  const _Title({required this.month, required this.open, required this.onTap});

  final DateTime month;
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      expanded: open,
      liveRegion: true,
      label: l.txPickMonth(_name(month), month.year),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 2,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 6,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _name(month),
                        style: AppText.title.copyWith(
                          fontSize: 36,
                          letterSpacing: -1.08,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: AppMotion.select,
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: open ? AppColors.ink : AppColors.mist,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowDown01,
                        size: 18,
                        strokeWidth: AppStroke.iconOnInkSmall,
                        color: open ? AppColors.paper : AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '${month.year}',
                style: AppText.caption.copyWith(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 04.1c: "balik ke okt 2026 ›" when not on the current month.
class _BackToNow extends StatelessWidget {
  const _BackToNow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 30,
          padding: const EdgeInsets.only(left: 12, right: 8),
          decoration: BoxDecoration(
            color: AppColors.mist,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 2,
            children: [
              Text(
                label,
                style: AppText.label.copyWith(
                  fontSize: 13,
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
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.label, required this.value, this.ink = false});

  final String label, value;
  final bool ink;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ink ? AppColors.ink : AppColors.mist,
          borderRadius: BorderRadius.circular(AppRadius.statTile),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(
                fontSize: 12,
                color: ink ? AppColors.onInkMuted : AppColors.muted,
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label.copyWith(
                fontWeight: FontWeight.w600,
                color: ink ? AppColors.paper : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Filter extends StatelessWidget {
  const _Filter({
    required this.selected,
    required this.labels,
    required this.onPick,
  });

  final TxFilter selected;
  final Map<TxFilter, String> labels;
  final ValueChanged<TxFilter> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.ink, width: AppStroke.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (final MapEntry(key: f, value: label) in labels.entries)
            Semantics(
              button: true,
              selected: f == selected,
              child: GestureDetector(
                onTap: () => onPick(f),
                child: AnimatedContainer(
                  duration: AppMotion.select,
                  curve: AppMotion.ease,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: f == selected ? AppColors.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Text(
                    label,
                    style: AppText.label.copyWith(
                      fontSize: 14,
                      color: f == selected ? AppColors.paper : AppColors.ink,
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

class _DayGroup extends StatelessWidget {
  const _DayGroup({
    required this.group,
    required this.today,
    required this.onOpen,
  });

  final DayGroup group;
  final DateTime today;
  final ValueChanged<Transaction>? onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final date = _dayTitle.format(group.day).toLowerCase();
    final title = switch (daysBetween(today, group.day)) {
      0 => [l.today, date],
      -1 => [l.yesterday, date],
      _ => [date],
    };
    return Semantics(
      container: true,
      label: title.join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColors.line,
                  width: AppStroke.hairline,
                ),
              ),
            ),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: MetaLine(
                    title,
                    style: AppText.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  context.rpSigned(group.total),
                  style: AppText.caption.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Column(
            spacing: 2,
            children: [
              for (final t in group.rows)
                TxRow(tx: t, onTap: onOpen == null ? null : () => onOpen!(t)),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutlinePill extends StatelessWidget {
  const _OutlinePill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.ink, width: AppStroke.outline),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: AppText.label.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
