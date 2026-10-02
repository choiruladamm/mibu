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
    this.onboarded = false,
    this.recentSearches = const [],
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
  final bool onboarded; // 01.4 atur awal done (or skipped with "nanti aja")
  final List<String> recentSearches; // 04.2b terakhir dicari, newest first
}

/// 01.4b kantong pertama: presets with the board's monthly limits.
const setupPockets = [
  ('🍜', 'makan', 1500000),
  ('☕', 'ngopi', 300000),
  ('🛵', 'ojol', 500000),
  ('💡', 'tagihan', 600000),
  ('🎉', 'hiburan', 400000),
  ('🛒', 'belanja', 800000),
  ('🐶', 'anabul', 300000),
  ('✈️', 'liburan', 500000),
];

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
      : usedPct > 100
      ? PocketStatus.over
      : usedPct >= 85
      ? PocketStatus.almostOut
      : PocketStatus.safe;
}

enum PocketStatus {
  safe,
  almostOut,
  over,
  unused;

  /// ≥ 85% kepake: ink chip / pill, bold "sisa".
  bool get ink => this == almostOut || this == over;
}

/// BudgetSheet prefill: Σ pocket limits rounded up to Rp500K.
int budgetPrefill(int pocketsTotal) =>
    (pocketsTotal + 499999) ~/ 500000 * 500000;

/// "pasang limit" default for a category that already spent [spent] this
/// month: 1,4× rounded up to Rp100K, at least Rp300K.
int suggestedLimit(int spent) {
  final v = (spent * 14 + 999999) ~/ 1000000 * 100000;
  return v < 300000 ? 300000 : v;
}

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

int _monthIndex(DateTime m) => m.year * 12 + m.month;

/// Balance at the end of [month] (first-of-month key, not after [now]'s).
/// Walks back from [balance] (= now) by [nets] (month → net change).
int monthEndBalance({
  required DateTime now,
  required int balance,
  required Map<DateTime, int> nets,
  required DateTime month,
}) {
  var b = balance;
  for (
    var m = DateTime(now.year, now.month);
    _monthIndex(m) > _monthIndex(month);
    m = DateTime(m.year, m.month - 1)
  ) {
    b -= nets[m] ?? 0;
  }
  return b;
}

/// "saldo per bulan": 6 months from [start] (default window = 3 past, now,
/// 2 predicted). Up to [now]'s month: balance at month end. After it:
/// prediction = balance + k × average net of the 3 months before now.
List<MonthBalance> balanceSeries({
  required DateTime now,
  required DateTime start,
  required int balance,
  required Map<DateTime, int> nets,
}) {
  final cur = DateTime(now.year, now.month);
  int net(int back) => nets[DateTime(cur.year, cur.month - back)] ?? 0;
  // ponytail: flat average; swap for something smarter once there's history.
  final avg = (net(3) + net(2) + net(1)) ~/ 3;
  return [
    for (var i = 0; i < 6; i++)
      () {
        final month = DateTime(start.year, start.month + i);
        final ahead = _monthIndex(month) - _monthIndex(cur);
        return MonthBalance(
          month: month,
          amount: ahead > 0
              ? balance + avg * ahead
              : monthEndBalance(
                  now: now,
                  balance: balance,
                  nets: nets,
                  month: month,
                ),
        );
      }(),
  ];
}

/// First month of the chart window after [picked]. Stays put while [picked]
/// is inside it; otherwise [picked] lands 4th, but the window never runs
/// past now + 2 months.
DateTime chartStart({
  required DateTime now,
  required DateTime start,
  required DateTime picked,
}) {
  final at = _monthIndex(picked) - _monthIndex(start);
  if (at >= 0 && at <= 5) return start;
  final latest = DateTime(now.year, now.month - 3);
  final want = DateTime(picked.year, picked.month - 3);
  return want.isAfter(latest) ? latest : want;
}
