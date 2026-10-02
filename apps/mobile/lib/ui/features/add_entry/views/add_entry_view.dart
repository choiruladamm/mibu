import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/amount.dart';
import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/amount_keypad.dart';
import '../../../core/widgets/date_sheet.dart';
import '../../../core/widgets/day_strip.dart';
import '../../../core/widgets/note_sheet.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/finance_providers.dart';
import '../view_models/add_entry_view_model.dart';
import 'category_picker_sheet.dart';

/// 03.1 catat — opened from + on every tab; pops on close / save.
class AddEntryView extends ConsumerStatefulWidget {
  const AddEntryView({super.key, this.again});

  /// "catat lagi" (04.3): start with this entry's kind, category and place.
  final Transaction? again;

  @override
  ConsumerState<AddEntryView> createState() => _AddEntryViewState();
}

class _AddEntryViewState extends ConsumerState<AddEntryView> {
  bool _calOpen = false;
  bool _saving = false;

  AddEntry get _vm => ref.read(addEntryProvider.notifier);

  @override
  void initState() {
    super.initState();
    if (widget.again case final t?) {
      // Providers can't change mid-build; the push transition hides the frame.
      WidgetsBinding.instance.addPostFrameCallback((_) => _vm.again(t));
    }
  }

  DateTime get _today => dateOnly(ref.read(clockProvider)());

  Future<void> _openCalendar(DateTime selected) async {
    setState(() => _calOpen = true);
    final d = await showDateSheet(context, selected: selected, today: _today);
    if (!mounted) return;
    setState(() => _calOpen = false);
    if (d != null) _vm.pickDay(d);
  }

  Future<void> _openPicker(AddEntryState s) async {
    final p = await showCategoryPicker(
      context,
      kind: s.kind,
      selected: s.category,
      place: s.place,
    );
    if (p != null) _vm.pick(p);
  }

  Future<void> _openNote(AddEntryState s) async {
    final sign = s.kind == CategoryKind.expense ? '-' : '+';
    final note = await showNoteSheet(
      context,
      initial: s.note,
      entryContext: [
        '$sign${rupiah(s.amount)}',
        if (s.category case final c?)
          '${c.emoji} ${s.place.isEmpty ? c.name : s.place}',
        dayLabel(s.day),
      ],
      today: _today,
    );
    if (note != null) _vm.setNote(note);
  }

  Future<void> _save() async {
    // A second tap before the pop would insert the entry twice.
    if (_saving) return;
    setState(() => _saving = true);
    await _vm.save();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = ref.watch(addEntryProvider);
    final income = s.kind == CategoryKind.income;

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.only(top: 12, bottom: 28),
        // Keypad pinned at the bottom; only what's above it scrolls.
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              CircleButton(
                                icon: HugeIcons.strokeRoundedCancel01,
                                label: l.close,
                                iconSize: 22,
                                color: Colors.transparent,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              Expanded(
                                child: Center(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: _KindToggle(
                                      kind: s.kind,
                                      onPick: _vm.setKind,
                                    ),
                                  ),
                                ),
                              ),
                              CircleButton(
                                icon: HugeIcons.strokeRoundedCalendar03,
                                label: l.pickOtherDate,
                                iconSize: 22,
                                color: Colors.transparent,
                                ink: _calOpen,
                                onTap: () => _openCalendar(s.day),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: DayStrip(
                            selected: s.day,
                            today: _today,
                            onPick: _vm.pickDay,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _AmountLine(_expression(s.draft)),
                        const SizedBox(height: 2),
                        _Amount(total: s.amount, sign: income ? '+' : '-'),
                        const SizedBox(height: 6),
                        _AmountLine(
                          s.amount == 0
                              ? l.amountTypeHint
                              : l.amountInWords(terbilang(s.amount)),
                          size: 13,
                        ),
                        const SizedBox(height: 12),
                        _Impact(state: s),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _CategoryChip(
                                state: s,
                                onTap: () => _openPicker(s),
                              ),
                              _NoteChip(
                                note: s.note,
                                onTap: () => _openNote(s),
                                onClear: () =>
                                    _vm.setNote((text: '', tags: const [])),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AmountKeypad(
                onKey: _vm.press,
                onBackspace: _vm.backspace,
                onClear: _vm.clear,
                onSave: _save,
                saveLabel: income ? l.income : l.expense,
                canClear: !draftIsEmpty(s.draft),
                canSave: s.canSave && !_saving,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KindToggle extends StatelessWidget {
  const _KindToggle({required this.kind, required this.onPick});

  final CategoryKind kind;
  final ValueChanged<CategoryKind> onPick;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.ink, width: AppStroke.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 2,
        children: [
          for (final (k, label) in [
            (CategoryKind.expense, l.expense),
            (CategoryKind.income, l.income),
          ])
            Semantics(
              button: true,
              selected: k == kind,
              child: GestureDetector(
                onTap: () => onPick(k),
                child: AnimatedContainer(
                  duration: AppMotion.select,
                  curve: AppMotion.ease,
                  height: 35,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: k == kind ? AppColors.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(19),
                  ),
                  child: Text(
                    label,
                    style: AppText.label.copyWith(
                      fontSize: 15,
                      fontWeight: k == kind ? FontWeight.w500 : FontWeight.w400,
                      color: k == kind ? AppColors.paper : AppColors.ink,
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

/// "50.000 + 20.000 + …" while adding up with "+"; empty otherwise.
String _expression(AmountDraft d) {
  if (d.parts.isEmpty) return '';
  String dots(int v) => rupiah(v).replaceFirst('Rp', '');
  final cur = int.tryParse(d.digits) ?? 0;
  return [...d.parts.map(dots), cur == 0 ? '…' : dots(cur)].join(' + ');
}

/// Muted one-liner above / below the amount; keeps its height when empty.
class _AmountLine extends StatelessWidget {
  const _AmountLine(this.text, {this.size = 14});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size + 4,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.caption.copyWith(fontSize: size, color: AppColors.muted),
      ),
    );
  }
}

/// Big amount with a blinking caret; shrinks 68 → 54 → 44 as it grows.
class _Amount extends StatefulWidget {
  const _Amount({required this.total, required this.sign});

  final int total;
  final String sign;

  @override
  State<_Amount> createState() => _AmountState();
}

class _AmountState extends State<_Amount> with SingleTickerProviderStateMixin {
  late final _blink = AnimationController(
    vsync: this,
    duration: AppMotion.cursorBlink,
  )..repeat();

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shown = rupiah(widget.total).replaceFirst('Rp', '');
    final size = shown.length > 9
        ? 44.0
        : shown.length > 7
        ? 54.0
        : 68.0;
    return Semantics(
      liveRegion: true,
      label: '${widget.sign}Rp$shown',
      excludeSemantics: true,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${widget.sign}Rp',
                style: AppText.title.copyWith(
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                  color: AppColors.muted,
                ),
              ),
            ),
            Text(
              shown,
              style: AppText.displayXl.copyWith(fontSize: size, height: 1),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: FadeTransition(
                // steps(1): on for the first half of each second.
                opacity: _blink.drive(
                  TweenSequence([
                    TweenSequenceItem(tween: ConstantTween(1.0), weight: 1),
                    TweenSequenceItem(tween: ConstantTween(0.0), weight: 1),
                  ]),
                ),
                child: Container(
                  width: 3,
                  height: (size * 0.85).roundToDouble(),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pocket bar: what's spent + this entry, then "sisa" / "kelebihan".
/// Income or a category without a limit shows the balance after instead.
class _Impact extends ConsumerWidget {
  const _Impact({required this.state});

  final AddEntryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final s = state;
    final v = s.amount;
    final pockets =
        ref
            .watch(pocketsInMonthProvider(DateTime(s.day.year, s.day.month)))
            .value ??
        const <Pocket>[];
    final balance = ref.watch(totalsProvider).value?.balance ?? 0;
    final pocket = s.kind == CategoryKind.expense
        ? pockets.where((p) => p.id == s.category?.id).firstOrNull
        : null;

    final double prev, add;
    final String label, note;
    if (pocket != null) {
      final limit = pocket.budget;
      final left = limit - pocket.spent - v;
      prev = (pocket.spent / limit).clamp(0.0, 1.0);
      add = (v / limit).clamp(0.0, 1.0 - prev);
      label = l.pocketAfter(pocket.emoji, pocket.name);
      note = left >= 0
          ? l.leftAmount(rupiahCompact(left))
          : l.overAmount(rupiahCompact(-left));
    } else {
      final after = s.kind == CategoryKind.income ? balance + v : balance - v;
      final whole = s.kind == CategoryKind.income ? after : balance;
      prev = whole <= 0 ? 0 : ((whole - v) / whole).clamp(0.0, 1.0);
      add = whole <= 0 ? 0 : (v / whole).clamp(0.0, 1.0 - prev);
      label = l.balanceAfter;
      note = rupiahCompact(after);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        spacing: 8,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: LayoutBuilder(
                // Stack, not Row: mid-animation widths can't overflow.
                builder: (context, c) => Container(
                  color: AppColors.track,
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: AppMotion.select,
                        left: 0,
                        top: 0,
                        bottom: 0,
                        width: c.maxWidth * prev,
                        child: const ColoredBox(color: AppColors.grey400),
                      ),
                      AnimatedPositioned(
                        duration: AppMotion.select,
                        left: c.maxWidth * prev + 2,
                        top: 0,
                        bottom: 0,
                        width: (c.maxWidth * add - 2).clamp(0, c.maxWidth),
                        child: const ColoredBox(color: AppColors.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppText.caption.copyWith(color: AppColors.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                note,
                style: AppText.caption.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.state, required this.onTap});

  final AddEntryState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = state.category;
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.only(left: 4, right: 18),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.paper,
                  shape: BoxShape.circle,
                ),
                child: c == null
                    ? const HugeIcon(
                        icon: HugeIcons.strokeRoundedTag01,
                        size: 18,
                        strokeWidth: AppStroke.icon,
                        color: AppColors.ink,
                      )
                    : Text(c.emoji, style: const TextStyle(fontSize: 19)),
              ),
              Text(
                c == null
                    ? l.pickCategory
                    : (state.place.isEmpty ? c.name : state.place),
                style: AppText.label.copyWith(color: AppColors.paper),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteChip extends StatelessWidget {
  const _NoteChip({
    required this.note,
    required this.onTap,
    required this.onClear,
  });

  final Note note;
  final VoidCallback onTap, onClear;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final text = note.text.isNotEmpty ? note.text : note.tags.join(' ');
    if (text.isEmpty) {
      return Semantics(
        button: true,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: AppColors.ink,
                width: AppStroke.outline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedPlusSign,
                  size: 16,
                  strokeWidth: AppStroke.iconOnInkSmall,
                  color: AppColors.ink,
                ),
                Text(l.noteButton, style: AppText.label),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      height: 44,
      padding: const EdgeInsets.only(left: 14, right: 4),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Semantics(
            button: true,
            label: l.editNote(text),
            excludeSemantics: true,
            child: GestureDetector(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    const HugeIcon(
                      icon: HugeIcons.strokeRoundedNote,
                      size: 16,
                      strokeWidth: AppStroke.icon,
                      color: AppColors.ink,
                    ),
                    Flexible(
                      child: Text(
                        text,
                        style: AppText.label.copyWith(fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          CircleButton(
            icon: HugeIcons.strokeRoundedCancel01,
            label: l.clearNote,
            size: 36,
            iconSize: 14,
            color: AppColors.paper,
            onTap: onClear,
          ),
        ],
      ),
    );
  }
}
