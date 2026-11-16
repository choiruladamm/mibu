import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/models/finance.dart';
import 'package:mibu/domain/period.dart';
import 'package:mibu/domain/stats.dart';

void main() {
  var n = 0;
  Transaction tx(
    DateTime at,
    int amount, {
    String? category = 'makan',
    String emoji = '🍜',
    bool deleted = false,
  }) => Transaction(
    id: '${n++}',
    emoji: emoji,
    category: category,
    categoryId: category,
    place: '',
    at: at,
    amount: amount,
    deleted: deleted,
  );

  final today = DateTime(2026, 10, 16, 20); // jumat
  test('categories with the same name retain their identity', () {
    Transaction entry(String id, String? categoryId) => Transaction(
      id: id,
      emoji: '🍜',
      category: categoryId == null ? null : 'makan',
      categoryId: categoryId,
      place: '',
      at: DateTime(2026, 10, 14),
      amount: -100,
    );
    final s = Stats(
      [entry('1', 'a'), entry('2', 'b'), entry('3', null)],
      period: StatsPeriod.month,
      span: spanOf(StatsPeriod.month, today),
      today: today,
    );
    expect(s.categories.map((c) => c.id).toSet(), {'a', 'b', null});
  });

  test('future expenses become actual on their date', () {
    final future = tx(DateTime(2026, 10, 18, 23), -10000);
    Stats at(DateTime day, List<Transaction> entries) => Stats(
      entries,
      period: StatsPeriod.week,
      span: spanOf(StatsPeriod.week, DateTime(2026, 10, 14)),
      today: day,
    );
    final empty = at(DateTime(2026, 10, 14), [future]);
    expect((empty.total, empty.peak, empty.peakTop), (0, null, null));
    expect(empty.spent, [0, 0, 0, null, null, null, null]);
    final mixed = at(DateTime(2026, 10, 14), [
      future,
      tx(DateTime(2026, 10, 14, 23), -5000),
    ]);
    expect(
      (mixed.total, mixed.categories.single.spent, mixed.peak),
      (5000, 5000, 2),
    );
    final arrived = at(DateTime(2026, 10, 18), [future]);
    expect(
      (arrived.total, arrived.peak, arrived.peakTop!.spent),
      (10000, 6, 10000),
    );
    final futureSpan = Stats(
      [future],
      period: StatsPeriod.week,
      span: spanOf(StatsPeriod.week, DateTime(2026, 10, 18)),
      today: DateTime(2026, 10, 1),
    );
    expect((futureSpan.peak, futureSpan.peakTop), (null, null));
  });
  test('future-only and mixed expenses across all periods', () {
    final now = DateTime(2026, 10, 14);
    final future = tx(DateTime(2026, 10, 18), -10000);
    final actual = tx(DateTime(2026, 10, 14, 23), -5000);
    for (final period in StatsPeriod.values) {
      Stats stats(List<Transaction> entries, DateTime day) =>
          Stats(entries, period: period, span: spanOf(period, now), today: day);
      final empty = stats([future], now);
      expect(
        (empty.total, empty.peak, empty.low, empty.peakTop),
        (0, null, null, null),
      );
      expect(empty.categories, isEmpty);
      expect(empty.average, 0);
      final mixed = stats([actual, future], now);
      expect(mixed.total, 5000);
      expect(mixed.categories.single.spent, 5000);
      expect(mixed.peakTop!.spent, 5000);
      final arrived = stats([actual, future], DateTime(2026, 10, 18));
      expect(arrived.total, 15000);
      expect(arrived.categories.single.spent, 15000);
    }
  });
  String span(Span s) =>
      '${s.start.month}/${s.start.day}–${s.end.month}/${s.end.day}';

  test('spans: monday weeks, months, years; shifting', () {
    final week = spanOf(StatsPeriod.week, today);
    expect(span(week), '10/12–10/19');
    expect(span(shiftSpan(StatsPeriod.week, week, -2)), '9/28–10/5');
    expect(
      span(shiftSpan(StatsPeriod.month, spanOf(StatsPeriod.month, today), -1)),
      '9/1–10/1',
    );
    expect(span(spanOf(StatsPeriod.year, today)), '1/1–1/1');
  });

  test('bars: 7 days, month = 7-day runs from its first day, 12 periods', () {
    final month = spanOf(StatsPeriod.month, today);
    expect(barsOf(StatsPeriod.month, month).map(span), [
      '10/1–10/8', // from the period's first day, not Monday weeks
      '10/8–10/15',
      '10/15–10/22',
      '10/22–11/1', // 31 days: the 3-day tail folds into the last bar
    ]);
    expect(
      barsOf(
        StatsPeriod.month,
        spanOf(StatsPeriod.month, DateTime(2026, 9)),
      ).map(span),
      ['9/1–9/8', '9/8–9/15', '9/15–9/22', '9/22–10/1'], // 30 days
    );
    expect(
      barsOf(StatsPeriod.week, spanOf(StatsPeriod.week, today)),
      hasLength(7),
    );
    expect(
      barsOf(StatsPeriod.year, spanOf(StatsPeriod.year, today)),
      hasLength(12),
    );
  });

  test('week: bars, future = null, total, rata², boros, hemat, days', () {
    final s = Stats(
      [
        tx(DateTime(2026, 10, 12, 9), -12000),
        tx(DateTime(2026, 10, 13, 9), -9000),
        tx(
          DateTime(2026, 10, 13, 14),
          -200000,
          category: 'anabul',
          emoji: '🐶',
        ),
        tx(DateTime(2026, 10, 14, 9), -15000),
        tx(DateTime(2026, 10, 16, 9), -9000),
        tx(DateTime(2026, 10, 16, 10), 500000), // income: not "keluar"
        tx(DateTime(2026, 10, 15, 9), -70000, deleted: true),
        tx(DateTime(2026, 10, 11, 9), -99000), // last week
      ],
      period: StatsPeriod.week,
      span: spanOf(StatsPeriod.week, today),
      today: today,
    );
    expect(s.spent, [12000, 209000, 15000, 0, 9000, null, null]);
    expect((s.total, s.current, s.counted), (245000, 4, 4));
    expect(s.average, 59000); // finished days only, today still growing
    expect((s.peak, s.low), (1, 3));
    expect((s.peakTop!.category, s.peakTop!.emoji), ('anabul', '🐶'));
    expect((s.elapsed, s.left), (5, 2));
    expect(s.categories.map((c) => (c.category, c.spent)), [
      ('anabul', 200000),
      ('makan', 45000),
    ]);
    expect(s.pace, isNull); // no budget
  });

  test('hemat skips the running bar; nothing spent = no boros/hemat', () {
    final year = spanOf(StatsPeriod.year, today);
    final s = Stats(
      [
        tx(DateTime(2026, 9, 3), -300000),
        tx(DateTime(2026, 8, 3), -500000),
        tx(DateTime(2026, 10, 3), -100000), // oktober so far: lowest
      ],
      period: StatsPeriod.year,
      span: year,
      today: today,
    );
    expect(s.low, isNot(9));
    expect(s.peak, 7); // agustus
    expect(s.spent.where((v) => v == null), hasLength(2)); // nov, des

    final none = Stats(
      const [],
      period: StatsPeriod.year,
      span: year,
      today: today,
    );
    expect((none.peak, none.low, none.average), (null, null, 0));
  });

  test('pace: week limit from its monday month, near ≥ 85%, year under', () {
    Stats of(StatsPeriod p, int spent, {DateTime? at}) => Stats(
      [
        tx(DateTime(2026, 1, 2), 1), // data since january
        tx(at ?? DateTime(2026, 10, 12), -spent),
      ],
      period: p,
      span: spanOf(p, today),
      today: today,
      budget: 8000000,
      // tahun: Σ each period's own budget.
      yearBudgets: List.filled(12, 8000000),
    );

    final w = of(StatsPeriod.week, 1000000);
    expect(w.limit, (8000000 * 7 / 31).round()); // 1.806.452
    expect(w.pace, BudgetPace.fine);
    expect(of(StatsPeriod.week, 1900000).pace, BudgetPace.over);

    expect(of(StatsPeriod.month, 6950000).pace, BudgetPace.near); // 87%
    expect(of(StatsPeriod.month, 2340000).pace, BudgetPace.fine);
    expect(of(StatsPeriod.month, 8000001).pace, BudgetPace.over);

    // 16 okt ≈ 79% of the year gone.
    expect(of(StatsPeriod.year, 40290000).pace, BudgetPace.under); // 42%
    expect(of(StatsPeriod.year, 90000000).pace, BudgetPace.fine); // 94%
    expect(of(StatsPeriod.year, 96000001).pace, BudgetPace.over);
    expect(of(StatsPeriod.year, 1).timePct.round(), 79);
  });

  test('past period: all days gone, none left', () {
    final s = Stats(
      const [],
      period: StatsPeriod.month,
      span: spanOf(StatsPeriod.month, DateTime(2026, 9)),
      today: today,
    );
    expect((s.elapsed, s.left, s.current, s.timePct), (30, 0, -1, 100));
  });

  test('year = 12 payday periods; jatah setahun = Σ their own budgets', () {
    final p25 = SegmentedResolver([
      (
        effectiveFrom: DateTime(2020),
        mode: PeriodMode.payday,
        paydayDay: 25,
        shift: PaydayShift.none,
      ),
    ]);
    final y = spanOf(StatsPeriod.year, today, periods: p25);
    // "januari" starts 25 des, "desember" ends 24 des.
    expect((y.start, y.end), (DateTime(2025, 12, 25), DateTime(2026, 12, 25)));
    final bars = barsOf(StatsPeriod.year, y, periods: p25);
    expect(bars, hasLength(12));
    expect(bars[9].start, DateTime(2026, 9, 25)); // "oktober"
    expect(
      shiftSpan(StatsPeriod.year, y, -1, periods: p25).start,
      DateTime(2024, 12, 25),
    );

    // Periods without a budget add nothing; none at all = no limit.
    Stats of(List<int?> b) => Stats(
      const [],
      period: StatsPeriod.year,
      span: y,
      today: today,
      yearBudgets: b,
      periods: p25,
    );
    // Periods before the first budget borrow the nearest one: their
    // spending is in the total too.
    expect(
      of([...List.filled(6, null), ...List.filled(6, 8000000)]).limit,
      96000000,
    );
    expect(of(List.filled(12, null)).limit, isNull);
  });

  test('year: label year, no data before the first entry', () {
    final p25 = SegmentedResolver([
      (
        effectiveFrom: DateTime(2020),
        mode: PeriodMode.payday,
        paydayDay: 25,
        shift: PaydayShift.none,
      ),
    ]);
    final s = Stats(
      [
        tx(DateTime(2026, 8, 3), -500000), // "agustus" (25 jul – 24 agu)
        tx(DateTime(2026, 9, 3), -300000), // "september"
      ],
      period: StatsPeriod.year,
      span: spanOf(StatsPeriod.year, today, periods: p25),
      today: today,
      yearBudgets: List.filled(12, 8000000),
      periods: p25,
    );
    expect(s.span.start.year, 2025); // starts 25 des 2025 …
    expect(s.year, 2026); // … but is 2026
    expect(s.limit, 8000000 * 5); // ago … des; jan–jul had no data
    expect((s.peak, s.low), (7, 8)); // agustus boros, september hemat
    expect(s.average, 400000); // 2 finished months, not 9
  });
  test('year pace starts at the first budget-counted period', () {
    final s = Stats(
      [tx(DateTime(2026, 8, 3), -2000000)],
      period: StatsPeriod.year,
      span: spanOf(StatsPeriod.year, DateTime(2026, 8, 16)),
      today: DateTime(2026, 8, 16),
      yearBudgets: List.filled(12, 1000000),
    );
    expect(s.limit, 5000000);
    expect(s.timePct, closeTo(16 / 153 * 100, 0.001));
    expect(s.pace, BudgetPace.fine);
  });
}
