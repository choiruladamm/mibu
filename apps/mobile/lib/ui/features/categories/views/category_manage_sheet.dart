import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/new_tile.dart';
import '../../../core/widgets/sheet.dart';
import '../view_models/categories_view_model.dart';
import 'category_form_sheet.dart';

/// 03.3 atur kategori — from 03.2 "atur" and (M6) 02.4.
Future<void> showCategoryManage(BuildContext context) =>
    showAppSheet(context, const CategoryManageSheet());

class CategoryManageSheet extends ConsumerStatefulWidget {
  const CategoryManageSheet({super.key});

  @override
  ConsumerState<CategoryManageSheet> createState() =>
      _CategoryManageSheetState();
}

class _CategoryManageSheetState extends ConsumerState<CategoryManageSheet>
    with SingleTickerProviderStateMixin {
  // Edit mode wiggles: ±2.5°, tiles out of phase by column.
  late final _wiggle = AnimationController(
    vsync: this,
    duration: AppMotion.wiggle,
  )..repeat();

  List<String>? _order; // ids while dragging; null = db order

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
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
    final still = MediaQuery.disableAnimationsOf(context);

    return SheetFrame(
      title: l.manageTitle,
      titleSize: 26,
      height: 700,
      scrollable: false,
      close: _DoneButton(
        label: l.manageDone,
        onTap: () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          Text(
            l.manageHint,
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 8,
              mainAxisExtent: 110,
              children: [
                for (final (i, c) in shown.indexed)
                  _DraggableTile(
                    key: ValueKey(c.id),
                    category: c,
                    uses: usage[c.id]?.count ?? 0,
                    wiggle: still ? null : _wiggle,
                    phase: (i % 4) * 0.25,
                    onTap: () => showCategoryForm(context, category: c),
                    onDelete: () {}, // → 03.6
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
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: NewCategoryTile(
                    label: l.categoryNew,
                    onTap: () => showCategoryForm(context),
                  ),
                ),
              ],
            ),
          ),
          if (income.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(AppRadius.statTile),
              ),
              child: Row(
                spacing: 12,
                children: [
                  const Text('🗂️', style: TextStyle(fontSize: 22)),
                  Expanded(
                    child: Text(
                      l.manageIncomeNote(income.first.name),
                      style: AppText.label.copyWith(fontSize: 14, height: 1.4),
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
/// there; dropping saves the order.
class _DraggableTile extends StatelessWidget {
  const _DraggableTile({
    super.key,
    required this.category,
    required this.uses,
    required this.wiggle,
    required this.phase,
    required this.onTap,
    required this.onDelete,
    required this.onDragStart,
    required this.onHover,
    required this.onDragEnd,
  });

  final Category category;
  final int uses;
  final Animation<double>? wiggle; // null = reduce motion
  final double phase; // 0–1
  final VoidCallback onTap, onDelete, onDragStart, onDragEnd;
  final ValueChanged<String> onHover;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tile = _Tile(
      category: category,
      uses: uses == 0 ? l.categoryUnused : l.manageUses(uses),
    );
    final wiggle = this.wiggle;

    return DragTarget<String>(
      onWillAcceptWithDetails: (d) {
        onHover(d.data);
        return true;
      },
      builder: (context, _, _) => Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: 6,
            child: LongPressDraggable<String>(
              data: category.id,
              onDragStarted: onDragStart,
              onDragEnd: (_) => onDragEnd(),
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(width: 76, child: tile),
              ),
              childWhenDragging: Opacity(opacity: 0.3, child: tile),
              child: Semantics(
                button: true,
                label: l.manageEdit(category.name),
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: wiggle == null
                      ? tile
                      : AnimatedBuilder(
                          animation: wiggle,
                          builder: (_, child) => Transform.rotate(
                            angle:
                                math.sin(2 * math.pi * (wiggle.value + phase)) *
                                AppMotion.wiggleAngle *
                                math.pi /
                                180,
                            child: child,
                          ),
                          child: tile,
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 2,
            top: 0,
            child: Semantics(
              button: true,
              label: l.manageDelete(category.name),
              excludeSemantics: true,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.paper, spreadRadius: 2),
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
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.category, required this.uses});

  final Category category;
  final String uses;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 4,
      children: [
        Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.mist,
            shape: BoxShape.circle,
          ),
          child: Text(category.emoji, style: const TextStyle(fontSize: 28)),
        ),
        Text(
          category.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.caption,
        ),
        Text(
          uses,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.micro.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}
