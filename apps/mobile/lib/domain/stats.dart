import 'models/finance.dart';
import 'period.dart';

/// 02.3 statistik toggle.
enum StatsPeriod { week, month, year }

/// Half-open window [start, end), local midnights.
typedef Span = ({DateTime start, DateTime end});

/// The [p] window holding [d]: Monday week, budget period ([periods],
/// calendar month in v1), calendar year.
Span spanOf(
  StatsPeriod p,
  DateTime d, {
  PeriodResolver periods = const CalendarMonthResolver(),
}) => switch (p) {
  StatsPeriod.week => (
    start: DateTime(d.year, d.month, d.day - d.weekday + 1),
    end: DateTime(d.year, d.month, d.day - d.weekday + 8),
  ),
  StatsPeriod.month => _span(periods.periodOf(d)),
  StatsPeriod.year => (start: DateTime(d.year), end: DateTime(d.year + 1)),
};

Span _span(Period p) => (start: p.start, end: p.end);

/// The window [by] periods after [s] (negative = earlier).
Span shiftSpan(
  StatsPeriod p,
  Span s,
  int by, {
  PeriodResolver periods = const CalendarMonthResolver(),
}) {
  if (p == StatsPeriod.month) {
    var q = periods.periodOf(s.start);
    for (var i = 0; i < by.abs(); i++) {
      q = by > 0 ? periods.next(q) : periods.prev(q);
    }
    return _span(q);
  }
  return spanOf(p, switch (p) {
    StatsPeriod.week => DateTime(
      s.start.year,
      s.start.month,
      s.start.day + 7 * by,
    ),
    _ => DateTime(s.start.year + by),
  });
}

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
    PeriodResolver periods = const CalendarMonthResolver(),
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
            // Week crossing periods: the period of its Monday.
            StatsPeriod.week =>
              (b * 7 / periods.periodOf(span.start).length).round(),
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

  /// "gara-gara": the biggest category in the [peak] bar; its emoji is the
  /// badge on that bar.
  StatsCategory? get peakTop {
    final i = peak;
    if (i == null) return null;
    final m = <String?, StatsCategory>{};
    for (final t in _expenses) {
      if (!_inside(t.at, bars[i])) continue;
      final c = m[t.category];
      m[t.category] = (
        category: t.category,
        emoji: t.emoji,
        spent: (c?.spent ?? 0) - t.amount,
      );
    }
    return m.values.reduce((a, b) => b.spent > a.spent ? b : a);
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
