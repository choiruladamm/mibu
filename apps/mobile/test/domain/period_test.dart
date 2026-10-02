import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/period.dart';

void main() {
  /// Every day from 2026 through 2028 sits in exactly one period, periods
  /// tile with no gap, and next / prev round-trip.
  void tiles(PeriodResolver r) {
    var p = r.periodOf(DateTime(2026));
    while (p.start.isBefore(DateTime(2029))) {
      expect(p.start.isBefore(p.end), isTrue, reason: '$p');
      expect(r.periodOf(p.start), p);
      expect(r.periodOf(DateTime(p.end.year, p.end.month, p.end.day - 1)), p);
      final n = r.next(p);
      expect(n.start, p.end, reason: 'gap/overlap after $p');
      expect(r.prev(n), p);
      p = n;
    }
  }

  test('calendar: same windows as DateTime(y, m) → DateTime(y, m + 1)', () {
    const r = CalendarMonthResolver();
    for (var m = 1; m <= 12; m++) {
      final p = r.periodOf(DateTime(2026, m, 14, 23, 59));
      expect(p.start, DateTime(2026, m));
      expect(p.end, DateTime(2026, m + 1));
      expect(p.id, periodId(2026, m));
    }
    expect(r.periodOf(DateTime(2026, 12, 31)).end, DateTime(2027));
    tiles(r);
  });

  test('payday 1, 15, 25, 28, akhir: tiles 3 years incl. leap feb 2028', () {
    for (final day in [1, 15, 25, 28, 0]) {
      tiles(PaydayCycleResolver(day));
    }
    // akhir = last day: feb 2028 has 29.
    expect(
      const PaydayCycleResolver(0).periodOf(DateTime(2028, 3, 10)).start,
      DateTime(2028, 2, 29),
    );
  });

  test('payday 25: 16 okt is the sep cycle, 25 okt starts okt', () {
    const r = PaydayCycleResolver(25);
    final p = r.periodOf(DateTime(2026, 10, 16, 14, 50));
    expect(
      (p.id, p.start, p.end),
      ('2026-09', DateTime(2026, 9, 25), DateTime(2026, 10, 25)),
    );
    expect(r.periodOf(DateTime(2026, 10, 25)).id, '2026-10');
    expect(p.daysLeft(DateTime(2026, 10, 16, 23, 30)), 9); // today counts
  });

  test('previousWorkday: weekend payday moves back, even across months', () {
    // 25 okt 2026 is a Sunday → paid Fri 23 okt.
    const r = PaydayCycleResolver(25, shift: PaydayShift.previousWorkday);
    expect(r.anchor(2026, 10), DateTime(2026, 10, 23));
    expect(r.periodOf(DateTime(2026, 10, 23)).id, '2026-10');
    expect(r.periodOf(DateTime(2026, 10, 22)).id, '2026-09');
    tiles(r);

    // 1 nov 2026 is a Sunday → paid Fri 30 okt, cycle still "2026-11".
    const first = PaydayCycleResolver(1, shift: PaydayShift.previousWorkday);
    expect(first.periodOf(DateTime(2026, 10, 30)).id, '2026-11');
    expect(first.periodOf(DateTime(2026, 10, 29)).id, '2026-10');
    tiles(first);

    // Holidays stack on the weekend: Mon 26 okt off too → still Fri 23.
    final h = PaydayCycleResolver(
      26,
      shift: PaydayShift.previousWorkday,
      holidays: {DateTime(2026, 10, 26)},
    );
    expect(h.anchor(2026, 10), DateTime(2026, 10, 23));
  });

  test('segments: a switch applies from its date, old periods stay', () {
    final r = SegmentedResolver([
      (
        effectiveFrom: DateTime(2020),
        mode: PeriodMode.calendar,
        paydayDay: 25,
        shift: PaydayShift.none,
      ),
      // Switched in okt, applies from the end of the running month.
      (
        effectiveFrom: DateTime(2026, 11),
        mode: PeriodMode.payday,
        paydayDay: 25,
        shift: PaydayShift.none,
      ),
    ]);
    expect(r.periodOf(DateTime(2026, 10, 16)).start, DateTime(2026, 10));
    // Siklus pertama: clipped to the switch, then full cycles.
    final first = r.periodOf(DateTime(2026, 11, 5));
    expect(
      (first.start, first.end),
      (DateTime(2026, 11), DateTime(2026, 11, 25)),
    );
    expect(r.next(first).start, DateTime(2026, 11, 25));
    tiles(r);

    // Payday day changed later: the running cycle ends at the new anchor.
    final changed = SegmentedResolver([
      (
        effectiveFrom: DateTime(2020),
        mode: PeriodMode.payday,
        paydayDay: 25,
        shift: PaydayShift.none,
      ),
      (
        effectiveFrom: DateTime(2026, 11, 10),
        mode: PeriodMode.payday,
        paydayDay: 10,
        shift: PaydayShift.none,
      ),
    ]);
    final p = changed.periodOf(DateTime(2026, 11, 1));
    expect((p.start, p.end), (DateTime(2026, 10, 25), DateTime(2026, 11, 10)));
    tiles(changed);
  });
}
