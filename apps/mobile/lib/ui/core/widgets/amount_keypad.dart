import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../l10n/app_localizations.dart';
import '../tokens.dart';

enum KeypadVariant {
  entry, // 03.1: "+" adds another amount
  budget, // 00.16: "00" instead of "+"
}

/// 00.17 AmountKeypad — 3×4 digits, then ⌫ · C · simpan in the right column.
/// Keys: '0'–'9', '000', and '+' (entry) or '00' (budget).
class AmountKeypad extends StatelessWidget {
  const AmountKeypad({
    super.key,
    this.variant = KeypadVariant.entry,
    required this.onKey,
    required this.onBackspace,
    required this.onClear,
    required this.onSave,
    required this.saveLabel,
    required this.canClear,
    required this.canSave,
  });

  static const _rowHeight = 58.0, _gap = 8.0;

  final KeypadVariant variant;
  final ValueChanged<String> onKey;
  final VoidCallback onBackspace, onClear, onSave;
  final String saveLabel; // under "simpan": "pengeluaran", "Rp8jt / bln" …
  final bool canClear, canSave;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final last = variant == KeypadVariant.entry ? '+' : '00';
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['000', '0', last],
    ];

    Widget key(String k) => _Key(
      label: switch (k) {
        '+' => l.keyPlus,
        '000' => l.keyThreeZeros,
        '00' => l.keyTwoZeros,
        _ => k,
      },
      color: k == '+' ? AppColors.pressed : AppColors.mist,
      onTap: () => onKey(k),
      child: Text(
        k,
        style: AppText.label.copyWith(
          fontSize: k.length > 1 ? 18 : 26,
          fontWeight: k == '+' ? FontWeight.w500 : FontWeight.w400,
        ),
      ),
    );

    return SizedBox(
      height: _rowHeight * 4 + _gap * 3,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: _gap,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              spacing: _gap,
              children: [
                for (final r in rows)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: _gap,
                      children: [for (final k in r) Expanded(child: key(k))],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: _gap,
              children: [
                Expanded(
                  child: _Key(
                    label: l.keyBackspace,
                    outline: AppColors.ink,
                    onTap: onBackspace,
                    child: const HugeIcon(
                      icon: AppIcons.backspace,
                      size: 24,
                      strokeWidth: AppStroke.icon,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                Expanded(
                  child: _Key(
                    label: l.keyClear,
                    outline: canClear ? AppColors.ink : AppColors.divider,
                    onTap: canClear ? onClear : null,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'C',
                          style: AppText.label.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                            color: canClear ? AppColors.ink : AppColors.line,
                          ),
                        ),
                        Text(
                          l.keyClearShort,
                          style: AppText.micro.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: canClear ? AppColors.ink : AppColors.line,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _SaveKey(
                    label: l.keySave,
                    sub: saveLabel,
                    onTap: canSave ? onSave : null,
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

class _Key extends StatelessWidget {
  const _Key({
    required this.label,
    required this.onTap,
    required this.child,
    this.color = AppColors.paper,
    this.outline,
  });

  final String label;
  final VoidCallback? onTap; // null = disabled
  final Widget child;
  final Color color;
  final Color? outline;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: outline == null
          ? BorderSide.none
          : BorderSide(color: outline!, width: AppStroke.outline),
    );
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: color,
        shape: shape,
        child: InkWell(
          customBorder: shape,
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _SaveKey extends StatelessWidget {
  const _SaveKey({required this.label, required this.sub, required this.onTap});

  final String label, sub;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final on = onTap != null;
    final fg = on ? AppColors.paper : AppColors.subtle;
    return _Key(
      label: '$label $sub',
      color: on ? AppColors.ink : AppColors.track,
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedTick02,
            size: 22,
            strokeWidth: AppStroke.iconOnInkSmall,
            color: fg,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppText.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
          Text(
            sub,
            textAlign: TextAlign.center,
            style: AppText.micro.copyWith(color: fg.withValues(alpha: 0.75)),
          ),
        ],
      ),
    );
  }
}
