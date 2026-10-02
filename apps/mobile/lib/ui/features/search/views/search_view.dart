import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../../domain/search.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/router.dart';
import '../../../core/clock.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/meta_line.dart';
import '../../../core/widgets/nav_header.dart';
import '../../../core/widgets/tx_row.dart';
import '../../transactions/view_models/transactions_view_model.dart';

final _monthName = DateFormat('MMMM', 'id');

/// 04.2 cari, versi simpel: category / place / note / tag in one month, a
/// summary card and the first 3 hits. The draggable day ticks
/// (SearchSummary 00.14) are post-MVP.
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
  CategoryKind? _kind; // null = semua
  bool _all = false; // "liat N lagi" pressed

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _set(String q) => setState(() {
    _controller.text = q;
    _controller.selection = TextSelection.collapsed(offset: q.length);
    _all = false;
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final now = ref.watch(nowProvider);
    final month = widget.month ?? DateTime(now.year, now.month);
    final monthName = _monthName.format(month).toLowerCase();
    final entries = ref.watch(monthTransactionsProvider(month)).value ?? [];
    final q = _controller.text.trim();
    final hits = searchEntries(entries, q, kind: _kind);

    final filters = {
      null: l.txAll,
      CategoryKind.expense: l.expense,
      CategoryKind.income: l.income,
    };

    return Scaffold(
      body: SafeArea(
        bottom: false,
        minimum: const EdgeInsets.only(top: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            NavHeader(
              title: l.search,
              sub: [l.searchSub(monthName)],
              backLabel: l.home,
              actionIcon: HugeIcons.strokeRoundedCancel01,
              actionLabel: l.searchClear,
              onAction: () => _set(''),
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
                    hint: l.searchHint,
                    onChanged: (_) => setState(() => _all = false),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final MapEntry(key: k, value: label)
                          in filters.entries)
                        _Pill(
                          label: label,
                          on: k == _kind,
                          onTap: () => setState(() {
                            _kind = k;
                            _all = false;
                          }),
                        ),
                    ],
                  ),
                  if (q.isEmpty)
                    _Ideas(
                      title: l.searchTry,
                      ideas: [
                        for (final c
                            in ref.watch(categoriesProvider).value ??
                                const <Category>[])
                          if (c.kind == CategoryKind.expense) c.name,
                      ].take(6).toList(),
                      onPick: _set,
                    )
                  else if (hits.isEmpty)
                    _None(text: l.searchNone(q, monthName))
                  else ...[
                    const SizedBox(height: 22),
                    _Summary(
                      hits: hits,
                      month: month,
                      today: month.year == now.year && month.month == now.month
                          ? now.day
                          : DateTime(month.year, month.month + 1, 0).day,
                    ),
                    const SizedBox(height: 14),
                    Column(
                      spacing: 4,
                      children: [
                        for (final t in _all ? hits : hits.take(_preview))
                          TxRow(
                            tx: t,
                            withDate: true,
                            onTap: () => context.push(Routes.transaction(t.id)),
                          ),
                      ],
                    ),
                    if (!_all && hits.length > _preview)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: _MoreButton(
                          label: l.searchMore(hits.length - _preview),
                          onTap: () => setState(() => _all = true),
                        ),
                      ),
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
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

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
              autofocus: true,
              onChanged: onChanged,
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

/// 00.14 SearchSummary (ink card, 212 tall): count + rata² / selisih, total,
/// badge + insight, one tick per day of the month, footer. Day picking by
/// dragging the ticks is post-MVP.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.hits,
    required this.month,
    required this.today,
  });

  final List<Transaction> hits;
  final DateTime month; // first of month
  final int today; // day of month the card counts up to

  static final _wd = DateFormat('EEE d MMM', 'id');
  static final _mo = DateFormat('MMM', 'id');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = SearchSummary(hits, today: today);
    final last = DateTime(month.year, month.month + 1, 0).day;
    final mo = _mo.format(month).toLowerCase();
    String day(int d) =>
        _wd.format(DateTime(month.year, month.month, d)).toLowerCase();
    String money(int v) => context.rpSigned(v);

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
            child: Row(
              spacing: 6,
              children: [
                if (badge.isNotEmpty)
                  Container(
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.onInk12,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      badge,
                      style: AppText.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onInk,
                      ),
                    ),
                  ),
                Flexible(child: MetaLine(insight, onInk: true, style: small)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _Ticks(summary: s, last: last),
          const SizedBox(height: 6),
          DefaultTextStyle(
            style: AppText.caption.copyWith(
              fontSize: 12,
              color: AppColors.onInkMuted,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 $mo'),
                MetaLine(
                  s.count > 1
                      ? [l.searchTickHeight, l.searchTickWidth]
                      : [l.searchTickWhen],
                  onInk: true,
                  style: AppText.caption.copyWith(
                    fontSize: 12,
                    color: AppColors.onInkMuted,
                  ),
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

/// One tick per day: height = |sum| of the day's hits, width = how many;
/// income-only days are outlined; a dot marks today.
class _Ticks extends StatelessWidget {
  const _Ticks({required this.summary, required this.last});

  final SearchSummary summary;
  final int last;

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
            Semantics(
              label: '$d',
              child: SizedBox(
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
    return Container(
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

class _None extends StatelessWidget {
  const _None({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        spacing: 10,
        children: [
          Text(
            context.rp(0),
            style: AppText.displayS.copyWith(
              fontSize: 44,
              letterSpacing: -1.32,
            ),
          ),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppText.label.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Ideas extends StatelessWidget {
  const _Ideas({
    required this.title,
    required this.ideas,
    required this.onPick,
  });

  final String title;
  final List<String> ideas;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    if (ideas.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(title, style: AppText.caption.copyWith(color: AppColors.muted)),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final idea in ideas)
                Semantics(
                  button: true,
                  child: GestureDetector(
                    onTap: () => onPick(idea),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.ink,
                          width: AppStroke.outline,
                        ),
                      ),
                      child: Text(
                        idea,
                        style: AppText.label.copyWith(fontSize: 19),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
