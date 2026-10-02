import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../l10n/app_localizations.dart';
import '../tokens.dart';

const _undoWindow = Duration(seconds: 5);

/// Ink toast floating at the bottom (02.4c/d, 04.3c). With [onUndo] it gets
/// "batalin" and a 5s timer bar; without, a tick and it just informs.
void showToast(
  BuildContext context, {
  required String title,
  required String sub,
  VoidCallback? onUndo,
}) {
  final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      duration: _undoWindow,
      content: _Toast(
        title: title,
        sub: sub,
        onUndo: onUndo == null
            ? null
            : () {
                messenger.hideCurrentSnackBar();
                onUndo();
              },
      ),
    ),
  );
}

class _Toast extends StatelessWidget {
  const _Toast({required this.title, required this.sub, this.onUndo});

  final String title, sub;
  final VoidCallback? onUndo;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final undo = onUndo != null;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppShadows.lift,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
            child: Row(
              spacing: 12,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.paper,
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: undo
                        ? HugeIcons.strokeRoundedDelete02
                        : HugeIcons.strokeRoundedTick02,
                    size: 18,
                    strokeWidth: undo
                        ? AppStroke.icon
                        : AppStroke.iconOnInkSmall,
                    color: AppColors.ink,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 3,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.label.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.onInk,
                        ),
                      ),
                      Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption.copyWith(
                          color: AppColors.onInkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (undo)
                  Semantics(
                    button: true,
                    child: GestureDetector(
                      onTap: onUndo,
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: AppColors.onInk12,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 6,
                          children: [
                            const HugeIcon(
                              icon: HugeIcons.strokeRoundedUndo02,
                              size: 16,
                              strokeWidth: AppStroke.iconOnInkSmall,
                              color: AppColors.onInk,
                            ),
                            Text(
                              l.undo,
                              style: AppText.label.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onInk,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (undo)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: TweenAnimationBuilder(
                tween: Tween(begin: 1.0, end: 0.0),
                duration: _undoWindow,
                builder: (_, v, _) => FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: v,
                  child: Container(height: 3, color: AppColors.onInk45),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
