import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import '../../../domain/period.dart';
import '../../../l10n/app_localizations.dart';
import '../dates.dart';
import '../money.dart';
import '../tokens.dart';
import 'app_emoji.dart';
import 'meta_line.dart';
import 'sheet.dart';

/// Where [showNumbersInfo] was opened from: its cards are the ink ones.
enum NumbersFrom { hero, pockets }

/// NumbersSheet 00.25 "dari mana angkanya?": sisa budget, aman jajan per
/// hari and sisa jajan (kantong) for [period], with this user's numbers.
/// [budget] null = no budget (no aman jajan); [share] = today's aman jajan
/// share before today's spending (null outside the running period);
/// [days] = days left in the period; [limits] / [pocketSpent] = Σ kantong
/// limits and what they spent (no kantong card when [limits] is 0).
Future<void> showNumbersInfo(
  BuildContext context, {
  required NumbersFrom from,
  required Period period,
  required int? budget,
  required int spent,
  required int spentToday,
  required int? share,
  required int days,
  required int limits,
  required int pocketSpent,
}) {
  final l = AppLocalizations.of(context)!;
  final rp = context.rpCompact;
  final hero = from == NumbersFrom.hero;
  final left = budget == null ? null : budget - spent;
  final outside = spent - pocketSpent;
  return showAppSheet<void>(
    context,
    _NumbersInfo(
      pockets: !hero,
      meta: [
        _monthFull.format(period.key).toLowerCase(),
        periodRange(period.start, period.end),
      ],
      cards: [
        (
          title: l.infoBudgetTitle,
          value: left == null ? '—' : rp(left),
          calc: budget == null
              ? l.infoBudgetNone
              : l.infoBudgetCalc(rp(budget), rp(spent)),
          note: null,
          on: hero,
        ),
        if (share != null && left != null)
          (
            title: l.infoSafeTitle,
            value: rp(share),
            calc: l.infoSafeCalc(rp(left + spentToday), days),
            note: spentToday > 0
                ? l.infoSafeToday(rp(spentToday), rp(share - spentToday))
                : null,
            on: hero,
          ),
        if (limits > 0)
          (
            title: l.infoJarTitle,
            value: rp(limits - pocketSpent),
            calc: l.infoJarCalc(rp(limits), rp(pocketSpent)),
            note: outside > 0 ? l.infoJarOutside(rp(outside)) : null,
            on: !hero,
          ),
      ],
    ),
  );
}

final _monthFull = DateFormat.MMMM('id');

typedef _Card = ({
  String title,
  String value,
  String calc,
  String? note,
  bool on, // ink: the figure the sheet was opened from
});

/// The "?" next to a figure that opens [showNumbersInfo]; an ink "!" when the
/// figures on screen disagree ([alert]), so it only shouts when it matters.
class InfoDisc extends StatelessWidget {
  const InfoDisc({
    super.key,
    required this.onTap,
    this.alert = false,
    this.target = 32,
  });

  final VoidCallback onTap;
  final bool alert;
  final double target; // tap area around the 20px disc

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      label: l.infoWhere,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: target,
          child: Center(
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: alert ? AppColors.ink : AppColors.mist,
                shape: BoxShape.circle,
              ),
              child: Text(
                alert ? '!' : '?',
                style: AppText.micro.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: alert ? AppColors.paper : AppColors.muted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NumbersInfo extends StatelessWidget {
  const _NumbersInfo({
    required this.pockets,
    required this.meta,
    required this.cards,
  });

  final bool pockets; // opened from kantong: one line on what a kantong is
  final List<String> meta;
  final List<_Card> cards;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tabular = [const FontFeature.tabularFigures()];
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
          Semantics(
            header: true,
            child: Text(
              l.infoWhere,
              style: AppText.sheetTitle.copyWith(fontSize: 24),
            ),
          ),
          const SizedBox(height: 4),
          MetaLine(
            meta,
            style: AppText.label.copyWith(fontSize: 14, color: AppColors.muted),
          ),
          if (pockets) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.mist,
                    shape: BoxShape.circle,
                  ),
                  child: const AppEmoji('🫙', size: 20),
                ),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: l.infoPocketsLead,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        TextSpan(text: ' ${l.infoPocketsBody}'),
                      ],
                    ),
                    style: AppText.label.copyWith(
                      fontSize: 14,
                      height: 1.4,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          for (final c in cards) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: c.on ? AppColors.ink : AppColors.mist,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    spacing: 12,
                    children: [
                      Expanded(
                        child: Text(
                          c.title,
                          style: AppText.label.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: c.on ? AppColors.paper : AppColors.ink,
                          ),
                        ),
                      ),
                      Text(
                        c.value,
                        style: AppText.label.copyWith(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: c.on ? AppColors.paper : AppColors.ink,
                          fontFeatures: tabular,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    c.calc,
                    style: AppText.label.copyWith(
                      fontSize: 14,
                      color: c.on ? AppColors.onInkMuted : AppColors.muted,
                      fontFeatures: tabular,
                    ),
                  ),
                  if (c.note case final note?)
                    Text(
                      note,
                      style: AppText.caption.copyWith(
                        height: 1.4,
                        color: c.on ? AppColors.onInkMuted : AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          PrimaryButton(
            label: l.infoOk,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
