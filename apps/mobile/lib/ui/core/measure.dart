import 'package:flutter/painting.dart';

/// Rendered width of [text] in [style] ("0" when empty) — fields that hug
/// their digits (00.15 PocketLimit, 04.4 nominal).
double textWidth(String text, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(text: text.isEmpty ? '0' : text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final w = tp.width;
  tp.dispose();
  return w;
}
