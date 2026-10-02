import 'dart:math';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/finance.dart';
import '../../domain/period.dart';
import 'app_database.dart';

const _uuid = Uuid();

/// Fills a freshly created database (debug builds only).
typedef Seed = Future<void> Function(AppDatabase db, DateTime now);

/// Design sample data, small enough to check by hand: tests and screenshots
/// assert these numbers, and they match the design boards. Dates are relative
/// to [now] so nothing lands in the future: 3 past months + this month.
Future<void> seedFixture(AppDatabase db, DateTime now) async {
  DateTime thisMonth(int day, int h, int m) {
    final at = DateTime(now.year, now.month, day.clamp(1, now.day), h, m);
    return at.isAfter(now) ? now : at;
  }

  final cats = <String, String>{}; // name → id
  await db.batch((b) {
    b.insert(
      db.profiles,
      ProfilesCompanion.insert(
        openingBalance: 3000000,
        openingAt: DateTime(now.year, now.month - 3),
        payday: 25,
        onboardedAt: Value(now),
      ),
    );
    // Budget + limits from the first seeded month, so past months have them.
    final from = DateTime(now.year, now.month - 3);
    final until = DateTime(from.year, from.month + 1);
    b.insert(
      db.budgets,
      BudgetsCompanion.insert(
        periodStart: from,
        periodEnd: until,
        amount: const Value(8000000),
      ),
    );
    for (final (i, (emoji, name, kind, limit)) in [
      ('🐶', 'anabul', CategoryKind.expense, 1000000),
      ('☕', 'ngopi', CategoryKind.expense, 300000),
      ('🛵', 'ojol', CategoryKind.expense, 500000),
      ('🍜', 'makan', CategoryKind.expense, 1500000),
      ('🛍️', 'belanja', CategoryKind.expense, null),
      ('💰', 'gajian', CategoryKind.income, null),
    ].indexed) {
      final id = _uuid.v4();
      cats[name] = id;
      b.insert(
        db.categories,
        CategoriesCompanion.insert(
          id: Value(id),
          emoji: emoji,
          name: name,
          kind: kind,
          sortOrder: Value(i),
          isPayday: Value(name == 'gajian'),
        ),
      );
      if (limit != null) {
        b.insert(
          db.limits,
          LimitsCompanion.insert(
            categoryId: id,
            periodStart: from,
            periodEnd: until,
            amount: Value(limit),
          ),
        );
      }
    }

    TransactionsCompanion tx(
      String cat,
      String place,
      DateTime at,
      int amount, {
      String note = '',
    }) => TransactionsCompanion.insert(
      amount: amount,
      categoryId: Value(cats[cat]),
      place: Value(place),
      note: Value(note),
      at: at,
    );

    b.insertAll(db.transactions, [
      // Past months: gajian in, belanja out → design's month balances.
      for (final (offset, out) in [
        (-3, 7954000),
        (-2, 9344500),
        (-1, 2612500),
      ]) ...[
        tx(
          'gajian',
          'kantor',
          DateTime(now.year, now.month + offset, 25, 9),
          8500000,
        ),
        tx(
          'belanja',
          'tokopedia',
          DateTime(now.year, now.month + offset, 5, 20),
          -out,
        ),
      ],
      // This month: pockets at 90 / 60 / 38 / 26 %.
      tx(
        'belanja',
        'tokopedia',
        thisMonth(now.day - 3, 20, 0),
        -2399000,
        note: 'titip beliin ibu',
      ),
      tx(
        'makan',
        'warteg',
        thisMonth(now.day - 1, 12, 30),
        -390000,
        note: 'makan siang bareng tim',
      ),
      tx('ojol', 'gojek', thisMonth(now.day - 3, 8, 15), -163000),
      tx('anabul', 'dokter hewan', thisMonth(now.day - 2, 17, 0), -450000),
      tx('ngopi', 'kopi kenangan', thisMonth(now.day - 1, 9, 0), -180000),
      tx('anabul', 'petshop', thisMonth(now.day - 1, 14, 32), -450000),
      tx('ojol', 'gojek', thisMonth(now.day, 11, 5), -27000),
    ]);
  });
}

/// Lived-in data for a dev phone: a young Jakarta employee (gaji Rp8,5jt on
/// the 25th, ngekos, has a dog) over 3 past months + this month, ~80 entries
/// a month. Rule-based with a fixed [Random] seed, so a given [now] always
/// gives the same data. This month ngopi ends ~90% (hampir abis), ojol ~105%
/// (over) and hiburan untouched, whatever day it is.
Future<void> seedDemo(AppDatabase db, DateTime now) async {
  final rnd = Random(25);
  T pick<T>(List<T> xs) => xs[rnd.nextInt(xs.length)];
  bool chance(double p) => rnd.nextDouble() < p;

  final start = DateTime(now.year, now.month - 3);
  final thisMonth = DateTime(now.year, now.month);

  final cats = <String, String>{}; // name → id
  final limits = <String, int>{};
  final rows = <TransactionsCompanion>[];
  final spent = <String, int>{}; // this month, expense pockets

  void tx(
    String? cat,
    String place,
    DateTime at,
    int amount, {
    String note = '',
    List<String> tags = const [],
  }) {
    if (at.isAfter(now)) return;
    rows.add(
      TransactionsCompanion.insert(
        amount: amount,
        categoryId: Value(cat == null ? null : cats[cat]),
        place: Value(place),
        note: Value(note),
        tags: Value(tags.join(',')),
        at: at,
      ),
    );
    if (cat != null && !at.isBefore(thisMonth)) {
      spent[cat] = (spent[cat] ?? 0) - amount;
    }
  }

  const categoryList = [
    ('🍜', 'makan', CategoryKind.expense, 2000000),
    ('☕', 'ngopi', CategoryKind.expense, 300000),
    ('🛵', 'ojol', CategoryKind.expense, 600000),
    ('🐶', 'anabul', CategoryKind.expense, 500000),
    ('🛒', 'dapur', CategoryKind.expense, 800000),
    ('🎬', 'hiburan', CategoryKind.expense, 300000),
    ('🏠', 'kos', CategoryKind.expense, null),
    ('💡', 'tagihan', CategoryKind.expense, null),
    ('🛍️', 'belanja', CategoryKind.expense, null),
    ('🤲', 'kondangan', CategoryKind.expense, null),
    ('💰', 'gajian', CategoryKind.income, null),
    ('💸', 'sampingan', CategoryKind.income, null),
  ];
  for (final (_, name, _, limit) in categoryList) {
    cats[name] = _uuid.v4();
    if (limit != null) limits[name] = limit;
  }

  for (
    var d = start;
    !d.isAfter(now);
    d = DateTime(d.year, d.month, d.day + 1)
  ) {
    DateTime at(int h, int m) => DateTime(d.year, d.month, d.day, h, m);
    final weekend = d.weekday >= DateTime.saturday;
    final past = d.isBefore(thisMonth);

    // Monthly fixed.
    switch (d.day) {
      case 1:
        tx('kos', 'ibu kos', at(8, 0), -1800000, note: 'kos bulan ini');
      case 2:
        tx('anabul', 'petshop', at(18, 20), -235000, note: 'makanan + pasir');
      case 3:
        tx('tagihan', 'pln mobile', at(19, 5), -200000, note: 'token listrik');
      case 5:
        tx('tagihan', 'indihome', at(20, 0), -330000);
      case 7:
        tx('tagihan', 'telkomsel', at(9, 30), -100000, note: 'paket data');
      case 15:
        tx('tagihan', 'netflix', at(0, 5), -54000);
        tx('dapur', 'superindo', at(16, 40), -215000);
      case 20:
        tx('tagihan', 'spotify', at(0, 5), -55000);
      case 25:
        tx('gajian', 'kantor', at(9, 0), 8500000, tags: ['gajian']);
      case 26:
        tx(null, 'transfer bca', at(10, 15), -1000000, note: 'kirim ortu');
    }

    if (!weekend) {
      tx(
        'ojol',
        pick(['gojek', 'grab']),
        at(7, 40 + rnd.nextInt(15)),
        -pick([14000, 16000, 18000, 21000, 24000]),
      );
      final patungan = d.weekday == DateTime.friday;
      tx(
        'makan',
        pick(['warteg', 'nasi padang', 'bakso', 'mie ayam', 'ayam geprek']),
        at(12, rnd.nextInt(40)),
        -pick([15000, 18000, 22000, 25000, 28000]),
        note: patungan ? 'patungan makan siang tim' : '',
        tags: patungan ? ['kantor'] : const [],
      );
      if (chance(0.4)) {
        final meeting = chance(0.25);
        tx(
          'ngopi',
          pick(['kopi kenangan', 'janji jiwa', 'fore', 'point coffee']),
          at(15, rnd.nextInt(50)),
          -pick([18000, 22000, 25000, 28000]),
          note: meeting ? 'meeting sama klien' : '',
          tags: meeting ? ['kantor'] : const [],
        );
      }
    } else {
      if (d.weekday == DateTime.saturday) {
        tx(
          'dapur',
          pick(['indomaret', 'alfamart']),
          at(10, rnd.nextInt(50)),
          -pick([65000, 88000, 112000, 135000]),
        );
      }
      if (chance(0.5)) {
        tx(
          'makan',
          'gofood',
          at(19, rnd.nextInt(50)),
          -pick([45000, 58000, 72000, 85000]),
          note: chance(0.4) ? 'mager masak' : '',
        );
      }
    }

    // Occasional, past months only so this month stays believable.
    if (!past) continue;
    if (d.day == d.month) {
      tx(
        'belanja',
        'shopee',
        at(0, 15),
        -pick([189000, 254000, 349000]),
        note: 'checkout tanggal kembar',
        tags: ['promo'],
      );
    }
    if (d.day == 17 && d.month.isEven) {
      tx('belanja', 'tokopedia', at(21, 10), -pick([129000, 410000]));
    }
    if (d.weekday == DateTime.saturday && d.day >= 8 && d.day <= 14) {
      tx(
        'kondangan',
        'nikahan teman',
        at(11, 0),
        -pick([100000, 150000, 200000]),
        note: 'amplop',
      );
    }
    if (d.weekday == DateTime.saturday && d.day >= 15 && d.day <= 21) {
      tx(
        'hiburan',
        pick(['xxi', 'cgv']),
        at(19, 30),
        -pick([90000, 110000]),
        note: 'nonton bareng',
        tags: ['weekend'],
      );
    }
    if (d.day == 12 && d.month == DateTime(now.year, now.month - 2).month) {
      tx(
        'sampingan',
        'klien freelance',
        at(14, 0),
        1500000,
        note: 'desain logo',
      );
    }
    if (d.day == 18 && d.month == DateTime(now.year, now.month - 2).month) {
      tx('anabul', 'dokter hewan', at(17, 0), -450000, note: 'vaksin tahunan');
    }
    if (d.day == 9) {
      tx(null, 'fotokopi', at(13, 10), -15000);
    }
  }

  // Top up so the pocket states show on any day, even the 1st.
  final topUpAt = now.subtract(const Duration(hours: 1)).isBefore(thisMonth)
      ? thisMonth
      : now.subtract(const Duration(hours: 1));
  for (final (cat, place, pct, note) in [
    ('ngopi', 'kopi kenangan', 90, 'traktir kopi satu tim'),
    ('ojol', 'grab', 105, 'ke bandara pp'),
  ]) {
    final gap = limits[cat]! * pct ~/ 100 - (spent[cat] ?? 0);
    if (gap > 0) {
      tx(cat, place, topUpAt, -gap, note: note, tags: ['kantor']);
    }
  }

  await db.batch((b) {
    b.insert(
      db.profiles,
      ProfilesCompanion.insert(
        openingBalance: 3000000,
        openingAt: start,
        payday: 25,
        onboardedAt: Value(start),
      ),
    );
    final from = DateTime(start.year, start.month);
    final until = DateTime(from.year, from.month + 1);
    b.insert(
      db.budgets,
      BudgetsCompanion.insert(
        periodStart: from,
        periodEnd: until,
        amount: const Value(6500000),
      ),
    );
    // Realistic data lives in gajian periods, like a real first run.
    b.insert(
      db.periodRules,
      PeriodRulesCompanion.insert(
        effectiveFrom: DateTime(start.year, start.month, start.day),
        mode: PeriodMode.payday,
        paydayDay: 25,
        shift: const Value(PaydayShift.previousWorkday),
      ),
    );
    for (final (i, (emoji, name, kind, limit)) in categoryList.indexed) {
      b.insert(
        db.categories,
        CategoriesCompanion.insert(
          id: Value(cats[name]!),
          emoji: emoji,
          name: name,
          kind: kind,
          sortOrder: Value(i),
          isPayday: Value(name == 'gajian'),
        ),
      );
      if (limit != null) {
        b.insert(
          db.limits,
          LimitsCompanion.insert(
            categoryId: cats[name]!,
            periodStart: from,
            periodEnd: until,
            amount: Value(limit),
          ),
        );
      }
    }
    b.insertAll(db.transactions, rows);
  });
}
