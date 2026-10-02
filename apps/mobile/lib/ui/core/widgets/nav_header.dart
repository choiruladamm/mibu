import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../l10n/app_localizations.dart';
import '../tokens.dart';
import 'meta_line.dart';
import 'sheet.dart';

/// 00.5 NavHeader — ink back disc, title + sub, optional action disc.
class NavHeader extends StatelessWidget {
  const NavHeader({
    super.key,
    required this.title,
    required this.sub,
    required this.backLabel,
    this.actionIcon,
    this.actionLabel,
    this.onAction,
    this.onMist = false,
  });

  final String title;
  final List<String> sub; // MetaLine parts
  final String backLabel; // "beranda" → "balik ke beranda"
  final List<List<dynamic>>? actionIcon; // null = no action
  final String? actionLabel;
  final VoidCallback? onAction; // null = disabled
  final bool onMist; // on a mist screen the action disc is paper

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SizedBox(
      height: 64, // 44 disc + 10 above and below, so it clears the safe area and the list
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          spacing: 14,
          children: [
            Semantics(
              button: true,
              label: l.backTo(backLabel),
              excludeSemantics: true,
              child: GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.ink,
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowLeft01,
                    size: 20,
                    strokeWidth: AppStroke.iconOnInkSmall,
                    color: AppColors.paper,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 1,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.headline.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                  MetaLine(
                    sub,
                    style: AppText.caption.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (actionIcon case final icon?)
              CircleButton(
                icon: icon,
                label: actionLabel ?? '',
                iconSize: 20,
                color: onMist ? AppColors.paper : AppColors.mist,
                onTap: onAction,
              ),
          ],
        ),
      ),
    );
  }
}
