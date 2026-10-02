import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/app_emoji.dart';
import '../../../core/widgets/sheet.dart';

/// "sering dicatat": this many entries this month gets the ink warning card.
const busyEntries = 10;

/// LimitOffSheet — "copot limit X?" before a limit is dropped (02.2 kartu
/// detail, 03.5). True = copot.
Future<bool> showLimitOff(
  BuildContext context, {
  required String emoji,
  required String name,
  required int limit,
  required int spent, // this month, positive
  required int count, // entries this month
}) async =>
    await showAppSheet<bool>(
      context,
      _LimitOffSheet(
        emoji: emoji,
        name: name,
        limit: limit,
        spent: spent,
        count: count,
      ),
    ) ??
    false;

class _LimitOffSheet extends StatelessWidget {
  const _LimitOffSheet({
    required this.emoji,
    required this.name,
    required this.limit,
    required this.spent,
    required this.count,
  });

  final String emoji, name;
  final int limit, spent, count;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rows = [
      (HugeIcons.strokeRoundedMinusSign, AppColors.ink, l.limitOffNoWarn),
      (
        HugeIcons.strokeRoundedPlusSign,
        AppColors.ink,
        l.limitOffFreed(rupiahCompact(limit)),
      ),
      (
        HugeIcons.strokeRoundedTick02,
        AppColors.muted,
        l.limitOffKept(count, rupiahCompact(spent)),
      ),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),
          ExcludeSemantics(
            child: SizedBox(
              height: 120,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 18,
                children: [
                  _OffJar(
                    emoji: emoji,
                    fill: limit == 0 ? 1 : math.min(1, spent / limit),
                  ),
                  // ponytail: solid hugeicon, the board's arrow is dashed.
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight02,
                    size: 28,
                    strokeWidth: 1.6,
                    color: AppColors.grey400,
                  ),
                  Flexible(
                    child: _Chip(emoji: emoji, name: name, spent: spent),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Semantics(
            header: true,
            child: Text(
              l.limitOffTitle(name),
              textAlign: TextAlign.center,
              style: AppText.sheetTitle.copyWith(fontSize: 24),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.limitOffSub(name),
            textAlign: TextAlign.center,
            style: AppText.label.copyWith(
              fontSize: 15,
              height: 1.4,
              color: AppColors.muted,
            ),
          ),
          if (count >= busyEntries) ...[
            const SizedBox(height: 16),
            _BusyCard(
              title: l.limitOffBusyTitle(name, count),
              sub: l.limitOffBusySub(name),
            ),
          ],
          const SizedBox(height: 16),
          for (final (mark, color, text) in rows)
            Container(
              constraints: const BoxConstraints(minHeight: 44),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.track)),
              ),
              child: Row(
                spacing: 12,
                children: [
                  SizedBox(
                    width: 22,
                    child: HugeIcon(
                      icon: mark,
                      size: 16,
                      strokeWidth: 2,
                      color: color,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style: AppText.label.copyWith(fontSize: 14, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: l.pocketRelease,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ink,
                shape: const StadiumBorder(),
              ),
              child: Text(
                l.confirmCancel,
                style: AppText.label.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The jar going away: faded with a thin outline, filled to [fill], ink
/// "−" badge top right.
class _OffJar extends StatelessWidget {
  const _OffJar({required this.emoji, required this.fill});

  final String emoji;
  final double fill; // 0–1

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Opacity(
          opacity: 0.5,
          child: Container(
            width: 50,
            height: 112,
            clipBehavior: Clip.antiAlias,
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: AppColors.pressed,
                width: AppStroke.outline,
              ),
            ),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: fill,
                    widthFactor: 1,
                    child: const ColoredBox(color: AppColors.ink),
                  ),
                ),
                Positioned(
                  left: 7,
                  top: 7,
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.paper,
                      shape: BoxShape.circle,
                    ),
                    child: AppEmoji(emoji, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: -8,
          top: -8,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.paper, spreadRadius: 3)],
            ),
            child: const HugeIcon(
              icon: HugeIcons.strokeRoundedMinusSign,
              size: 12,
              strokeWidth: 3,
              color: AppColors.onInk,
            ),
          ),
        ),
      ],
    );
  }
}

/// Where it lands: a plain "buat apa" chip with this month's spend.
class _Chip extends StatelessWidget {
  const _Chip({required this.emoji, required this.name, required this.spent});

  final String emoji, name;
  final int spent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.fromLTRB(6, 0, 14, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.ink, width: AppStroke.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.mist,
              shape: BoxShape.circle,
            ),
            child: AppEmoji(emoji, size: 22),
          ),
          Flexible(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.label.copyWith(fontSize: 14),
            ),
          ),
          Text(
            rupiahCompact(spent),
            style: AppText.label.copyWith(
              fontSize: 14,
              color: AppColors.muted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _BusyCard extends StatelessWidget {
  const _BusyCard({required this.title, required this.sub});

  final String title, sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.paper,
              shape: BoxShape.circle,
            ),
            child: ExcludeSemantics(
              child: Text(
                '!',
                style: AppText.label.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  title,
                  style: AppText.label.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.paper,
                  ),
                ),
                Text(
                  sub,
                  style: AppText.caption.copyWith(
                    height: 1.4,
                    color: AppColors.onInkMuted,
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
