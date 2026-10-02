import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/finance_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../dates.dart';
import '../money.dart';
import '../tokens.dart';
import 'sheet.dart';
import 'meta_line.dart';

/// 00.12 DateSheet — month grid; resolves to the picked day (date-only).
Future<DateTime?> showDateSheet(
  BuildContext context, {
  required DateTime selected,
  required DateTime today,
}) => showAppSheet(context, _DateSheet(selected: selected, today: today));

class _DateSheet extends ConsumerStatefulWidget {
  const _DateSheet({required this.selected, required this.today});

  final DateTime selected, today;

  @override
  ConsumerState<_DateSheet> createState() => _DateSheetState();
}

class _DateSheetState extends ConsumerState<_DateSheet> {
  static final _monthTitle = DateFormat.yMMMM('id');
  static const _weekdays = ['sen', 'sel', 'rab', 'kam', 'jum', 'sab', 'min'];

  late DateTime _sel = widget.selected;
  late DateTime _month = DateTime(_sel.year, _sel.month);

  void _choose(DateTime d) => setState(() {
    _sel = d;
    _month = DateTime(d.year, d.month);
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final today = widget.today;
    final days = ref.watch(daysProvider(_month)).value ?? const {};
    final atNow = _month == DateTime(today.year, today.month);
    final lead = _month.weekday - 1; // Monday first
    final len = DateTime(_month.year, _month.month + 1, 0).day;
    final quick = [
      (today, l.today),
      (DateTime(today.year, today.month, today.day - 1), l.yesterday),
      (DateTime(today.year, today.month, today.day - 7), l.lastWeek),
      (DateTime(today.year, today.month), l.startOfMonth),
    ];
    final selDay = days[_sel];

    return SheetFrame(
      title: l.dateSheetTitle,
      height: 660,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 8,
              children: [
                for (final (d, label) in quick)
                  _QuickChip(
                    label: label,
                    on: d == _sel,
                    onTap: () => _choose(d),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              CircleButton(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                label: l.prevMonth,
                size: 36,
                onTap: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1),
                ),
              ),
              Expanded(
                child: Text(
                  _monthTitle.format(_month).toLowerCase(),
                  textAlign: TextAlign.center,
                  style: AppText.label.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CircleButton(
                icon: HugeIcons.strokeRoundedArrowRight01,
                label: l.nextMonth,
                size: 36,
                onTap: atNow
                    ? null
                    : () => setState(
                        () => _month = DateTime(_month.year, _month.month + 1),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final w in _weekdays)
                Expanded(
                  child: Text(
                    w,
                    textAlign: TextAlign.center,
                    style: AppText.caption.copyWith(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var row = 0; row < 6; row++)
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  for (var col = 0; col < 7; col++)
                    Expanded(
                      child: switch (row * 7 + col - lead + 1) {
                        final dd when dd >= 1 && dd <= len => _cell(
                          l,
                          DateTime(_month.year, _month.month, dd),
                          days,
                        ),
                        _ => const SizedBox(),
                      },
                    ),
                ],
              ),
            ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 1,
                    children: [
                      MetaLine.rich([
                        TextSpan(text: relativeDay(l, _sel, today)),
                        TextSpan(
                          text: dayLabel(_sel),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ], style: AppText.caption),
                      Text(
                        selDay == null
                            ? l.noEntriesThatDay
                            : l.entriesThatDay(selDay.count),
                        style: AppText.caption.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                if (selDay != null)
                  Text(
                    rupiahCompact(selDay.net),
                    style: AppText.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: l.useDate(dayLabel(_sel)),
            icon: HugeIcons.strokeRoundedTick02,
            onPressed: () => Navigator.of(context).pop(_sel),
          ),
        ],
      ),
    );
  }

  Widget _cell(
    AppLocalizations l,
    DateTime d,
    Map<DateTime, ({int count, int net})> days,
  ) {
    final today = widget.today;
    final future = d.isAfter(today), on = d == _sel, isToday = d == today;
    final count = days[d]?.count ?? 0;
    return Semantics(
      button: true,
      selected: on,
      enabled: !future,
      label: [
        dayLabel(d),
        if (isToday) l.today,
        if (count > 0) '$count ${l.noteButton}',
        if (future) l.notYet,
      ].join(', '),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: future ? null : () => _choose(d),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 3,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: on ? AppColors.ink : Colors.transparent,
                border: !on && isToday
                    ? Border.all(color: AppColors.ink, width: AppStroke.outline)
                    : null,
              ),
              child: Text(
                '${d.day}',
                style: AppText.label.copyWith(
                  fontWeight: on || isToday ? FontWeight.w600 : FontWeight.w400,
                  color: on
                      ? AppColors.paper
                      : future
                      ? AppColors.line
                      : AppColors.ink,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 2,
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    width: 3,
                    height: 3,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < count ? AppColors.ink : Colors.transparent,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: on,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: on ? AppColors.ink : AppColors.paper,
          borderRadius: BorderRadius.circular(18),
          border: on
              ? null
              : Border.all(color: AppColors.ink, width: AppStroke.outline),
        ),
        child: Text(
          label,
          style: AppText.caption.copyWith(
            color: on ? AppColors.paper : AppColors.ink,
          ),
        ),
      ),
    ),
  );
}
