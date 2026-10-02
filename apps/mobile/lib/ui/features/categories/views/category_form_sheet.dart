import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/clock.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/pocket_limit.dart';
import '../../../core/widgets/sheet.dart';
import '../../budget/views/budget_sheet.dart';
import '../../../core/finance_providers.dart';
import '../view_models/categories_view_model.dart';
import '../../pockets/views/set_limit_sheet.dart';
import 'category_delete_sheet.dart';
import '../../../core/widgets/meta_line.dart';

/// Where a new category is made from (03.4 / 03.4b / 03.4c / 03.4d).
enum CategoryOrigin { catat, kantong, atur }

/// 03.4 bikin baru (no [category]) / 03.5 edit. Saves and pops the
/// saved category, or null on batal / lepas limit. [origin] picks the 03.4
/// variant; [CategoryOrigin.kantong] always has a limit (03.4b), the others
/// start without one.
Future<Category?> showCategoryForm(
  BuildContext context, {
  Category? category,
  CategoryKind kind = CategoryKind.expense,
  String name = '',
  CategoryOrigin origin = CategoryOrigin.catat,
}) => showAppSheet(
  context,
  CategoryFormSheet(category: category, kind: kind, name: name, origin: origin),
);

class CategoryFormSheet extends ConsumerStatefulWidget {
  const CategoryFormSheet({
    super.key,
    this.category,
    this.kind = CategoryKind.expense,
    this.name = '',
    this.origin = CategoryOrigin.catat,
  });

  final CategoryOrigin origin; // new only
  final Category? category; // null = new
  final CategoryKind kind; // new only
  final String name; // new only, e.g. the picker's search term

  @override
  ConsumerState<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends ConsumerState<CategoryFormSheet> {
  static const _palette = [
    '🍜', '☕', '🐶', '🛵', '🛒', '💡', '🎉', '✈️', //
    '🏠', '🎁', '📚', '🎮', '🎧', '📱', '🧾', '✨',
  ];
  static const _defaultLimit = 300000;

  Category? get _edit => widget.category;

  late final _name = TextEditingController(text: _edit?.name ?? widget.name);
  late String _emoji = _edit?.emoji ?? emojiIdeas(widget.name).first;
  late bool _locked = _edit != null; // emoji follows the name until picked
  bool get _fromPocket =>
      _edit == null && widget.origin == CategoryOrigin.kantong;
  late CategoryKind _kind = _fromPocket
      ? CategoryKind.expense
      : _edit?.kind ?? widget.kind;
  late bool _pocket = _edit == null ? _fromPocket : _edit!.monthlyLimit != null;
  late int _limit = _edit?.monthlyLimit ?? _defaultLimit;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _pickEmoji(String e) => setState(() {
    _emoji = e;
    _locked = true;
  });

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = ref.read(financeRepositoryProvider);
    final name = _name.text.trim().toLowerCase();
    final limit = _kind == CategoryKind.expense && _pocket ? _limit : null;
    final id =
        _edit?.id ??
        await repo.addCategory(
          emoji: _emoji,
          name: name,
          kind: _kind,
          monthlyLimit: limit,
        );
    if (_edit != null) {
      await repo.updateCategory(
        id,
        emoji: _emoji,
        name: name,
        kind: _kind,
        monthlyLimit: limit,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(
      Category(
        id: id,
        emoji: _emoji,
        name: name,
        kind: _kind,
        monthlyLimit: _kind == CategoryKind.expense ? limit : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final name = _name.text.trim().toLowerCase();
    final expense = _kind == CategoryKind.expense;
    final canSave =
        name.isNotEmpty && !(expense && _pocket && _limit == 0) && !_saving;
    final now = ref.watch(nowProvider);
    final others = [
      for (final p in ref.watch(pocketsProvider).value ?? const <Pocket>[])
        if (p.id != _edit?.id) p.budget,
    ].fold(0, (a, b) => a + b);
    final usage = _edit == null
        ? null
        : ref.watch(categoryUsageProvider).value?[_edit!.id];
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: 820,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  SizedBox(
                    width: 64,
                    height: AppSpace.minTouch,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        foregroundColor: AppColors.ink,
                      ),
                      child: Text(l.cancel, style: AppText.label),
                    ),
                  ),
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        _edit != null
                            ? l.categoryEditTitle
                            : l.categoryNewTitle,
                        textAlign: TextAlign.center,
                        style: AppText.label.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 64),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 2),
                      Center(
                        child: _ContextChip(
                          _edit != null
                              ? l.categoryChipEdit
                              : switch (widget.origin) {
                                  CategoryOrigin.catat => l.categoryChipCatat,
                                  CategoryOrigin.kantong =>
                                    l.categoryChipPocket,
                                  CategoryOrigin.atur => l.categoryChipAtur,
                                },
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(child: _EmojiDisc(_emoji)),
                      if (_edit != null) ...[
                        const SizedBox(height: 10),
                        Center(
                          child: _UsageChip(
                            usage == null || usage.count == 0
                                ? [l.categoryUnused]
                                : [
                                    l.manageUses(usage.count),
                                    l.categoryUsageYear(
                                      rupiahCompact(usage.spentThisYear),
                                    ),
                                  ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      _NameField(
                        controller: _name,
                        hint: l.categoryNameHint,
                        label: l.categoryNameLabel,
                        onChanged: (v) => setState(() {
                          if (!_locked) _emoji = emojiIdeas(v).first;
                        }),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name.isEmpty
                                  ? l.categorySuggest
                                  : l.categorySuggestFor(name),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                          for (final e in emojiIdeas(name))
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: _EmojiButton(
                                emoji: e,
                                label: l.categoryUseEmoji(e),
                                size: 44,
                                fontSize: 22,
                                color: e == _emoji
                                    ? AppColors.ink
                                    : AppColors.mist,
                                onTap: () => _pickEmoji(e),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.mist,
                          borderRadius: BorderRadius.circular(
                            AppRadius.statTile,
                          ),
                        ),
                        child: Column(
                          spacing: 4,
                          children: [
                            for (final row in [
                              _palette.sublist(0, 8),
                              _palette.sublist(8),
                            ])
                              Row(
                                spacing: 4,
                                children: [
                                  for (final e in row)
                                    Expanded(
                                      child: _EmojiButton(
                                        emoji: e,
                                        label: l.categoryUseEmoji(e),
                                        size: 38,
                                        fontSize: 19,
                                        color: e == _emoji
                                            ? AppColors.paper
                                            : Colors.transparent,
                                        ring: e == _emoji,
                                        onTap: () => _pickEmoji(e),
                                      ),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      if (!_fromPocket) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                l.categoryKindLabel,
                                style: AppText.label,
                              ),
                            ),
                            Flexible(
                              flex: 3,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: _KindSegment(
                                  kind: _kind,
                                  labels: (l.kindOut, l.kindIn),
                                  onPick: (k) => setState(() => _kind = k),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      // Pockets track spending only. The limit stays
                      // in the draft if they flip back.
                      if (expense) ...[
                        if (!_fromPocket) ...[
                          const SizedBox(height: 14),
                          _PocketSwitch(
                            on: _pocket,
                            title: l.categoryPocket,
                            hint: _pocket
                                ? l.categoryPocketOn
                                : l.categoryPocketOff,
                            onChanged: (v) => setState(() => _pocket = v),
                          ),
                        ],
                        if (_pocket) ...[
                          const SizedBox(height: 14),
                          PocketLimit(
                            value: _limit,
                            budget: ref
                                .watch(profileProvider)
                                .value
                                ?.monthlyBudget,
                            others: others,
                            monthDays: DateTime(now.year, now.month + 1, 0).day,
                            onChanged: (v) => setState(() => _limit = v),
                            onSetBudget: () => editBudget(context, ref),
                          ),
                          if (_edit case Category(
                            :final id,
                            :final name,
                            monthlyLimit: final limit?,
                          ))
                            Center(
                              child: TextButton(
                                onPressed: () async {
                                  await releaseLimit(
                                    context,
                                    ref,
                                    id: id,
                                    name: name,
                                    limit: limit,
                                  );
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.ink,
                                ),
                                child: Text(
                                  l.pocketRelease,
                                  style: AppText.label.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.ink,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                spacing: 10,
                children: [
                  if (_edit case final c?)
                    _TrashButton(
                      label: l.deleteCategory,
                      onTap: () async {
                        if (await showCategoryDelete(context, c) &&
                            context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                  Expanded(
                    child: PrimaryButton(
                      label:
                          (_edit != null
                          ? l.categorySave
                          : widget.origin == CategoryOrigin.catat
                          ? l.categoryCreateUse
                          : l.categoryCreate)(
                            _emoji,
                            name.isEmpty ? l.categoryFallbackName : name,
                          ),
                      onPressed: canSave ? _save : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrashButton extends StatelessWidget {
  const _TrashButton({required this.label, required this.onTap});

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
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.ink, width: AppStroke.outline),
          ),
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedDelete02,
            size: 22,
            strokeWidth: AppStroke.icon,
            color: AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _EmojiDisc extends StatelessWidget {
  const _EmojiDisc(this.emoji);

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.mist,
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 64)),
          ),
          Positioned(
            right: 0,
            bottom: 4,
            child: Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.paper, spreadRadius: 3)],
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedPencilEdit02,
                size: 16,
                strokeWidth: AppStroke.iconOnInkSmall,
                color: AppColors.onInk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Where the sheet was opened from (12px, muted).
class _ContextChip extends StatelessWidget {
  const _ContextChip(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Text(
        text,
        style: AppText.caption.copyWith(fontSize: 12, color: AppColors.muted),
      ),
    );
  }
}

class _UsageChip extends StatelessWidget {
  const _UsageChip(this.parts);

  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: MetaLine(parts, style: AppText.caption),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.hint,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint, label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final style = AppText.sheetTitle.copyWith(
      fontSize: 34,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.68,
    );
    return Semantics(
      label: label,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        textCapitalization: TextCapitalization.none,
        autocorrect: false,
        style: style,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: style.copyWith(color: AppColors.subtle),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.ink,
              width: AppStroke.outline,
            ),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(
              color: AppColors.ink,
              width: AppStroke.outline,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmojiButton extends StatelessWidget {
  const _EmojiButton({
    required this.emoji,
    required this.label,
    required this.size,
    required this.fontSize,
    required this.color,
    required this.onTap,
    this.ring = false,
  });

  final String emoji, label;
  final double size, fontSize;
  final Color color;
  final bool ring;
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
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(size / 2),
            border: ring ? Border.all(color: AppColors.ink, width: 2) : null,
          ),
          child: Text(emoji, style: TextStyle(fontSize: fontSize)),
        ),
      ),
    );
  }
}

class _KindSegment extends StatelessWidget {
  const _KindSegment({
    required this.kind,
    required this.labels,
    required this.onPick,
  });

  final CategoryKind kind;
  final (String, String) labels; // pengeluaran, pemasukan
  final ValueChanged<CategoryKind> onPick;

  @override
  Widget build(BuildContext context) {
    Widget item(CategoryKind k, String label) {
      final on = k == kind;
      return Semantics(
        button: true,
        selected: on,
        child: GestureDetector(
          onTap: () => onPick(k),
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: on ? AppColors.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Text(
              label,
              style: AppText.label.copyWith(
                fontSize: 14,
                color: on ? AppColors.paper : AppColors.ink,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.ink, width: AppStroke.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          item(CategoryKind.expense, labels.$1),
          item(CategoryKind.income, labels.$2),
        ],
      ),
    );
  }
}

class _PocketSwitch extends StatelessWidget {
  const _PocketSwitch({
    required this.on,
    required this.title,
    required this.hint,
    required this.onChanged,
  });

  final bool on;
  final String title, hint;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: on,
      label: title,
      excludeSemantics: true,
      onTap: () => onChanged(!on),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!on),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.label),
                  Text(
                    hint,
                    style: AppText.caption.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: AppMotion.select,
              width: 52,
              height: 32,
              padding: const EdgeInsets.all(3),
              alignment: on ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: on ? AppColors.ink : AppColors.track,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
