import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/sheet.dart';
import '../view_models/categories_view_model.dart';
import '../../../core/widgets/meta_line.dart';

/// 03.6 hapus kategori. True when it ended deleted (beres or dismissed
/// after the delete); false when cancelled or undone.
Future<bool> showCategoryDelete(
  BuildContext context,
  Category category,
) async =>
    await showAppSheet<bool>(
      context,
      CategoryDeleteSheet(category: category),
    ) ??
    false;

class CategoryDeleteSheet extends ConsumerStatefulWidget {
  const CategoryDeleteSheet({super.key, required this.category});

  final Category category;

  @override
  ConsumerState<CategoryDeleteSheet> createState() =>
      _CategoryDeleteSheetState();
}

class _CategoryDeleteSheetState extends ConsumerState<CategoryDeleteSheet>
    with SingleTickerProviderStateMixin {
  late final _hold = AnimationController(vsync: this, duration: AppMotion.hold)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _delete();
    });

  Category? _target; // null = tanpa kategori
  List<String>? _moved; // set once deleted; ids for batalin
  int _movedCount = 0; // live entries moved, for the done text

  Category get _c => widget.category;

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_moved != null) return;
    _movedCount = ref.read(categoryUsageProvider).value?[_c.id]?.count ?? 0;
    final moved = await ref
        .read(financeRepositoryProvider)
        .deleteCategory(_c.id, moveTo: _target?.id);
    if (mounted) setState(() => _moved = moved);
  }

  Future<void> _undo() async {
    await ref
        .read(financeRepositoryProvider)
        .undoDeleteCategory(_c.id, _moved ?? const []);
    if (mounted) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final usage = ref.watch(categoryUsageProvider).value?[_c.id];
    final count = _moved != null ? _movedCount : usage?.count ?? 0;
    final targets = [
      for (final c in ref.watch(categoriesProvider).value ?? const <Category>[])
        if (c.kind == _c.kind && c.id != _c.id) c,
    ];
    final target = _target;
    final (tEmoji, tName) = target == null
        ? ('📦', l.uncategorized)
        : (target.emoji, target.name);
    final done = _moved != null;

    return PopScope(
      // Once deleted, any dismiss counts as "beres".
      canPop: !done,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(true);
      },
      child: SizedBox(
        height: 560,
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
              Expanded(
                child: SingleChildScrollView(
                  child: done
                      ? _Done(
                          title: l.deleteDoneTitle(_c.name),
                          body: count == 0
                              ? l.deleteDoneEmpty
                              : l.deleteDoneMoved(count, tEmoji, tName),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 24),
                            _Header(
                              emoji: _c.emoji,
                              title: l.deleteTitle(_c.name),
                              sub: count == 0
                                  ? [l.deleteUnused]
                                  : [
                                      l.manageUses(count),
                                      l.deleteUsageIn(
                                        rupiahCompact(usage!.spentThisYear),
                                        _c.name,
                                      ),
                                    ],
                            ),
                            if (count > 0) ...[
                              const SizedBox(height: 22),
                              Text(
                                l.deleteMoveTo(count),
                                style: AppText.label.copyWith(fontSize: 15),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _TargetChip(
                                    emoji: '📦',
                                    label: l.uncategorized,
                                    on: target == null,
                                    onTap: () => setState(() => _target = null),
                                  ),
                                  for (final c in targets)
                                    _TargetChip(
                                      emoji: c.emoji,
                                      label: c.name,
                                      on: c.id == target?.id,
                                      onTap: () => setState(() => _target = c),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _MoveSummary(
                                from: '${_c.emoji} ',
                                count: l.deleteCount(count),
                                to: (tEmoji, tName),
                              ),
                            ],
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              if (done) ...[
                OutlinedButton(
                  onPressed: _undo,
                  style: _outline,
                  child: Text(l.undo, style: _button),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: l.manageDone,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ] else ...[
                _HoldButton(
                  hold: _hold,
                  label: l.deleteHold,
                  holding: l.deleteHolding,
                  semantics: l.deleteHoldLabel(_c.name),
                  onAccessibleDelete: _delete,
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: AppColors.ink,
                  ),
                  child: Text(l.deleteCancel, style: AppText.label),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static final _outline = OutlinedButton.styleFrom(
    minimumSize: const Size.fromHeight(56),
    foregroundColor: AppColors.ink,
    side: const BorderSide(color: AppColors.ink, width: AppStroke.outline),
    shape: const StadiumBorder(),
  );
  static final _button = AppText.label.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w500,
  );
}

class _Header extends StatelessWidget {
  const _Header({required this.emoji, required this.title, required this.sub});

  final String emoji, title;
  final List<String> sub; // MetaLine parts

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 14,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.mist,
                  shape: BoxShape.circle,
                ),
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              ),
              Positioned(
                right: -4,
                top: -4,
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
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: AppText.headline.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              MetaLine(
                sub,
                style: AppText.label.copyWith(
                  fontSize: 14,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TargetChip extends StatelessWidget {
  const _TargetChip({
    required this.emoji,
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String emoji, label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: AppSpace.minTouch,
          padding: const EdgeInsets.only(left: 10, right: 16),
          decoration: BoxDecoration(
            color: on ? AppColors.ink : AppColors.paper,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: on
                ? null
                : Border.all(color: AppColors.ink, width: AppStroke.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 8,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              Text(
                label,
                style: AppText.label.copyWith(
                  fontSize: 15,
                  color: on ? AppColors.paper : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "☕ 12 catatan → 🍜 makan".
class _MoveSummary extends StatelessWidget {
  const _MoveSummary({
    required this.from,
    required this.count,
    required this.to,
  });

  final String from, count;
  final (String, String) to; // emoji, name

  @override
  Widget build(BuildContext context) {
    final style = AppText.label.copyWith(fontSize: 15);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(AppRadius.statTile),
      ),
      child: Row(
        children: [
          Text(from, style: style),
          Text(count, style: style.copyWith(color: AppColors.muted)),
          const Spacer(),
          const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowRight02,
            size: 22,
            strokeWidth: AppStroke.icon,
            color: AppColors.ink,
          ),
          const Spacer(),
          Flexible(
            flex: 4,
            child: Text(
              '${to.$1} ${to.$2}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tahan buat hapus: ink fills over [AppMotion.hold]; letting go early
/// resets. Screen readers get a long-press action instead.
class _HoldButton extends StatelessWidget {
  const _HoldButton({
    required this.hold,
    required this.label,
    required this.holding,
    required this.semantics,
    required this.onAccessibleDelete,
  });

  final AnimationController hold;
  final String label, holding, semantics;
  final VoidCallback onAccessibleDelete;

  @override
  Widget build(BuildContext context) {
    void release() {
      if (hold.status != AnimationStatus.completed) hold.value = 0;
    }

    Widget face(Color fg) => Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 10,
      children: [
        HugeIcon(
          icon: HugeIcons.strokeRoundedDelete02,
          size: 20,
          strokeWidth: AppStroke.icon,
          color: fg,
        ),
        Text(
          hold.value == 0 ? label : holding,
          style: AppText.label.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: fg,
          ),
        ),
      ],
    );

    return Semantics(
      button: true,
      label: semantics,
      excludeSemantics: true,
      onLongPress: onAccessibleDelete,
      child: Listener(
        onPointerDown: (_) => hold.forward(from: 0),
        onPointerUp: (_) => release(),
        onPointerCancel: (_) => release(),
        child: AnimatedBuilder(
          animation: hold,
          builder: (context, _) => Container(
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: AppColors.ink,
                width: AppStroke.outline,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                face(AppColors.ink),
                // The filled part shows the label in paper.
                ClipRect(
                  clipper: _LeftPart(hold.value),
                  child: ColoredBox(
                    color: AppColors.ink,
                    child: face(AppColors.paper),
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

class _LeftPart extends CustomClipper<Rect> {
  const _LeftPart(this.fraction);

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_LeftPart old) => old.fraction != fraction;
}

class _Done extends StatelessWidget {
  const _Done({required this.title, required this.body});

  final String title, body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 88,
          height: 88,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.ink,
            shape: BoxShape.circle,
          ),
          child: const HugeIcon(
            icon: HugeIcons.strokeRoundedTick02,
            size: 36,
            strokeWidth: AppStroke.iconOnInkSmall,
            color: AppColors.onInk,
          ),
        ),
        const SizedBox(height: 20),
        Semantics(
          liveRegion: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.headline.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: AppText.label.copyWith(fontSize: 15, color: AppColors.muted),
        ),
      ],
    );
  }
}
