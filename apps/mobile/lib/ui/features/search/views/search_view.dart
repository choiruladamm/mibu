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
import '../../../core/dates.dart';
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
                    _Summary(hits: hits),
                    const SizedBox(height: 14),
                    for (final t in _all ? hits : hits.take(_preview))
                      TxRow(
                        tx: t,
                        withDate: true,
                        onTap: () => context.push(Routes.transaction(t.id)),
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

/// Ink card: "N hasil • M hari" / rata² or selisih, then the total.
class _Summary extends StatelessWidget {
  const _Summary({required this.hits});

  final List<Transaction> hits;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = SearchSummary(hits);
    final right = s.count == 1
        ? dayLabel(hits.first.at)
        : s.mixed
        ? l.txNet
        : l.searchAvg(context.rpSigned(s.average));
    final muted = AppText.label.copyWith(
      fontSize: 14,
      color: AppColors.onInkMuted,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.groupCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Row(
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              context.rpSigned(s.total),
              style: AppText.displayS.copyWith(
                fontSize: 44,
                letterSpacing: -1.32,
                color: AppColors.onInk,
              ),
            ),
          ),
        ],
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
