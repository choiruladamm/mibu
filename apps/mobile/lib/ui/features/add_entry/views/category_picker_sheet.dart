import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/new_tile.dart';
import '../../../core/widgets/sheet.dart';
import '../../categories/views/category_form_sheet.dart';

/// 03.2 pilih kategori — resolves to the category + place, or null.
Future<RecentPick?> showCategoryPicker(
  BuildContext context, {
  required CategoryKind kind,
  required Category? selected,
  required String place,
}) => showAppSheet(
  context,
  _CategoryPicker(kind: kind, selected: selected, place: place),
);

class _CategoryPicker extends ConsumerStatefulWidget {
  const _CategoryPicker({
    required this.kind,
    required this.selected,
    required this.place,
  });

  final CategoryKind kind;
  final Category? selected;
  final String place;

  @override
  ConsumerState<_CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends ConsumerState<_CategoryPicker> {
  late Category? _picked = widget.selected;
  late final _place = TextEditingController(text: widget.place);
  bool _placeTyped = false; // typed here → survives a category change
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _place.dispose();
    _query.dispose();
    super.dispose();
  }

  /// 03.4 from the grid; the new category comes back picked.
  Future<void> _create(String term) async {
    final c = await showCategoryForm(context, kind: widget.kind, name: term);
    if (c == null || !mounted || c.kind != widget.kind) return;
    setState(() {
      _picked = c;
      _query.clear();
      if (!_placeTyped) _place.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final term = _query.text.trim().toLowerCase();
    final cats = [
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        if (c.kind == widget.kind && (term.isEmpty || c.name.contains(term))) c,
    ];
    final recents = [
      for (final r
          in ref.watch(recentPicksProvider).value ?? const <RecentPick>[])
        if (r.category.kind == widget.kind) r,
    ].take(3);
    final picked = _picked;

    return SheetFrame(
      title: l.pickerTitle,
      titleSize: 26,
      height: 700,
      scrollable: false, // the grid scrolls
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: AppColors.ink,
                width: AppStroke.outline,
              ),
            ),
            child: Row(
              spacing: 10,
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  size: 20,
                  strokeWidth: AppStroke.icon,
                  color: AppColors.ink,
                ),
                Expanded(
                  child: TextField(
                    controller: _query,
                    style: AppText.label,
                    decoration: InputDecoration.collapsed(
                      hintText: l.pickerSearch,
                      hintStyle: AppText.label.copyWith(
                        color: AppColors.subtle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (recents.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l.pickerRecent,
              style: AppText.caption.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 8,
                children: [
                  for (final r in recents)
                    _RecentChip(
                      pick: r,
                      onTap: () => Navigator.of(context).pop(r),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 8,
              mainAxisExtent: 88,
              children: [
                for (final c in cats)
                  _CategoryTile(
                    category: c,
                    on: c.id == picked?.id,
                    // Tap the picked one again to unpick.
                    onTap: () => setState(() {
                      _picked = c.id == picked?.id ? null : c;
                      // The prefilled place belonged to the old pick.
                      if (!_placeTyped) _place.clear();
                    }),
                  ),
                NewCategoryTile(
                  label: term.isNotEmpty && cats.isEmpty
                      ? l.categoryCreateNamed(term)
                      : l.categoryNew,
                  onTap: () => _create(term),
                ),
              ],
            ),
          ),
          Text(
            l.pickerWhere,
            style: AppText.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _place,
            onChanged: (_) => _placeTyped = true,
            style: AppText.label.copyWith(fontSize: 17),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.mist,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.tile),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: picked == null
                ? l.pickCategory
                : l.pickerUse(picked.emoji, picked.name),
            onPressed: picked == null
                ? null
                : () => Navigator.of(context).pop(
                    RecentPick(category: picked, place: _place.text.trim()),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecentChip extends StatelessWidget {
  const _RecentChip({required this.pick, required this.onTap});

  final RecentPick pick;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 40,
      padding: const EdgeInsets.only(left: 6, right: 14),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.paper,
              shape: BoxShape.circle,
            ),
            child: Text(
              pick.category.emoji,
              style: const TextStyle(fontSize: 15),
            ),
          ),
          Text(pick.place, style: AppText.label.copyWith(fontSize: 15)),
        ],
      ),
    ),
  );
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.on,
    required this.onTap,
  });

  final Category category;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: on,
    label: category.name,
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        spacing: 6,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: on ? AppColors.ink : AppColors.mist,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                if (on)
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
                        icon: HugeIcons.strokeRoundedTick02,
                        size: 12,
                        strokeWidth: 3,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            category.name,
            style: AppText.caption.copyWith(
              fontWeight: on ? FontWeight.w600 : FontWeight.w400,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}
