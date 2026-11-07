import 'models/finance.dart';
import 'period.dart';

/// 04.1 statistik toggle.
enum StatsPeriod { week, month, year }

/// Half-open window [start, end), local midnights.
typedef Span = ({DateTime start, DateTime end});

/// The [p] window holding [d]: Monday week, budget period ([periods]), and
/// a year of 12 budget periods (januari … desember by name).
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
  StatsPeriod.year => _yearSpan(periods.periodOf(d).key.year, periods),
};

Span _span(Period p) => (start: p.start, end: p.end);

/// The periods named januari … desember [y]: gajian 25 → 25 des – 24 des.
Span _yearSpan(int y, PeriodResolver periods) => (
  start: periods.periodForMonth(DateTime(y)).start,
  end: periods.periodForMonth(DateTime(y, 12)).end,
);

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
  if (p == StatsPeriod.year) {
    return _yearSpan(periods.periodOf(s.start).key.year + by, periods);
  }
  return spanOf(p, DateTime(s.start.year, s.start.month, s.start.day + 7 * by));
}

/// One bar per day (week), per 7 days from the period's first day (month:
/// 25 sep, 2 okt … — the last one runs 7–9 days), per budget period
/// (year: januari … desember).
List<Span> barsOf(
  StatsPeriod p,
  Span s, {
  PeriodResolver periods = const CalendarMonthResolver(),
}) {
  if (p == StatsPeriod.year) {
    final y = periods.periodOf(s.start).key.year;
    return [
      for (var m = 1; m <= 12; m++)
        _span(periods.periodForMonth(DateTime(y, m))),
    ];
  }
  final bars = <Span>[];
  var a = s.start;
  while (a.isBefore(s.end)) {
    var b = switch (p) {
      StatsPeriod.week => DateTime(a.year, a.month, a.day + 1),
      _ => DateTime(a.year, a.month, a.day + 7),
    };
    if (b.isAfter(s.end)) b = s.end;
    bars.add((start: a, end: b));
    a = b;
  }
  // A 29–31 day period leaves a 1–3 day tail: fold it into the last full
  // bar, a sliver would skew rata², paling boros and paling hemat.
  if (p == StatsPeriod.month && bars.length > 1) {
    final tail = bars.last;
    if (_days(tail.start, tail.end) < 4) {
      bars
        ..removeLast()
        ..add((start: bars.removeLast().start, end: tail.end));
    }
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

/// ritme budget (on track nggak?), see mvp.md › Statistik.
enum BudgetPace { over, near, under, fine }

/// One expense category in "larinya ke mana"; [category] null = tanpa
/// kategori.
typedef StatsCategory = ({String? category, String emoji, int spent});

/// What 04.1 shows for [span] of [period] (today = [today]).
class Stats {
  Stats(
    List<Transaction> entries, {
    required this.period,
    required this.span,
    required DateTime today,
    int? budget,
    List<int?> yearBudgets = const [],
    PeriodResolver periods = const CalendarMonthResolver(),
  }) : bars = barsOf(period, span, periods: periods),
       monthKey = periods.periodOf(span.start).key {
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
    // Bars ended before the first entry ever: no data, not "spent nothing".
    final first = entries
        .where((t) => !t.deleted)
        .map((t) => t.at)
        .fold<DateTime?>(null, (m, a) => m == null || a.isBefore(m) ? a : m);
    _live = [for (final b in bars) first == null || b.end.isAfter(first)];
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
    limit = period == StatsPeriod.year
        // Σ each period's own budget (ahead of now: today's, carried on).
        ? _yearLimit(yearBudgets)
        : b == null || b <= 0
        ? null
        : switch (period) {
            // Week crossing periods: the period of its Monday.
            StatsPeriod.week =>
              (b * 7 / periods.periodOf(span.start).length).round(),
            _ => b,
          };
  }

  final StatsPeriod period;
  final Span span;

  /// The year the year window is named after (januari starts in des).
  int get year => monthKey.year;

  late final List<bool> _live; // per bar: not before the first entry

  /// Σ own budget of the bars with data; a bar with none uses the nearest
  /// set one (earlier first), so a budget set mid-year doesn't leave the
  /// months before it out of "jatah setahun" while their spending counts.
  int? _yearLimit(List<int?> budgets) {
    int? carry = budgets.firstWhere(
      (y) => y != null && y > 0,
      orElse: () => null,
    );
    if (carry == null) return null;
    var sum = 0;
    for (var i = 0; i < bars.length; i++) {
      final y = i < budgets.length ? budgets[i] : null;
      if (y != null && y > 0) carry = y;
      if (_live[i]) sum += carry!;
    }
    return sum;
  }

  /// The month label of the period [span] starts in (what the "bulan" tab
  /// calls it: 25 sep – 24 okt is "oktober").
  final DateTime monthKey;
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

  /// Bars that count for rata²: finished and with data; the running one
  /// only when nothing else is (it can still grow).
  List<int> get _shown {
    final done = [
      for (var i = 0; i < spent.length; i++)
        if (spent[i] != null && _live[i] && i != current) spent[i]!,
    ];
    if (done.isEmpty && current >= 0 && _live[current]) {
      return [spent[current]!];
    }
    return done;
  }

  /// rata²: over the finished bars (see [_shown]).
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
      if (spent[i] == null || !_live[i] || i == current) continue;
      if (best == null || spent[i]! < spent[best]!) best = i;
    }
    return best ?? (current >= 0 && _live[current] ? current : null);
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
