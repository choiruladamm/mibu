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
    // daysLeft counts today ("16 hari lagi" on 16 okt).
    expect(
      r.periodOf(DateTime(2026, 10, 16)).daysLeft(DateTime(2026, 10, 16)),
      16,
    );
    expect(
      r.periodOf(DateTime(2026, 10, 31)).daysLeft(DateTime(2026, 10, 31)),
      1,
    );
    expect(r.periodOf(DateTime(2026, 2)).daysLeft(DateTime(2026, 2)), 28);
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

  test('payday 25: 16 okt is in "oktober" (25 sep – 24 okt)', () {
    const r = PaydayCycleResolver(25);
    final p = r.periodOf(DateTime(2026, 10, 16, 14, 50));
    expect(
      (p.id, p.start, p.end),
      (
        '2026-10',
        DateTime(2026, 9, 25),
        DateTime(2026, 10, 25),
      ), // named by most days
    );
    expect(r.periodOf(DateTime(2026, 10, 25)).id, '2026-11');
    expect(p.daysLeft(DateTime(2026, 10, 16, 23, 30)), 9); // today counts
  });

  test('previousWorkday: weekend payday moves back, even across months', () {
    // 25 okt 2026 is a Sunday → paid Fri 23 okt.
    const r = PaydayCycleResolver(25, shift: PaydayShift.previousWorkday);
    expect(r.anchor(2026, 10), DateTime(2026, 10, 23));
    expect(r.periodOf(DateTime(2026, 10, 23)).id, '2026-11');
    expect(r.periodOf(DateTime(2026, 10, 22)).id, '2026-10');
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

    // Payday day changed later: the sliver to the new anchor would also be
    // "november", so it joins the running cycle (docs/PAYDAY_CHANGE_PLAN.md).
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
    expect((p.start, p.end), (DateTime(2026, 10, 25), DateTime(2026, 12, 10)));
    tiles(changed);
  });

  test('payday change: slivers merge or stand alone, transitions prorate', () {
    PeriodRule pay(DateTime from, int day) => (
      effectiveFrom: from,
      mode: PeriodMode.payday,
      paydayDay: day,
      shift: PaydayShift.none,
    );
    DateTime d(int m, int day) => DateTime(2026, m, day);
    // Saved mid-oktober: the new day applies from the running period's end.
    // (from → to, transition period: id, start, end, normalDays)
    final cases = [
      (25, 1, '2026-10', d(9, 25), d(11, 1), 30), // merged, 37 days
      (25, 10, '2026-10', d(9, 25), d(11, 10), 30), // merged, 46
      (28, 15, '2026-10', d(9, 28), d(11, 15), 30), // merged, 48
      (16, 15, '2026-11', d(10, 16), d(12, 15), 31), // merged, 60
      (31, 1, '2026-10', d(9, 30), d(11, 1), 30), // merged, 32
      (25, 20, '2026-11', d(10, 25), d(11, 20), 30), // sliver, 26
      (15, 16, '2026-11', d(11, 15), d(11, 16), 30), // sliver, 1
      (10, 25, '2026-11', d(11, 10), d(11, 25), 30), // sliver, 15
      (1, 25, '2026-11', d(11, 1), d(11, 25), 30), // sliver, 24
    ];
    for (final (a, b, id, start, end, normal) in cases) {
      final why = '$a → $b';
      final running = SegmentedResolver([
        calendarBase,
        pay(periodsFromStart, a),
      ]).periodOf(d(10, 20));
      final r = SegmentedResolver([
        calendarBase,
        pay(periodsFromStart, a),
        pay(running.end, b),
      ]);
      final t = r.periodOf(DateTime(end.year, end.month, end.day - 1));
      expect((t.id, t.start, t.end), (id, start, end), reason: why);
      expect(t.normalDays, normal, reason: why);
      expect(r.periodOf(start), t, reason: why);
      // Around it: normal periods, one per month name, no month skipped.
      expect(r.prev(t).normalDays, isNull, reason: why);
      expect(r.next(t).normalDays, isNull, reason: why);
      expect(r.next(t).length, normal, reason: why);
      var p = r.periodOf(d(6, 1));
      for (var i = 0; i < 10; i++) {
        final n = r.next(p);
        expect(n.key, DateTime(p.key.year, p.key.month + 1), reason: why);
        expect(r.periodForMonth(n.key), n, reason: why);
        p = n;
      }
      tiles(r);
    }
  });

  test('weekend tetap from the next period: running one ends on Sunday', () {
    PeriodRule pay(DateTime from, PaydayShift shift) => (
      effectiveFrom: from,
      mode: PeriodMode.payday,
      paydayDay: 25,
      shift: shift,
    );
    // 25 okt 2026 is a Sunday: jumat ends the period on 23 okt; switching to
    // tetap from there gives a "oktober" sliver that joins it, and the result
    // is just the tetap cycle: a normal period, nothing prorated.
    final r = SegmentedResolver([
      calendarBase,
      pay(periodsFromStart, PaydayShift.previousWorkday),
      pay(DateTime(2026, 10, 23), PaydayShift.none),
    ]);
    final p = r.periodOf(DateTime(2026, 10, 14));
    expect(
      (p.id, p.start, p.end),
      ('2026-10', DateTime(2026, 9, 25), DateTime(2026, 10, 25)),
    );
    expect(p.normalDays, isNull);
    expect(r.next(p).start, DateTime(2026, 10, 25));
    tiles(r);
  });

  test('prorate: transitions scale by length ÷ normal, others untouched', () {
    final normal = Period(
      '2026-10',
      DateTime(2026, 9, 25),
      DateTime(2026, 10, 25),
    );
    expect(prorate(3000000, normal), 3000000);
    final short = Period(
      '2026-11',
      DateTime(2026, 11, 15),
      DateTime(2026, 11, 16),
      normalDays: 30,
    );
    expect(prorate(3000000, short), 100000);
    final long = Period(
      '2026-10',
      DateTime(2026, 9, 25),
      DateTime(2026, 11, 1),
      normalDays: 30,
    );
    expect(prorate(3000000, long), 3700000);
    expect(prorate(1000, long), 1233); // whole rupiah
  });

  test('named after the month most of its days fall in', () {
    String name(int day, DateTime d) => PaydayCycleResolver(day).periodOf(d).id;
    expect(name(25, DateTime(2026, 10, 3)), '2026-10'); // 25 sep – 24 okt
    expect(name(5, DateTime(2026, 10, 20)), '2026-10'); // 5 okt – 4 nov
    expect(name(15, DateTime(2026, 10, 20)), '2026-10'); // 15 okt – 14 nov
    expect(name(15, DateTime(2026, 10, 3)), '2026-09'); // 15 sep – 14 okt
    expect(name(1, DateTime(2026, 10, 20)), '2026-10'); // = calendar month
  });

  test('periodForMonth: the period a month label points at', () {
    for (final day in [1, 5, 15, 16, 25, 28, 0]) {
      final r = PaydayCycleResolver(day);
      var seen = <String>{};
      for (var m = 1; m <= 12; m++) {
        final p = r.periodForMonth(DateTime(2026, m, 1));
        expect(p.key, DateTime(2026, m), reason: 'day $day month $m');
        expect(seen.add(p.id), isTrue, reason: 'two months, one period');
      }
    }
    final r = PaydayCycleResolver(25);
    final oct = r.periodForMonth(DateTime(2026, 10));
    expect(
      (oct.start, oct.end),
      (DateTime(2026, 9, 25), DateTime(2026, 10, 25)),
    );
  });

  test('cair duluan: a salary ≤ 3 days early starts the cycle that day', () {
    // 25 nov 2026 is a Wednesday.
    final plain = PaydayCycleResolver(25).periodOf(DateTime(2026, 11, 24));
    expect(plain.end, DateTime(2026, 11, 25));

    final r = PaydayCycleResolver(25, salaries: [DateTime(2026, 11, 23, 9)]);
    expect(r.periodOf(DateTime(2026, 11, 22)).end, DateTime(2026, 11, 23));
    expect(r.periodOf(DateTime(2026, 11, 24)).start, DateTime(2026, 11, 23));
    // 5 days early is just income.
    final far = PaydayCycleResolver(25, salaries: [DateTime(2026, 11, 20)]);
    expect(far.periodOf(DateTime(2026, 11, 24)).end, DateTime(2026, 11, 25));
    // The earliest one in the window wins.
    final two = PaydayCycleResolver(
      25,
      salaries: [DateTime(2026, 11, 24), DateTime(2026, 11, 22)],
    );
    expect(two.periodOf(DateTime(2026, 11, 22)).start, DateTime(2026, 11, 22));
    tiles(r);
    tiles(two);
  });
}
