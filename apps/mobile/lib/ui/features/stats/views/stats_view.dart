import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/stats.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/router.dart';
import '../../../core/clock.dart';
import '../../../core/dashed.dart';
import '../../../core/finance_providers.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/meta_line.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/tab_bar.dart';
import '../../budget/views/budget_sheet.dart';
import '../../../core/widgets/app_emoji.dart';

final _day = DateFormat('d', 'id');
final _dayMonth = DateFormat('d MMM', 'id');
final _weekday = DateFormat('EEE', 'id');
final _weekdayFull = DateFormat('EEEE', 'id');
final _monthFull = DateFormat('MMMM', 'id');
final _monthShort = DateFormat('MMM', 'id');

String _lower(DateFormat f, DateTime d) => f.format(d).toLowerCase();

/// "12 – 18 okt" · "29 sep – 5 okt" (end exclusive in [s]).
String _range(Span s) {
  final last = DateTime(s.end.year, s.end.month, s.end.day - 1);
  return s.start.month == last.month
      ? '${_day.format(s.start)} – ${_lower(_dayMonth, last)}'
      : '${_lower(_dayMonth, s.start)} – ${_lower(_dayMonth, last)}';
}

/// 02.3 statistik: minggu / bulan / tahun, ‹ › through periods, bars,
/// sekilas, on track nggak? (ritme budget) and larinya ke mana.
class StatsView extends ConsumerStatefulWidget {
  const StatsView({super.key});

  @override
  ConsumerState<StatsView> createState() => _StatsViewState();
}

class _StatsViewState extends ConsumerState<StatsView> {
  var _period = StatsPeriod.month;
  Span? _span; // null = the one holding today
  int? _sel; // picked bar; null = the current one

  void _go(StatsPeriod p, [Span? s]) => setState(() {
    _period = p;
    _span = s;
    _sel = null;
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final now = ref.watch(nowProvider);
    final entries = ref.watch(allTransactionsProvider).value ?? const [];
    final budget = ref.watch(profileProvider).value?.monthlyBudget;
    final periods = ref.watch(periodsProvider);
    final span = _span ?? spanOf(_period, now, periods: periods);
    final s = Stats(
      entries,
      period: _period,
      span: span,
      today: now,
      budget: budget,
      periods: periods,
    );
    final prev = shiftSpan(_period, span, -1, periods: periods);
    // Any entry before this window (first is a month label, not a date).
    final hasPrev = entries.any((t) => !t.deleted && t.at.isBefore(span.start));
    final isNow = s.current >= 0;

    return Scaffold(
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + 20,
              bottom: AppSpace.tabBarClearance,
            ),
            children: [
              Center(
                child: _Segmented(
                  selected: _period,
                  labels: {
                    StatsPeriod.week: l.statsWeek,
                    StatsPeriod.month: l.statsMonth,
                    StatsPeriod.year: l.statsYear,
                  },
                  onPick: _go,
                ),
              ),
              const SizedBox(height: 26),
              _Hero(
                stats: s,
                previous: spentIn(entries, prev),
                prevSpan: prev,
                prevMonthKey: periods.periodOf(prev.start).key,
                onPrev: hasPrev ? () => _go(_period, prev) : null,
                onNext: isNow
                    ? null
                    : () => _go(
                        _period,
                        shiftSpan(_period, span, 1, periods: periods),
                      ),
              ),
              const SizedBox(height: 26),
              _Chart(
                stats: s,
                selected: _sel ?? (isNow ? s.current : null),
                onPick: (i) => setState(() => _sel = i),
              ),
              _Glance(stats: s),
              if (s.limit == null)
                _NoBudget(onTap: () => editBudget(context, ref))
              else
                _Pace(stats: s, isNow: isNow),
              if (s.categories.isNotEmpty) _Where(stats: s),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AppTabBar(
              active: AppTab.stats,
              onSelect: (tab) => goTab(context, tab),
              onAdd: () => context.push(Routes.addEntry),
            ),
          ),
        ],
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({
    required this.selected,
    required this.labels,
    required this.onPick,
  });

  final StatsPeriod selected;
  final Map<StatsPeriod, String> labels;
  final ValueChanged<StatsPeriod> onPick;

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
          for (final MapEntry(key: p, value: label) in labels.entries)
            Semantics(
              button: true,
              selected: p == selected,
              child: GestureDetector(
                onTap: () => onPick(p),
                child: AnimatedContainer(
                  duration: AppMotion.select,
                  curve: AppMotion.ease,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: p == selected ? AppColors.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Text(
                    label,
                    style: AppText.label.copyWith(
                      fontSize: 15,
                      fontWeight: p == selected
                          ? FontWeight.w500
                          : FontWeight.w400,
                      color: p == selected ? AppColors.paper : AppColors.ink,
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

/// ‹ keluar … · range, total, delta vs last period (year: rata² / bulan) ›
class _Hero extends StatelessWidget {
  const _Hero({
    required this.stats,
    required this.previous,
    required this.prevSpan,
    required this.prevMonthKey,
    required this.onPrev,
    required this.onNext,
  });

  final Stats stats;
  final int previous; // spent in the period before
  final Span prevSpan;
  final DateTime prevMonthKey; // month label of the period before
  final VoidCallback? onPrev, onNext;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = stats;
    final isNow = s.current >= 0;
    final caption = !isNow
        ? l.statsOut
        : switch (s.period) {
            StatsPeriod.week => l.statsOutWeek,
            StatsPeriod.month => l.statsOutMonth,
            StatsPeriod.year => l.statsOutYear,
          };
    final range = switch (s.period) {
      StatsPeriod.week => _range(s.span),
      StatsPeriod.month =>
        '${_lower(_monthFull, s.monthKey)} ${s.monthKey.year}',
      StatsPeriod.year =>
        '${_lower(_monthShort, DateTime(2000))} – '
            '${_lower(_monthShort, DateTime(2000, 12))} ${s.span.start.year}',
    };
    final String delta;
    if (s.period == StatsPeriod.year) {
      delta = l.statsPerMonth(context.rpCompact(s.average));
    } else {
      final than = s.period == StatsPeriod.week
          ? (isNow ? l.statsLastWeek : l.statsWeekBefore)
          : _lower(_monthFull, prevMonthKey);
      final diff = context.rpCompact((s.total - previous).abs());
      delta = s.total >= previous
          ? l.statsUp(diff, than)
          : l.statsDown(diff, than);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      child: Row(
        children: [
          CircleButton(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            label: l.statsPrev,
            iconSize: 20,
            onTap: onPrev,
          ),
          Expanded(
            child: Column(
              spacing: 8,
              children: [
                MetaLine(
                  [caption, range],
                  style: AppText.label.copyWith(
                    fontSize: 14,
                    color: AppColors.muted,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    context.rpCompact(s.total),
                    style: AppText.display.copyWith(height: 1),
                  ),
                ),
                Container(
                  height: 30,
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(delta, style: AppText.caption),
                ),
              ],
            ),
          ),
          CircleButton(
            icon: HugeIcons.strokeRoundedArrowRight01,
            label: l.statsNext,
            iconSize: 20,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

/// Ink card: one bar per day / week / month, dashed rata² line, tap a bar
/// for its amount; the biggest one wears its top category's emoji.
class _Chart extends StatelessWidget {
  const _Chart({
    required this.stats,
    required this.selected,
    required this.onPick,
  });

  final Stats stats;
  final int? selected;
  final ValueChanged<int> onPick;

  static const _barH = 172.0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = stats;
    final max = s.spent.whereType<int>().fold(1, (a, b) => a > b ? a : b);
    final barW = switch (s.period) {
      StatsPeriod.week => 26.0,
      StatsPeriod.month => 40.0,
      StatsPeriod.year => 14.0,
    };
    final avgY = s.average / max * _barH;
    final peak = s.peak, emoji = s.peakTop?.emoji;

    String label(Span b) => switch (s.period) {
      StatsPeriod.week => _lower(_weekday, b.start),
      StatsPeriod.month =>
        '${b.start.day}–${DateTime(b.end.year, b.end.month, b.end.day - 1).day}',
      StatsPeriod.year => _lower(_monthFull, b.start)[0],
    };
    String full(Span b) => switch (s.period) {
      StatsPeriod.week =>
        '${_lower(_weekdayFull, b.start)} ${_lower(_dayMonth, b.start)}',
      StatsPeriod.month => _range(b),
      StatsPeriod.year => _lower(_monthFull, b.start),
    };
    final small = AppText.caption.copyWith(
      fontSize: 12,
      color: AppColors.grey400,
    );

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpace.cardInset),
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.inkCard),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 214,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (s.average > 0) ...[
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: avgY,
                    child: CustomPaint(
                      size: const Size.fromHeight(AppStroke.outline),
                      painter: _DashedLine(),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: avgY + 4,
                    child: Text(
                      l.statsAvgShort,
                      style: small.copyWith(fontSize: 11),
                    ),
                  ),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (i, b) in s.bars.indexed)
                      Expanded(
                        child: _Bar(
                          value: s.spent[i],
                          height: switch (s.spent[i]) {
                            null || 0 => 0,
                            final v => (v / max * _barH).clamp(6, _barH),
                          },
                          width: barW,
                          isNow: i == s.current,
                          selected: i == selected,
                          emoji: i == peak ? emoji : null,
                          label:
                              '${full(b)}, ${switch (s.spent[i]) {
                                null => l.statsNotYet,
                                final v => context.rpCompact(v),
                              }}',
                          onTap: () => onPick(i),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (final (i, b) in s.bars.indexed)
                Expanded(
                  child: Text(
                    label(b),
                    textAlign: TextAlign.center,
                    style: small.copyWith(
                      fontWeight: i == s.current || i == selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: i == s.current || i == selected
                          ? AppColors.onInk
                          : AppColors.grey400,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DefaultTextStyle(
            style: small,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 20,
              children: [
                _Legend(
                  mark: _dot(AppColors.onInk),
                  label: switch (s.period) {
                    StatsPeriod.week => l.statsNowWeek,
                    StatsPeriod.month => l.statsNowMonth,
                    StatsPeriod.year => l.statsNowYear,
                  },
                ),
                _Legend(mark: _dot(AppColors.onInk42), label: l.statsBefore),
                _Legend(
                  mark: CustomPaint(
                    size: const Size(14, AppStroke.outline),
                    painter: _DashedLine(),
                  ),
                  label: l.statsAvgLegend,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _dot(Color c) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );
}

class _Legend extends StatelessWidget {
  const _Legend({required this.mark, required this.label});

  final Widget mark;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 6,
    children: [mark, Text(label)],
  );
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.value,
    required this.height,
    required this.width,
    required this.isNow,
    required this.selected,
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final int? value; // null = belum
  final double height, width;
  final bool isNow, selected;
  final String? emoji; // paling boros badge
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final future = value == null;
    final r = BorderRadius.circular(width / 2);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          spacing: 10,
          children: [
            if (selected)
              // Wider than the bar's column (a year bar is ~26 wide): centred
              // on the bar, spilling into the card padding.
              SizedBox(
                height: 26,
                child: OverflowBox(
                  maxWidth: double.infinity,
                  child: Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.paper,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Text(
                      future ? l.statsNotYet : context.rpCompact(value!),
                      maxLines: 1,
                      softWrap: false,
                      style: AppText.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            Container(
              width: width,
              height: _Chart._barH,
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                color: future ? Colors.transparent : AppColors.onInk8,
                borderRadius: r,
                border: future
                    ? Border.all(
                        color: AppColors.onInk12,
                        width: AppStroke.outline,
                      )
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  AnimatedContainer(
                    duration: AppMotion.select,
                    curve: AppMotion.ease,
                    width: width,
                    height: height,
                    decoration: BoxDecoration(
                      color: isNow
                          ? AppColors.onInk
                          : selected
                          ? AppColors.onInk72
                          : AppColors.onInk42,
                      borderRadius: r,
                    ),
                  ),
                  if (emoji != null)
                    Positioned(
                      bottom: height - 15,
                      child: Container(
                        width: 30,
                        height: 30,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.ink, width: 2),
                        ),
                        child: AppEmoji(emoji!, size: 18),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedLine extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    dashPath(
      Path()
        ..moveTo(0, size.height / 2)
        ..lineTo(size.width, size.height / 2),
    ),
    Paint()
      ..color = AppColors.onInk45
      ..strokeWidth = AppStroke.outline
      ..style = PaintingStyle.stroke,
  );

  @override
  bool shouldRepaint(_DashedLine old) => false;
}

/// Section title left, info right (no dot).
class _Title extends StatelessWidget {
  const _Title(this.title, {this.info});

  final String title;
  final String? info;

  @override
  Widget build(BuildContext context) {
    final style = AppText.caption.copyWith(color: AppColors.muted);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: style.copyWith(fontWeight: FontWeight.w500)),
        if (info != null) Text(info!, style: style),
      ],
    );
  }
}

String _barName(Stats s, int i) {
  final b = s.bars[i];
  return switch (s.period) {
    StatsPeriod.week => _lower(_weekdayFull, b.start),
    StatsPeriod.month =>
      '${b.start.day}–${_lower(_dayMonth, DateTime(b.end.year, b.end.month, b.end.day - 1))}',
    StatsPeriod.year => _lower(_monthFull, b.start),
  };
}

/// sekilas: ink card for paling boros (+ gara-gara), mist cards for paling
/// hemat and rata² per bar.
class _Glance extends StatelessWidget {
  const _Glance({required this.stats});

  final Stats stats;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = stats;
    final peak = s.peak, low = s.low, top = s.peakTop;
    final (avgName, avgSub) = switch (s.period) {
      StatsPeriod.week => (l.statsAvgDay, l.statsFromDays(s.counted)),
      StatsPeriod.month => (l.statsAvgWeek, l.statsFromWeeks(s.counted)),
      StatsPeriod.year => (l.statsAvgMonth, l.statsFromMonths(s.counted)),
    };
    final why = top == null ? null : top.category ?? l.uncategorized;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Text(
            l.statsGlance,
            style: AppText.label.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(
            height: 184,
            child: Row(
              spacing: 10,
              children: [
                _PeakCard(
                  label: l.statsPeak,
                  amount: peak == null
                      ? '–'
                      : context.rpCompact(s.spent[peak]!),
                  name: peak == null ? '' : _barName(s, peak),
                  because: l.statsBecause,
                  why: why,
                  emoji: top?.emoji,
                  semantics: peak == null
                      ? l.statsPeak
                      : l.statsPeakLabel(
                          _barName(s, peak),
                          context.rpCompact(s.spent[peak]!),
                          why!,
                        ),
                ),
                Expanded(
                  child: Column(
                    spacing: 10,
                    children: [
                      _MiniTile(
                        label: l.statsLow,
                        value: low == null
                            ? '–'
                            : context.rpCompact(s.spent[low]!),
                        sub: low == null ? '' : _barName(s, low),
                      ),
                      _MiniTile(
                        label: avgName,
                        value: context.rpCompact(s.average),
                        sub: avgSub,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PeakCard extends StatelessWidget {
  const _PeakCard({
    required this.label,
    required this.amount,
    required this.name,
    required this.because,
    required this.why,
    required this.emoji,
    required this.semantics,
  });

  final String label, amount, name, because, semantics;
  final String? why, emoji; // null = nothing spent

  @override
  Widget build(BuildContext context) {
    final onInk = AppText.caption.copyWith(color: AppColors.onInkMuted);
    return Semantics(
      container: true,
      label: semantics,
      excludeSemantics: true,
      child: Container(
        width: 158,
        clipBehavior: Clip.antiAlias,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.ink,
          borderRadius: BorderRadius.circular(AppRadius.groupCard),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (emoji != null)
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 72,
                  height: 72,
                  // Board: padding 10px 10px 0 0 → the glyph sits 27px from the
                  // card's top and right edges, centred in what the card
                  // clips of the circle (it pokes 14px out of both).
                  padding: const EdgeInsets.only(top: 10, right: 10),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.onInk12,
                    shape: BoxShape.circle,
                  ),
                  child: AppEmoji(emoji!, size: 34),
                ),
              ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: onInk.copyWith(fontSize: 12)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        amount,
                        style: AppText.headline.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onInk,
                        ),
                      ),
                    ),
                    if (name.isNotEmpty) Text(name, style: onInk),
                    if (why != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        because,
                        style: onInk.copyWith(
                          fontSize: 11,
                          color: AppColors.grey400,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        why!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: AppColors.onInk,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniTile extends StatelessWidget {
  const _MiniTile({
    required this.label,
    required this.value,
    required this.sub,
  });

  final String label, value, sub;

  @override
  Widget build(BuildContext context) {
    final muted = AppText.caption.copyWith(
      fontSize: 12,
      color: AppColors.muted,
    );
    return Expanded(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(AppRadius.statTile),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 1,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: muted,
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: AppText.label.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: muted,
            ),
          ],
        ),
      ),
    );
  }
}

/// on track nggak? — kepake vs waktu jalan against the period's budget.
class _Pace extends StatelessWidget {
  const _Pace({required this.stats, required this.isNow});

  final Stats stats;
  final bool isNow;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = stats;
    final limit = s.limit!, pace = s.pace!;
    final rest = limit - s.total;
    final scope = isNow
        ? switch (s.period) {
            StatsPeriod.week => l.statsScopeWeek,
            StatsPeriod.month => l.statsScopeMonth,
            StatsPeriod.year => '${s.span.start.year}',
          }
        : switch (s.period) {
            StatsPeriod.week => _range(s.span),
            StatsPeriod.month => _lower(_monthFull, s.monthKey),
            StatsPeriod.year => '${s.span.start.year}',
          };
    final headline = switch (pace) {
      BudgetPace.over => l.statsOverBy(context.rpCompact(-rest), scope),
      _ when !isNow => l.statsPastLeft(context.rpCompact(rest), scope),
      BudgetPace.near => l.statsNearLeft(context.rpCompact(rest), s.left),
      _ when s.period == StatsPeriod.year => l.statsYearLeft(
        context.rpCompact(rest),
        '${s.span.start.year}',
      ),
      _ => l.statsLeft(context.rpCompact(rest), s.left),
    };
    final status = switch (pace) {
      BudgetPace.over => l.statsPaceOver,
      BudgetPace.near => l.statsPaceNear,
      BudgetPace.under => l.statsPaceUnder,
      BudgetPace.fine => l.statsPaceFine,
    };
    final alarm = pace == BudgetPace.over || pace == BudgetPace.near;
    final row = AppText.caption;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      l.statsTrack,
                      style: row.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.muted,
                      ),
                    ),
                    MetaLine(
                      [
                        l.statsBudget(context.rpCompact(limit)),
                        switch (s.period) {
                          StatsPeriod.week => l.statsLimitWeek,
                          StatsPeriod.month => l.statsLimitMonth,
                          StatsPeriod.year => l.statsLimitYear,
                        },
                      ],
                      style: row.copyWith(
                        fontSize: 12,
                        color: AppColors.grey400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 28,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: alarm ? AppColors.ink : null,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: alarm
                      ? null
                      : Border.all(
                          color: AppColors.ink,
                          width: AppStroke.outline,
                        ),
                ),
                child: Text(
                  status,
                  style: row.copyWith(
                    fontWeight: FontWeight.w500,
                    color: alarm ? AppColors.paper : AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
          Text(
            headline,
            style: AppText.headline.copyWith(
              letterSpacing: -0.48,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          _Meter(label: l.statsUsed, pct: s.usedPct, bold: true),
          const SizedBox(height: 2),
          _Meter(label: l.statsTime, pct: s.timePct, striped: true),
        ],
      ),
    );
  }
}

class _Meter extends StatelessWidget {
  const _Meter({
    required this.label,
    required this.pct,
    this.bold = false,
    this.striped = false,
  });

  final String label;
  final double pct;
  final bool bold, striped;

  @override
  Widget build(BuildContext context) {
    final style = AppText.caption.copyWith(
      color: bold ? AppColors.ink : AppColors.muted,
    );
    final fill = (pct / 100).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: style),
            Text(
              '${pct.round()}%',
              style: style.copyWith(
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Container(
            height: 10,
            color: AppColors.track,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: fill,
              heightFactor: 1,
              child: striped
                  ? CustomPaint(painter: _Stripes())
                  : const DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// waktu jalan: 135° ink stripes on paper, ink edge.
class _Stripes extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(5),
    );
    canvas.save();
    canvas.clipRRect(r);
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.paper);
    final ink = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 3 / 1.4142;
    for (var x = -size.height; x < size.width + size.height; x += 6 / 1.4142) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), ink);
    }
    canvas.restore();
    canvas.drawRRect(
      r.deflate(0.5),
      Paint()
        ..color = AppColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppStroke.hairline,
    );
  }

  @override
  bool shouldRepaint(_Stripes old) => false;
}

/// 02.3d no budget: dashed card → 00.16 BudgetSheet.
class _NoBudget extends StatelessWidget {
  const _NoBudget({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: CustomPaint(
        painter: const DashedCardPainter(AppRadius.groupCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              _Title(l.statsTrack),
              Text(
                l.statsNoBudget,
                style: AppText.body.copyWith(
                  fontSize: 20,
                  letterSpacing: -0.2,
                  height: 1.3,
                ),
              ),
              Semantics(
                button: true,
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    height: AppSpace.minTouch,
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.statsSetBudget,
                          style: AppText.label.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppColors.paper,
                          ),
                        ),
                      ],
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

/// larinya ke mana: top 4 categories, stacked bar + list.
class _Where extends StatelessWidget {
  const _Where({required this.stats});

  final Stats stats;

  static const _shades = [
    AppColors.ink,
    AppColors.grey700,
    AppColors.grey400,
    AppColors.line,
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = stats;
    final top = s.categories.take(4).toList();
    final rest = s.categories.skip(4).toList();
    int pct(int v) => s.total == 0 ? 0 : (v / s.total * 100).round();
    final note = switch (rest.length) {
      0 => l.statsTop(top.length),
      1 => l.statsMoreOne(
        rest.first.category ?? l.uncategorized,
        pct(rest.first.spent),
      ),
      _ => l.statsMoreN(rest.length),
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Title(l.statsWhere, info: note),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 12,
              color: AppColors.track,
              child: Row(
                spacing: 3,
                children: [
                  for (final (i, c) in top.indexed)
                    Flexible(
                      flex: c.spent,
                      child: Container(color: _shades[i]),
                    ),
                  if (rest.isNotEmpty)
                    Flexible(
                      flex: rest.fold(0, (a, c) => a + c.spent),
                      child: const SizedBox.expand(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final (i, c) in top.indexed)
            Container(
              height: AppSpace.row,
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.track,
                    width: AppStroke.hairline,
                  ),
                ),
              ),
              child: Row(
                spacing: 12,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _shades[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.line,
                        width: AppStroke.hairline,
                      ),
                    ),
                  ),
                  AppEmoji(c.emoji, size: 23),
                  Expanded(
                    child: Text(
                      c.category ?? l.uncategorized,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.label.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    '${pct(c.spent)}%',
                    style: AppText.label.copyWith(color: AppColors.muted),
                  ),
                  SizedBox(
                    width: 96,
                    child: Text(
                      context.rpCompact(c.spent),
                      textAlign: TextAlign.right,
                      style: AppText.label.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
