import '../period.dart';

// Amounts are whole rupiah (IDR has no decimals).

enum CategoryKind { expense, income }

class Category {
  const Category({
    required this.id,
    required this.emoji,
    required this.name,
    required this.kind,
    this.monthlyLimit,
    this.isPayday = false,
  });

  final String id, emoji, name;
  final CategoryKind kind;
  final int? monthlyLimit; // set = kantong
  final bool isPayday; // gajian: can't be deleted, counts the payday
}

/// "terakhir" in 03.2: a category + place logged recently.
class RecentPick {
  const RecentPick({required this.category, required this.place});

  final Category category;
  final String place;
}

/// One point of the beranda chart (PeriodBars 00.26).
class PeriodPoint {
  const PeriodPoint({required this.month, required this.amount});

  final DateTime month; // the period's month label (first of month)
  final int amount; // kepake: spent in that period, positive
}

/// 02.4 sembunyiin nominal (02.4h): what turns into `Rp•••`. [income] =
/// pemasukan and the figures it can be read back from; [all] = everything.
enum HideAmounts { none, income, all }

/// No saldo here: mibu is a ledger per payday period, so nothing carries
/// over and there's no opening balance (docs/PERIOD_LEDGER_PLAN.md).
class Profile {
  const Profile({
    required this.payday,
    this.monthlyBudget,
    this.hideAmounts = HideAmounts.none,
    this.onboarded = false,
    this.onboardedAt,
    this.recentSearches = const [],
    this.pocketsIntroSeen = false,
  });

  /// Before 01.4 atur awal has run.
  static const empty = Profile(payday: 0);

  final int payday; // 1–31, 31 = akhir (legacy 0 too)
  final int? monthlyBudget; // budget bulanan, set by the user; null = not set
  final HideAmounts hideAmounts;
  final bool onboarded; // 01.4 atur awal done (or skipped with "nanti aja")
  final DateTime? onboardedAt; // when: a payday change in that period is a fix
  final List<String> recentSearches; // 04.2b terakhir dicari, newest first
  final bool pocketsIntroSeen; // 02.2l kenalan kantong dismissed with "oke"
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
    int? limit,
  }) : limit = limit ?? budget;

  final String id, emoji, name;
  final int budget, spent; // budget = the limit for this period (prorated)
  final int limit; // as set: what limit sheets edit and add up against

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

/// "gajian telat" shows this many days at most, then quietly rolls on.
const paydayLateMaxDays = 7;

enum PaydayStatus { upcoming, today, late }

/// Where [now] stands against payday. [next] = the payday the money has to
/// last until (exclusive); [daysToNext] = days from today to it, today
/// included (always ≥ 1); [daysLeft] = the same while [status] is upcoming,
/// 0 on payday / telat (no "gajian lagi n hari" then); [lateDays] > 0 only
/// when late.
typedef PaydayInfo = ({
  PaydayStatus status,
  DateTime next,
  int daysToNext,
  int daysLeft,
  int lateDays,
});

/// [payday] 1–31 (31 = akhir; a day past the month's end = its last day). A
/// payday on Saturday / Sunday is paid the Friday before. [salaries] = dates
/// of live gajian income (any order): one logged up to [paydayEarlyDays]
/// early starts the cycle that day, so the money lasts until the next one.
/// On the scheduled day or after it with no salary logged yet: today / late;
/// late needs a salary logged before (people who never log it don't get
/// nagged) and ends after [paydayLateMaxDays]. Same cycles as the period
/// resolver.
PaydayInfo paydayInfo({
  required DateTime now,
  required int payday,
  Iterable<DateTime> salaries = const [],
}) {
  final today = DateTime(now.year, now.month, now.day);
  final paid = [for (final d in salaries) DateTime(d.year, d.month, d.day)];
  final r = PaydayCycleResolver(
    payday,
    shift: PaydayShift.previousWorkday,
    salaries: paid,
  );
  final cycle = r.cycleOf(today);
  final period = r.periodOf(today);
  int days(DateTime from, DateTime to) => DateTime.utc(
    to.year,
    to.month,
    to.day,
  ).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

  final toNext = days(today, period.end);
  final upcoming = (
    status: PaydayStatus.upcoming,
    next: period.end,
    daysToNext: toNext,
    daysLeft: toNext,
    lateDays: 0,
  );
  // Scheduled payday of this cycle, and whether its salary is in already.
  final due = r.anchor(cycle.y, cycle.m);
  final from = DateTime(due.year, due.month, due.day - paydayEarlyDays);
  final logged = paid.any((d) => !d.isBefore(from) && !d.isAfter(today));
  if (logged || today.isBefore(due)) return upcoming;
  final late = days(due, today);
  if (late == 0) {
    return (
      status: PaydayStatus.today,
      next: period.end,
      daysToNext: toNext,
      daysLeft: 0,
      lateDays: 0,
    );
  }
  if (paid.isNotEmpty && late <= paydayLateMaxDays) {
    return (
      status: PaydayStatus.late,
      next: period.end,
      daysToNext: toNext,
      daysLeft: 0,
      lateDays: late,
    );
  }
  return upcoming;
}

/// Today's share of what's left of the budget, before today's spending:
/// (sisa budget + spent today) ÷ days left in the period, today included.
/// Null without a budget: aman jajan only ever comes from the budget the
/// user set, never from income. Also shown by "dari mana angkanya?" so the
/// explanation can't drift from the figure.
int? safeShare({
  required int? budgetLeft,
  required int spentToday,
  required int days,
}) => budgetLeft == null
    ? null
    : (budgetLeft + spentToday) ~/ (days < 1 ? 1 : days);

/// "aman jajan hari ini": today's [safeShare] minus what's already spent
/// today ([budgetLeft] = budget − spent this period, [days] = days left in
/// the period). Negative = overspent today; null without a budget. See
/// MVP_PLAN.md.
int? safeToSpendToday({
  required int? budgetLeft,
  required int spentToday,
  required int days,
}) => switch (safeShare(
  budgetLeft: budgetLeft,
  spentToday: spentToday,
  days: days,
)) {
  final share? => share - spentToday,
  null => null,
};

int _monthIndex(DateTime m) => m.year * 12 + m.month;

/// The beranda chart (PeriodBars 00.26): what was spent in 6 periods from
/// [start] ([spent], month label → expenses). Nothing ahead of now: no
/// prediction, the window ends at the running period at the latest.
List<PeriodPoint> spentSeries({
  required DateTime start,
  required Map<DateTime, int> spent,
}) => [
  for (var i = 0; i < 6; i++)
    if (DateTime(start.year, start.month + i) case final month)
      PeriodPoint(month: month, amount: spent[month] ?? 0),
];

/// First month of the chart window after [picked]. Stays put while [picked]
/// is inside it; otherwise [picked] lands 4th, but the window never runs
/// past now.
DateTime chartStart({
  required DateTime now,
  required DateTime start,
  required DateTime picked,
}) {
  final at = _monthIndex(picked) - _monthIndex(start);
  if (at >= 0 && at <= 5) return start;
  final latest = DateTime(now.year, now.month - 5);
  final want = DateTime(picked.year, picked.month - 3);
  return want.isAfter(latest) ? latest : want;
}
