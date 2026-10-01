import 'dart:ui';

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
