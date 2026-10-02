import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../l10n/app_localizations.dart';
import '../dashed.dart';
import '../tokens.dart';
import 'sheet.dart';
import 'app_emoji.dart';

/// Pocket before → after, shown in the modal's mist box.
typedef ConfirmImpact = ({String label, String value, int fromPct, int toPct});

/// 00.6 ConfirmModal — floating card over a 45% scrim. True = confirmed.
Future<bool> showConfirmModal(
  BuildContext context, {
  required String emoji,
  required String title,
  required String body,
  ConfirmImpact? impact,
}) async =>
    await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppLocalizations.of(context)!.close,
      barrierColor: AppColors.scrim,
      transitionDuration: AppMotion.sheet,
      transitionBuilder: (_, a, _, child) {
        final t = AppMotion.ease.transform(a.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 24 * (1 - t)),
            child: child,
          ),
        );
      },
      pageBuilder: (context, _, _) => SafeArea(
        minimum: const EdgeInsets.only(bottom: 24),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _ConfirmModal(
              emoji: emoji,
              title: title,
              body: body,
              impact: impact,
            ),
          ),
        ),
      ),
    ) ??
    false;

class _ConfirmModal extends StatelessWidget {
  const _ConfirmModal({
    required this.emoji,
    required this.title,
    required this.body,
    required this.impact,
  });

  final String emoji, title, body;
  final ConfirmImpact? impact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final muted = AppText.caption.copyWith(color: AppColors.muted);
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: Material(
        type: MaterialType.transparency,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(AppRadius.sheet),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40111111),
                offset: Offset(0, 24),
                blurRadius: 60,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: _Badge(emoji: emoji)),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppText.label.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.44,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                body,
                textAlign: TextAlign.center,
                style: AppText.label.copyWith(
                  fontSize: 15,
                  height: 1.4,
                  color: AppColors.muted,
                ),
              ),
              if (impact case final i?) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(AppRadius.statTile),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 10,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          Expanded(
                            child: EmojiText(
                              i.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: muted,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              i.value,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.caption.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                        child: CustomPaint(
                          painter: _ImpactBar(i.fromPct, i.toPct),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        spacing: 8,
                        children: [
                          for (final text in [
                            l.confirmNow(i.fromPct),
                            l.confirmAfter(i.toPct),
                          ])
                            Flexible(
                              child: Text(
                                text,
                                overflow: TextOverflow.ellipsis,
                                style: muted.copyWith(fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: l.confirmDelete,
                icon: HugeIcons.strokeRoundedDelete02,
                onPressed: () => Navigator.of(context).pop(true),
              ),
              const SizedBox(height: 8),
              Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).pop(false),
                  child: SizedBox(
                    height: 48,
                    child: Center(
                      child: Text(
                        l.confirmCancel,
                        style: AppText.label.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Emoji disc with an ink "−" badge.
class _Badge extends StatelessWidget {
  const _Badge({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.mist,
              shape: BoxShape.circle,
            ),
            child: AppEmoji(emoji, size: 38),
          ),
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.ink,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.paper, width: 3),
              ),
              child: const HugeIcon(
                icon: HugeIcons.strokeRoundedMinusSign,
                size: 12,
                strokeWidth: 3,
                color: AppColors.paper,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paper track; dashed outline = now, ink fill = after.
class _ImpactBar extends CustomPainter {
  const _ImpactBar(this.fromPct, this.toPct);

  final int fromPct, toPct;

  @override
  void paint(Canvas canvas, Size size) {
    const r = Radius.circular(5);
    RRect bar(int pct) => RRect.fromLTRBR(
      0,
      0,
      size.width * pct.clamp(0, 100) / 100,
      size.height,
      r,
    );
    canvas
      ..drawRRect(
        RRect.fromLTRBR(0, 0, size.width, size.height, r),
        Paint()..color = AppColors.paper,
      )
      ..drawPath(
        dashPath(Path()..addRRect(bar(fromPct).deflate(0.75))),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppStroke.outline
          ..color = AppColors.grey400,
      )
      ..drawRRect(bar(toPct), Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(_ImpactBar old) =>
      old.fromPct != fromPct || old.toPct != toPct;
}
