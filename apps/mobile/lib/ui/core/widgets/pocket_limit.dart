import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/models/finance.dart';
import '../../../l10n/app_localizations.dart';
import '../dashed.dart';
import '../money.dart';
import '../tokens.dart';

/// 00.15 PocketLimit — type, slide or pick a preset. Rules in MVP_PLAN.md
/// (Batas kantong); the scale comes from [pocketLimitScale].
class PocketLimit extends StatefulWidget {
  const PocketLimit({
    super.key,
    required this.value,
    required this.budget,
    required this.others,
    required this.monthDays,
    required this.onChanged,
    required this.onSetBudget,
  });

  static const presets = [100000, 300000, 600000, 1000000];
  static const cap = 100000000; // batas keras Rp100jt

  final int value;
  final int? budget; // budget bulanan; null = not set
  final int others; // Σ limits of the other pockets
  final int monthDays; // "≈ Rp… sehari" divides by this
  final ValueChanged<int> onChanged;
  final VoidCallback onSetBudget; // 00.16, shown when there's no budget

  @override
  State<PocketLimit> createState() => _PocketLimitState();
}

class _PocketLimitState extends State<PocketLimit> {
  late final _text = TextEditingController(text: _dots(widget.value));
  bool _capped = false;

  static String _dots(int v) => v == 0 ? '' : rupiah(v).replaceFirst('Rp', '');

  @override
  void didUpdateWidget(PocketLimit old) {
    super.didUpdateWidget(old);
    final shown = _dots(widget.value);
    if (_text.text != shown) _text.text = shown;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _set(int v, {bool capped = false}) {
    setState(() => _capped = capped);
    widget.onChanged(v);
  }

  void _typed(String s) {
    final digits = s.replaceAll(RegExp('[^0-9]'), '');
    final v = int.tryParse(digits.length > 9 ? digits.substring(0, 9) : digits);
    final over = (v ?? 0) > PocketLimit.cap;
    _set(over ? PocketLimit.cap : v ?? 0, capped: over);
    // Keep the dots as they type; caret stays at the end.
    final shown = _dots(over ? PocketLimit.cap : v ?? 0);
    _text.value = TextEditingValue(
      text: shown,
      selection: TextSelection.collapsed(offset: shown.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final v = widget.value;
    final scale = pocketLimitScale(
      budget: widget.budget,
      others: widget.others,
    );
    final free = scale.free;
    final over = free != null && v > free;
    final note = _capped
        ? l.limitMax
        : v == 0
        ? l.limitEmpty
        : over
        ? l.limitOver(rupiahCompact(v - free))
        : l.limitPerDay(rupiahCompact(v ~/ widget.monthDays));
    final loud = _capped || over;

    final len = _dots(v).isEmpty ? 1 : _dots(v).length;
    final size = len <= 9
        ? 30.0
        : len == 10
        ? 26.0
        : 22.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'Rp',
              style: AppText.label.copyWith(
                fontWeight: FontWeight.w500,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: (len * size * 0.58 + 6).clamp(24, 200),
              child: Semantics(
                label: l.limitFieldLabel,
                child: TextField(
                  controller: _text,
                  onChanged: _typed,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                  ],
                  style: AppText.headline.copyWith(
                    fontSize: size,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.03 * size,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: '0',
                    hintStyle: AppText.headline.copyWith(
                      fontSize: size,
                      color: AppColors.grey400,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              l.limitPerMonth,
              style: AppText.caption.copyWith(color: AppColors.muted),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                note,
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption.copyWith(
                  fontWeight: loud ? FontWeight.w600 : FontWeight.w400,
                  color: loud ? AppColors.ink : AppColors.muted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        _Track(
          value: v,
          max: scale.max,
          step: scale.step,
          free: free,
          freeLabel: free == null ? '' : l.limitFree(rupiahCompact(free)),
          setBudgetLabel: l.limitSetBudget,
          sliderLabel: l.limitSliderLabel,
          onSetBudget: widget.onSetBudget,
          onChanged: _set,
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final p in PocketLimit.presets)
              _Preset(
                label: rupiahCompact(p),
                on: v == p,
                onTap: () => _set(p),
              ),
          ],
        ),
      ],
    );
  }
}

/// Track + thumb; dashed mark at "sisa budget", or the set-budget link.
class _Track extends StatelessWidget {
  const _Track({
    required this.value,
    required this.max,
    required this.step,
    required this.free,
    required this.freeLabel,
    required this.setBudgetLabel,
    required this.sliderLabel,
    required this.onSetBudget,
    required this.onChanged,
  });

  final int value, max, step;
  final int? free;
  final String freeLabel, setBudgetLabel, sliderLabel;
  final VoidCallback onSetBudget;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        double x(int v) => (v / max).clamp(0.0, 1.0) * w;
        void slide(double dx) => onChanged(
          ((dx / w * max) / step).round().clamp(0, max ~/ step) * step,
        );
        final free = this.free;
        final up = (value + step).clamp(0, max),
            down = (value - step).clamp(0, max);

        return Semantics(
          slider: true,
          label: sliderLabel,
          value: rupiah(value),
          increasedValue: rupiah(up),
          decreasedValue: rupiah(down),
          onIncrease: () => onChanged(up),
          onDecrease: () => onChanged(down),
          child: SizedBox(
            height: 44,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (d) => slide(d.localPosition.dx),
                    onHorizontalDragUpdate: (d) => slide(d.localPosition.dx),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 26,
                  child: IgnorePointer(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.track,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: x(value),
                        decoration: BoxDecoration(
                          color: AppColors.ink,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
                if (free != null) ...[
                  Positioned(
                    left: x(free),
                    top: 18,
                    child: IgnorePointer(
                      child: CustomPaint(
                        size: const Size(1.5, 22),
                        painter: _DashedLine(),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (x(free) - 60).clamp(0, w - 120),
                    width: 120,
                    top: 0,
                    child: IgnorePointer(
                      child: Text(
                        freeLabel,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: AppText.micro.copyWith(color: AppColors.muted),
                      ),
                    ),
                  ),
                ] else
                  Positioned(
                    left: 0,
                    top: -2,
                    child: GestureDetector(
                      onTap: onSetBudget,
                      child: Text(
                        setBudgetLabel,
                        style: AppText.micro.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: x(value) - 12,
                  top: 17,
                  child: IgnorePointer(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.ink,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppColors.paper, spreadRadius: 4),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DashedLine extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      dashPath(Path()..lineTo(0, size.height), dash: 3, gap: 3),
      Paint()
        ..color = AppColors.grey400
        ..strokeWidth = AppStroke.outline
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_DashedLine old) => false;
}

class _Preset extends StatelessWidget {
  const _Preset({required this.label, required this.on, required this.onTap});

  final String label;
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
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: on ? AppColors.ink : AppColors.mist,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: AppText.caption.copyWith(
                fontWeight: on ? FontWeight.w600 : FontWeight.w400,
                color: on ? AppColors.paper : AppColors.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
