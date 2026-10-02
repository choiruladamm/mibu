import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/models/finance.dart';
import 'package:mibu/domain/search.dart';

void main() {
  Transaction tx(
    String id, {
    int amount = -28000,
    String? category = 'ngopi',
    String place = '',
    String note = '',
    List<String> tags = const [],
    int day = 1,
    bool deleted = false,
  }) => Transaction(
    id: id,
    emoji: '☕',
    category: category,
    place: place,
    at: DateTime(2026, 10, day, 8),
    amount: amount,
    note: note,
    tags: tags,
    deleted: deleted,
  );

  final all = [
    tx('a', place: 'Kopi Kenangan', day: 1),
    tx('b', category: 'makan', place: 'warteg', note: 'es kopi susu', day: 5),
    tx('c', category: 'gajian', amount: 8500000, place: 'kantor', day: 2),
    tx('d', category: 'ojol', place: 'gojek', tags: ['kopi'], day: 9),
    tx('e', place: 'fore', deleted: true, day: 3),
  ];

  test('matches category, place, note and tags; case-insensitive', () {
    expect(searchEntries(all, 'KOPI').map((t) => t.id), ['d', 'b', 'a']);
    expect(searchEntries(all, 'ngopi').map((t) => t.id), ['a']);
  });

  test('kind filter, blank term, soft-deleted are left out', () {
    expect(
      searchEntries(all, 'k', kind: CategoryKind.income).map((t) => t.id),
      ['c'],
    );
    expect(searchEntries(all, '   '), isEmpty);
    expect(searchEntries(all, 'fore'), isEmpty);
    expect(searchEntries(all, 'xyz'), isEmpty);
  });

  test('summary: count, distinct days, total, average, mixed', () {
    final s = SearchSummary([
      tx('a', amount: -30000, day: 1),
      tx('b', amount: -20000, day: 1),
      tx('c', amount: -10000, day: 4),
    ], today: 16);
    expect(
      (s.count, s.days, s.total, s.average, s.mixed),
      (3, 2, -60000, -20000, false),
    );
    expect(
      SearchSummary([tx('a'), tx('b', amount: 100)], today: 16).mixed,
      isTrue,
    );
  });

  test('insight: mixed, single, busiest day, biggest day, daily + streak', () {
    SearchSummary of(List<Transaction> h, [int today = 16]) =>
        SearchSummary(h, today: today);

    expect(of([tx('a'), tx('b', amount: 500)]).insight, SearchInsight.mixed);
    expect(of([tx('a')]).insight, SearchInsight.single);

    final busy = of([tx('a', day: 2), tx('b', day: 9), tx('c', day: 9)]);
    expect((busy.insight, busy.busiestDay), (SearchInsight.busiest, 9));

    final big = of([
      tx('a', day: 2, amount: -10000),
      tx('b', day: 9, amount: -50000),
    ]);
    expect((big.insight, big.biggestDay), (SearchInsight.biggest, 9));

    final daily = of([
      for (var d = 1; d <= 16; d++)
        if (d != 4) tx('t$d', day: d),
    ]);
    expect(
      (daily.insight, daily.days, daily.streak),
      (SearchInsight.daily, 15, 12),
    );
  });
}
