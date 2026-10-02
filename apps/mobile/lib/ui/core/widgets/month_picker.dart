import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../l10n/app_localizations.dart';
import '../tokens.dart';

/// 00.7 MonthPicker — pill trigger for 00.8 MonthMenu.
class MonthPicker extends StatelessWidget {
  const MonthPicker({
    super.key,
    required this.label,
    required this.onTap,
    this.open = false,
  });

  final String label;
  final bool open;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = open ? AppColors.paper : AppColors.ink;
    return Semantics(
      button: true,
      expanded: open,
      label: AppLocalizations.of(context)!.monthPickerLabel(label),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.select,
          height: 40,
          padding: const EdgeInsets.only(left: 16, right: 12),
          decoration: BoxDecoration(
            color: open ? AppColors.ink : AppColors.paper,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: open
                ? null
                : Border.all(color: AppColors.ink, width: AppStroke.outline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.label.copyWith(fontSize: 15, color: fg),
                ),
              ),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration: AppMotion.select,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowDown01,
                  size: 16,
                  strokeWidth: AppStroke.iconOnInkSmall,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
