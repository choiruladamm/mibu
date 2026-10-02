import 'package:flutter/rendering.dart';

import 'tokens.dart';

/// Dashed copy of [source] — "dashed" stroke from 00.1 (rata-rata, budget, baru).
Path dashPath(Path source, {double dash = 4, double gap = 5}) {
  final out = Path();
  for (final m in source.computeMetrics()) {
    for (var d = 0.0; d < m.length; d += dash + gap) {
      out.addPath(m.extractPath(d, d + dash), Offset.zero);
    }
  }
  return out;
}

/// Dashed ink outline of a rounded card (02.1 belum ada catatan, 04.2b2).
class DashedCardPainter extends CustomPainter {
  const DashedCardPainter(this.radius);

  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(AppStroke.outline / 2),
      Radius.circular(radius),
    );
    canvas.drawPath(
      dashPath(Path()..addRRect(r)),
      Paint()
        ..color = AppColors.ink
        ..strokeWidth = AppStroke.outline
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(DashedCardPainter old) => old.radius != radius;
}
