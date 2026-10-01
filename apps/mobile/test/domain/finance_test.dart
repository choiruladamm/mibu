import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/models/finance.dart';

void main() {
  test('daysUntilPayday counts today, rolls over, handles akhir', () {
    expect(daysUntilPayday(DateTime(2026, 10, 16), 25), 9); // 16…24
    expect(daysUntilPayday(DateTime(2026, 10, 25), 25), 31); // payday today
    expect(daysUntilPayday(DateTime(2026, 10, 26), 25), 30);
    expect(daysUntilPayday(DateTime(2026, 2, 10), 0), 18); // akhir = 28 feb
    expect(daysUntilPayday(DateTime(2026, 1, 31), 0), 28); // → 28 feb
  });

  test('safeToSpendToday: spending today eats today\'s share', () {
    final now = DateTime(2026, 10, 16);
    int s(int balance, int spent) => safeToSpendToday(
      balance: balance,
      spentToday: spent,
      payday: 25,
      now: now,
    );
    expect(s(4530000, 0), 503333); // plan example
    expect(s(4530000 - 100000, 100000), 403333);
    expect(s(900000, 600000), -433334); // kebablasan
    expect(s(0, 0), 0);
    expect(s(-5000, 0), 0);
  });

  test('balanceSeries walks back from balance and predicts flat avg', () {
    final series = balanceSeries(
      now: DateTime(2026, 10, 14),
      balance: 4530000,
      nets: [546000, -844500, 5887500, -4059000],
    );
    expect(series.map((m) => m.month.month), [7, 8, 9, 10, 11, 12]);
    expect(series.map((m) => m.amount), [
      3546000,
      2701500,
      8589000,
      4530000,
      6393000,
      8256000,
    ]);
  });
}
