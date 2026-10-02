// Amounts are whole rupiah (IDR has no decimals).

enum CategoryKind { expense, income }

class Category {
  const Category({
    required this.id,
    required this.emoji,
    required this.name,
    required this.kind,
    this.monthlyLimit,
  });

  final String id, emoji, name;
  final CategoryKind kind;
  final int? monthlyLimit; // set = kantong
}

/// "terakhir" in 03.2: a category + place logged recently.
class RecentPick {
  const RecentPick({required this.category, required this.place});

  final Category category;
  final String place;
}

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
    this.monthlyBudget,
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
  final int? monthlyBudget; // budget bulanan, set by the user; null = not set
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
  int get left => budget - spent; // negative = over

  PocketStatus get status => spent == 0
      ? PocketStatus.unused
      : usedPct >= 85
      ? PocketStatus.almostOut
      : PocketStatus.safe;
}

enum PocketStatus { safe, almostOut, unused }

/// BudgetSheet prefill: Σ pocket limits rounded up to Rp500K.
int budgetPrefill(int pocketsTotal) =>
    (pocketsTotal + 499999) ~/ 500000 * 500000;

/// Days left in [now]'s month, today included (never 0).
int daysLeftInMonth(DateTime now) =>
    DateTime(now.year, now.month + 1, 0).day - now.day + 1;

/// PocketLimit 00.15 slider scale. [budget] = monthly budget (null = not
/// set), [others] = Σ limits of the other pockets. [free] = room left in the
/// budget ("sisa budget"), null when there's no budget. See MVP_PLAN.md.
({int max, int step, int? free}) pocketLimitScale({
  required int? budget,
  required int others,
}) {
  if (budget == null || budget <= 0) {
    return (max: 2000000, step: 50000, free: null);
  }
  const half = 500000;
  final free = budget - others < 0 ? 0 : budget - others;
  final roundedUp = (free * 2 + half - 1) ~/ half * half;
  final max = roundedUp < 1000000 ? 1000000 : roundedUp;
  return (
    max: max > budget ? budget : max,
    step: budget <= 5000000
        ? 50000
        : budget <= 20000000
        ? 100000
        : 250000,
    free: free,
  );
}

const _emojiIdeas = {
  'gym': ['🏋️', '🧘', '🏃'],
  'makan': ['🍜', '🍛', '🍲'],
  'mie': ['🍜', '🥢', '🍲'],
  'kos': ['🏠', '🔑', '🏢'],
  'sewa': ['🏠', '🔑', '🏢'],
  'kado': ['🎁', '💐', '🎀'],
  'buku': ['📚', '📖', '✏️'],
  'game': ['🎮', '🕹️', '🎲'],
  'musik': ['🎧', '🎸', '🎵'],
  'pulsa': ['📱', '📶', '🔌'],
  'bensin': ['⛽', '🛵', '🅿️'],
  'motor': ['🛵', '⛽', '🔧'],
  'kopi': ['☕', '🧋', '🥐'],
  'anak': ['🧸', '🍼', '🎒'],
  'kucing': ['🐱', '🐟', '🧶'],
  'anjing': ['🐶', '🦴', '🐾'],
  'liburan': ['✈️', '🧳', '🏝️'],
  'skincare': ['🧴', '💆', '✨'],
};

/// 03.4 "saran": 3 emoji for a category name, by Indonesian keyword.
List<String> emojiIdeas(String name) {
  final n = name.trim().toLowerCase();
  for (final MapEntry(:key, :value) in _emojiIdeas.entries) {
    if (n.contains(key)) return value;
  }
  return const ['✨', '🧾', '📦'];
}

class Transaction {
  const Transaction({
    required this.id,
    required this.emoji,
    required this.category,
    required this.place,
    required this.at,
    required this.amount,
    this.categoryId,
    this.note = '',
    this.tags = const [],
    this.deleted = false,
  });

  final String id, emoji, place, note;
  final String? category, categoryId; // null = tanpa kategori
  final DateTime at;
  final int amount; // negative = pengeluaran
  final List<String> tags;
  final bool deleted; // soft-deleted, still shown stamped on 04.3

  CategoryKind get kind =>
      amount < 0 ? CategoryKind.expense : CategoryKind.income;
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
