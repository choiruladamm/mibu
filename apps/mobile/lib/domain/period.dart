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
  const Period(this.id, this.start, this.end);

  final String id; // the month it's named after, see [periodId]
  final DateTime start; // inclusive
  final DateTime end; // exclusive

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
/// a rule change is clipped to it ("siklus pertama"). Dates before the first
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

  @override
  Period periodOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    var i = 0;
    for (var j = 0; j < _rules.length; j++) {
      if (!_rules[j].effectiveFrom.isAfter(d)) i = j;
    }
    final p = _of(_rules[i]).periodOf(d);
    final from = _rules[i].effectiveFrom;
    final until = i + 1 < _rules.length ? _rules[i + 1].effectiveFrom : null;
    final start = i > 0 && p.start.isBefore(from) ? from : p.start;
    final end = until != null && until.isBefore(p.end) ? until : p.end;
    return Period(p.id, start, end);
  }
}
