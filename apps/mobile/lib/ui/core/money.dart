import 'package:intl/intl.dart';

final _full = NumberFormat('#,##0', 'id_ID');
final _k = NumberFormat('#,##0.#', 'id_ID');
final _jt = NumberFormat('#,##0.##', 'id_ID');

String _sign(int v) => v < 0 ? '-' : '';

/// Rp4.530.000 — hero / full amounts. Rupiah, no decimals.
String rupiah(int v) => '${_sign(v)}Rp${_full.format(v.abs())}';

/// Rp580K · Rp6,7K · Rp4,53jt — when space is tight.
// ponytail: no miliar unit; ≥1M rupiah stays in jt (Rp1.250jt). Add when needed.
String rupiahCompact(int v) {
  final a = v.abs();
  if (a < 1000) return rupiah(v);
  // One decimal under 100K (Rp6,7K), whole K from there (Rp387K).
  final k = a < 99950 ? (a / 100).round() / 10 : (a / 1000).roundToDouble();
  if (k < 1000) return '${_sign(v)}Rp${_k.format(k)}K';
  return '${_sign(v)}Rp${_jt.format((a / 10000).round() / 100)}jt';
}

/// +Rp8,5jt · -Rp450K · Rp0 — compact with the sign spelled out.
String rupiahSigned(int v) => v > 0 ? '+${rupiahCompact(v)}' : rupiahCompact(v);
