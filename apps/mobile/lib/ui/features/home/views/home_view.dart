import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/router.dart';
import '../../../core/dashed.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/month_picker.dart';
import '../../../core/widgets/tab_bar.dart';
import '../../../core/widgets/tx_row.dart';
import '../view_models/home_view_model.dart';

/// 02.1 beranda.
class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  static final _monthFull = DateFormat.MMMM('id');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeState s;
    switch (ref.watch(homeProvider)) {
      case AsyncData(:final value):
        s = value;
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
        return const Scaffold();
    }
    final l = AppLocalizations.of(context)!;
    final caption = AppText.caption.copyWith(color: AppColors.muted);
    final link = AppText.caption.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: AppColors.ink,
    );

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpace.tabBarClearance),
            child: SafeArea(
              bottom: false,
              minimum: const EdgeInsets.only(top: AppSpace.contentTop),
              child: Builder(
                builder: (context) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _gutter(
                      Row(
                        children: [
                          Text('mibu', style: AppText.wordmark(30)),
                          const Spacer(),
                          // ponytail: 00.8 MonthMenu not sliced yet.
                          MonthPicker(
                            label: _monthFull
                                .format(s.selectedMonth.month)
                                .toLowerCase(),
                            onTap: null,
                          ),
                          const SizedBox(width: 8),
                          _SearchButton(label: l.search),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _Hero(balance: s.balance, safeToSpend: s.safeToSpendToday),
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
                    _BalanceChart(
                      state: s,
                      onSelect: ref.read(selectedMonthProvider.notifier).select,
                    ),
                    const SizedBox(height: 18),
                    _gutter(
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(l.tabPockets, style: caption),
                          GestureDetector(
                            onTap: () => goTab(context, AppTab.pockets),
                            child: Text(l.seeAll, style: link),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    _gutter(
                      Row(
                        spacing: 8,
                        children: [
                          for (final (i, p) in s.pockets.indexed)
                            Expanded(
                              child: _PocketChip(pocket: p, ink: i == 0),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _gutter(
                      Container(
                        padding: const EdgeInsets.only(bottom: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.line,
                              width: AppStroke.hairline,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l.homeRecent,
                              style: AppText.caption.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push(Routes.transactions),
                              child: Text(l.seeAll, style: link),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _gutter(
                      Column(
                        spacing: 2,
                        children: [
                          for (final tx in s.recent)
                            TxRow(tx: tx, onTap: () {}), // → 04.3 detail
                        ],
                      ),
                    ),
                  ],
                ),
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
        ],
      ),
    );
  }

  static Widget _gutter(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
    child: child,
  );
}

class _SearchButton extends StatelessWidget {
  const _SearchButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: () {}, // → 04.2 cari
        child: Container(
          alignment: Alignment.center,
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: AppColors.mist,
            shape: BoxShape.circle,
          ),
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedSearch01,
            size: 20,
            strokeWidth: AppStroke.icon,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.balance, required this.safeToSpend});

  final int balance, safeToSpend;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final digits = rupiah(balance).replaceFirst('Rp', '');
    return Column(
      children: [
        Text(
          l.balanceLabel,
          style: AppText.label.copyWith(fontSize: 14, color: AppColors.muted),
        ),
        const SizedBox(height: 6),
        // Long balances shrink instead of overflowing.
        _gutterFit(
          Row(
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
              Text(digits, style: AppText.display.copyWith(height: 1)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 34,
          padding: const EdgeInsets.only(left: 6, right: 14),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Container(
                alignment: Alignment.center,
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: safeToSpend < 0
                      ? HugeIcons.strokeRoundedAlert02
                      : HugeIcons.strokeRoundedTick02,
                  size: 14,
                  strokeWidth: AppStroke.iconOnInkSmall,
                  color: AppColors.ink,
                ),
              ),
              Flexible(
                child: Text.rich(
                  overflow: TextOverflow.ellipsis,
                  TextSpan(
                    text:
                        '${safeToSpend < 0 ? l.overspentToday : l.safeToSpendToday} · ',
                    children: [
                      TextSpan(
                        text: rupiahCompact(safeToSpend.abs()),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  style: AppText.label.copyWith(
                    fontSize: 14,
                    color: AppColors.paper,
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

Widget _gutterFit(Widget child) => Padding(
  padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
  child: FittedBox(fit: BoxFit.scaleDown, child: child),
);

class _PocketChip extends StatelessWidget {
  const _PocketChip({required this.pocket, required this.ink});

  final Pocket pocket;
  final bool ink; // most-used pocket is highlighted

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => goTab(context, AppTab.pockets),
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ink ? AppColors.ink : AppColors.mist,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          '${pocket.emoji} ${pocket.usedPct}%',
          style: AppText.label.copyWith(
            fontSize: 14,
            fontWeight: ink ? FontWeight.w500 : FontWeight.w400,
            color: ink ? AppColors.paper : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// "saldo per bulan" — curve through month balances, tap a month to peek.
class _BalanceChart extends StatelessWidget {
  const _BalanceChart({required this.state, required this.onSelect});

  final HomeState state;
  final ValueChanged<int> onSelect;

  static const _height = 186.0;
  static const _base = 150.0; // stems end here
  static const _top = 22.0, _bottom = 120.0; // y of max / min balance
  static final _monthShort = DateFormat.MMM('id');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final months = state.months;
    final sel = state.selected;
    const now = HomeState.nowIndex;
    if (months.length < 2) return const SizedBox(height: _height);

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        // Design: points at x = 33 … 360 on a 390 frame.
        final xs = [
          for (var i = 0; i < months.length; i++)
            w * (33 + i * 327 / (months.length - 1)) / 390,
        ];
        final amounts = months.map((m) => m.amount);
        final lo = amounts.reduce(math.min), hi = amounts.reduce(math.max);
        final ys = [
          for (final m in months)
            hi == lo
                ? (_top + _bottom) / 2
                : _bottom - (m.amount - lo) / (hi - lo) * (_bottom - _top),
        ];
        final pillTop = [
          if (sel == now) l.today,
          if (sel > now) l.prediction,
          _monthShort.format(months[sel].month).toLowerCase(),
        ].join(' · ');
        final pillVal =
            '${sel > now ? '± ' : ''}${rupiahCompact(months[sel].amount)}';

        return SizedBox(
          height: _height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _ChartPainter(xs: xs, ys: ys, sel: sel, now: now),
                ),
              ),
              for (var i = 0; i < months.length; i++)
                Positioned(
                  left: xs[i] - 28,
                  top: 0,
                  width: 56,
                  height: _height,
                  child: Semantics(
                    button: true,
                    selected: i == sel,
                    label: _monthShort.format(months[i].month).toLowerCase(),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(i),
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
              AnimatedPositioned(
                duration: AppMotion.select,
                curve: AppMotion.ease,
                left: xs[sel].clamp(60, w - 60),
                top: ys[sel] < 60 ? ys[sel] + 18 : ys[sel] - 58,
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
                          Text(
                            pillTop,
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
    required this.sel,
    required this.now,
  });

  final List<double> xs, ys;
  final int sel, now;

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
      final line = Path()
        ..moveTo(p.dx, p.dy)
        ..lineTo(p.dx, _BalanceChart._base);
      if (i == sel) {
        canvas.drawPath(
          line,
          stem
            ..color = AppColors.ink
            ..strokeWidth = AppStroke.outline,
        );
        canvas.drawCircle(p, 12, fill..color = AppColors.paper); // 3px ring
        canvas.drawCircle(p, 9, fill..color = AppColors.ink);
      } else {
        canvas.drawPath(
          dashPath(line, dash: 3, gap: 3),
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
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.sel != sel || old.now != now || old.xs != xs || old.ys != ys;
}
