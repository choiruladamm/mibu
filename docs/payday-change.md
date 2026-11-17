# mibu — changing payday: transition periods

Decision made 2026-10-03 and implemented. Boards 00.24, 00.25, 05.1e–g and the note in row 02 have been aligned. This extends [payday-cycle.md](payday-cycle.md) (rule 4: a payday change starts next period) and case 7 in [period-ledger.md](period-ledger.md). That document called duplicate period names “rare, leave it for now”; the effects turned out to go beyond naming.

## Problem

Changing payday writes a new rule starting at `current.end` (`setPayday`). `SegmentedResolver` computes the new rule's cycle at that date, clipping its start. This creates a **transition sliver (S)** between the running period (P) and the first full period under the new rule (Q).

Example: current period is in October 2026, with no weekend shift:

| change | P | S | Q | S label |
|---|---|---|---|---|
| 25→1 | Oct 25/9–25/10 | 25/10–1/11, 7 days | Nov 1/11–1/12 | **Oct (duplicate)** |
| 25→10 | Oct 25/9–25/10 | 25/10–10/11, 16 days | Nov 10/11–10/12 | **Oct (duplicate)** |
| 28→15 | Oct 28/9–28/10 | 28/10–15/11, 18 days | Nov 15/11–15/12 | **Oct (duplicate)** |
| 16→15 | Nov 16/10–16/11 | 16/11–15/12, 29 days | Dec 15/12–15/1 | **Nov (duplicate)** |
| 31→1 | Oct 30/9–31/10 | 31/10–1/11, 1 day | Nov 1/11–1/12 | **Oct (duplicate)** |
| 25→20 | Oct 25/9–25/10 | 25/10–20/11, 26 days | Dec 20/11–20/12 | Nov |
| 15→16 | Oct 15/10–15/11 | 15/11–16/11, **1 day** | Dec 16/11–16/12 | Nov |
| 10→25 | Oct 10/10–10/11 | 10/11–25/11, 15 days | Dec 25/11–25/12 | Nov |
| 1→25 | Oct 1/10–1/11 | 1/11–25/11, 24 days | Dec 25/11–25/12 | Nov |

Pattern: when payday moves earlier (or crosses from the 16th to 15th), S gets **the same label** as P. When moved later, labels remain ordered, but S can be as short as one day.

## Effects on existing features

Duplicate name (S = P):

- **09.1, month menu, search:** `periodForMonth(okt)` returns P, so S cannot be opened. Entries in S appear missing from the list although they remain in the database. This remains true after S passes.
- **Home:** `totals.spent` is keyed by period label, so P + S spending is combined under “Oct” with one budget. Remaining days use S.
- **Pockets:** use `currentPeriodProvider` = S, with a full budget again. Its numbers differ from home.
- **Stats:** safe because navigation uses `periodOf`.

Short S (ordered label):

- A full budget is available for a one-day period, so safe-to-spend that day equals the entire budget. The “starts next period” rule is meant to prevent this.
- Weekly stats limit = `budget × 7 ÷ length`, so it becomes 7× the budget.

Frequency: only when a user changes payday outside the setup period. It is rare and loses no data, but looks like data loss when it occurs.

## Constraints

- Code looks up periods by month name (`homeMonthProvider`, `monthTransactionsProvider(month)`, `totals.spent[key]`). Therefore **one name = one period** must hold, unless all these locations are changed.
- A period in the past must not change (rule 4).
- In reality, S is the period between two actual paydays (salary on Oct 25, then Nov 1). A short period is valid. Its name and budget are the problems.

## Options

**A. Merge duplicate S into P.** If S has P's label, extend P through the start of Q. For 25→1, October becomes Sep 25–Nov 1 (37 days). The label stays unique and the budget is not duplicated; change `SegmentedResolver.periodOf` (+ `prev`).
Downside: moving payday earlier can make P much longer (25→10: 46 days, 16→15: 60 days). Two salaries also land in one period, making P's remaining-income total large.

**B. A + prorate S budget.** Keep ordered-label S as its own period, but set its budget to `budget × length of S ÷ length of Q`. Example: 15→16, one day: budget/31. Adds one point in `watchBudget` / view model and a sentence in “where did this number come from?”.

**C. Shift S label forward (+1); shift Q and later periods too.** Periods remain short or normal, but all labels after the change are permanently one month off (16→15: Dec 15–Jan 15 becomes “Jan”). This breaks the rule “month with the most days”.

**D. Replace all month-name keys with periods.** Most correct, but touches nearly every provider and the month menu. Too large before release.

## Decision

Option **B**. The details:

1. **Merge duplicate S into P.** When S shares P's label, extend P through the start of Q (25→1: October = Sep 25–Nov 1). Keep ordered-label S as a separate period. Merging ordered S too would hide its name from the month menu (15→16: October runs through Nov 16, then December, so November is skipped).
2. **Allow long periods.** Payday usually changes because of an employer, not user choice. A 46–60 day interval contains two salaries and is valid. Only its budget is unusual, handled in item 3. Show the new range before saving to avoid surprises (item 4).
3. **Prorate the transition-period budget.** A transition period is one with a rule boundary inside it or at its end: merged P, or standalone S. Q is the first full period under the new rule.
   - Budget = `budget × transition period length ÷ Q length`, rounded to rupiah. One formula handles both short and long periods: 7 days gets 7/30; 60 days gets 60/30, so safe-to-spend per day stays the same as a normal period.
   - Divide by Q, not an average 30, because Q is the first normal period on the new payday rhythm.
   - **Pocket limits use the same factor.** Otherwise total pocket limits can exceed the budget, and pocket figures disagree with home. Downside: a monthly expense such as rent is also prorated in a short period. This happens once, and its limit can be changed for that period.
   - Calculate the factor; do not store it (derived values are not persisted). Stored budget and limit values remain normal-period amounts. 00.16 and “where did this number come from?” show the prorated amount with an explanatory line.
4. **Preview in sheet 00.24, no extra confirmation sheet.** As soon as the user picks a date, show “periode ini jadi 25 sep – 31 okt” below it, followed by “37 hari” and “budget Rp…” using `MetaLine`. Show only if the running period changes (outside setup period). Toast + undo remains as a safety net.

This preserves one period per label, skips no month, and avoids granting a full budget to a period that is not a normal length.

## Work sequence

1. ✅ **Domain + test:** `SegmentedResolver` merges duplicate S into P (`periodOf`, `prev`, `next`). Added a pure transition-period factor function (null for normal periods). One test per row in [Problem](#problem): range, label, factor.
2. ✅ **Data:** factor is applied when reading budgets (`budgetInPeriodProvider` / `watchBudget`) and pocket limits (`watchPockets`, `watchCategories`). Stats follow automatically via period budget.
3. ✅ **UI:** 00.24 preview, explanatory line in 00.16 and “where did this number come from?”, copy in `app_id.arb`.

Implementation notes:

- `Period.normalDays` (null = normal period) and `prorate(amount, period)` are in `domain/period.dart`. Prorated values: `budgetInPeriodProvider`, pocket budget, and `Pocket.budget`. Edit sheets (00.16, limit, category form, total limits in 05.1) continue using the configured values: `Profile.monthlyBudget` and `Pocket.limit`.
- `setPayday`: if a rule is already queued, update it (its start date stays the same). After a merge, `current.end` may extend past that rule date, so using `current.end` would create a third rule.
- `paydayChangeFrom` (domain) determines when the change takes effect; `setPayday` and the 00.24 preview use it. Preview calculates periods through `withPayday` + `SegmentedResolver`, so its values match the saved state.
- 00.24 preview has two lines: “periode ini jadi 25 sep – 27 okt” (15/600), then `MetaLine` “33 hari • budget Rp8,8jt” (13, gray).
- 00.24 toast: if the running period changes, “periode ini jadi sampai sen 9 nov”. Otherwise it remains “berlaku mulai …, periode ini selesai dulu”.
- 00.25 remaining-budget card shows “periode peralihan n hari, budget dihitung n/30”.
