import 'models/finance.dart';

/// 04.2 cari: entries whose category, place, note or a tag contains [term]
/// (case-insensitive), newest first. [kind] null = semua. Empty term = none.
List<Transaction> searchEntries(
  List<Transaction> all,
  String term, {
  CategoryKind? kind,
}) {
  final q = term.trim().toLowerCase();
  if (q.isEmpty) return const [];
  return [
    for (final t in all)
      if (!t.deleted &&
          (kind == null || t.kind == kind) &&
          [
            t.category ?? '',
            t.place,
            t.note,
            ...t.tags,
          ].any((s) => s.toLowerCase().contains(q)))
        t,
  ]..sort((a, b) => b.at.compareTo(a.at));
}

/// What the 04.2 summary card shows for [hits] (non-empty).
class SearchSummary {
  SearchSummary(List<Transaction> hits)
    : count = hits.length,
      days = {for (final t in hits) DateTime(t.at.year, t.at.month, t.at.day)}
          .length,
      total = hits.fold(0, (sum, t) => sum + t.amount),
      mixed = hits.any((t) => t.amount > 0) && hits.any((t) => t.amount < 0);

  final int count, days;
  final int total; // signed; negative = pengeluaran
  final bool mixed; // both pengeluaran and pemasukan → "selisih"

  /// "rata²" per hit.
  int get average => count == 0 ? 0 : total ~/ count;
}
