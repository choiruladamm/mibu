import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/dates.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/nav_header.dart';
import '../../../core/widgets/tx_row.dart';
import '../view_models/transactions_view_model.dart';

final _monthName = DateFormat('MMMM', 'id');
final _monthShort = DateFormat('MMM', 'id');
final _dayTitle = DateFormat('EEE d MMM', 'id');

String _name(DateTime m) => _monthName.format(m).toLowerCase();
String _short(DateTime m) => _monthShort.format(m).toLowerCase();

/// 04.1 semua transaksi.
class TransactionsView extends ConsumerWidget {
  const TransactionsView({super.key, this.onOpen});

  /// Row tap → 04.3 struk.
  final ValueChanged<Transaction>? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final s = ref.watch(transactionsProvider).value;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        minimum: const EdgeInsets.only(top: 12),
        child: Column(
          children: [
            NavHeader(
              title: l.txTitle,
              sub: s == null ? '' : l.txCount(s.count),
              backLabel: l.home,
              actionIcon: HugeIcons.strokeRoundedSearch01,
              actionLabel: l.search,
              onAction: null, // → 04.2 cari (M6)
            ),
            Expanded(
              child: s == null
                  ? const SizedBox()
                  : _Body(state: s, onOpen: onOpen),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state, required this.onOpen});

  final TransactionsState state;
  final ValueChanged<Transaction>? onOpen;

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
          child: _MonthCarousel(state: s, onPick: go),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          child: Row(
            spacing: 8,
            children: [
              _Tile(label: l.income, value: rupiahSigned(s.income)),
              _Tile(label: l.expense, value: rupiahSigned(s.expense)),
              _Tile(
                label: l.txNet,
                value: rupiahSigned(s.income + s.expense),
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
                label: l.txSeeMonth(_short(s.months[s.selected - 1])),
                onTap: prev,
              ),
          ],
        ),
      ],
    );
  }
}

class _MonthCarousel extends StatelessWidget {
  const _MonthCarousel({required this.state, required this.onPick});

  final TransactionsState state;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = state;
    final i = s.selected;
    // Up to 7 dots, sliding with the selection.
    final from = (i - 3).clamp(0, (s.months.length - 7).clamp(0, 1 << 30));
    final to = (from + 7).clamp(0, s.months.length);

    Widget side({
      required String label,
      required String semantics,
      required VoidCallback? onTap,
      required TextAlign align,
    }) => Semantics(
      button: true,
      enabled: onTap != null,
      label: semantics,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 88,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: align == TextAlign.left
              ? Alignment.centerLeft
              : Alignment.centerRight,
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              side(
                label: s.hasPrev ? _short(s.months[i - 1]) : '',
                semantics: s.hasPrev
                    ? l.txSeeMonth(_name(s.months[i - 1]))
                    : l.txNoPrev,
                onTap: s.hasPrev ? () => onPick(i - 1) : null,
                align: TextAlign.left,
              ),
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Column(
                    spacing: 2,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _name(s.month),
                          style: AppText.title.copyWith(
                            fontSize: 36,
                            letterSpacing: -1.08,
                            height: 1,
                          ),
                        ),
                      ),
                      Text(
                        '${s.month.year}',
                        style: AppText.caption.copyWith(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              side(
                label: _short(next),
                semantics: s.nextIsFuture
                    ? l.txNotYet(_name(next))
                    : l.txSeeMonth(_name(next)),
                onTap: s.nextIsFuture ? null : () => onPick(i + 1),
                align: TextAlign.right,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              for (var j = from; j < to; j++)
                AnimatedContainer(
                  duration: AppMotion.select,
                  curve: AppMotion.ease,
                  width: j == i ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: j == i
                        ? AppColors.ink
                        : j == s.months.length - 1
                        ? AppColors.track
                        : AppColors.line,
                  ),
                ),
            ],
          ),
        ),
      ],
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
      0 => '${l.today} · $date',
      -1 => '${l.yesterday} · $date',
      _ => date,
    };
    return Semantics(
      container: true,
      label: title,
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
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  rupiahSigned(group.total),
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
