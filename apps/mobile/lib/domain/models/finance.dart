/// Amounts are whole rupiah (IDR has no decimals).
class MonthBalance {
  const MonthBalance({required this.month, required this.amount});

  final DateTime month; // first day of month
  final int amount; // balance at month end (or now, for the current month)
}

class Profile {
  const Profile({
    required this.openingBalance,
    required this.openingAt,
    required this.payday,
    this.hideAmounts = false,
  });

  /// Before 01.4 atur awal has run.
  static final empty = Profile(
    openingBalance: 0,
    openingAt: DateTime(2000),
    payday: 0,
  );

  final int openingBalance;
  final DateTime openingAt; // transactions before this aren't in the balance
  final int payday; // 1–28, 0 = last day of month
  final bool hideAmounts;
}

/// A category with a monthly limit, plus what's spent this month.
class Pocket {
  const Pocket({
    required this.id,
    required this.emoji,
    required this.name,
    required this.budget,
    required this.spent,
  });

  final String id, emoji, name;
  final int budget, spent;

  int get usedPct => budget == 0 ? 0 : (spent * 100 / budget).round();
}

class Transaction {
  const Transaction({
    required this.id,
    required this.emoji,
    required this.category,
    required this.place,
    required this.at,
    required this.amount,
  });

  final String id, emoji, place;
  final String? category; // null = tanpa kategori
  final DateTime at;
  final int amount; // negative = pengeluaran
}

/// Days left until payday, today included. [payday] 0 = last day of month.
int daysUntilPayday(DateTime now, int payday) {
  int monthLen(int y, int m) => DateTime(y, m + 1, 0).day;
  final len = monthLen(now.year, now.month);
  final pay = payday == 0 ? len : payday;
  if (pay > now.day) return pay - now.day;
  // Payday passed (or is today): count to next month's payday.
  final nextPay = payday == 0 ? monthLen(now.year, now.month + 1) : payday;
  return len - now.day + nextPay;
}

/// "aman jajan hari ini": today's share of the balance until payday, minus
/// what's already spent today. Negative = overspent today. See MVP_PLAN.md.
int safeToSpendToday({
  required int balance,
  required int spentToday,
  required int payday,
  required DateTime now,
}) {
  if (balance <= 0) return 0;
  final days = daysUntilPayday(now, payday);
  return (balance + spentToday) ~/ days - spentToday;
}

/// "saldo per bulan": 3 past months, this month, 2 predicted.
/// [nets] = net change of months now-3 … now (4 values).
/// Prediction = balance + average net of the 3 full months.
List<MonthBalance> balanceSeries({
  required DateTime now,
  required int balance,
  required List<int> nets,
}) {
  assert(nets.length == 4);
  DateTime month(int offset) => DateTime(now.year, now.month + offset);
  final ends = List<int>.filled(4, 0);
  ends[3] = balance;
  for (var i = 2; i >= 0; i--) {
    ends[i] = ends[i + 1] - nets[i + 1];
  }
  // ponytail: flat average; swap for something smarter once there's history.
  final avg = (nets[0] + nets[1] + nets[2]) ~/ 3;
  return [
    for (var i = 0; i < 4; i++)
      MonthBalance(month: month(i - 3), amount: ends[i]),
    for (var k = 1; k <= 2; k++)
      MonthBalance(month: month(k), amount: balance + avg * k),
  ];
}
