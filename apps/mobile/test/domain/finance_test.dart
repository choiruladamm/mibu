import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/models/finance.dart';

void main() {
  // 25 nov 2026 is a Wednesday; 25 okt 2026 a Sunday; 28 feb 2026 a Saturday.
  group('paydayInfo', () {
    PaydayInfo at(
      DateTime now, {
      int payday = 25,
      List<DateTime> paid = const [],
    }) => paydayInfo(now: now, payday: payday, salaries: paid);

    test('counts today up to payday (exclusive)', () {
      final p = at(DateTime(2026, 11, 16, 14, 50));
      expect(
        (p.status, p.next, p.daysLeft),
        (
          PaydayStatus.upcoming,
          DateTime(2026, 11, 25),
          9, // 16…24
        ),
      );
    });

    test('weekend payday is paid the Friday before', () {
      final p = at(DateTime(2026, 10, 16));
      expect((p.next, p.daysLeft), (DateTime(2026, 10, 23), 7));
      // akhir (31) in feb 2026 → 28 feb, a Saturday → Fri 27.
      expect(at(DateTime(2026, 2, 10), payday: 31).next, DateTime(2026, 2, 27));
      expect(at(DateTime(2026, 4, 10), payday: 31).next, DateTime(2026, 4, 30));
    });

    test('payday with no salary yet → today; logged → lasts to the next', () {
      final hariH = at(DateTime(2026, 11, 25));
      expect(
        (hariH.status, hariH.daysLeft, hariH.daysToNext),
        (PaydayStatus.today, 0, 30),
      );
      final p = at(
        DateTime(2026, 11, 25, 20),
        paid: [DateTime(2026, 11, 25, 9)],
      );
      expect(
        (p.status, p.next, p.daysLeft),
        (PaydayStatus.upcoming, DateTime(2026, 12, 25), 30),
      );
    });

    test('cair duluan: up to 3 days early counts as this payday', () {
      final p = at(DateTime(2026, 11, 23), paid: [DateTime(2026, 11, 23)]);
      expect((p.next, p.daysLeft), (DateTime(2026, 12, 25), 32));
      // 5 days early is just income: still counting to 25 nov.
      expect(
        at(DateTime(2026, 11, 21), paid: [DateTime(2026, 11, 20)]).next,
        DateTime(2026, 11, 25),
      );
    });

    test('telat only for people who log salary, at most 7 days', () {
      final before = [DateTime(2026, 10, 23)];
      final late = at(DateTime(2026, 11, 27), paid: before);
      expect((late.status, late.lateDays), (PaydayStatus.late, 2));
      final over = at(DateTime(2026, 12, 3), paid: before); // 8 days
      expect(
        (over.status, over.next),
        (PaydayStatus.upcoming, DateTime(2026, 12, 25)),
      );
      // Never logged salary: no nagging.
      expect(at(DateTime(2026, 11, 27)).status, PaydayStatus.upcoming);
    });
  });

  test('safeShare: sisa budget over the days left, none without budget', () {
    // budget 984K left over 29 days, 34K spent today.
    final b = safeShare(budgetLeft: 984000, spentToday: 34000, days: 29);
    expect(b, 35103);
    // Same figure as safeToSpendToday: what the chip shows.
    expect(
      safeToSpendToday(budgetLeft: 984000, spentToday: 34000, days: 29),
      1103,
    );
    // No budget: no aman jajan at all, never guessed from income.
    expect(safeShare(budgetLeft: null, spentToday: 34000, days: 29), null);
    expect(safeToSpendToday(budgetLeft: null, spentToday: 0, days: 29), null);
    // Last day of the period: no division by zero.
    expect(safeShare(budgetLeft: 50000, spentToday: 0, days: 0), 50000);
  });

  test('suggestedLimit: 1,4× up to Rp100K, min Rp300K', () {
    expect(suggestedLimit(0), 300000);
    expect(suggestedLimit(200000), 300000); // 280K → floor
    expect(suggestedLimit(420000), 600000); // 588K → 600K
    expect(suggestedLimit(500000), 700000); // exact
    expect(suggestedLimit(2399000), 3400000); // 3.358.600 → 3,4jt
  });

  test('safeToSpendToday: spending today eats today\'s share', () {
    int? s(int left, int spent) =>
        safeToSpendToday(budgetLeft: left, spentToday: spent, days: 9);
    expect(s(4530000, 0), 503333);
    expect(s(4530000 - 100000, 100000), 403333);
    expect(s(300000, 600000), -500000); // kebablasan
    expect(s(-5000, 0), -555); // budget gone
  });

  final nets = {
    DateTime(2026, 7): 546000,
    DateTime(2026, 8): -844500,
    DateTime(2026, 9): 5887500,
    DateTime(2026, 10): -4059000,
  };
  final now = DateTime(2026, 10, 14);

  test('balanceSeries: each period on its own, peeks at the 3-period avg', () {
    final series = balanceSeries(
      now: now,
      start: DateTime(2026, 7),
      nets: nets,
    );
    expect(series.map((m) => m.month.month), [7, 8, 9, 10, 11, 12]);
    // Nothing carries over: each point is that period's income − spending.
    expect(series.map((m) => m.amount), [
      546000,
      -844500,
      5887500,
      -4059000,
      1863000,
      1863000,
    ]);
  });

  test('balanceSeries: periods without entries are 0', () {
    final series = balanceSeries(
      now: now,
      start: DateTime(2026, 5),
      nets: nets,
    );
    expect(series.map((m) => m.month.month), [5, 6, 7, 8, 9, 10]);
    expect((series[0].amount, series[1].amount), (0, 0));
  });

  test('chartStart stays while picked is inside, else lands 4th', () {
    DateTime start(DateTime from, DateTime picked) =>
        chartStart(now: now, start: from, picked: picked);
    final def = DateTime(2026, 7);
    expect(start(def, DateTime(2026, 12)), def); // inside (a prediction)
    expect(start(def, DateTime(2026, 8)), def);
    expect(start(def, DateTime(2026, 3)), DateTime(2025, 12)); // 4th: mar
    expect(start(DateTime(2025, 12), DateTime(2026, 10)), DateTime(2026, 7));
    expect(start(DateTime(2025, 12), DateTime(2026, 12)), DateTime(2026, 7));
  });

  test('pocket status: unused, safe, almost out at 85%, over past 100%', () {
    Pocket p(int spent) =>
        Pocket(id: '', emoji: '', name: '', budget: 1000000, spent: spent);
    expect(p(0).status, PocketStatus.unused);
    expect(p(844000).status, PocketStatus.safe); // 84%; 84,9% rounds to 85
    expect(p(850000).status, PocketStatus.almostOut);
    expect(p(1000000).status, PocketStatus.almostOut); // exactly 100%
    expect(p(1010000).status, PocketStatus.over);
    expect(p(1200000).left, -200000);
  });

  test('pocketLimitScale follows the PocketLimit rules', () {
    // design example: 6,9jt − 5,6jt = 1,3jt free → end 3jt
    expect(pocketLimitScale(budget: 6900000, others: 5600000), (
      max: 3000000,
      step: 100000,
      free: 1300000,
    ));
    // min 1jt end, capped at the budget itself
    expect(pocketLimitScale(budget: 800000, others: 700000), (
      max: 800000,
      step: 50000,
      free: 100000,
    ));
    // over budget already → free 0, end 1jt
    expect(pocketLimitScale(budget: 3000000, others: 4000000), (
      max: 1000000,
      step: 50000,
      free: 0,
    ));
    expect(pocketLimitScale(budget: 30000000, others: 0).step, 250000);
    expect(pocketLimitScale(budget: null, others: 5600000), (
      max: 2000000,
      step: 50000,
      free: null,
    ));
  });

  test('budgetPrefill rounds Σ limits up to Rp500K', () {
    expect(budgetPrefill(7400000), 7500000);
    expect(budgetPrefill(7500000), 7500000);
    expect(budgetPrefill(1), 500000);
    expect(budgetPrefill(0), 0);
  });
}
