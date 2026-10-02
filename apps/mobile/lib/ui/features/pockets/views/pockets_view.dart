import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/router.dart';
import '../../../core/dashed.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/tab_bar.dart';
import '../../budget/views/budget_sheet.dart';
import '../../categories/views/category_form_sheet.dart';
import '../../categories/views/category_manage_sheet.dart';
import '../view_models/pockets_view_model.dart';
import 'set_limit_sheet.dart';

/// 02.2 kantong. Isi ulang and impian are post-MVP.
class PocketsView extends ConsumerStatefulWidget {
  const PocketsView({super.key, this.initial});

  /// Pocket (category id) to open on, from 02.1; unknown = most used.
  final String? initial;

  @override
  ConsumerState<PocketsView> createState() => _PocketsViewState();
}

final _monthFull = DateFormat.MMMM('id');

class _PocketsViewState extends ConsumerState<PocketsView> {
  @override
  void initState() {
    super.initState();
    final id = widget.initial;
    if (id != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => ref.read(selectedPocketProvider.notifier).select(id),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final PocketsState s;
    switch (ref.watch(pocketsScreenProvider)) {
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
    final muted = AppText.label.copyWith(fontSize: 14, color: AppColors.muted);
    final selected = s.selected;
    Widget gutter(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
      child: child,
    );
    // "pasang limit ke…": picks an existing category, not a new one.
    void setLimit() => showSetLimit(context, ref);

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: AppSpace.tabBarClearance),
            child: SafeArea(
              bottom: false,
              minimum: const EdgeInsets.only(top: AppSpace.contentTop),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  gutter(
                    Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(l.tabPockets, style: AppText.title),
                          ),
                        ),
                        _NewButton(label: l.pocketsSetLimit, onTap: setLimit),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  gutter(
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.pocketsLeftTitle(
                              _monthFull.format(s.month).toLowerCase(),
                            ),
                            style: muted,
                          ),
                        ),
                        _DaysChip(l.pocketsDaysLeft(s.daysLeft)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  gutter(_Amount(s.left)),
                  const SizedBox(height: 4),
                  gutter(
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _BudgetLine(
                        state: s,
                        onTap: () => editBudget(context, ref),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (selected == null)
                    gutter(_FirstPocket(onTap: setLimit))
                  else ...[
                    _Jars(
                      pockets: s.pockets,
                      selected: selected,
                      onSelect: ref
                          .read(selectedPocketProvider.notifier)
                          .select,
                      onNew: setLimit,
                    ),
                    const SizedBox(height: 18),
                    gutter(
                      _Detail(
                        pocket: selected,
                        daysLeft: s.daysLeft,
                        // A pocket is an expense category with a limit.
                        onManage: () => showCategoryForm(
                          context,
                          category: Category(
                            id: selected.id,
                            emoji: selected.emoji,
                            name: selected.name,
                            kind: CategoryKind.expense,
                            monthlyLimit: selected.budget,
                          ),
                        ),
                        onRelease: () => releaseLimit(
                          context,
                          ref,
                          id: selected.id,
                          name: selected.name,
                          limit: selected.budget,
                        ),
                      ),
                    ),
                  ],
                  if (s.free.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    gutter(
                      _FreeSection(
                        free: s.free,
                        total: s.freeSpent,
                        onPick: (f) => showSetLimit(context, ref, pick: f),
                        onMore: setLimit,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AppTabBar(
              active: AppTab.pockets,
              onSelect: (tab) => goTab(context, tab),
              onAdd: () => context.push(Routes.addEntry),
            ),
          ),
        ],
      ),
    );
  }
}

class _DaysChip extends StatelessWidget {
  const _DaysChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        text,
        style: AppText.caption.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// "Rp2,34jt dari Rp7,4jt kepake · budget Rp8jt ›" — opens 00.16.
class _BudgetLine extends StatelessWidget {
  const _BudgetLine({required this.state, required this.onTap});

  final PocketsState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final budget = state.budget;
    final muted = AppText.label.copyWith(fontSize: 14, color: AppColors.muted);
    return Transform.translate(
      offset: const Offset(-8, 0),
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Flexible(
                  child: Text.rich(
                    TextSpan(
                      text: l.pocketsSpentOf(
                        rupiahCompact(state.spent),
                        rupiahCompact(state.limit),
                      ),
                      children: [
                        TextSpan(
                          text: budget == null
                              ? l.pocketsSetBudget
                              : l.pocketsBudget(rupiahCompact(budget)),
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: budget == null
                                ? FontWeight.w600
                                : FontWeight.w400,
                            decoration: budget == null
                                ? TextDecoration.underline
                                : null,
                            decorationColor: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                ),
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 14,
                  strokeWidth: AppStroke.iconOnInkSmall,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NewButton extends StatelessWidget {
  const _NewButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.only(left: 12, right: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.ink, width: AppStroke.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedAdd01,
                size: 16,
                strokeWidth: AppStroke.iconOnInkSmall,
                color: AppColors.ink,
              ),
              Text(label, style: AppText.label.copyWith(fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero "Rp 5.060.000", long values shrink.
class _Amount extends StatelessWidget {
  const _Amount(this.value);

  final int value;

  @override
  Widget build(BuildContext context) {
    final rp = AppText.sheetTitle.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: AppColors.muted,
    );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(value < 0 ? '-Rp' : 'Rp', style: rp),
          ),
          Text(
            rupiah(value.abs()).replaceFirst('Rp', ''),
            style: AppText.display.copyWith(height: 1),
          ),
        ],
      ),
    );
  }
}

/// Toples per kantong: fill = % kepake. Left-aligned, always scrollable, a
/// dashed "limit" jar closes the row. "geser ›" and the right fade show only
/// while there's more to scroll to.
class _Jars extends StatefulWidget {
  const _Jars({
    required this.pockets,
    required this.selected,
    required this.onSelect,
    required this.onNew,
  });

  static const _width = 50.0;

  final List<Pocket> pockets;
  final Pocket selected;
  final ValueChanged<String> onSelect;
  final VoidCallback onNew;

  @override
  State<_Jars> createState() => _JarsState();
}

class _JarsState extends State<_Jars> {
  // One key per jar for good: a key hopping between jars would carry the
  // old jar's fill animation along (the selected jar filling from its
  // neighbour's level).
  final _keys = <String, GlobalKey>{};
  final _scroll = ScrollController();
  bool _more = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_measure);
    _afterLayout();
  }

  @override
  void didUpdateWidget(_Jars old) {
    super.didUpdateWidget(old);
    if (old.selected.id != widget.selected.id) _reveal();
    _afterLayout();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _afterLayout() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) _measure();
  });

  void _measure() {
    if (!_scroll.hasClients || !_scroll.position.hasContentDimensions) return;
    final p = _scroll.position;
    final more = p.maxScrollExtent > 0 && p.pixels < p.maxScrollExtent - 1;
    if (more != _more) setState(() => _more = more);
  }

  /// A deep link (02.1 pill) can select a jar scrolled off to the right.
  void _reveal() => WidgetsBinding.instance.addPostFrameCallback((_) {
    final ctx = _keys[widget.selected.id]?.currentContext;
    if (ctx != null && ctx.mounted) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: AppMotion.select,
        curve: AppMotion.ease,
      );
    }
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final small = AppText.caption.copyWith(
      fontSize: 12,
      color: AppColors.muted,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: l.pocketsCount(widget.pockets.length),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                    children: [
                      TextSpan(
                        text: l.pocketsOrder,
                        style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: small,
                ),
              ),
              if (_more)
                Row(
                  spacing: 2,
                  children: [
                    Text(l.pocketsSwipe, style: small),
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 14,
                      strokeWidth: AppStroke.iconOnInkSmall,
                      color: AppColors.muted,
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpace.gutter,
                vertical: 6,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 14,
                children: [
                  for (final p in widget.pockets)
                    _Jar(
                      key: _keys.putIfAbsent(p.id, GlobalKey.new),
                      pocket: p,
                      on: p.id == widget.selected.id,
                      label: l.pocketJarLabel(p.name, p.usedPct),
                      onTap: () => widget.onSelect(p.id),
                    ),
                  _NewJar(label: l.pocketsJarNew, onTap: widget.onNew),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            if (_more)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 48,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.paper.withValues(alpha: 0),
                          AppColors.paper,
                        ],
                      ),
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

/// Dashed "+ limit" jar closing the row: opens "pasang limit ke…".
class _NewJar extends StatelessWidget {
  const _NewJar({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l.pocketsNewJar,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          spacing: 8,
          children: [
            CustomPaint(
              painter: _DashedBox(radius: _Jars._width / 2),
              child: const SizedBox(
                width: _Jars._width,
                height: 176,
                child: Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedAdd01,
                    size: 18,
                    strokeWidth: AppStroke.iconOnInkSmall,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
            // Jar-wide, so the label never widens the row.
            SizedBox(
              width: _Jars._width,
              child: Text(
                label,
                textAlign: TextAlign.center,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: AppText.caption.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedBox extends CustomPainter {
  const _DashedBox({required this.radius});

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(AppStroke.outline / 2),
      Radius.circular(radius),
    );
    canvas.drawPath(
      dashPath(Path()..addRRect(r)),
      Paint()
        ..color = AppColors.ink
        ..strokeWidth = AppStroke.outline
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_DashedBox old) => old.radius != radius;
}

/// 02.2d: no limits yet; the whole card opens "pasang limit ke…".
class _FirstPocket extends StatelessWidget {
  const _FirstPocket({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: const _DashedBox(radius: AppRadius.inkCard),
          child: Container(
            // 214 in the design; grows if the text needs more.
            constraints: const BoxConstraints(minHeight: 214),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              spacing: 20,
              children: [
                Container(
                  width: _Jars._width,
                  height: 150,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(_Jars._width / 2),
                  ),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: _Jars._width,
                          height: 150 * 0.35,
                          color: AppColors.line,
                        ),
                      ),
                      Positioned(
                        left: 7,
                        top: 7,
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.paper,
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '🫙',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      Text(
                        l.pocketsFirstTitle,
                        style: AppText.label.copyWith(
                          fontSize: 20,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        l.pocketsFirstBody,
                        style: AppText.label.copyWith(
                          fontSize: 14,
                          height: 1.4,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 36,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          l.pocketsFirstButton,
                          style: AppText.label.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.paper,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "belum ada limit · Rp… bulan ini": expense categories with no limit, the
/// two biggest as chips (tap = their limit step), the rest behind "+n".
class _FreeSection extends StatelessWidget {
  const _FreeSection({
    required this.free,
    required this.total,
    required this.onPick,
    required this.onMore,
  });

  final List<FreeCategory> free; // most spent first
  final int total;
  final ValueChanged<FreeCategory> onPick;
  final VoidCallback onMore; // the whole list

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final style = AppText.caption.copyWith(
      fontSize: 13,
      color: AppColors.muted,
    );
    return Semantics(
      container: true,
      label: l.pocketsFreeTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: l.pocketsFreeTitle,
                    children: [
                      TextSpan(
                        text: rupiahCompact(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      TextSpan(text: l.pocketsFreeSuffix),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: style,
                ),
              ),
              const SizedBox(width: 12),
              Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showCategoryManage(context),
                  child: Row(
                    spacing: 2,
                    children: [
                      Text(
                        l.pocketsFreeManage,
                        style: style.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w500,
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
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in free.take(2))
                Semantics(
                  button: true,
                  label: l.pocketsFreeChip(f.category.name),
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: () => onPick(f),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.only(left: 6, right: 12),
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.divider,
                          width: AppStroke.hairline,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.mist,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              f.category.emoji,
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                          Text(
                            f.category.name,
                            style: style.copyWith(color: AppColors.ink),
                          ),
                          Text(rupiahCompact(f.spent), style: style),
                        ],
                      ),
                    ),
                  ),
                ),
              if (free.length > 2)
                Semantics(
                  button: true,
                  label: l.pocketsFreeMore,
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: onMore,
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.mist,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+${free.length - 2}',
                        style: style.copyWith(color: AppColors.ink),
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

class _Jar extends StatelessWidget {
  const _Jar({
    super.key,
    required this.pocket,
    required this.on,
    required this.label,
    required this.onTap,
  });

  final Pocket pocket;
  final bool on;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const w = _Jars._width, h = 176.0;
    return Semantics(
      button: true,
      selected: on,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          spacing: 8,
          children: [
            Container(
              width: w,
              height: h,
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(w / 2),
                boxShadow: on
                    ? const [
                        BoxShadow(color: AppColors.ink, spreadRadius: 4.5),
                        BoxShadow(color: AppColors.paper, spreadRadius: 3),
                      ]
                    : null,
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: AppMotion.fill,
                      curve: AppMotion.ease,
                      width: w,
                      height: h * (pocket.usedPct.clamp(0, 100) / 100),
                      color: AppColors.ink,
                    ),
                  ),
                  Positioned(
                    left: 7,
                    top: 7,
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: AppColors.paper,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        pocket.emoji,
                        style: const TextStyle(fontSize: 19),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${pocket.usedPct}%',
              style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu kantong yang dipilih.
class _Detail extends StatelessWidget {
  const _Detail({
    required this.pocket,
    required this.daysLeft,
    required this.onManage,
    required this.onRelease,
  });

  final Pocket pocket;
  final int daysLeft;
  final VoidCallback onManage; // atur limit → 03.5
  final VoidCallback onRelease; // lepas limit

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final muted = AppText.label.copyWith(fontSize: 14, color: AppColors.muted);
    final (status, ink) = switch (pocket.status) {
      PocketStatus.safe => (l.pocketStatusSafe, false),
      PocketStatus.almostOut => (l.pocketStatusAlmostOut, true),
      PocketStatus.unused => (l.pocketStatusUnused, false),
    };
    final left = pocket.left;

    return Semantics(
      container: true,
      label: l.pocketSelected,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.groupCard),
          border: Border.all(color: AppColors.ink, width: AppStroke.outline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Row(
              spacing: 8,
              children: [
                Text(pocket.emoji, style: const TextStyle(fontSize: 20)),
                Expanded(
                  child: Text(
                    pocket.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.label.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: ink ? AppColors.ink : AppColors.paper,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: ink
                        ? null
                        : Border.all(
                            color: AppColors.ink,
                            width: AppStroke.outline,
                          ),
                  ),
                  child: Text(
                    status,
                    style: AppText.caption.copyWith(
                      fontWeight: FontWeight.w500,
                      color: ink ? AppColors.paper : AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              spacing: 8,
              children: [
                Text(
                  rupiahCompact(left),
                  style: AppText.headline.copyWith(
                    fontSize: 36,
                    height: 1,
                    letterSpacing: -1.08,
                  ),
                ),
                Flexible(
                  child: Text(
                    l.pocketLeftOf(rupiahCompact(pocket.budget)),
                    style: muted,
                  ),
                ),
              ],
            ),
            Text(
              left < 0
                  ? l.pocketOver(rupiahCompact(-left))
                  : l.pocketDaily(rupiahCompact(left ~/ daysLeft), daysLeft),
              style: muted,
            ),
            const SizedBox(height: 2),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: _OutlineButton(label: l.pocketManage, onTap: onManage),
                ),
                _MistButton(label: l.pocketRelease, onTap: onRelease),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  const _OutlineButton({required this.label, required this.onTap});

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
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.ink, width: AppStroke.outline),
          ),
          child: Text(
            label,
            style: AppText.label.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MistButton extends StatelessWidget {
  const _MistButton({required this.label, required this.onTap});

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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.mist,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(label, style: AppText.label.copyWith(fontSize: 15)),
        ),
      ),
    );
  }
}
