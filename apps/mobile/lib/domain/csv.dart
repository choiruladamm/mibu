import 'package:intl/intl.dart';

import 'emoji_catalog.dart';
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

/// One row of a mibu export, read back (import dari csv, 02.4l). [category]
/// empty = tanpa kategori; [amount] signed like [Transaction.amount].
typedef CsvEntry = ({
  DateTime at,
  int amount,
  String category,
  String emoji,
  String place,
  String note,
  List<String> tags,
});

/// RFC 4180 records split on [sep]: quoted fields may hold it, `""` and
/// line breaks.
List<List<String>> _records(String s, String sep) {
  final out = <List<String>>[];
  var row = <String>[];
  final f = StringBuffer();
  var quoted = false;
  void endField() {
    row.add(f.toString());
    f.clear();
  }

  void endRow() {
    endField();
    if (row.length > 1 || row.first.isNotEmpty) out.add(row);
    row = <String>[];
  }

  for (var i = 0; i < s.length; i++) {
    final c = s[i];
    if (quoted) {
      if (c != '"') {
        f.write(c);
      } else if (i + 1 < s.length && s[i + 1] == '"') {
        f.write('"');
        i++;
      } else {
        quoted = false;
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == sep) {
      endField();
    } else if (c == '\n') {
      endRow();
    } else if (c != '\r') {
      f.write(c);
    }
  }
  endRow();
  return out;
}

// yyyy-MM-dd as mibu writes it, or d/M/yyyy: Excel (id) re-saves dates so.
final _isoDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
final _idDate = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{4})$');
// HH:mm; Excel may drop the leading 0 or add seconds (dropped here).
final _timeRe = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2})?$');

DateTime? _at(String date, String time) {
  final ymd = switch ((_isoDate.firstMatch(date), _idDate.firstMatch(date))) {
    (final m?, _) => [m[1]!, m[2]!, m[3]!],
    (_, final m?) => [m[3]!, m[2]!, m[1]!],
    _ => null,
  };
  final t = _timeRe.firstMatch(time);
  if (ymd == null || t == null) return null;
  final [y, mo, d] = [for (final v in ymd) int.parse(v)];
  final h = int.parse(t[1]!), mi = int.parse(t[2]!);
  final at = DateTime(y, mo, d, h, mi);
  // DateTime rolls 31 feb over to march, 24:00 to the next day: not real.
  return at.month == mo && at.day == d && at.hour == h && at.minute == mi
      ? at
      : null;
}

final _digits = RegExp(r'^\d+$');

CsvEntry? _entry(List<String> r) {
  if (r.length != 9) return null;
  final [date, time, kind, nominal, category, emoji, place, note, tags] = r;
  final at = _at(date.trim(), time.trim());
  if (at == null) return null;
  if (!_digits.hasMatch(nominal)) return null;
  final n = int.parse(nominal);
  if (n == 0) return null;
  final sign = switch (kind) {
    'pengeluaran' => -1,
    'pemasukan' => 1,
    _ => null,
  };
  if (sign == null) return null;
  return (
    at: at,
    amount: sign * n,
    category: category.trim().toLowerCase(),
    emoji: emoji.trim(),
    place: place.trim(),
    note: note.trim(),
    tags: tags.split(' ').where((t) => t.isNotEmpty).toList(),
  );
}

/// Import: [csv] as written by [transactionsCsv] → its rows, plus how many
/// rows didn't read ([bad]). Null = not a mibu export (header differs). A
/// file Excel saved with `;` (id locale) reads too.
({List<CsvEntry> entries, int bad})? parseTransactionsCsv(String csv) {
  final body = csv.startsWith('\u{FEFF}') ? csv.substring(1) : csv;
  final head = body.split('\n').first;
  final records = _records(
    body,
    head.contains(';') && !head.contains(',') ? ';' : ',',
  );
  if (records.isEmpty || records.first.join(',') != csvHeader) return null;
  final entries = <CsvEntry>[];
  var bad = 0;
  for (final r in records.skip(1)) {
    if (_entry(r) case final e?) {
      entries.add(e);
    } else {
      bad++;
    }
  }
  return (entries: entries, bad: bad);
}

/// A buat apa the import makes (not in mibu yet), with its entry count.
typedef CsvNewCategory = ({
  String name,
  String emoji,
  CategoryKind kind,
  int count,
});

/// What 02.4m shows and the import writes: rows not in mibu yet ([entries]),
/// ones already there ([dupes], skipped) and buat apa to make.
class CsvImport {
  const CsvImport({
    required this.entries,
    required this.dupes,
    required this.bad,
    required this.newCategories,
  });

  final List<CsvEntry> entries;
  final int dupes, bad;
  final List<CsvNewCategory> newCategories;
}

String _catKey(CategoryKind kind, String name) => '${kind.name}|$name';

CategoryKind csvKind(CsvEntry e) =>
    e.amount < 0 ? CategoryKind.expense : CategoryKind.income;

String _dupeKey(DateTime at, int amount, String category, String note) =>
    '${DateFormat('yyyy-MM-dd HH:mm').format(at)}|$amount|$category|$note';

/// Matches [parsed] against mibu: an entry with the same minute, amount,
/// buat apa and catatan as a live one ([existing]) is skipped, once per
/// live entry, so importing the same file twice adds nothing. Buat apa
/// match by name + kind ([categories] = the live ones); the rest are made
/// with the file's emoji (outside the catalog → [fallbackEmoji]).
CsvImport planImport(
  ({List<CsvEntry> entries, int bad}) parsed, {
  required List<Transaction> existing,
  required List<Category> categories,
}) {
  final have = <String, int>{};
  for (final t in existing.where((t) => !t.deleted)) {
    final k = _dupeKey(t.at, t.amount, t.category ?? '', t.note);
    have[k] = (have[k] ?? 0) + 1;
  }
  final known = {for (final c in categories) _catKey(c.kind, c.name)};
  final entries = <CsvEntry>[];
  final made = <String, CsvNewCategory>{};
  var dupes = 0;
  for (final e in parsed.entries) {
    final k = _dupeKey(e.at, e.amount, e.category, e.note);
    if ((have[k] ?? 0) > 0) {
      have[k] = have[k]! - 1;
      dupes++;
      continue;
    }
    entries.add(e);
    final kind = csvKind(e);
    final ck = _catKey(kind, e.category);
    if (e.category.isEmpty || known.contains(ck)) continue;
    final c = made[ck];
    made[ck] = (
      name: e.category,
      emoji: c?.emoji ?? catalogEmoji(e.emoji),
      kind: kind,
      count: (c?.count ?? 0) + 1,
    );
  }
  return CsvImport(
    entries: entries,
    dupes: dupes,
    bad: parsed.bad,
    newCategories: made.values.toList(),
  );
}
