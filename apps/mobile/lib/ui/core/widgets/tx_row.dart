import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/finance.dart';
import '../../../l10n/app_localizations.dart';
import '../money.dart';
import '../tokens.dart';
import 'meta_line.dart';
import 'app_emoji.dart';

/// 00.4 TxRow — always 64 tall, two symmetric columns. Left: buat apa + tag
/// chip (first tag + "+n") over tempat • catatan. Right: nominal over jam.
/// Tap opens 04.3 detail, tap the tag chip opens 04.2 on that tag.
class TxRow extends StatelessWidget {
  const TxRow({
    super.key,
    required this.tx,
    this.onTap,
    this.onTagTap,
    this.withDate = false,
  });

  final Transaction tx;
  final VoidCallback? onTap;
  final ValueChanged<String>? onTagTap;
  final bool withDate; // search results span days: jam becomes "13 okt • 12:40"

  // "14:32", not the id locale's "14.32": a dot next to the rupiah reads as a number
  static final _time = DateFormat('HH:mm');
  static final _date = DateFormat('d MMM', 'id');
  static final _text = AppText.body.copyWith(letterSpacing: -0.18);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final note = tx.note.trim();
    final tags = tx.tags;
    final muted = AppText.caption.copyWith(color: AppColors.muted);
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
              child: Center(child: AppEmoji(tx.emoji, size: 34)),
            ),
            Expanded(
              child: Row(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    // no tempat and no catatan: buat apa centers alone
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 2,
                      children: [
                        SizedBox(
                          height: 23,
                          child: Row(
                            spacing: 6,
                            children: [
                              Flexible(
                                child: Text(
                                  tx.category ?? l.uncategorized,
                                  style: _text,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (tags.isNotEmpty)
                                _TagChip(
                                  // seed / csv tags come without the #
                                  tags.first.startsWith('#')
                                      ? tags.first
                                      : '#${tags.first}',
                                  onTap: onTagTap == null
                                      ? null
                                      : () => onTagTap!(tags.first),
                                ),
                              if (tags.length > 1)
                                _TagChip('+${tags.length - 1}'),
                            ],
                          ),
                        ),
                        if (tx.place.isNotEmpty || note.isNotEmpty)
                          SizedBox(
                            height: 18,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: MetaLine.rich([
                                if (tx.place.isNotEmpty)
                                  TextSpan(text: tx.place),
                                if (note.isNotEmpty)
                                  TextSpan(
                                    text: note,
                                    style: const TextStyle(
                                      color: AppColors.ink,
                                    ),
                                  ),
                              ], style: muted),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 2,
                    children: [
                      SizedBox(
                        height: 23,
                        child: Text(
                          context.rpSigned(tx.amount, income: tx.amount > 0),
                          style: _text,
                        ),
                      ),
                      SizedBox(
                        height: 18,
                        // jam sits quieter than the nominal: 11px, subtle
                        child: MetaLine(
                          [
                            if (withDate) _date.format(tx.at).toLowerCase(),
                            _time.format(tx.at),
                          ],
                          style: AppText.micro.copyWith(
                            color: AppColors.subtle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 00.4b tag chip: mist, 20 tall, never shrinks (the buat apa gives way).
class _TagChip extends StatelessWidget {
  const _TagChip(this.label, {this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(label, style: AppText.caption.copyWith(fontSize: 12)),
    ),
  );
}
