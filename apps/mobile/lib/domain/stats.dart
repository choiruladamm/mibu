import 'models/finance.dart';

/// 02.3 statistik toggle.
enum StatsPeriod { week, month, year }

/// Half-open window [start, end), local midnights.
typedef Span = ({DateTime start, DateTime end});

/// The [p] window holding [d]: Monday week, calendar month, calendar year.
Span spanOf(StatsPeriod p, DateTime d) => switch (p) {
  StatsPeriod.week => (
    start: DateTime(d.year, d.month, d.day - d.weekday + 1),
    end: DateTime(d.year, d.month, d.day - d.weekday + 8),
  ),
  StatsPeriod.month => (
    start: DateTime(d.year, d.month),
    end: DateTime(d.year, d.month + 1),
  ),
  StatsPeriod.year => (start: DateTime(d.year), end: DateTime(d.year + 1)),
};

/// The window [by] periods after [s] (negative = earlier).
Span shiftSpan(StatsPeriod p, Span s, int by) => spanOf(p, switch (p) {
  StatsPeriod.week => DateTime(
    s.start.year,
    s.start.month,
    s.start.day + 7 * by,
  ),
  StatsPeriod.month => DateTime(s.start.year, s.start.month + by),
  StatsPeriod.year => DateTime(s.start.year + by),
});

/// One bar per day (week), per Monday week clipped to the month (month:
/// 1–4, 5–11 …), per month (year).
List<Span> barsOf(StatsPeriod p, Span s) {
  final bars = <Span>[];
  var a = s.start;
  while (a.isBefore(s.end)) {
    var b = switch (p) {
      StatsPeriod.week => DateTime(a.year, a.month, a.day + 1),
      StatsPeriod.month => DateTime(a.year, a.month, a.day - a.weekday + 8),
      StatsPeriod.year => DateTime(a.year, a.month + 1),
    };
    if (b.isAfter(s.end)) b = s.end;
    bars.add((start: a, end: b));
    a = b;
  }
  return bars;
}

bool _inside(DateTime at, Span s) =>
    !at.isBefore(s.start) && at.isBefore(s.end);

int _days(DateTime a, DateTime b) => DateTime.utc(
  b.year,
  b.month,
  b.day,
).difference(DateTime.utc(a.year, a.month, a.day)).inDays;

/// Expenses (positive) of live [entries] inside [s].
int spentIn(List<Transaction> entries, Span s) => entries
    .where((t) => !t.deleted && t.amount < 0 && _inside(t.at, s))
    .fold(0, (sum, t) => sum - t.amount);

/// ritme budget (on track nggak?), see MVP_PLAN › Statistik.
enum BudgetPace { over, near, under, fine }

/// One expense category in "larinya ke mana"; [category] null = tanpa
/// kategori.
typedef StatsCategory = ({String? category, String emoji, int spent});

/// What 02.3 shows for [span] of [period] (today = [today]).
class Stats {
  Stats(
    List<Transaction> entries, {
    required this.period,
    required this.span,
    required DateTime today,
    int? budget,
  }) : bars = barsOf(period, span) {
    final day = DateTime(today.year, today.month, today.day);
    _expenses = [
      for (final t in entries)
        if (!t.deleted && t.amount < 0 && _inside(t.at, span)) t,
    ];
    final expenses = _expenses;
    spent = [
      for (final b in bars) b.start.isAfter(day) ? null : spentIn(expenses, b),
    ];
    current = bars.indexWhere((b) => _inside(day, b));
    total = expenses.fold(0, (sum, t) => sum - t.amount);

    final byCat = <String?, StatsCategory>{};
    for (final t in expenses) {
      final c = byCat[t.category];
      byCat[t.category] = (
        category: t.category,
        emoji: t.emoji,
        spent: (c?.spent ?? 0) - t.amount,
      );
    }
    categories = byCat.values.toList()
      ..sort((a, b) => b.spent.compareTo(a.spent));

    // Days of the period gone by, today included.
    final length = _days(span.start, span.end);
    elapsed = day.isBefore(span.start)
        ? 0
        : day.isBefore(span.end)
        ? _days(span.start, day) + 1
        : length;
    left = length - elapsed;

    final b = budget;
    limit = b == null || b <= 0
        ? null
        : switch (period) {
            // Week crossing months: the month of its Monday.
            StatsPeriod.week =>
              (b * 7 / DateTime(span.start.year, span.start.month + 1, 0).day)
                  .round(),
            StatsPeriod.month => b,
            StatsPeriod.year => b * 12,
          };
  }

  final StatsPeriod period;
  final Span span;
  final List<Span> bars;
  late final List<Transaction> _expenses; // this period's, live

  /// Per bar; null = not yet (bar starts after today).
  late final List<int?> spent;

  /// Bar holding today; -1 = a past (or future) period.
  late final int current;
  late final int total;
  late final List<StatsCategory> categories; // most spent first
  late final int elapsed, left; // days
  late final int? limit; // budget for this period; null = no budget

  List<int> get _shown => [...spent.whereType<int>()];

  /// rata²: over bars that started, the current one included.
  int get average => _shown.isEmpty
      ? 0
      : (_shown.fold(0, (a, b) => a + b) / _shown.length).round();

  int get counted => _shown.length; // "dari 5 hari"

  /// paling boros: biggest bar so far; null = nothing spent.
  int? get peak {
    if (total == 0) return null;
    var best = 0;
    for (var i = 1; i < spent.length; i++) {
      if ((spent[i] ?? -1) > spent[best]!) best = i;
    }
    return best;
  }

  /// paling hemat: smallest finished bar (the running one can still grow);
  /// the current bar only when it's the only one.
  int? get low {
    if (total == 0) return null;
    int? best;
    for (var i = 0; i < spent.length; i++) {
      if (spent[i] == null || i == current) continue;
      if (best == null || spent[i]! < spent[best]!) best = i;
    }
    return best ?? (current >= 0 ? current : null);
  }

  /// Emoji of the biggest category in the [peak] bar (its badge).
  String? get peakEmoji {
    final i = peak;
    if (i == null) return null;
    final m = <String, int>{};
    for (final t in _expenses) {
      if (_inside(t.at, bars[i])) m[t.emoji] = (m[t.emoji] ?? 0) - t.amount;
    }
    return m.entries.reduce((a, b) => b.value > a.value ? b : a).key;
  }

  double get usedPct => limit == null ? 0 : total / limit! * 100;
  double get timePct => elapsed / _days(span.start, span.end) * 100;

  BudgetPace? get pace {
    final l = limit;
    if (l == null) return null;
    if (total > l) return BudgetPace.over;
    if (period == StatsPeriod.year) {
      return usedPct < timePct ? BudgetPace.under : BudgetPace.fine;
    }
    return usedPct >= 85 ? BudgetPace.near : BudgetPace.fine;
  }
}
