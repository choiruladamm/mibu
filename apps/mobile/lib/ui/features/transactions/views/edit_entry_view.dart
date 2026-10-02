import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/measure.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/day_strip.dart';
import '../../../core/widgets/nav_header.dart';
import '../../../core/widgets/note_sheet.dart';
import '../../../core/widgets/sheet.dart';
import 'transaction_detail_view.dart';

final _dots = NumberFormat('#,##0', 'id_ID');
final _headerDay = DateFormat('EEE d MMM', 'id');

/// 04.4 edit catatan. Kind stays; tags are kept (no field for them here).
class EditEntryView extends ConsumerWidget {
  const EditEntryView({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(transactionProvider(id)).value;
    if (t == null) return const Scaffold();
    return _EditForm(key: ValueKey(t.id), orig: t);
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({super.key, required this.orig});

  final Transaction orig;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  late final _amount = TextEditingController();
  late final _place = TextEditingController();
  late final _note = TextEditingController();
  late String? _category;
  late DateTime _day;
  bool _saving = false;

  Transaction get _o => widget.orig;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() => setState(() {
    _amount.text = _dots.format(_o.amount.abs());
    _place.text = _o.place;
    _note.text = _o.note;
    _category = _o.categoryId;
    _day = dateOnly(_o.at);
  });

  @override
  void dispose() {
    _amount.dispose();
    _place.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _value =>
      int.tryParse(_amount.text.replaceAll(RegExp('[^0-9]'), '')) ?? 0;

  ({bool amount, bool category, bool place, bool day, bool note})
  get _changed => (
    amount: _value != _o.amount.abs(),
    category: _category != _o.categoryId,
    place: _place.text.trim() != _o.place,
    day: _day != dateOnly(_o.at),
    note: _note.text.trim() != _o.note,
  );

  void _typed(String s) {
    // Digits only, max 10, dots as they type; caret at the end.
    var digits = s.replaceAll(RegExp('[^0-9]'), '');
    if (digits.length > 10) digits = digits.substring(0, 10);
    final shown = digits.isEmpty ? '' : _dots.format(int.parse(digits));
    _amount.value = TextEditingValue(
      text: shown,
      selection: TextSelection.collapsed(offset: shown.length),
    );
    setState(() {});
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final at = DateTime(
      _day.year,
      _day.month,
      _day.day,
      _o.at.hour,
      _o.at.minute,
      _o.at.second,
    );
    await ref
        .read(financeRepositoryProvider)
        .updateTransaction(
          _o.id,
          amount: _o.amount < 0 ? -_value : _value,
          categoryId: _category,
          place: _place.text,
          note: _note.text,
          at: at,
        );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final pocket = _o.amount < 0 ? pocketOf(ref, _o) : null;
    // Lands back on 04.3, toast above its "balik ke transaksi".
    final gone = await confirmDeleteEntry(
      context,
      ref,
      _o,
      pocket,
      toastBottom: 28 + 48 + 10,
    );
    if (gone && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final c = _changed;
    final n = [
      c.amount,
      c.category,
      c.place,
      c.day,
      c.note,
    ].where((v) => v).length;
    final cats = [
      for (final cat in ref.watch(categoriesProvider).value ?? <Category>[])
        if (cat.kind == _o.kind) cat,
    ];
    final input = AppText.label.copyWith(fontSize: 17);

    return Scaffold(
      body: SafeArea(
        minimum: const EdgeInsets.only(top: 12, bottom: 28),
        child: Column(
          children: [
            NavHeader(
              title: l.receiptEdit,
              sub: [
                _o.place.isNotEmpty ? _o.place : _o.category ?? l.uncategorized,
                _headerDay.format(_o.at).toLowerCase(),
              ],
              backLabel: l.receiptTitle,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 20,
                  children: [
                    _Field(
                      label: l.editAmount,
                      changed: c.amount,
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.ink,
                              width: AppStroke.outline,
                            ),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, box) {
                            final prefix = AppText.inputXl.copyWith(
                              fontSize: 26,
                              letterSpacing: -0.52,
                              color: AppColors.muted,
                            );
                            final sign = _o.amount < 0 ? '-Rp' : '+Rp';
                            // Shrink the digits (never clip) once they'd
                            // outgrow the row; letterSpacing scales with size.
                            final room =
                                box.maxWidth - textWidth(sign, prefix) - 4 - 4;
                            final full = textWidth(
                              _amount.text,
                              AppText.display,
                            );
                            final size = (56 * (room / full).clamp(0.0, 1.0))
                                .clamp(28.0, 56.0);
                            final style = AppText.display.copyWith(
                              fontSize: size,
                              letterSpacing: -0.04 * size,
                            );
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              spacing: 4,
                              children: [
                                Text(sign, style: prefix),
                                // Hugs the digits so "-Rp" sits next to them.
                                SizedBox(
                                  width: (textWidth(_amount.text, style) + 4)
                                      .clamp(size * 0.7, room),
                                  child: Semantics(
                                    label: l.editAmount,
                                    child: TextField(
                                      controller: _amount,
                                      onChanged: _typed,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp('[0-9.]'),
                                        ),
                                      ],
                                      textAlign: TextAlign.center,
                                      style: style,
                                      decoration: InputDecoration.collapsed(
                                        hintText: '0',
                                        hintStyle: style.copyWith(
                                          color: AppColors.grey400,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    _Field(
                      label: l.editCategory,
                      changed: c.category,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        clipBehavior: Clip.none,
                        child: Row(
                          spacing: 8,
                          children: [
                            for (final cat in cats)
                              _CategoryChip(
                                category: cat,
                                selected: cat.id == _category,
                                onTap: () => setState(() => _category = cat.id),
                              ),
                          ],
                        ),
                      ),
                    ),
                    _Field(
                      label: l.editPlace,
                      changed: c.place,
                      child: _MistField(
                        controller: _place,
                        label: l.editPlace,
                        style: input,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    _Field(
                      label: l.editDay,
                      changed: c.day,
                      child: DayStrip(
                        selected: _day,
                        today: dateOnly(ref.read(clockProvider)()),
                        onPick: (d) => setState(() => _day = dateOnly(d)),
                      ),
                    ),
                    _Field(
                      label: l.receiptNote,
                      changed: c.note,
                      child: _MistField(
                        controller: _note,
                        label: l.receiptNote,
                        hint: l.receiptAddNote,
                        maxLength: noteMaxLength,
                        style: input,
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    Center(
                      child: Semantics(
                        button: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _delete,
                          child: SizedBox(
                            height: 44,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 8,
                              children: [
                                const HugeIcon(
                                  icon: HugeIcons.strokeRoundedDelete02,
                                  size: 18,
                                  strokeWidth: AppStroke.icon,
                                  color: AppColors.ink,
                                ),
                                Text(
                                  l.editDelete,
                                  style: AppText.label.copyWith(
                                    fontSize: 15,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.ink,
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
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                spacing: 10,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 200),
                    child: Semantics(
                      button: n > 0,
                      child: GestureDetector(
                        onTap: n > 0 ? _reset : null,
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: AppColors.mist,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Center(
                            widthFactor: 1,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                n == 0 ? l.editNoChanges : l.editChanges(n),
                                style: AppText.label.copyWith(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PrimaryButton(
                      label: l.editSave,
                      icon: HugeIcons.strokeRoundedTick02,
                      onPressed: n > 0 && _value > 0 && !_saving ? _save : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Label row with a "• diubah" badge once the value moved.
class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.changed,
    required this.child,
  });

  final String label;
  final bool changed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        SizedBox(
          height: 18,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppText.caption.copyWith(color: AppColors.muted),
              ),
              if (changed)
                Row(
                  spacing: 6,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Text(
                      l.editChanged,
                      style: AppText.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _MistField extends StatelessWidget {
  const _MistField({
    required this.controller,
    required this.label,
    required this.style,
    required this.onChanged,
    this.hint,
    this.maxLength,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final int? maxLength;
  final TextStyle style;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLength: maxLength,
        style: style,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: style.copyWith(color: AppColors.subtle),
          counterText: '',
          filled: true,
          fillColor: AppColors.mist,
          isDense: true,
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
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.select,
          curve: AppMotion.ease,
          height: 44,
          padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
          decoration: BoxDecoration(
            color: selected ? AppColors.ink : AppColors.paper,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.ink, width: AppStroke.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Text(category.emoji, style: const TextStyle(fontSize: 17)),
              Text(
                category.name,
                style: AppText.label.copyWith(
                  fontSize: 15,
                  color: selected ? AppColors.paper : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
