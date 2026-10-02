import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/models/finance.dart';
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
    place: '',
    at: at,
    amount: amount,
    deleted: deleted,
  );

  final today = DateTime(2026, 10, 16, 20); // jumat
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

  test('bars: 7 days, month weeks clipped to the month, 12 months', () {
    final month = spanOf(StatsPeriod.month, today);
    expect(barsOf(StatsPeriod.month, month).map(span), [
      '10/1–10/5', // 1–4 (thu–sun)
      '10/5–10/12',
      '10/12–10/19',
      '10/19–10/26',
      '10/26–11/1',
    ]);
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
    expect((s.total, s.current, s.counted), (245000, 4, 5));
    expect(s.average, 49000);
    expect((s.peak, s.low, s.peakEmoji), (1, 3, '🐶'));
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
      [tx(at ?? DateTime(2026, 10, 12), -spent)],
      period: p,
      span: spanOf(p, today),
      today: today,
      budget: 8000000,
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
}
