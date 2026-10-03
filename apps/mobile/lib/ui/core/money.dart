import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../domain/models/finance.dart';

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

/// 02.4 sembunyiin nominal: digits (and K / jt) become •••, sign and Rp stay.
String maskAmount(String s) => s.replaceAll(RegExp(r'\d[\d.,]*(K|jt)?'), '•••');

/// Above the Navigator (MibuApp). [hide] = profile.hideAmounts; [peek] = the
/// user is peeking, nothing hidden. The context formatters read it, so a
/// screen only needs a context.
class AmountMask extends InheritedWidget {
  const AmountMask({
    super.key,
    required this.hide,
    this.peek = false,
    required super.child,
  });

  final HideAmounts hide;
  final bool peek;

  @override
  bool updateShouldNotify(AmountMask old) =>
      hide != old.hide || peek != old.peek;
}

/// `context.rp(v)` etc.: the formatters above, masked when 02.4 says so.
/// [income]: the figure is pemasukan or gives it away (a day total with a
/// salary in it), so "pemasukan aja" hides it too (99.5).
/// Outside an [AmountMask] (tests) nothing is hidden.
extension MoneyContext on BuildContext {
  AmountMask? get amountMask =>
      dependOnInheritedWidgetOfExactType<AmountMask>();

  bool hidesAmount({bool income = false}) {
    final m = amountMask;
    if (m == null || m.peek) return false;
    return switch (m.hide) {
      HideAmounts.none => false,
      HideAmounts.income => income,
      HideAmounts.all => true,
    };
  }

  String _m(String s, bool income) =>
      hidesAmount(income: income) ? maskAmount(s) : s;

  String rp(int v, {bool income = false}) => _m(rupiah(v), income);
  String rpCompact(int v, {bool income = false}) =>
      _m(rupiahCompact(v), income);
  String rpSigned(int v, {bool income = false}) => _m(rupiahSigned(v), income);
}
