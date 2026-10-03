import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../tokens.dart';

/// Quick payday picks in 01.4 and 00.24; 31 = akhir (last day of month).
const paydayChoices = [1, 10, 15, 25, 28, 31];

/// The most common payday in Indonesia: its chip gets the "umum" tag.
const commonPayday = 25;

/// One payday chip (01.4, 00.24): ink when [on], "umum" tag on 25.
class PaydayChip extends StatelessWidget {
  const PaydayChip({
    super.key,
    required this.day,
    required this.on,
    required this.onTap,
    this.label,
  });

  final int day; // 1–31, 31 = akhir
  final bool on;
  final VoidCallback onTap;
  final String? label; // overrides the day / "akhir" text ("lainnya")

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final text = label ?? (day == 31 ? l.setupPaydayEnd : '$day');
    return Semantics(
      button: true,
      selected: on,
      label:
          label ??
          (day == 31 ? l.setupPaydayEndLabel : l.setupPaydayLabel(day)),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            AnimatedContainer(
              duration: AppMotion.select,
              curve: AppMotion.ease,
              height: 48,
              constraints: const BoxConstraints(minWidth: 48),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              // No `alignment` on the container: it would stretch the chip to
              // the full width in a Wrap and stack them one per row. Center
              // with factors keeps it as wide as its text (min 48).
              decoration: BoxDecoration(
                color: on ? AppColors.ink : AppColors.paper,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.ink,
                  width: AppStroke.outline,
                ),
              ),
              // Shrinks instead of overflowing on narrow screens.
              child: Center(
                widthFactor: 1,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    style: AppText.label.copyWith(
                      fontWeight: FontWeight.w500,
                      color: on ? AppColors.paper : AppColors.ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ),
            if (day == commonPayday && label == null)
              Positioned(
                top: -9,
                child: Container(
                  height: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.paper,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    l.paydayCommon,
                    style: AppText.micro.copyWith(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
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
