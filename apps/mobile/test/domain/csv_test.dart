import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/csv.dart';
import 'package:mibu/domain/emoji_catalog.dart';
import 'package:mibu/domain/models/finance.dart';

void main() {
  Transaction tx({
    int amount = -25000,
    String? category = 'makan',
    String place = '',
    String note = '',
    List<String> tags = const [],
    bool deleted = false,
  }) => Transaction(
    id: 'x',
    emoji: '🍜',
    category: category,
    place: place,
    at: DateTime(2026, 10, 2, 7, 5),
    amount: amount,
    note: note,
    tags: tags,
    deleted: deleted,
  );

  test('file name', () {
    expect(csvFileName(DateTime(2026, 10, 2)), 'mibu-20261002.csv');
  });

  test('BOM, header, CRLF, expense and income as positive amounts', () {
    final csv = transactionsCsv([
      tx(place: 'warteg', tags: ['kantor', 'siang']),
      tx(amount: 4500000, category: 'gajian'),
    ]);
    expect(csv.startsWith('﻿$csvHeader\r\n'), isTrue);
    expect(
      csv.split('\r\n'),
      containsAllInOrder([
        '2026-10-02,07:05,pengeluaran,25000,makan,🍜,warteg,,kantor siang',
        '2026-10-02,07:05,pemasukan,4500000,gajian,🍜,,,',
        '',
      ]),
    );
  });

  test('tanpa kategori leaves kategori and emoji empty', () {
    expect(
      transactionsCsv([tx(category: null)]),
      contains('pengeluaran,25000,,,,,'),
    );
  });

  test('escapes comma, quote and line break', () {
    final csv = transactionsCsv([tx(note: 'a, "b"\nc')]);
    expect(csv, contains(',"a, ""b""\nc",'));
  });

  test('skips soft-deleted; empty list is header only', () {
    expect(transactionsCsv([tx(deleted: true)]), '﻿$csvHeader\r\n');
    expect(transactionsCsv(const []), '﻿$csvHeader\r\n');
  });

  group('import', () {
    const head = '\u{FEFF}$csvHeader\r\n';
    Category cat(String name, CategoryKind kind) =>
        Category(id: name, emoji: '🍜', name: name, kind: kind);

    test('round-trips an export, quotes and line breaks included', () {
      final csv = transactionsCsv([
        tx(place: 'warteg', note: 'a, "b"\nc', tags: ['kantor', 'siang']),
        tx(amount: 4500000, category: 'gajian'),
        tx(category: null),
      ]);
      final parsed = parseTransactionsCsv(csv)!;
      expect(parsed.bad, 0);
      final [food, salary, none] = parsed.entries;
      expect(food.at, DateTime(2026, 10, 2, 7, 5));
      expect(food.amount, -25000);
      expect(food.category, 'makan');
      expect(food.emoji, '🍜');
      expect(food.note, 'a, "b"\nc');
      expect(food.tags, ['kantor', 'siang']);
      expect(salary.amount, 4500000);
      expect(none.category, '');
    });

    test('LF and no BOM read too; other header = not a mibu export', () {
      expect(
        parseTransactionsCsv(
          '$csvHeader\n2026-10-02,07:05,pengeluaran,25000,,,,,\n',
        )!.entries,
        hasLength(1),
      );
      expect(parseTransactionsCsv('tanggal,nominal\n2026-10-02,1\n'), isNull);
      expect(parseTransactionsCsv(''), isNull);
    });

    test('a file Excel re-saved: `;`, d/M/yyyy, H:mm and seconds', () {
      final parsed = parseTransactionsCsv(
        '${csvHeader.replaceAll(',', ';')}\r\n'
        '2/10/2026;7:05;pengeluaran;25000;makan;🍜;;"a; b";\r\n'
        '02/10/2026;07:05:59;pemasukan;4500000;gajian;💼;;;\r\n'
        '31/02/2026;07:05;pengeluaran;25000;;;;;\r\n'
        '2/10/2026;24:00;pengeluaran;25000;;;;;\r\n',
      )!;
      expect(parsed.bad, 2);
      final [food, salary] = parsed.entries;
      expect(food.at, DateTime(2026, 10, 2, 7, 5));
      expect(food.note, 'a; b');
      expect(salary.at, DateTime(2026, 10, 2, 7, 5));
    });

    test('rows that don\'t read are counted, the rest still come in', () {
      final parsed = parseTransactionsCsv(
        '$head'
        '2026-02-31,07:05,pengeluaran,25000,,,,,\r\n' // no 31 feb
        '2026-10-02,7:5,pengeluaran,25000,,,,,\r\n'
        '2026-10-02,07:05,transfer,25000,,,,,\r\n'
        '2026-10-02,07:05,pengeluaran,0,,,,,\r\n'
        '2026-10-02,07:05,pengeluaran,25.000,,,,,\r\n'
        '2026-10-02,07:05,pengeluaran,25000\r\n'
        '2026-10-02,07:05,pengeluaran,25000,,,,,\r\n',
      )!;
      expect(parsed.bad, 6);
      expect(parsed.entries, hasLength(1));
    });

    test('plan: dupes once per live entry, new buat apa by name + kind', () {
      final parsed = parseTransactionsCsv(
        '$head'
        '2026-10-02,07:05,pengeluaran,25000,makan,🍜,,,\r\n'
        '2026-10-02,07:05,pengeluaran,25000,makan,🍜,,,\r\n'
        '2026-10-03,08:00,pengeluaran,30000,boba,🧋,,,\r\n'
        '2026-10-04,08:00,pengeluaran,32000,Boba,🧋,,,\r\n'
        '2026-10-05,09:00,pemasukan,50000,makan,🍜,,,\r\n'
        '2026-10-06,09:00,pengeluaran,10000,aneh,🦄,,,\r\n'
        '2026-10-06,10:00,pengeluaran,10000,,,,,\r\n',
      )!;
      final plan = planImport(
        parsed,
        // seconds don't count: the file only keeps minutes
        existing: [
          Transaction(
            id: 'a',
            emoji: '🍜',
            category: 'makan',
            place: '',
            at: DateTime(2026, 10, 2, 7, 5, 42),
            amount: -25000,
          ),
        ],
        categories: [cat('makan', CategoryKind.expense)],
      );
      expect(plan.dupes, 1);
      expect(plan.entries, hasLength(6));
      expect(plan.newCategories, [
        (name: 'boba', emoji: '🧋', kind: CategoryKind.expense, count: 2),
        (name: 'makan', emoji: '🍜', kind: CategoryKind.income, count: 1),
        (
          name: 'aneh',
          emoji: fallbackEmoji,
          kind: CategoryKind.expense,
          count: 1,
        ),
      ]);
    });
  });
}
