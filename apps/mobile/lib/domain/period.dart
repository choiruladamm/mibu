/// Budget periods: every "bulan ini" number (budget, limits, aman jajan,
/// stats "bulan", month picker) goes through one [PeriodResolver]: from one
/// payday to the next (gajian 1 = calendar months). A period is named after
/// the month most of its days fall in ("oktober" = 25 sep – 24 okt): paydays
/// from the 16th take the month they end in, earlier ones the month they
/// start in. That keeps names one per month, in a row (a rule on the midpoint
/// skips a month when February is short).
/// See the doc "mibu · rencana siklus gajian".
library;

/// "2026-10": label / analytics only, never a database key.
String periodId(int y, int m) {
  final n = DateTime(y, m); // normalises month 0 / 13
  return '${n.year}-${n.month.toString().padLeft(2, '0')}';
}

/// [start, end), date-only.
class Period {
  const Period(this.id, this.start, this.end, {this.normalDays});

  final String id; // the month it's named after, see [periodId]
  final DateTime start; // inclusive
  final DateTime end; // exclusive

  /// Set on a transition period (around a payday change): the length of the
  /// first full cycle after it, which budget and limits are scaled against.
  /// Null = a normal period.
  final int? normalDays;

  /// First of the month it's named after: the "month" the UI picks by.
  DateTime get key =>
      DateTime(int.parse(id.substring(0, 4)), int.parse(id.substring(5)));

  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);

  /// Days until [end], [today] included (time of day ignored; never < 1
  /// inside the period).
  int daysLeft(DateTime today) => DateTime.utc(
    end.year,
    end.month,
    end.day,
  ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;

  int get length => DateTime.utc(
    end.year,
    end.month,
    end.day,
  ).difference(DateTime.utc(start.year, start.month, start.day)).inDays;

  @override
  bool operator ==(Object other) =>
      other is Period && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'Period($id, $start – $end)';
}

/// [amount] (budget, kantong limit: set per normal period) for [p]: a
/// transition period gets length ÷ [Period.normalDays] of it, so aman jajan
/// per day stays what a normal period gives. See docs/PAYDAY_CHANGE_PLAN.md.
int prorate(int amount, Period p) =>
    p.normalDays == null ? amount : (amount * p.length / p.normalDays!).round();

abstract class PeriodResolver {
  const PeriodResolver();

  Period periodOf(DateTime date);
  Period next(Period p) => periodOf(p.end);
  Period prev(Period p) =>
      periodOf(DateTime(p.start.year, p.start.month, p.start.day - 1));

  /// The period named after [month] (any day of it): the UI picks months,
  /// the data lives in periods.
  Period periodForMonth(DateTime month) {
    final c = periodOf(DateTime(month.year, month.month, 15));
    final key = DateTime(month.year, month.month);
    for (final p in [c, prev(c), next(c)]) {
      if (p.key == key) return p;
    }
    return c;
  }
}

class CalendarMonthResolver extends PeriodResolver {
  const CalendarMonthResolver();

  @override
  Period periodOf(DateTime d) => Period(
    periodId(d.year, d.month),
    DateTime(d.year, d.month),
    DateTime(d.year, d.month + 1),
  );
}

enum PaydayShift { none, previousWorkday }

/// Salary logged up to this many days before a payday counts as that payday
/// (cair duluan): the period starts on the day the money came in.
const paydayEarlyDays = 3;

/// [paydayDay] 1–31 (31 = akhir; a day past the month's end, and legacy 0,
/// = its last day). Each cycle runs from one payday to the next. [salaries]
/// = dates of logged gajian: one inside the [paydayEarlyDays] before a
/// scheduled payday moves that cycle's start to it (the earliest one).
class PaydayCycleResolver extends PeriodResolver {
  const PaydayCycleResolver(
    this.paydayDay, {
    this.shift = PaydayShift.none,
    this.holidays = const {},
    this.salaries = const [],
  });

  final int paydayDay;
  final PaydayShift shift;
  final Set<DateTime> holidays; // date-only
  final List<DateTime> salaries;

  /// The scheduled payday for nominal month (y, m).
  DateTime anchor(int y, int m) {
    final last = DateTime(y, m + 1, 0).day;
    final day = paydayDay == 0 || paydayDay > last ? last : paydayDay;
    var a = DateTime(y, m, day);
    if (shift == PaydayShift.previousWorkday) {
      while (a.weekday >= DateTime.saturday || holidays.contains(a)) {
        a = DateTime(a.year, a.month, a.day - 1);
      }
    }
    return a;
  }

  /// Where cycle (y, m) really starts: the scheduled payday, or an earlier
  /// logged salary.
  DateTime start(int y, int m) {
    final a = anchor(y, m);
    final from = DateTime(a.year, a.month, a.day - paydayEarlyDays);
    DateTime? early;
    for (final d in salaries) {
      final day = DateTime(d.year, d.month, d.day);
      if (!day.isBefore(from) && !day.isAfter(a)) {
        if (early == null || day.isBefore(early)) early = day;
      }
    }
    return early ?? a;
  }

  /// The nominal month of the cycle holding [d].
  ({int y, int m}) cycleOf(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    // Next month's start first: an early salary can pull it into this month.
    for (final off in const [1, 0, -1]) {
      final m = DateTime(day.year, day.month + off);
      if (!day.isBefore(start(m.year, m.month))) return (y: m.year, m: m.month);
    }
    throw StateError('unreachable');
  }

  @override
  Period periodOf(DateTime date) {
    final c = cycleOf(date);
    final from = start(c.y, c.m);
    final to = start(c.y, c.m + 1);
    final late = (paydayDay == 0 ? 31 : paydayDay) >= 16;
    return Period(periodId(c.y, c.m + (late ? 1 : 0)), from, to);
  }
}

enum PeriodMode { calendar, payday }

/// One row of `periodRules`: from [effectiveFrom] on, periods follow [mode].
typedef PeriodRule = ({
  DateTime effectiveFrom,
  PeriodMode mode,
  int paydayDay,
  PaydayShift shift,
});

/// A rule that covers all history: setup writes its payday rule from here,
/// so entries back-filled before the install day fall in the same periods
/// (a rule starting on install day left a calendar-month sliver before it,
/// with the same name as the period after it).
final DateTime periodsFromStart = DateTime(1971);

/// Before any saved rule: calendar months.
final PeriodRule calendarBase = (
  effectiveFrom: DateTime(1970),
  mode: PeriodMode.calendar,
  paydayDay: 0,
  shift: PaydayShift.none,
);

/// Picks the rule in force on a date (latest [PeriodRule.effectiveFrom] ≤
/// it), so past periods keep the rules of their time. A period that straddles
/// a rule change is clipped to it, or merged with its neighbour when they'd
/// share a name (see [periodOf]). Dates before the first
/// rule use it anyway.
class SegmentedResolver extends PeriodResolver {
  SegmentedResolver(List<PeriodRule> rules, {this.salaries = const []})
    : assert(rules.isNotEmpty),
      _rules = [...rules]
        ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));

  final List<PeriodRule> _rules;
  final List<DateTime> salaries; // logged gajian, for payday rules

  PeriodResolver _of(PeriodRule r) => switch (r.mode) {
    PeriodMode.calendar => const CalendarMonthResolver(),
    PeriodMode.payday => PaydayCycleResolver(
      r.paydayDay,
      shift: r.shift,
      salaries: salaries,
    ),
  };

  /// The rule in force on [d] (date-only).
  int _ruleAt(DateTime d) {
    var i = 0;
    for (var j = 0; j < _rules.length; j++) {
      if (!_rules[j].effectiveFrom.isAfter(d)) i = j;
    }
    return i;
  }

  bool _isSwitch(DateTime d) => _rules.skip(1).any((r) => r.effectiveFrom == d);

  /// The rule's own period for [d], clipped to the rule's span.
  Period _clipped(DateTime d) {
    final i = _ruleAt(d);
    final p = _of(_rules[i]).periodOf(d);
    final from = _rules[i].effectiveFrom;
    final until = i + 1 < _rules.length ? _rules[i + 1].effectiveFrom : null;
    final start = i > 0 && p.start.isBefore(from) ? from : p.start;
    final end = until != null && until.isBefore(p.end) ? until : p.end;
    return Period(p.id, start, end);
  }

  /// A payday change leaves a sliver between the running period and the new
  /// rule's first full cycle. Named like its neighbour, it's merged into it
  /// (one name, one period); either way the period around a switch is a
  /// transition, scaled by [Period.normalDays].
  // ponytail: only the periods touching a switch are checked; a salary
  // logged early that moves the old rule's last end off the switch isn't
  // merged (rare: payday changed and paid early in the same cycle).
  @override
  Period periodOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final p = _clipped(d);
    // Clipping only happens at a switch: no switch at either edge, normal.
    if (!_isSwitch(p.start) && !_isSwitch(p.end)) return p;
    var start = p.start, end = p.end;
    if (_isSwitch(start)) {
      final q = _clipped(DateTime(start.year, start.month, start.day - 1));
      if (q.id == p.id) start = q.start;
    }
    if (_isSwitch(end)) {
      final q = _clipped(end);
      if (q.id == p.id) end = q.end;
    }
    // Transition = the rule's own cycle ending here isn't this period.
    final last = DateTime(end.year, end.month, end.day - 1);
    final own = _of(_rules[_ruleAt(last)]).periodOf(last);
    if (own.start == start && own.end == end) return Period(p.id, start, end);
    final next = _of(_rules[_ruleAt(end)]).periodOf(end);
    return Period(p.id, start, end, normalDays: next.length);
  }
}
