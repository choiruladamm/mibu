/// Budget periods: every "bulan ini" number (budget, limits, aman jajan,
/// stats "bulan", month picker) goes through one [PeriodResolver], so payday
/// cycles can land later without touching queries. v1 = calendar months.
/// See the doc "mibu · rencana siklus gajian" (fase 0).
library;

/// "2026-10": label / analytics only, never a database key.
String periodId(int y, int m) {
  final n = DateTime(y, m); // normalises month 0 / 13
  return '${n.year}-${n.month.toString().padLeft(2, '0')}';
}

/// [start, end), date-only.
class Period {
  const Period(this.id, this.start, this.end);

  final String id; // nominal month, see [periodId]
  final DateTime start; // inclusive
  final DateTime end; // exclusive

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

/// [paydayDay] 1–28, 0 = last day of the month (01.4 chips). Each cycle runs
/// from one payday to the next and is named after its payday's month.
class PaydayCycleResolver extends PeriodResolver {
  const PaydayCycleResolver(
    this.paydayDay, {
    this.shift = PaydayShift.none,
    this.holidays = const {},
  });

  final int paydayDay;
  final PaydayShift shift;
  final Set<DateTime> holidays; // date-only

  /// The real payday for nominal month (y, m).
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

  @override
  Period periodOf(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    // Next month's anchor first: a shift can pull it into this month.
    for (final off in const [1, 0, -1]) {
      final m = d.month + off;
      final a = anchor(d.year, m);
      if (!d.isBefore(a)) {
        return Period(periodId(d.year, m), a, anchor(d.year, m + 1));
      }
    }
    throw StateError('unreachable');
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

/// Picks the rule in force on a date (latest [PeriodRule.effectiveFrom] ≤
/// it), so past periods keep the rules of their time. A period that straddles
/// a rule change is clipped to it ("siklus pertama"). Dates before the first
/// rule use it anyway.
class SegmentedResolver extends PeriodResolver {
  SegmentedResolver(List<PeriodRule> rules)
    : assert(rules.isNotEmpty),
      _rules = [...rules]
        ..sort((a, b) => a.effectiveFrom.compareTo(b.effectiveFrom));

  final List<PeriodRule> _rules;

  static PeriodResolver _of(PeriodRule r) => switch (r.mode) {
    PeriodMode.calendar => const CalendarMonthResolver(),
    PeriodMode.payday => PaydayCycleResolver(r.paydayDay, shift: r.shift),
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
