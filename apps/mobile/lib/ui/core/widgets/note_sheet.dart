import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../data/repositories/finance_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../dates.dart';
import '../tokens.dart';
import 'meta_line.dart';
import 'sheet.dart';

typedef Note = ({String text, List<String> tags});

const noteMaxLength = 80;
const noteMaxTags = 3;
const noteTags = [
  '#splitbill',
  '#kantor',
  '#nongkrong',
  '#darurat',
  '#hadiah',
  '#langganan',
];

/// 00.13 NoteSheet. [entryContext] is the entry it's for, as MetaLine parts:
/// -Rp50.000 • 🍜 warteg • sel 13 okt. Resolves to the note (empty =
/// cleared), or null if dismissed.
Future<Note?> showNoteSheet(
  BuildContext context, {
  required Note initial,
  required List<String> entryContext,
  required DateTime today,
}) => showAppSheet(
  context,
  _NoteSheet(initial: initial, entryContext: entryContext, today: today),
);

class _NoteSheet extends ConsumerStatefulWidget {
  const _NoteSheet({
    required this.initial,
    required this.entryContext,
    required this.today,
  });

  final Note initial;
  final List<String> entryContext;
  final DateTime today;

  @override
  ConsumerState<_NoteSheet> createState() => _NoteSheetState();
}

class _NoteSheetState extends ConsumerState<_NoteSheet> {
  late final _text = TextEditingController(text: widget.initial.text);
  late final _tags = [...widget.initial.tags];
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _text.addListener(() => setState(() {}));
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final recent = ref.watch(recentNotesProvider).value ?? const [];
    final len = _text.text.characters.length;
    final empty = _text.text.trim().isEmpty && _tags.isEmpty;
    final focused = _focus.hasFocus;

    return SheetFrame(
      title: l.noteButton,
      height: 580,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppColors.line),
              ),
              // widthFactor 1: hug the text (alignment would stretch it).
              child: Center(
                widthFactor: 1,
                child: MetaLine(widget.entryContext, style: AppText.caption),
              ),
            ),
          ),
          const SizedBox(height: 14),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 124,
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 10),
            decoration: BoxDecoration(
              color: focused ? AppColors.paper : AppColors.mist,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: focused ? AppColors.ink : Colors.transparent,
                width: AppStroke.outline,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: TextField(
                    controller: _text,
                    focusNode: _focus,
                    autofocus: true,
                    maxLength: noteMaxLength,
                    maxLines: null,
                    expands: true,
                    style: AppText.label.copyWith(fontSize: 17, height: 1.4),
                    decoration: InputDecoration.collapsed(
                      hintText: l.notePlaceholder,
                      hintStyle: AppText.label.copyWith(
                        fontSize: 17,
                        color: AppColors.subtle,
                      ),
                    ).copyWith(counterText: ''),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _tags.join(' '),
                        style: AppText.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '$len / $noteMaxLength',
                      style: AppText.caption.copyWith(
                        fontSize: 12,
                        color: len >= 70 ? AppColors.ink : AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Section title: title left, info right, no dot.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                l.noteQuickTags,
                style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
              ),
              Text(
                l.noteTagsMax(noteMaxTags),
                style: AppText.caption.copyWith(
                  fontSize: 12,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in noteTags)
                _TagChip(
                  label: t,
                  on: _tags.contains(t),
                  onTap: () => setState(() {
                    if (!_tags.remove(t) && _tags.length < noteMaxTags) {
                      _tags.add(t);
                    }
                  }),
                ),
            ],
          ),
          if (recent.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l.noteWroteBefore,
              style: AppText.caption.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            for (final r in recent)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _text.text = r.text,
                child: Container(
                  height: 40,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.track)),
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedClock01,
                        size: 16,
                        strokeWidth: AppStroke.icon,
                        color: AppColors.ink,
                      ),
                      Expanded(
                        child: Text(
                          r.text,
                          style: AppText.label.copyWith(fontSize: 15),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        relativeDay(l, r.at, widget.today),
                        style: AppText.caption.copyWith(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const Spacer(),
          PrimaryButton(
            label: empty ? l.noteLeaveEmpty : l.noteSave,
            icon: HugeIcons.strokeRoundedTick02,
            onPressed: () =>
                Navigator.of(context)
                    .pop<Note>((text: _text.text.trim(), tags: [..._tags])),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.on, required this.onTap});

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: on,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: on ? AppColors.ink : AppColors.paper,
          borderRadius: BorderRadius.circular(17),
          border: on
              ? null
              : Border.all(color: AppColors.ink, width: AppStroke.outline),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: AppText.label.copyWith(
              fontSize: 14,
              color: on ? AppColors.paper : AppColors.ink,
            ),
          ),
        ),
      ),
    ),
  );
}
