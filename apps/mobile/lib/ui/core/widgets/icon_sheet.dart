import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../domain/emoji_catalog.dart';
import '../../../domain/emoji_search.dart';
import '../../../l10n/app_localizations.dart';
import '../tokens.dart';
import 'app_emoji.dart';
import 'sheet.dart';
import '../finance_providers.dart';

/// 00.21 IconSheet: pick one of the catalog icons. Resolves to the picked
/// emoji, or null when closed.
Future<String?> showIconSheet(
  BuildContext context, {
  required String selected,
}) => showAppSheet<String>(context, IconSheet(selected: selected));

/// Chip icon per group, "semua" first.
const _groupIcon = {
  null: '✨',
  EmojiGroup.makan: '☕',
  EmojiGroup.jalan: '🛵',
  EmojiGroup.rumah: '🏠',
  EmojiGroup.belanja: '🛒',
  EmojiGroup.hiburan: '🎉',
  EmojiGroup.hewan: '🐶',
  EmojiGroup.duit: '💰',
  EmojiGroup.sehat: '🏋️',
  EmojiGroup.sekolah: '📚',
  EmojiGroup.kerja: '💼',
  EmojiGroup.sosial: '🎁',
};

/// Words offered when a search finds nothing (after the one that does).
const _tries = ['makan', 'motor', 'rumah'];

class IconSheet extends ConsumerStatefulWidget {
  const IconSheet({super.key, required this.selected});

  final String selected;

  @override
  ConsumerState<IconSheet> createState() => _IconSheetState();
}

class _IconSheetState extends ConsumerState<IconSheet> {
  final _q = TextEditingController();
  late String _sel = catalogEmoji(widget.selected);
  EmojiGroup? _group; // null = semua

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  String _name(String emoji) =>
      emojiCatalog.where((c) => c.emoji == emoji).firstOrNull?.keywords.first ??
      '';

  void _search(String q) => setState(() {
    _q.text = q;
    _q.selection = TextSelection.collapsed(offset: q.length);
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final term = _q.text.trim().toLowerCase();
    final typing = term.isNotEmpty;

    // terakhir dipakai: categories of the latest entries, then the rest.
    final recent = <String>{
      for (final p in ref.watch(recentPicksProvider).value ?? const [])
        catalogEmoji(p.category.emoji),
      for (final c in ref.watch(categoriesProvider).value ?? const [])
        catalogEmoji(c.emoji),
    }.take(5).toList();

    final items = typing
        ? searchEmoji(term)
        : [
            for (final c in emojiCatalog)
              if (_group == null || c.group == _group) c,
          ];
    final matched = typing
        ? {
            for (final c in items)
              for (final k in c.keywords)
                if (k.startsWith(term)) k,
          }.take(4).join(', ')
        : '';
    final tries = <String>{?emojiRetry(term), ..._tries}.take(3).toList();

    return SheetFrame(
      title: l.iconSheetTitle,
      titleSize: 24,
      height: math.min(780, MediaQuery.sizeOf(context).height * 0.92),
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 14),
          _SearchField(
            controller: _q,
            hint: l.iconSearchHint,
            label: l.iconSearchLabel,
            clearLabel: l.searchClear,
            onChanged: () => setState(() {}),
          ),
          if (!typing) ...[
            if (recent.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l.pickerRecent,
                style: AppText.label.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                spacing: 8,
                children: [
                  for (final e in recent)
                    _Disc(
                      emoji: e,
                      label: _name(e),
                      on: e == _sel,
                      onTap: () => setState(() => _sel = e),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                children: [
                  for (final MapEntry(key: g, value: icon)
                      in _groupIcon.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _GroupChip(
                        emoji: icon,
                        label: l.iconGroup(g?.name ?? 'semua'),
                        on: g == _group,
                        onTap: () => setState(() => _group = g),
                      ),
                    ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              spacing: 12,
              children: [
                Text(
                  l.iconCount(items.length),
                  style: AppText.label.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Flexible(
                  child: Text(
                    matched,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(color: AppColors.muted),
                  ),
                ),
              ],
            ),
          ],
          Expanded(
            child: Stack(
              children: [
                if (items.isEmpty)
                  _Empty(
                    title: l.iconEmpty(term),
                    sub: l.iconEmptyTry,
                    tries: tries,
                    onTry: _search,
                  )
                else
                  GridView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 104),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisExtent: 62,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                    itemCount: items.length,
                    itemBuilder: (_, i) => _Cell(
                      emoji: items[i].emoji,
                      label: items[i].keywords.first,
                      on: items[i].emoji == _sel,
                      onTap: () => setState(() => _sel = items[i].emoji),
                    ),
                  ),
                // "pakai ☕ kopi" over the grid's fading bottom.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.only(top: 36),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: [0, 0.36],
                        colors: [Color(0x00FFFFFF), AppColors.paper],
                      ),
                    ),
                    child: PrimaryButton(
                      label: l.pickerUse(_sel, _name(_sel)),
                      onPressed: () => Navigator.of(context).pop(_sel),
                    ),
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

/// 48 pill: search glyph, field, × while typing.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hint,
    required this.label,
    required this.clearLabel,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hint, label, clearLabel;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 18, right: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.ink, width: AppStroke.outline),
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
            child: Semantics(
              label: label,
              child: TextField(
                controller: controller,
                onChanged: (_) => onChanged(),
                textInputAction: TextInputAction.search,
                cursorColor: AppColors.ink,
                style: AppText.label,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: hint,
                  hintStyle: AppText.label.copyWith(color: AppColors.subtle),
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            TextFieldTapRegion(
              child: CircleButton(
                icon: HugeIcons.strokeRoundedCancel01,
                label: clearLabel,
                size: 32,
                iconSize: 14,
                onTap: () {
                  controller.clear();
                  onChanged();
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// 48 disc in terakhir dipakai.
class _Disc extends StatelessWidget {
  const _Disc({
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
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.paper : AppColors.mist,
            shape: BoxShape.circle,
            border: on ? Border.all(color: AppColors.ink, width: 2) : null,
          ),
          child: AppEmoji(emoji, size: 30),
        ),
      ),
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
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
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: const EdgeInsets.only(left: 6, right: 14),
          decoration: BoxDecoration(
            color: on ? AppColors.ink : AppColors.mist,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: on ? AppColors.onInk12 : AppColors.paper,
                  shape: BoxShape.circle,
                ),
                child: AppEmoji(emoji, size: 22),
              ),
              Text(
                label,
                style: AppText.label.copyWith(
                  fontSize: 14,
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

/// Grid cell: picked = paper + ink ring, icon 1.12× with a soft shadow.
class _Cell extends StatelessWidget {
  const _Cell({
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
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.paper : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: on ? Border.all(color: AppColors.ink, width: 2) : null,
          ),
          child: AnimatedScale(
            scale: on ? 1.12 : 1,
            duration: AppMotion.select,
            curve: AppMotion.ease,
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: on
                    ? const [
                        BoxShadow(
                          color: Color(0x2E111111), // ink 18%
                          offset: Offset(0, 6),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
                shape: BoxShape.circle,
              ),
              child: AppEmoji(emoji, size: 40),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nothing found: the line + words to try instead.
class _Empty extends StatelessWidget {
  const _Empty({
    required this.title,
    required this.sub,
    required this.tries,
    required this.onTry,
  });

  final String title, sub;
  final List<String> tries;
  final ValueChanged<String> onTry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 36),
      child: Column(
        spacing: 8,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppText.body.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            sub,
            style: AppText.label.copyWith(fontSize: 14, color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final t in tries)
                Semantics(
                  button: true,
                  child: GestureDetector(
                    onTap: () => onTry(t),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.only(left: 6, right: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.ink,
                          width: AppStroke.outline,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 6,
                        children: [
                          AppEmoji(searchEmoji(t).first.emoji, size: 24),
                          Text(t, style: AppText.label.copyWith(fontSize: 14)),
                        ],
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
