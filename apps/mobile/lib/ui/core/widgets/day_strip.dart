import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../dates.dart';
import '../tokens.dart';

/// 00.11 DayStrip — one Mon–Sun week, sliding pill on the picked day.
/// Swipe or ‹ › changes week; future days and weeks are locked.
class DayStrip extends StatefulWidget {
  const DayStrip({
    super.key,
    required this.selected,
    required this.today,
    required this.onPick,
  });

  final DateTime selected, today; // date-only
  final ValueChanged<DateTime> onPick;

  @override
  State<DayStrip> createState() => _DayStripState();
}

class _DayStripState extends State<DayStrip> {
  static final _wd = DateFormat.E('id');
  static final _mo = DateFormat.MMM('id');
  static const _pillCurve = Cubic(0.2, 0.9, 0.3, 1.2); // slight bounce

  late DateTime _week = mondayOf(widget.selected);
  int _dir = 0; // -1 = came from the left, 1 = from the right

  DateTime get _thisWeek => mondayOf(widget.today);

  @override
  void didUpdateWidget(DayStrip old) {
    super.didUpdateWidget(old);
    if (old.selected != widget.selected) _go(mondayOf(widget.selected));
  }

  void _go(DateTime week) {
    if (week.isAfter(_thisWeek) || week == _week) return;
    setState(() {
      _dir = week.isAfter(_week) ? 1 : -1;
      _week = week;
    });
  }

  void _shift(int weeks) =>
      _go(DateTime(_week.year, _week.month, _week.day + 7 * weeks));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final sel = widget.selected, today = widget.today;
    final days = [
      for (var i = 0; i < 7; i++)
        DateTime(_week.year, _week.month, _week.day + i),
    ];
    final selIndex = days.indexOf(sel);
    final inView = selIndex >= 0;
    final weeksBack = (daysBetween(_week, _thisWeek) / 7).round();
    final first = days.first, last = days.last;
    final range = first.month == last.month
        ? '${first.day}–${last.day} ${_mo.format(last).toLowerCase()}'
        : '${first.day} ${_mo.format(first).toLowerCase()} – '
              '${last.day} ${_mo.format(last).toLowerCase()}';
    final nextLocked = !_week.isBefore(_thisWeek);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: l.pickDayIn(range),
          child: GestureDetector(
            onHorizontalDragEnd: (d) {
              final v = d.primaryVelocity ?? 0;
              if (v > 200) _shift(-1);
              if (v < -200) _shift(1);
            },
            child: SizedBox(
              height: 66,
              child: LayoutBuilder(
                builder: (context, c) {
                  final cellW = c.maxWidth / 7;
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 260),
                        curve: _pillCurve,
                        left:
                            (inView
                                    ? selIndex
                                    : (sel.isBefore(first) ? -1 : 7)) *
                                cellW +
                            (cellW - 46) / 2,
                        top: 0,
                        width: 46,
                        height: 66,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 160),
                          opacity: inView ? 1 : 0,
                          child: const DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.ink,
                              borderRadius: BorderRadius.all(
                                Radius.circular(23),
                              ),
                            ),
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        transitionBuilder: (child, a) => SlideTransition(
                          position: Tween(
                            begin: Offset(_dir * 0.1, 0),
                            end: Offset.zero,
                          ).animate(a),
                          child: FadeTransition(opacity: a, child: child),
                        ),
                        child: Row(
                          key: ValueKey(_week),
                          children: [
                            for (final d in days)
                              Expanded(child: _cell(l, d, d == sel, today)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 26,
          padding: const EdgeInsets.only(left: 6),
          child: Row(
            spacing: 6,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: inView
                            ? relativeDay(l, sel, today)
                            : _weekRel(l, weeksBack),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: '  ${inView ? dayLabel(sel) : range}',
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                  style: AppText.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!inView || sel != today)
                _Chip(
                  label: inView
                      ? l.today
                      : l.backTo(
                          DateFormat('EEE d', 'id').format(sel).toLowerCase(),
                        ),
                  onTap: () =>
                      inView ? widget.onPick(today) : _go(mondayOf(sel)),
                ),
              _Arrow(
                icon: HugeIcons.strokeRoundedArrowLeft01,
                label: l.prevWeek,
                onTap: () => _shift(-1),
              ),
              _Arrow(
                icon: HugeIcons.strokeRoundedArrowRight01,
                label: l.nextWeek,
                onTap: nextLocked ? null : () => _shift(1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _weekRel(AppLocalizations l, int back) => switch (back) {
    0 => l.thisWeek,
    1 => l.lastWeek,
    _ => l.weeksAgo(back),
  };

  Widget _cell(AppLocalizations l, DateTime d, bool on, DateTime today) {
    final future = d.isAfter(today);
    final isToday = d == today;
    final firstOfMonth = d.day == 1;
    final fg = on
        ? AppColors.paper
        : future
        ? AppColors.line
        : AppColors.ink;
    final sub = on
        ? AppColors.onInkMuted
        : future
        ? AppColors.line
        : firstOfMonth
        ? AppColors.ink
        : AppColors.muted;
    return Semantics(
      button: true,
      selected: on,
      enabled: !future,
      label: [
        dayLabel(d),
        if (isToday) l.today,
        if (future) l.notYet,
      ].join(', '),
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: future ? null : () => widget.onPick(d),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 1,
          children: [
            Text(
              (firstOfMonth ? _mo : _wd).format(d).toLowerCase(),
              style: AppText.caption.copyWith(
                fontSize: 12,
                fontWeight: firstOfMonth ? FontWeight.w700 : FontWeight.w400,
                color: sub,
              ),
            ),
            Text(
              '${d.day}',
              style: AppText.body.copyWith(
                fontSize: 19,
                fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                color: fg,
              ),
            ),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isToday
                    ? (on ? AppColors.paper : AppColors.ink)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        label,
        style: AppText.caption.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.paper,
        ),
      ),
    ),
  );
}

class _Arrow extends StatelessWidget {
  const _Arrow({required this.icon, required this.label, required this.onTap});

  final List<List<dynamic>> icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    return Semantics(
      button: true,
      enabled: on,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: on ? AppColors.mist : Colors.transparent,
          ),
          child: HugeIcon(
            icon: icon,
            size: 14,
            strokeWidth: AppStroke.iconOnInkSmall,
            color: on ? AppColors.ink : AppColors.line,
          ),
        ),
      ),
    );
  }
}
