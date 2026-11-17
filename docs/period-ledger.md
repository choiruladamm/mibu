# mibu — ledger by payday period

Decision made 2026-10-03. The logic and interim UI are implemented; final design followed (see [Status](#status)). This replaces the “cumulative balance” model (opening balance + all entries) in [mvp.md](mvp.md) and the hero toggle in [features.md](features.md). Period rules remain in [payday-cycle.md](payday-cycle.md).

## Summary

mibu is a **ledger of income and spending for each payday period**, not a mirror of a bank account. Bank balance is outside this app's scope. Its job is to record transactions, set a budget per period, and show how much is safe to spend.

The intended user is an employee, or an employee who also freelances, who knows when payday is. Payday is the single reference point for all figures. No amount carries across periods.

## Status

Logic and final design (canvas 2026-10-03) are implemented:

| Area | Board | Details |
|---|---|---|
| Domain + schema + repository | — | Cumulative balance, opening balance, and hero toggle removed; `Totals` = `income` + `spent` per period; safe-to-spend uses budget only |
| Hero | HeroBudget 00.23 / 00.23b | Remaining budget + “?” beside label · “dari budget Rp… • gajian lagi N hari” (date range for past periods) · when budget is empty, dashed “atur budget periode ini” card + “isi budget biar dapet aman jajan” chip |
| Home chart | PeriodBars 00.26 (option a) | Spending per period, dashed line = current-period budget, 6 periods through current, pill “berjalan • okt” / “lewat budget”, no forecast |
| Number explanation | NumbersSheet 00.25 | 3 cards (remaining budget · safe-to-spend per day · remaining pocket allowance); opening-screen card is ink; used on home and pockets |
| Setup | 01.4 / 01.4c / 01.4d | Payday date first + “current period” card, optional budget without quick chips, safe-to-spend preview only when a budget is entered; 01.4b “/periode”, without budget “total limit per periode” |
| Budget sheet | 00.16 | “budget per periode”, “periode lalu kepake Rp…”, “Rp… / periode” |
| Payday sheet | 00.24 | No safe-to-spend row, note “tgl 25 jatuh hari minggu → dihitung jumat” |
| Add transaction | 06.1b–d | “sisa budget abis ini” / “pemasukan periode ini jadi” / hide bar when no budget |
| 09.1 | 09.1 / 09.1d | Date range under title, ink remaining-income card + change, income and spending vs previous period, “—” + “catat gajian dulu” |

The proposed home budget toast is tracked in [#22](https://github.com/choiruladamm/mibu/issues/22).

Payday changes take effect **from the next period** (immediately if still in the setup period); decided 2026-10-03 and reflected in the 00.24 sheet note. If they took effect immediately, the running period would change length midstream, move entries between periods, and could grant the period's budget twice (25 → 10 on Oct 16: old period ends Oct 9, new period gets a full budget again).

## Why change the model

Cumulative balance = `openingBalance` + entries since `openingAt`. In real use this creates problems:

- Salary on Sep 25 entered on Oct 3 is excluded from balance (`at < openingAt`), although the user considers it part of that period.
- Counting all entries duplicates the amount the user typed as opening balance (which already included that salary).
- Skipping opening balance (0) means balance comes only from entries, but old entries are still discarded.
- “Balance” sounds like a bank balance, which mibu cannot know.
- Income is not a budget. A 20m salary does not mean the user can spend 20m.

These issues disappear when amounts represent only “entries in this period”.

## Decisions

1. **Payday periods are authoritative.** The only time axis throughout the app: budget, limits, pockets, safe-to-spend, stats, search, and charts.
2. **No cumulative balance, opening balance, or carryover.** Money left from the previous period does not carry forward. Bank balance is outside mibu's scope.
3. **Remaining income is analytics.** Label it “sisa pemasukan”, not “sisa gaji”, because freelance income, bonuses, and other income count too. Show it in stats, not the hero.
4. **Budget is the daily reference.** The hero shows remaining budget only. Safe-to-spend draws only from budget and is **never** inferred from income.
5. **No budget → prompt, not guess.** Hero and chip invite the user to “atur budget periode ini”. Other features continue to work.
6. **Setup requires nothing.** Everything can be skipped and defaults are safe. A budget is optional during setup.
7. **Non-salary income counts** toward period income.
8. **Budget sheet shows “periode lalu kepake Rp…”** as a hint (starting with the second period). Income is not used to suggest a budget, avoiding the impression “spend your salary”.

## Formulas

All values are for period `P` (period rules: [period.dart](../apps/mobile/lib/domain/period.dart)). The entry date determines its period; `deletedAt` must be null. **There is no `openingAt` filter.**

```
income(P)           = Σ income transaction amounts in P
spent(P)            = Σ expenses in P
remainingIncome(P)  = income(P) − spent(P)                  -- analytics
remainingBudget(P)  = budget in force for P − spent(P)
remainingPocket(P)  = Σ pocket limits − spending in pockets -- 03.1, unchanged

safe = floor((remainingBudget + spendingToday) / daysLeftInPeriod) − spendingToday
```

`daysLeftInPeriod` means days through the end of the period, including today (`period.daysLeft`). Other safe-to-spend rules remain: budget exceeded → “rem dulu ya”; `safe < 0` → “kebablasan”; payday / late payday → prompt to record salary (`paydayInfo`). The difference is **no balance side**, so there is no `min(balance, budget)`.

Example: salary 15m on Sep 25, freelance 2m on Oct 2, budget 7m, 3m already spent.

| | Value |
|---|---|
| period income | 15m + 2m = 17m |
| remaining income | 17m − 3m = **14m** |
| remaining budget | 7m − 3m = **4m** |
| salary − budget difference | amount not allocated (savings) |

Freelance income increases remaining income; it **does not affect the budget** unless the user raises it.

## Removed

- Cumulative balance, `profiles.openingBalance`, `profiles.openingAt`, and the balance step in 01.4.
- Hero toggle balance ⇄ remaining budget: `BalanceMode`, `profiles.heroMode`, `profiles.heroHintSeen`, hint “tap buat liat sisa budget”.
- Balance side of safe-to-spend (`safeShare` becomes budget-only).
- Next-month balance forecast (requires cumulative balance).
- The note in mvp.md that “balance only counts entries since opening balance”.

## Edge cases

| # | Case | Handling |
|---|---|---|
| 1 | Salary has not been recorded in the new period | Period income 0 → remaining income shows “—”, not a negative value. Existing “record salary” chip is a reminder. |
| 2 | Spending exceeds income for the period | Remaining income is negative; show it as-is in stats. |
| 3 | Income the day before payday (e.g. freelance on the 23rd) | Belongs to the previous period. The entry date decides. |
| 4 | Salary arrives early | `paydayEarlyDays` remains: period starts on the recorded payday date, and the income belongs to the new period. |
| 5 | Backdated entry before install / first payday | It still belongs to a period via `periodsFromStart`, and appears in history and stats. No special hint is needed. |
| 6 | No budget, safe-to-spend | Prompt to set a budget; show no amount. |
| 7 | Change payday mid-period | Existing rule: effective next period (immediately if still in setup period). Split at the change and prorate budget: [payday-change.md](payday-change.md). |

## Pockets

Pockets are categories with limits. The pockets screen shows the no-limit section and warns when remaining pocket allowance exceeds remaining budget. Uncategorized entries reduce remaining budget but do not appear as a pocket. The virtual “other” pocket proposal is tracked in [#43](https://github.com/choiruladamm/mibu/issues/43).
