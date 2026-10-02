import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/new_tile.dart';
import '../../../core/widgets/sheet.dart';
import '../view_models/categories_view_model.dart';
import 'category_delete_sheet.dart';
import 'category_form_sheet.dart';
import '../../../core/widgets/meta_line.dart';
import '../../../core/widgets/app_emoji.dart';
import '../../../core/widgets/icon_sheet.dart';
import '../../../core/widgets/toast.dart';
import '../../../core/finance_providers.dart';

/// 03.3 buat apa aja — from 03.2 "atur" and 02.4. Its own messenger, so
/// "ikon diganti" floats over the sheet instead of behind it.
Future<void> showCategoryManage(BuildContext context) => showAppSheet(
  context,
  const SizedBox(
    height: _height,
    child: ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CategoryManageSheet(),
      ),
    ),
  ),
);

const _height = 700.0;

class CategoryManageSheet extends ConsumerStatefulWidget {
  const CategoryManageSheet({super.key});

  @override
  ConsumerState<CategoryManageSheet> createState() =>
      _CategoryManageSheetState();
}

class _CategoryManageSheetState extends ConsumerState<CategoryManageSheet>
    with SingleTickerProviderStateMixin {
  // Mode hapus (03.3d): tiles wiggle ±2°, out of phase by column. Only runs
  // while deleting, so normal mode has no endless animation.
  late final _wiggle = AnimationController(
    vsync: this,
    duration: AppMotion.wiggle,
  );

  List<String>? _order; // ids while dragging; null = db order
  String? _iconFor; // tile whose IconSheet is open
  bool _del = false;

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  void _setDel(bool on) {
    setState(() => _del = on);
    if (on && !MediaQuery.disableAnimationsOf(context)) {
      _wiggle.repeat();
    } else {
      _wiggle.stop();
    }
  }

  void _moveTo(String dragged, String target) {
    final order = _order;
    if (order == null || dragged == target) return;
    final to = order.indexOf(target);
    setState(() {
      order
        ..remove(dragged)
        ..insert(to, dragged);
    });
  }

  /// Tap ikon: IconSheet, saved right away, toast with batalin.
  Future<void> _swapIcon(Category c) async {
    setState(() => _iconFor = c.id);
    final emoji = await showIconSheet(context, selected: c.emoji);
    if (!mounted) return;
    setState(() => _iconFor = null);
    if (emoji == null || emoji == c.emoji) return;
    final repo = ref.read(financeRepositoryProvider);
    Future<void> save(String e) => repo.updateCategory(
      c.id,
      emoji: e,
      name: c.name,
      kind: c.kind,
      monthlyLimit: c.monthlyLimit,
      period: ref.read(currentPeriodProvider),
    );
    await save(emoji);
    if (!mounted) return;
    final l = AppLocalizations.of(context)!;
    showToast(
      context,
      icon: ToastIcon.check,
      title: l.manageIconSwapped(c.name),
      sub: l.manageIconSwappedSub,
      onUndo: () => save(c.emoji),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cats = ref.watch(categoriesProvider).value ?? const <Category>[];
    final usage = ref.watch(categoryUsageProvider).value ?? const {};
    final byId = {for (final c in cats) c.id: c};
    final shown = [
      for (final id in _order ?? [for (final c in cats) c.id]) ?byId[id],
    ];
    final income = cats.where((c) => c.kind == CategoryKind.income);
    final uncategorized = ref.watch(uncategorizedCountProvider);
    TextSpan hint(String text, String bold) => TextSpan(
      children: [
        TextSpan(
          text: bold,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
        TextSpan(text: text.substring(bold.length)),
      ],
    );

    return SheetFrame(
      title: _del ? l.manageTitleDelete : l.manageTitle,
      titleSize: 26,
      height: _height,
      scrollable: false,
      actions: [
        if (!_del)
          _DeleteModeButton(
            label: l.manageDeleteMode,
            onTap: () => _setDel(true),
          ),
      ],
      close: _DoneButton(
        label: _del ? l.manageDeleteDone : l.manageDone,
        onTap: _del ? () => _setDel(false) : () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          MetaLine.rich(
            _del
                ? [
                    hint(l.manageHintMinus, l.manageHintMinusBold),
                    TextSpan(text: l.manageHintMoved),
                  ]
                : [
                    hint(l.manageHintIcon, l.manageHintIconBold),
                    hint(l.manageHintName, l.manageHintNameBold),
                    TextSpan(text: l.manageHintMove),
                  ],
            tight: true,
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 8,
              mainAxisExtent: 114,
              children: [
                for (final (i, c) in shown.indexed)
                  _DraggableTile(
                    key: ValueKey(c.id),
                    category: c,
                    uses: usage[c.id]?.count ?? 0,
                    iconOpen: c.id == _iconFor,
                    del: _del,
                    wiggle: _del ? _wiggle : null,
                    phase: (i % 4) * 0.25,
                    onDelete: () => showCategoryDelete(context, c),
                    onIcon: () => _swapIcon(c),
                    onTap: () => showCategoryForm(context, category: c),
                    onDragStart: () => _order = [for (final c in shown) c.id],
                    onHover: (dragged) => _moveTo(dragged, c.id),
                    onDragEnd: () async {
                      final order = _order;
                      if (order == null) return;
                      await ref
                          .read(financeRepositoryProvider)
                          .reorderCategories(order);
                      if (mounted) setState(() => _order = null);
                    },
                  ),
                // "lain-lain": entries without a buat apa. Not a row in the
                // database, so it can't be edited, dragged or deleted.
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: _Tile(
                    category: Category(
                      id: '',
                      emoji: '🧾',
                      name: l.uncategorized,
                      kind: CategoryKind.expense,
                    ),
                    uses: uncategorized == 0
                        ? l.categoryUnused
                        : l.manageUses(uncategorized),
                    iconOpen: false,
                    system: true,
                    badge: _Badge.locked,
                    dim: _del,
                  ),
                ),
                if (!_del)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: NewCategoryTile(
                      label: l.categoryNew,
                      onTap: () => showCategoryForm(
                        context,
                        origin: CategoryOrigin.atur,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_del)
            const _LockedNote()
          else
            _JarNote(income: income.firstOrNull?.name),
        ],
      ),
    );
  }
}

/// Outlined 40px tong sampah in the header: enters mode hapus.
class _DeleteModeButton extends StatelessWidget {
  const _DeleteModeButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ink, width: AppStroke.outline),
          ),
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedDelete02,
            size: 18,
            strokeWidth: AppStroke.icon,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.label, required this.onTap});

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
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            style: AppText.label.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.paper,
            ),
          ),
        ),
      ),
    );
  }
}

/// Tahan & geser: long-press picks a tile up; hovering another moves it
/// there; dropping saves the order. Tap ikon = IconSheet, tap nama = 03.5.
/// In mode hapus ([del]) tiles wiggle, can't be dragged, and tap − = 03.6;
/// gajian is locked there.
class _DraggableTile extends StatelessWidget {
  const _DraggableTile({
    super.key,
    required this.category,
    required this.uses,
    required this.iconOpen,
    required this.del,
    required this.wiggle,
    required this.phase,
    required this.onDelete,
    required this.onIcon,
    required this.onTap,
    required this.onDragStart,
    required this.onHover,
    required this.onDragEnd,
  });

  final Category category;
  final int uses;
  final bool iconOpen, del;
  final Animation<double>? wiggle; // only while [del]
  final double phase; // 0–1
  final VoidCallback onDelete, onIcon, onTap, onDragStart, onDragEnd;
  final ValueChanged<String> onHover;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locked = del && category.isPayday;
    _Tile tile({bool live = false}) => _Tile(
      category: category,
      uses: uses == 0 ? l.categoryUnused : l.manageUses(uses),
      limit: switch (category.monthlyLimit) {
        final v? => l.manageLimit(rupiahCompact(v)),
        null => null,
      },
      iconOpen: iconOpen,
      system: del,
      badge: !del
          ? null
          : locked
          ? _Badge.locked
          : _Badge.delete,
      dim: locked,
      onIcon: live && !del ? onIcon : null,
      onTap: live && !del ? onTap : null,
      onBadge: live && del && !locked ? onDelete : null,
    );

    Widget wiggly(Widget child) {
      final w = wiggle;
      if (w == null || locked) return child;
      return AnimatedBuilder(
        animation: w,
        builder: (_, c) => Transform.rotate(
          angle:
              math.sin(2 * math.pi * (w.value + phase)) *
              AppMotion.wiggleAngle *
              math.pi /
              180,
          child: c,
        ),
        child: child,
      );
    }

    if (del) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: wiggly(tile(live: true)),
      );
    }
    return DragTarget<String>(
      onWillAcceptWithDetails: (d) {
        onHover(d.data);
        return true;
      },
      builder: (context, _, _) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: LongPressDraggable<String>(
          data: category.id,
          onDragStarted: onDragStart,
          onDragEnd: (_) => onDragEnd(),
          feedback: Material(
            color: Colors.transparent,
            child: SizedBox(width: 76, child: tile()),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: tile()),
          child: tile(live: true),
        ),
      ),
    );
  }
}

/// Corner badge on a tile in mode hapus: − (delete) or 🔒 (locked).
enum _Badge { delete, locked }

class _Tile extends StatelessWidget {
  const _Tile({
    required this.category,
    required this.uses,
    required this.iconOpen,
    this.limit,
    this.system = false,
    this.badge,
    this.dim = false,
    this.onIcon,
    this.onTap,
    this.onBadge,
  });

  final Category category;
  final String uses;
  final String? limit; // "limit Rp…" ink chip, replaces [uses]
  final bool iconOpen; // its IconSheet is up: paper disc, ink ring
  final bool system; // plain disc: no pencil, name isn't a link
  final _Badge? badge;
  final bool dim; // locked in mode hapus
  final VoidCallback? onIcon, onTap, onBadge; // null = not tappable

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final disc = Container(
      width: 60,
      height: 60,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: iconOpen ? AppColors.paper : AppColors.mist,
        shape: BoxShape.circle,
        border: iconOpen ? Border.all(color: AppColors.ink, width: 2) : null,
      ),
      child: AppEmoji(category.emoji, size: 34),
    );
    return Opacity(
      opacity: dim ? 0.45 : 1,
      child: Column(
        spacing: 4,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              if (system)
                disc
              else
                Semantics(
                  container: true,
                  button: true,
                  label: l.manageIcon(category.name),
                  excludeSemantics: true,
                  child: GestureDetector(
                    onTap: onIcon,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        disc,
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.paper,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.ink,
                                width: AppStroke.outline,
                              ),
                            ),
                            child: const HugeIcon(
                              icon: HugeIcons.strokeRoundedPencilEdit02,
                              size: 10,
                              strokeWidth: 2.6,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (badge case final b?)
                Positioned(
                  left: -4,
                  top: -4,
                  child: switch (b) {
                    _Badge.delete => Semantics(
                      container: true,
                      button: true,
                      label: l.manageDelete(category.name),
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: onBadge,
                        child: Container(
                          width: 26,
                          height: 26,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: AppColors.ink,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.paper,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedMinusSign,
                            size: 12,
                            strokeWidth: 3,
                            color: AppColors.onInk,
                          ),
                        ),
                      ),
                    ),
                    _Badge.locked => Semantics(
                      container: true,
                      label: l.manageLocked,
                      excludeSemantics: true,
                      child: Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.mist,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppColors.paper, spreadRadius: 2),
                          ],
                        ),
                        child: const HugeIcon(
                          icon: HugeIcons.strokeRoundedSquareLock02,
                          size: 11,
                          strokeWidth: 2.4,
                          color: AppColors.grey400,
                        ),
                      ),
                    ),
                  },
                ),
            ],
          ),
          Semantics(
            button: onTap != null,
            label: system ? category.name : l.manageEdit(category.name),
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Column(
                spacing: 4,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(
                      decoration: system ? null : TextDecoration.underline,
                      decorationColor: AppColors.line,
                    ),
                  ),
                  if (limit case final text?)
                    Container(
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        text,
                        maxLines: 1,
                        style: AppText.micro.copyWith(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.onInk,
                        ),
                      ),
                    )
                  else
                    Text(
                      uses,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.micro.copyWith(color: AppColors.muted),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mode hapus footer: why lain-lain and gajian can't go.
class _LockedNote extends StatelessWidget {
  const _LockedNote();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(AppRadius.statTile),
      ),
      child: Row(
        spacing: 12,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.paper,
              shape: BoxShape.circle,
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedSquareLock02,
              size: 11,
              strokeWidth: 2.4,
              color: AppColors.grey400,
            ),
          ),
          Expanded(
            child: Text(
              l.manageLockedNote,
              style: AppText.label.copyWith(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🫙 "yang ada limit jadi toples di tab kantong." + the income note.
class _JarNote extends StatelessWidget {
  const _JarNote({required this.income});

  final String? income; // first income category's name

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bold = l.manageJarNoteLimit;
    final [before, after] = l.manageJarNote(bold).split(bold).take(2).toList();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(AppRadius.statTile),
      ),
      child: Row(
        spacing: 12,
        children: [
          const AppEmoji('🫙', size: 25),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: before,
                children: [
                  TextSpan(
                    text: bold,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: after),
                  if (income != null)
                    TextSpan(text: ' ${l.manageIncomeNote(income!)}'),
                ],
              ),
              style: AppText.label.copyWith(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
