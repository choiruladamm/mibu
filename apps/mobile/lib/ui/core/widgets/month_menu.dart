import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../tokens.dart';

/// 00.8 MonthMenu — popover under 00.7 MonthPicker: 12 months of a year with
/// a mini bar of spending each; months after [now]'s, and before [min]'s,
/// are locked.
class MonthMenu extends StatefulWidget {
  const MonthMenu({
    super.key,
    required this.selected,
    required this.now,
    required this.spent,
    required this.onPick,
    this.min,
  });

  /// First of the picked month.
  final DateTime selected;
  final DateTime now;

  /// First of month → expenses, for the mini bars.
  final Map<DateTime, int> spent;
  final ValueChanged<DateTime> onPick;

  /// First month with entries (first of month); earlier months are locked
  /// and the year step stops at its year. Null = no lower limit.
  final DateTime? min;

  static const width = 300.0;

  @override
  State<MonthMenu> createState() => _MonthMenuState();
}

class _MonthMenuState extends State<MonthMenu> {
  static final _short = DateFormat.MMM('id');
  static final _full = DateFormat.MMMM('id');

  late int _year = widget.selected.year;

  DateTime get _cur => DateTime(widget.now.year, widget.now.month);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final peak = widget.spent.values.fold(0, math.max);
    final onNow = widget.selected == _cur;

    return Semantics(
      scopesRoute: true,
      explicitChildNodes: true,
      label: l.monthMenuTitle,
      child: Container(
        width: MonthMenu.width,
        padding: const EdgeInsets.all(AppSpace.s16),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadius.groupCard),
          border: Border.all(color: AppColors.divider),
          boxShadow: AppShadows.float,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 36,
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        l.monthMenuTitle,
                        style: AppText.label.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  _YearStep(
                    label: l.monthMenuPrevYear,
                    icon: HugeIcons.strokeRoundedArrowLeft01,
                    onTap: widget.min == null || _year > widget.min!.year
                        ? () => setState(() => _year--)
                        : null,
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '$_year',
                      textAlign: TextAlign.center,
                      style: AppText.label.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  _YearStep(
                    label: l.monthMenuNextYear,
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    onTap: _year < _cur.year
                        ? () => setState(() => _year++)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              mainAxisExtent: 52,
              padding: EdgeInsets.zero,
              children: [
                for (var m = 1; m <= 12; m++)
                  _Cell(
                    month: DateTime(_year, m),
                    label: _short.format(DateTime(_year, m)).toLowerCase(),
                    semantics: _semantics(l, DateTime(_year, m)),
                    selected: DateTime(_year, m) == widget.selected,
                    isNow: DateTime(_year, m) == _cur,
                    locked: _isLocked(DateTime(_year, m)),
                    fill: peak == 0
                        ? 0
                        : (widget.spent[DateTime(_year, m)] ?? 0) / peak,
                    onTap: () => widget.onPick(DateTime(_year, m)),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      spacing: 6,
                      children: [
                        Container(
                          width: 16,
                          height: 3,
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            l.monthMenuLegend,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption.copyWith(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  child: GestureDetector(
                    onTap: () => widget.onPick(_cur),
                    child: Container(
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: onNow ? AppColors.mist : AppColors.ink,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        l.monthMenuNow,
                        style: AppText.label.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: onNow ? AppColors.subtle : AppColors.paper,
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
    );
  }

  bool _isLocked(DateTime m) =>
      m.isAfter(_cur) || (widget.min != null && m.isBefore(widget.min!));

  String _semantics(AppLocalizations l, DateTime m) => [
    l.monthMenuCell(_full.format(m).toLowerCase(), m.year),
    if (m.isAfter(_cur))
      l.monthMenuFuture
    else if (_isLocked(m))
      l.monthMenuEarly,
    if (m == _cur) l.monthMenuNow,
  ].join(', ');
}

class _YearStep extends StatelessWidget {
  const _YearStep({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final List<List<dynamic>> icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final off = onTap == null;
    return Semantics(
      button: true,
      enabled: !off,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: off ? Colors.transparent : AppColors.mist,
            shape: BoxShape.circle,
          ),
          child: HugeIcon(
            icon: icon,
            size: 16,
            strokeWidth: AppStroke.iconOnInkSmall,
            color: off ? AppColors.line : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.month,
    required this.label,
    required this.semantics,
    required this.selected,
    required this.isNow,
    required this.locked,
    required this.fill,
    required this.onTap,
  });

  final DateTime month;
  final String label, semantics;
  final bool selected, isNow, locked;
  final double fill; // 0–1, share of the busiest month
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.ink
        : locked
        ? Colors.transparent
        : AppColors.mist;
    final fg = selected
        ? AppColors.paper
        : locked
        ? AppColors.line
        : AppColors.ink;
    return Semantics(
      button: true,
      selected: selected,
      enabled: !locked,
      label: semantics,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: locked ? null : onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: selected
                ? null
                : isNow
                ? Border.all(color: AppColors.ink, width: AppStroke.outline)
                : locked
                ? Border.all(color: AppColors.divider)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 6,
            children: [
              Text(
                label,
                style: AppText.label.copyWith(
                  fontSize: 15,
                  fontWeight: selected || isNow
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: fg,
                ),
              ),
              if (!locked)
                Container(
                  width: 28,
                  height: 3,
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.centerLeft,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.onInk8 : AppColors.pressed,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    widthFactor: fill.clamp(0.0, 1.0),
                    child: ColoredBox(
                      color: selected ? AppColors.paper : AppColors.ink,
                      child: const SizedBox(height: 3),
                    ),
                  ),
                )
              else
                const SizedBox(height: 3),
            ],
          ),
        ),
      ),
    );
  }
}
