import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/csv.dart';
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
}
