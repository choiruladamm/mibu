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

/// One day's hits in the summary ticks.
typedef SearchDay = ({int count, int sum, int income, int expense});

/// The line under the total in the summary card.
enum SearchInsight { mixed, daily, single, busiest, biggest }

/// What the 04.2 summary card (00.14 SearchSummary) shows for [hits]
/// (non-empty, all in one month). [today] = day of month the card counts
/// up to (the last day for a past month).
class SearchSummary {
  SearchSummary(List<Transaction> hits, {required this.today})
    : count = hits.length,
      byDay = _byDay(hits),
      total = hits.fold(0, (sum, t) => sum + t.amount),
      income = hits.fold(0, (sum, t) => sum + (t.amount > 0 ? t.amount : 0)),
      expense = hits.fold(0, (sum, t) => sum + (t.amount < 0 ? t.amount : 0));

  final int count, today;
  final Map<int, SearchDay> byDay; // day of month → that day's hits
  final int total; // signed; negative = pengeluaran
  final int income, expense; // expense ≤ 0

  int get days => byDay.length;
  bool get mixed => income > 0 && expense < 0; // → "selisih"

  /// "rata²" per hit.
  int get average => count == 0 ? 0 : total ~/ count;

  /// Longest run of consecutive days with a hit, up to [today].
  int get streak {
    var best = 0, run = 0;
    for (var d = 1; d <= today; d++) {
      run = byDay.containsKey(d) ? run + 1 : 0;
      if (run > best) best = run;
    }
    return best;
  }

  /// Day with the most hits (first wins a tie).
  int get busiestDay => _best((d) => d.count);

  /// Day with the largest |sum| (first wins a tie).
  int get biggestDay => _best((d) => d.sum.abs());

  SearchInsight get insight {
    if (mixed) return SearchInsight.mixed;
    if (days >= 12) return SearchInsight.daily;
    if (count == 1) return SearchInsight.single;
    return byDay[busiestDay]!.count >= 2
        ? SearchInsight.busiest
        : SearchInsight.biggest;
  }

  int _best(int Function(SearchDay) score) {
    final keys = byDay.keys.toList()..sort();
    return keys.reduce((a, b) => score(byDay[b]!) > score(byDay[a]!) ? b : a);
  }

  static Map<int, SearchDay> _byDay(List<Transaction> hits) {
    final m = <int, SearchDay>{};
    for (final t in hits) {
      final b = m[t.at.day] ?? (count: 0, sum: 0, income: 0, expense: 0);
      m[t.at.day] = (
        count: b.count + 1,
        sum: b.sum + t.amount,
        income: b.income + (t.amount > 0 ? t.amount : 0),
        expense: b.expense + (t.amount < 0 ? t.amount : 0),
      );
    }
    return m;
  }
}
