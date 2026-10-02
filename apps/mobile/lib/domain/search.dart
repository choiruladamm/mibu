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

/// 04.2b "terakhir dicari": [q] moved to the front, at most 5.
List<String> rememberSearch(List<String> recent, String q) {
  final t = q.trim();
  if (t.isEmpty) return recent;
  return [t, ...recent.where((r) => r != t)].take(5).toList();
}

/// 04.2b "coba cari": the 3 most-used places (one per category), then the
/// 3 most-used categories not already covered. Expenses in [month] only.
List<({String emoji, String label})> searchIdeas(List<Transaction> month) {
  final places = <String, ({int n, String emoji, String? cat})>{};
  final cats = <String, ({int n, String emoji})>{};
  for (final t in month) {
    if (t.deleted || t.amount >= 0) continue;
    if (t.place.isNotEmpty) {
      final p = places[t.place];
      places[t.place] = (n: (p?.n ?? 0) + 1, emoji: t.emoji, cat: t.category);
    }
    if (t.category case final c?) {
      cats[c] = (n: (cats[c]?.n ?? 0) + 1, emoji: t.emoji);
    }
  }
  // Most used first; ties keep first appearance (input is newest first).
  List<String> ranked(Map<String, int> n) {
    final keys = n.keys.toList();
    return [...keys]..sort(
      (a, b) => n[b] != n[a]
          ? n[b]!.compareTo(n[a]!)
          : keys.indexOf(a).compareTo(keys.indexOf(b)),
    );
  }

  final seen = <String?>{};
  final topPlaces = [
    for (final k in ranked({for (final e in places.entries) e.key: e.value.n}))
      if (seen.add(places[k]!.cat)) k,
  ].take(3).toList();
  final covered = {for (final k in topPlaces) places[k]!.cat};
  final topCats = [
    for (final k in ranked({for (final e in cats.entries) e.key: e.value.n}))
      if (!covered.contains(k)) k,
  ].take(3);
  return [
    for (final k in topPlaces) (emoji: places[k]!.emoji, label: k),
    for (final k in topCats) (emoji: cats[k]!.emoji, label: k),
  ];
}

/// 04.2c "maksud kamu …?": the closest category name or place word in
/// [entries] within 2 edits of [term] (3+ letters), or null.
String? didYouMean(List<Transaction> entries, String term) {
  final q = term.trim().toLowerCase();
  if (q.length < 3) return null;
  final vocab = {
    for (final t in entries) ...[
      ?t.category?.toLowerCase(),
      ...t.place.toLowerCase().split(' '),
    ],
  }..remove('');
  if (vocab.contains(q)) return null; // spelled right, just not here
  String? best;
  var bestD = 3;
  for (final w in vocab) {
    if ((w.length - q.length).abs() > 2) continue;
    final d = _edits(w, q);
    if (d < bestD) (best, bestD) = (w, d);
  }
  return best;
}

/// Levenshtein distance.
int _edits(String a, String b) {
  var prev = List.generate(b.length + 1, (j) => j);
  for (var i = 1; i <= a.length; i++) {
    final cur = [i, ...List.filled(b.length, 0)];
    for (var j = 1; j <= b.length; j++) {
      final sub = prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1);
      final del = prev[j] + 1, ins = cur[j - 1] + 1;
      cur[j] = sub < del ? (sub < ins ? sub : ins) : (del < ins ? del : ins);
    }
    prev = cur;
  }
  return prev[b.length];
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

  /// Day with a hit closest to [d] (earlier wins a tie): picking a tick
  /// snaps to it.
  int nearestDay(int d) {
    final keys = byDay.keys.toList()..sort();
    return keys.reduce((a, b) => (b - d).abs() < (a - d).abs() ? b : a);
  }

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
