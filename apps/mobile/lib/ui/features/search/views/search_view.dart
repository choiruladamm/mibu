import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../../domain/period.dart';
import '../../../../domain/search.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/router.dart';
import '../../../core/clock.dart';
import '../../../core/dashed.dart';
import '../../../core/finance_providers.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/meta_line.dart';
import '../../../core/widgets/nav_header.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/tx_row.dart';
import '../../transactions/view_models/transactions_view_model.dart';
import '../../../core/widgets/app_emoji.dart';

final _monthName = DateFormat('MMMM', 'id');

String _name(DateTime m) => _monthName.format(m).toLowerCase();

/// 04.2 cari: category / place / note / tag in one month (or all months),
/// the 00.14 summary card and the first 3 hits. Idle (04.2b): terakhir
/// dicari + coba cari; nothing found (04.2c): ways out.
class SearchView extends ConsumerStatefulWidget {
  const SearchView({super.key, this.month});

  /// Month to search; null = this month.
  final DateTime? month;

  @override
  ConsumerState<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends ConsumerState<SearchView> {
  static const _preview = 3;

  final _controller = TextEditingController();
  final _focus = FocusNode();
  CategoryKind? _kind; // null = semua
  int? _day; // day number in the period picked on the summary ticks
  bool _allMonths = false;
  bool _expanded = false; // all months: "liat N lagi" opens in place

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Picking a day or "liat N lagi" only holds for the current results.
  void _reset() {
    _day = null;
    _expanded = false;
  }

  void _set(String q) {
    setState(() {
      _controller.text = q;
      _controller.selection = TextSelection.collapsed(offset: q.length);
      _reset();
    });
    _remember(q);
  }

  void _remember(String q) {
    final recent = ref.read(profileProvider).value?.recentSearches;
    if (recent == null) return;
    final next = rememberSearch(recent, q);
    if (next.join('\n') == recent.join('\n')) return;
    ref.read(financeRepositoryProvider).setRecentSearches(next);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final now = ref.watch(nowProvider);
    final periods = ref.watch(periodsProvider);
    final DateTime month = widget.month ?? ref.watch(currentMonthProvider);
    final period = periods.periodForMonth(month);
    final monthName = _name(month);
    final inMonth = ref.watch(monthTransactionsProvider(month)).value ?? [];
    final all = ref.watch(allTransactionsProvider);
    final everything = all.value ?? [];
    final recent = ref.watch(profileProvider).value?.recentSearches ?? [];
    final q = _controller.text.trim();
    final pool = _allMonths ? everything : inMonth;
    final hits = searchEntries(pool, q, kind: _kind);
    final shown = _day == null
        ? hits
        : [
            for (final t in hits)
              if (SearchSummary.dayNumber(t.at, period.start) == _day) t,
          ];
    final kindLabel = {
      null: l.txAll,
      CategoryKind.expense: l.expense,
      CategoryKind.income: l.income,
    };

    void pickKind(CategoryKind? k) => setState(() {
      _kind = k;
      _reset();
    });
    void allMonths(bool on) => setState(() {
      _allMonths = on;
      _reset();
    });
    void open(Transaction t) {
      _remember(q);
      context.push(Routes.transaction(t.id));
    }

    void more() {
      _remember(q);
      if (_allMonths) {
        setState(() => _expanded = true);
        return;
      }
      context.push(
        Routes.transactionsFound(
          month,
          q,
          filter: switch (_kind) {
            null => TxFilter.all,
            CategoryKind.expense => TxFilter.expenses,
            CategoryKind.income => TxFilter.income,
          },
          day: _day,
        ),
      );
    }

    List<Widget> idle() {
      final ideas = searchIdeas(inMonth);
      return [
        if (recent.isNotEmpty)
          _Recent(
            recent: recent,
            onUse: _set,
            onDelete: (r) => ref
                .read(financeRepositoryProvider)
                .setRecentSearches([...recent]..remove(r)),
            onClear: () =>
                ref.read(financeRepositoryProvider).setRecentSearches([]),
          ),
        if (ideas.isNotEmpty) _Ideas(ideas: ideas, onPick: _set),
        if (all.hasValue && everything.isEmpty)
          _Empty(onTap: () => context.push(Routes.addEntry)),
      ];
    }

    Widget none() {
      final fix = didYouMean(everything, q);
      final elsewhere = _allMonths
          ? const <Transaction>[]
          : [
              for (final t in searchEntries(everything, q, kind: _kind))
                if (periods.periodOf(t.at).key != month) t,
            ];
      final months = {for (final t in elsewhere) periods.periodOf(t.at).key};
      final otherKind = _kind == null
          ? 0
          : searchEntries(pool, q).length; // no hits: all are the other kind
      return _None(
        title: l.searchNotFound(q),
        sub: _allMonths
            ? l.searchAllMonths
            : _kind == null
            ? l.searchSub(monthName)
            : l.searchSubKind(kindLabel[_kind]!, monthName),
        ways: [
          if (fix != null)
            (
              pre: l.searchFixPre,
              em: fix,
              post: l.searchFixPost,
              onTap: () => _set(fix),
            ),
          if (elsewhere.isNotEmpty)
            (
              pre: l.searchWayPre,
              em: l.searchWayIn(
                elsewhere.length,
                months.length == 1 ? _name(months.first) : l.searchOtherMonths,
              ),
              post: '',
              onTap: () => allMonths(true),
            ),
          if (otherKind > 0)
            (
              pre: l.searchWayPre,
              em: l.searchWayIn(
                otherKind,
                _kind == CategoryKind.income ? l.expense : l.income,
              ),
              post: '',
              onTap: () => pickKind(null),
            ),
        ],
      );
    }

    List<Widget> results() => [
      const SizedBox(height: 22),
      if (_allMonths)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l.searchAllCount(hits.length),
              style: AppText.label.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            _TextLink(
              label: l.searchBackTo(monthName),
              onTap: () => allMonths(false),
            ),
          ],
        )
      else
        _Summary(
          hits: hits,
          month: month,
          period: period,
          today: period.contains(now)
              ? SearchSummary.dayNumber(now, period.start)
              : period.length,
          selected: _day,
          onPick: (d) => setState(() => _day = d),
        ),
      const SizedBox(height: 14),
      Column(
        spacing: 4,
        children: [
          for (final t in _expanded ? shown : shown.take(_preview))
            TxRow(tx: t, withDate: true, onTap: () => open(t)),
        ],
      ),
      if (!_expanded && shown.length > _preview)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: _MoreButton(
            label: _day == null
                ? l.searchMore(shown.length - _preview)
                : l.searchMoreDay(shown.length - _preview),
            onTap: more,
          ),
        ),
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        minimum: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NavHeader(
              title: l.search,
              sub: [_allMonths ? l.searchAllMonths : l.searchSub(monthName)],
              backLabel: l.home,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.gutter,
                  14,
                  AppSpace.gutter,
                  AppSpace.s32,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  _Field(
                    controller: _controller,
                    focus: _focus,
                    hint: l.searchHint,
                    onChanged: (_) => setState(_reset),
                    onSubmitted: _remember,
                    onClear: () {
                      setState(() {
                        _controller.clear();
                        _kind = null;
                        _allMonths = false;
                        _reset();
                      });
                      _focus.requestFocus();
                    },
                  ),
                  if (q.isEmpty)
                    ...idle()
                  else ...[
                    const SizedBox(height: 16),
                    Row(
                      spacing: 8,
                      children: [
                        for (final MapEntry(key: k, value: label)
                            in kindLabel.entries)
                          _Pill(
                            label: label,
                            on: k == _kind,
                            onTap: () => pickKind(k),
                          ),
                      ],
                    ),
                    if (hits.isEmpty) none() else ...results(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 40px query, underlined, with the search glyph.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.focus,
    required this.hint,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final String hint;
  final ValueChanged<String> onChanged, onSubmitted;
  final VoidCallback onClear; // × while typing

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.ink, width: AppStroke.outline),
        ),
      ),
      child: Row(
        spacing: 12,
        children: [
          const HugeIcon(
            icon: HugeIcons.strokeRoundedSearch01,
            size: 30,
            strokeWidth: AppStroke.icon,
            color: AppColors.ink,
          ),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focus,
              autofocus: true,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.ink,
              style: AppText.inputXl.copyWith(color: AppColors.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppText.inputXl.copyWith(color: AppColors.subtle),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            // Part of the field: tapping × mustn't unfocus it first
            // (TapOutsideUnfocus) — closing the keyboard hands the old text
            // back and undoes the clear.
            TextFieldTapRegion(
              child: CircleButton(
                icon: HugeIcons.strokeRoundedCancel01,
                label: AppLocalizations.of(context)!.searchClear,
                size: 32,
                iconSize: 16,
                onTap: onClear,
              ),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.ink : AppColors.paper,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: on
                ? null
                : Border.all(color: AppColors.ink, width: AppStroke.outline),
          ),
          child: Text(
            label,
            style: AppText.label.copyWith(
              fontSize: 15,
              fontWeight: on ? FontWeight.w500 : FontWeight.w400,
              color: on ? AppColors.paper : AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// Muted 13px link with a chevron: "balik ke oktober".
class _TextLink extends StatelessWidget {
  const _TextLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 2,
          children: [
            Text(
              label,
              style: AppText.caption.copyWith(color: AppColors.muted),
            ),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 16,
              strokeWidth: AppStroke.iconOnInkSmall,
              color: AppColors.muted,
            ),
          ],
        ),
      ),
    );
  }
}

/// 00.14 SearchSummary (ink card, 212 tall): count + rata² / selisih, total,
/// badge + insight (or the picked day), one tick per day of the month,
/// footer. Tap or drag the ticks to pick a day; it snaps to the nearest day
/// with a hit.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.hits,
    required this.month,
    required this.period,
    required this.today,
    required this.selected,
    required this.onPick,
  });

  final List<Transaction> hits;
  final DateTime month; // the month label the period is named after
  final Period period;
  final int today; // day number in the period the card counts up to
  final int? selected;
  final ValueChanged<int?> onPick;

  static final _wd = DateFormat('EEE d MMM', 'id');
  static final _mo = DateFormat('MMM', 'id');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = SearchSummary(hits, today: today, start: period.start);
    final sel = s.byDay.containsKey(selected) ? selected : null;
    final last = period.length;
    final mo = _mo.format(month).toLowerCase();
    String day(int d) => _wd
        .format(
          DateTime(
            period.start.year,
            period.start.month,
            period.start.day + d - 1,
          ),
        )
        .toLowerCase();
    // Any pemasukan in the hits: every figure here can give it away (99.5).
    String money(int v) => context.rpSigned(v, income: s.income > 0);

    final right = s.count == 1
        ? day(s.byDay.keys.first)
        : s.mixed
        ? l.txNet
        : l.searchAvg(money(s.average));

    final (badge, insight) = switch (s.insight) {
      SearchInsight.mixed => (
        l.searchBadgeMixed,
        [
          l.searchInsExpense(money(s.expense)),
          l.searchInsIncome(money(s.income)),
        ],
      ),
      SearchInsight.daily => (
        l.searchBadgeDaily,
        [l.searchInsDays(s.days, today), l.searchInsStreak(s.streak)],
      ),
      SearchInsight.single => ('', [l.searchInsOnly]),
      SearchInsight.busiest => (
        l.searchBadgeBusiest,
        [
          day(s.busiestDay),
          l.searchInsTimes(s.byDay[s.busiestDay]!.count),
          money(s.byDay[s.busiestDay]!.sum),
        ],
      ),
      SearchInsight.biggest => (
        l.searchBadgeBiggest,
        [day(s.biggestDay), money(s.byDay[s.biggestDay]!.sum)],
      ),
    };

    final total = money(s.total);
    final muted = AppText.label.copyWith(
      fontSize: 14,
      color: AppColors.onInkMuted,
    );
    final small = AppText.caption.copyWith(color: AppColors.onInkMuted);
    final footer = AppText.caption.copyWith(
      fontSize: 12,
      color: AppColors.onInkMuted,
    );
    return Container(
      height: 212,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.groupCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MetaLine(
                  [
                    l.searchResults(s.count),
                    if (s.count > 1) l.searchDays(s.days),
                  ],
                  onInk: true,
                  style: muted,
                ),
                Text(right, style: muted),
              ],
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              total,
              style: AppText.displayS.copyWith(
                fontSize: total.length > 9 ? 36 : 44,
                letterSpacing: total.length > 9 ? -1.08 : -1.32,
                height: 1.1,
                color: AppColors.onInk,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 26,
            child: sel == null
                ? Row(
                    spacing: 6,
                    children: [
                      if (badge.isNotEmpty) _Badge(badge),
                      Flexible(
                        child: MetaLine(insight, onInk: true, style: small),
                      ),
                    ],
                  )
                : Row(
                    spacing: 6,
                    children: [
                      Text(
                        day(sel),
                        style: small.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onInk,
                        ),
                      ),
                      Expanded(
                        child: MetaLine(
                          [
                            l.searchInsTimes(s.byDay[sel]!.count),
                            money(s.byDay[sel]!.sum),
                          ],
                          onInk: true,
                          style: small,
                        ),
                      ),
                      _AllDays(
                        label: l.searchAllDays,
                        onTap: () => onPick(null),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          // Expanded: absorbs font-metric slack so the fixed-height card never overflows.
          Expanded(
            child: Semantics(
              label: l.searchTicksLabel,
              child: LayoutBuilder(
                builder: (context, c) {
                  void pick(Offset p) {
                    final d = s.nearestDay(
                      (p.dx / c.maxWidth * (last - 1)).round().clamp(
                            0,
                            last - 1,
                          ) +
                          1,
                    );
                    if (d == sel) return;
                    HapticFeedback.selectionClick();
                    onPick(d);
                  }

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (e) => pick(e.localPosition),
                    onHorizontalDragStart: (e) => pick(e.localPosition),
                    onHorizontalDragUpdate: (e) => pick(e.localPosition),
                    child: _Ticks(summary: s, last: last, selected: sel),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
          DefaultTextStyle(
            style: footer,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 $mo'),
                MetaLine(
                  sel != null
                      ? [l.searchTickDrag]
                      : s.count > 1
                      ? [l.searchTickHeight, l.searchTickWidth]
                      : [l.searchTickWhen],
                  onInk: true,
                  style: footer,
                ),
                Text('$last $mo'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.onInk12,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.onInk,
        ),
      ),
    );
  }
}

/// Paper chip "× semua hari": drop the picked day.
class _AllDays extends StatelessWidget {
  const _AllDays({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 26,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                size: 12,
                strokeWidth: AppStroke.iconOnInkSmall,
                color: AppColors.ink,
              ),
              Text(
                label,
                style: AppText.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One tick per day: height = |sum| of the day's hits, width = how many;
/// income-only days are outlined; a dot marks today. With a day picked the
/// other hit days dim to 35%.
class _Ticks extends StatelessWidget {
  const _Ticks({
    required this.summary,
    required this.last,
    required this.selected,
  });

  final SearchSummary summary;
  final int last;
  final int? selected;

  @override
  Widget build(BuildContext context) {
    final maxAbs = summary.byDay.values
        .map((d) => d.sum.abs())
        .fold(1, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 52,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var d = 1; d <= last; d++)
            SizedBox(
              width: 8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 3,
                children: [
                  _tick(d, maxAbs),
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: d == summary.today
                          ? AppColors.onInk
                          : Colors.transparent,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _tick(int d, int maxAbs) {
    final b = summary.byDay[d];
    final future = d > summary.today;
    final h = b != null
        ? (14 + 30 * (b.sum.abs() / maxAbs)).round()
        : future
        ? 4
        : 10;
    final w = b != null ? (2 + b.count * 2).clamp(0, 8) : 4;
    final incomeOnly = b != null && b.expense == 0;
    return AnimatedOpacity(
      duration: AppMotion.select,
      opacity: selected != null && b != null && d != selected ? 0.35 : 1,
      child: AnimatedContainer(
        duration: AppMotion.select,
        curve: AppMotion.ease,
        width: w.toDouble(),
        height: h.toDouble(),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: b == null
              ? (future ? AppColors.onInk12 : AppColors.onInk42)
              : incomeOnly
              ? Colors.transparent
              : AppColors.onInk,
          border: incomeOnly
              ? Border.all(color: AppColors.onInk, width: AppStroke.outline)
              : null,
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({required this.label, required this.onTap});

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
            color: AppColors.mist,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(label, style: AppText.label.copyWith(fontSize: 15)),
        ),
      ),
    );
  }
}

typedef _Way = ({String pre, String em, String post, VoidCallback onTap});

/// 04.2c nggak ketemu: search glyph, the line, where it looked, and the
/// ways out (maksud kamu …? / ada N di september / ada N di pemasukan).
class _None extends StatelessWidget {
  const _None({required this.title, required this.sub, required this.ways});

  final String title, sub;
  final List<_Way> ways;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 48),
        Center(
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.mist,
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedSearch01,
              size: 26,
              strokeWidth: AppStroke.icon,
              color: AppColors.ink,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          sub,
          textAlign: TextAlign.center,
          style: AppText.label.copyWith(fontSize: 14, color: AppColors.muted),
        ),
        if (ways.isNotEmpty) const SizedBox(height: 28),
        Column(
          spacing: 8,
          children: [
            for (final w in ways)
              Semantics(
                button: true,
                child: GestureDetector(
                  onTap: w.onTap,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.mist,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(text: w.pre),
                                TextSpan(
                                  text: w.em,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                TextSpan(text: w.post),
                              ],
                            ),
                            style: AppText.label.copyWith(fontSize: 15),
                          ),
                        ),
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          size: 16,
                          strokeWidth: AppStroke.iconOnInkSmall,
                          color: AppColors.ink,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Section title left, info right (no dot).
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.trailing});

  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          title,
          style: AppText.label.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing,
      ],
    );
  }
}

/// 04.2b terakhir dicari: tap = search again, × = forget it.
class _Recent extends StatelessWidget {
  const _Recent({
    required this.recent,
    required this.onUse,
    required this.onDelete,
    required this.onClear,
  });

  final List<String> recent;
  final ValueChanged<String> onUse, onDelete;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        _SectionTitle(
          title: l.searchRecent,
          trailing: Semantics(
            button: true,
            child: GestureDetector(
              onTap: onClear,
              child: Text(
                l.searchRecentClear,
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        for (final r in recent)
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
              spacing: 10,
              children: [
                Expanded(
                  child: Semantics(
                    button: true,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onUse(r),
                      child: Row(
                        spacing: 10,
                        children: [
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedClock01,
                            size: 16,
                            strokeWidth: AppStroke.icon,
                            color: AppColors.grey400,
                          ),
                          Expanded(
                            child: Text(
                              r,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.label.copyWith(fontSize: 17),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: l.searchRecentDel(r),
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onDelete(r),
                    child: const SizedBox.square(
                      dimension: 36,
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedCancel01,
                          size: 14,
                          strokeWidth: AppStroke.iconOnInkSmall,
                          color: AppColors.subtle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 04.2b coba cari: most-used places and categories this month.
class _Ideas extends StatelessWidget {
  const _Ideas({required this.ideas, required this.onPick});

  final List<({String emoji, String label})> ideas;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 28),
        _SectionTitle(
          title: l.searchTry,
          trailing: Text(
            l.searchTryHint,
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final idea in ideas)
              Semantics(
                button: true,
                child: GestureDetector(
                  onTap: () => onPick(idea.label),
                  child: Container(
                    height: AppSpace.minTouch,
                    padding: const EdgeInsets.only(left: 8, right: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: AppColors.ink,
                        width: AppStroke.outline,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 8,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.mist,
                            shape: BoxShape.circle,
                          ),
                          child: AppEmoji(idea.emoji, size: 17),
                        ),
                        Text(idea.label, style: AppText.label),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// 04.2b2 user baru: nothing to search yet → catat.
class _Empty extends StatelessWidget {
  const _Empty({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Semantics(
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: CustomPaint(
            painter: const DashedCardPainter(AppRadius.statTile),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        Text(
                          l.searchEmptyTitle,
                          style: AppText.label.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          l.searchEmptySub,
                          style: AppText.label.copyWith(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    size: 16,
                    strokeWidth: AppStroke.iconOnInkSmall,
                    color: AppColors.ink,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
