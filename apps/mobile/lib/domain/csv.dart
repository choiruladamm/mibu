import 'package:intl/intl.dart';

import 'models/finance.dart';

const csvHeader = 'tanggal,jam,jenis,nominal,kategori,emoji,tempat,catatan,tag';

/// `mibu-yyyyMMdd.csv`.
String csvFileName(DateTime now) =>
    'mibu-${DateFormat('yyyyMMdd').format(now)}.csv';

/// RFC 4180 field: quote when it holds a comma, quote, or line break.
String _field(String s) =>
    s.contains(RegExp('[",\r\n]')) ? '"${s.replaceAll('"', '""')}"' : s;

/// Ekspor CSV: UTF-8 BOM (so Excel reads the emoji), CRLF rows, [entries]
/// as given (callers pass newest first). See MVP_PLAN.md › Ekspor CSV.
String transactionsCsv(List<Transaction> entries) {
  final date = DateFormat('yyyy-MM-dd');
  final time = DateFormat('HH:mm');
  final rows = [
    csvHeader,
    for (final t in entries.where((t) => !t.deleted))
      [
        date.format(t.at),
        time.format(t.at),
        t.kind == CategoryKind.expense ? 'pengeluaran' : 'pemasukan',
        t.amount.abs().toString(),
        t.category ?? '',
        t.category == null ? '' : t.emoji,
        t.place,
        t.note,
        t.tags.join(' '),
      ].map(_field).join(','),
  ];
  return '﻿${rows.join('\r\n')}\r\n';
}
