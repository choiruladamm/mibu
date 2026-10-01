import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/finance.dart';
import '../money.dart';
import '../tokens.dart';

/// 00.4 TxRow — 64 tall; tap opens 04.3 detail.
class TxRow extends StatelessWidget {
  const TxRow({super.key, required this.tx, this.onTap});

  final Transaction tx;
  final VoidCallback? onTap;

  static final _time = DateFormat.Hm('id');
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
                    tx.category,
                    style: _text,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${tx.place} · ${_time.format(tx.at)}',
                    style: AppText.caption.copyWith(color: AppColors.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(rupiahCompact(tx.amount), style: _text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
