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

  test('suggestedLimit: 1,4× up to Rp100K, min Rp300K', () {
    expect(suggestedLimit(0), 300000);
    expect(suggestedLimit(200000), 300000); // 280K → floor
    expect(suggestedLimit(420000), 600000); // 588K → 600K
    expect(suggestedLimit(500000), 700000); // exact
    expect(suggestedLimit(2399000), 3400000); // 3.358.600 → 3,4jt
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

  final nets = {
    DateTime(2026, 7): 546000,
    DateTime(2026, 8): -844500,
    DateTime(2026, 9): 5887500,
    DateTime(2026, 10): -4059000,
  };
  final now = DateTime(2026, 10, 14);

  test('balanceSeries walks back from balance and predicts flat avg', () {
    final series = balanceSeries(
      now: now,
      start: DateTime(2026, 7),
      balance: 4530000,
      nets: nets,
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

  test('balanceSeries window can start earlier; months without entries', () {
    final series = balanceSeries(
      now: now,
      start: DateTime(2026, 5),
      balance: 4530000,
      nets: nets,
    );
    expect(series.map((m) => m.month.month), [5, 6, 7, 8, 9, 10]);
    expect(series[0].amount, 3000000); // 3.546.000 − 546.000, nothing before
    expect(series[1].amount, 3000000);
  });

  test('monthEndBalance: now is the balance, older walks back', () {
    int at(DateTime m) =>
        monthEndBalance(now: now, balance: 4530000, nets: nets, month: m);
    expect(at(DateTime(2026, 10)), 4530000);
    expect(at(DateTime(2026, 9)), 8589000);
    expect(at(DateTime(2025, 12)), 3000000);
  });

  test('chartStart stays while picked is inside, else lands 4th', () {
    DateTime start(DateTime from, DateTime picked) =>
        chartStart(now: now, start: from, picked: picked);
    final def = DateTime(2026, 7);
    expect(start(def, DateTime(2026, 12)), def); // inside (a prediction)
    expect(start(def, DateTime(2026, 8)), def);
    expect(start(def, DateTime(2026, 3)), DateTime(2025, 12)); // 4th: mar
    expect(start(DateTime(2025, 12), DateTime(2026, 10)), DateTime(2026, 7));
    expect(start(DateTime(2025, 12), DateTime(2026, 12)), DateTime(2026, 7));
  });

  test('pocket status: unused, safe, almost out at 85%', () {
    Pocket p(int spent) =>
        Pocket(id: '', emoji: '', name: '', budget: 1000000, spent: spent);
    expect(p(0).status, PocketStatus.unused);
    expect(p(844000).status, PocketStatus.safe); // 84%; 84,9% rounds to 85
    expect(p(850000).status, PocketStatus.almostOut);
    expect(p(1200000).left, -200000);
  });

  test('daysLeftInMonth counts today', () {
    expect(daysLeftInMonth(DateTime(2026, 10, 16)), 16);
    expect(daysLeftInMonth(DateTime(2026, 10, 31)), 1);
    expect(daysLeftInMonth(DateTime(2026, 2, 1)), 28);
  });

  test('pocketLimitScale follows the PocketLimit rules', () {
    // design example: 6,9jt − 5,6jt = 1,3jt free → end 3jt
    expect(pocketLimitScale(budget: 6900000, others: 5600000), (
      max: 3000000,
      step: 100000,
      free: 1300000,
    ));
    // min 1jt end, capped at the budget itself
    expect(pocketLimitScale(budget: 800000, others: 700000), (
      max: 800000,
      step: 50000,
      free: 100000,
    ));
    // over budget already → free 0, end 1jt
    expect(pocketLimitScale(budget: 3000000, others: 4000000), (
      max: 1000000,
      step: 50000,
      free: 0,
    ));
    expect(pocketLimitScale(budget: 30000000, others: 0).step, 250000);
    expect(pocketLimitScale(budget: null, others: 5600000), (
      max: 2000000,
      step: 50000,
      free: null,
    ));
  });

  test('emojiIdeas matches keywords inside the name', () {
    expect(emojiIdeas('Kopi Susu'), ['☕', '🧋', '🥐']);
    expect(emojiIdeas('makan siang').first, '🍜');
    expect(emojiIdeas('zakat'), ['✨', '🧾', '📦']);
  });

  test('budgetPrefill rounds Σ limits up to Rp500K', () {
    expect(budgetPrefill(7400000), 7500000);
    expect(budgetPrefill(7500000), 7500000);
    expect(budgetPrefill(1), 500000);
    expect(budgetPrefill(0), 0);
  });
}
