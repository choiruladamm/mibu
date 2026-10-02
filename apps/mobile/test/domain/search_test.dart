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

  test('nearest day with a hit; ties go earlier', () {
    final s = SearchSummary([
      tx('a', day: 2),
      tx('b', day: 9),
      tx('c', day: 13),
    ], today: 16);
    expect([1, 5, 6, 11, 30].map(s.nearestDay), [2, 2, 9, 9, 13]);
  });

  test('rememberSearch: newest first, no dupes, at most 5', () {
    expect(rememberSearch(['a', 'b'], ' b '), ['b', 'a']);
    expect(rememberSearch(['a'], '  '), ['a']);
    expect(rememberSearch(['1', '2', '3', '4', '5'], '6'), [
      '6',
      '1',
      '2',
      '3',
      '4',
    ]);
  });

  test('ideas: top 3 places one per category, then other categories', () {
    final month = [
      for (var i = 0; i < 4; i++) tx('k$i', place: 'kopi kenangan'),
      for (var i = 0; i < 3; i++) tx('f$i', place: 'fore'), // ngopi again
      for (var i = 0; i < 2; i++) tx('g$i', category: 'ojol', place: 'gojek'),
      tx('w', category: 'makan', place: 'warteg'),
      tx('a', category: 'anabul'),
      tx('b', category: 'belanja'),
      tx('h', category: 'hiburan'),
      tx('s', category: 'gajian', place: 'kantor', amount: 8500000),
    ];
    expect(searchIdeas(month).map((i) => i.label), [
      'kopi kenangan',
      'gojek',
      'warteg',
      'anabul',
      'belanja',
      'hiburan',
    ]);
  });

  test('didYouMean: within 2 edits, 3+ letters', () {
    final e = [
      tx('a', place: 'Kopi Kenangan'),
      tx('b', category: 'ojol', place: 'gojek'),
    ];
    expect(didYouMean(e, 'kopii'), 'kopi');
    expect(didYouMean(e, 'gojke'), 'gojek');
    expect(didYouMean(e, 'kopi'), isNull); // exact = no fix
    expect(didYouMean(e, 'ko'), isNull);
    expect(didYouMean(e, 'bioskop'), isNull);
  });
}
