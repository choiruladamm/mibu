/// Amounts are whole rupiah (IDR has no decimals).
class MonthBalance {
  const MonthBalance({required this.month, required this.amount});

  final DateTime month; // first day of month
  final int amount;
}

class Pocket {
  const Pocket({
    required this.emoji,
    required this.name,
    required this.budget,
    required this.spent,
  });

  final String emoji, name;
  final int budget, spent;

  int get usedPct => budget == 0 ? 0 : (spent * 100 / budget).round();
}

class Transaction {
  const Transaction({
    required this.emoji,
    required this.category,
    required this.place,
    required this.at,
    required this.amount,
  });

  final String emoji, category, place;
  final DateTime at;
  final int amount; // negative = pengeluaran
}
