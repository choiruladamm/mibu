import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../tokens.dart';
import 'sheet.dart';

/// One short paragraph of the "dari mana angkanya?" dialog.
typedef InfoLine = ({String title, String body});

/// "dari mana angkanya?": a few short lines on how the figures on screen
/// are worked out, with this user's own numbers. [note] = a caution box.
Future<void> showNumbersInfo(
  BuildContext context, {
  required List<InfoLine> lines,
  String? note,
}) => showAppSheet<void>(context, _NumbersInfo(lines: lines, note: note));

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
  const _NumbersInfo({required this.lines, required this.note});

  final List<InfoLine> lines;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
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
          const SizedBox(height: 16),
          for (final line in lines) ...[
            Text(
              line.title,
              style: AppText.label.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              line.body,
              style: AppText.label.copyWith(
                fontSize: 14,
                height: 1.45,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 14),
          ],
          if (note case final text?)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(AppRadius.statTile),
              ),
              child: Text(
                text,
                style: AppText.label.copyWith(fontSize: 14, height: 1.4),
              ),
            ),
          const SizedBox(height: 6),
          PrimaryButton(
            label: l.infoOk,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
