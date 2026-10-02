import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/finance.dart';
import '../../../l10n/app_localizations.dart';
import '../money.dart';
import '../tokens.dart';
import 'meta_line.dart';

/// 00.4 TxRow — 64 tall; tap opens 04.3 detail.
class TxRow extends StatelessWidget {
  const TxRow({super.key, required this.tx, this.onTap, this.withDate = false});

  final Transaction tx;
  final VoidCallback? onTap;
  final bool withDate; // search results span days: "warteg • 13 okt • 12:40"

  static final _time = DateFormat.Hm('id');
  static final _date = DateFormat('d MMM', 'id');
  static final _text = AppText.body.copyWith(letterSpacing: -0.18);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Row(
          spacing: 14,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: Text(
                  tx.emoji,
                  style: const TextStyle(fontSize: 30, height: 1),
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
                    tx.category ?? AppLocalizations.of(context)!.uncategorized,
                    style: _text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    spacing: 4,
                    children: [
                      if (tx.note.isNotEmpty)
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedNote,
                          size: 12,
                          strokeWidth: AppStroke.icon,
                          color: AppColors.ink,
                        ),
                      Expanded(
                        child: MetaLine(
                          [
                            tx.place,
                            if (withDate) _date.format(tx.at).toLowerCase(),
                            _time.format(tx.at),
                          ],
                          style: AppText.caption.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(context.rpSigned(tx.amount), style: _text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
