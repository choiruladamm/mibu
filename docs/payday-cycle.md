# mibu — payday periods

A payday period runs from one payday to the next. Budgets, limits, pockets, safe-to-spend, monthly statistics, search, transactions, and the home chart use these periods. The [period ledger](period-ledger.md) explains how amounts are calculated.

## Period rules

- `Period` uses local, date-only boundaries `[start, end)`: the start is included and the end is excluded. `daysLeft` includes today when today is inside the period. Its ID is a month label, not a database key.
- A period is named for the month in which most of its days fall: payday on the 16th or later uses the ending month; earlier payday uses the starting month. For example, September 25–October 24 is “oktober”. `periodForMonth` maps a selected month to its period.
- The payday date is 1–31; 31 means the last day of the month. A date beyond the month's length is clamped to its last day; legacy 0 also means month-end. Setup defaults to 25.
- For a weekend payday, the user can keep the scheduled date or shift it to the previous Friday. The resolver supports supplied holidays, but the app has no holiday calendar. See [weekend payday](payday-weekend.md); the proposed holiday support is [#42](https://github.com/choiruladamm/mibu/issues/42).
- Salary in a category marked `isPayday`, recorded up to three days before the scheduled payday, starts that period on the recorded date; the earliest qualifying salary wins. Late salary does not extend a period.
- Rules apply to backdated entries before setup as well as new entries. Transaction `at` is local time; determine the period from its local date.
- A payday change normally takes effect at the next period, or immediately while still in the setup period. Transition periods can merge and prorate budget and pocket limits; see [changing payday](payday-change.md).

## Repository adjustments

The implementation is in [`domain/period.dart`](../apps/mobile/lib/domain/period.dart). `SegmentedResolver` selects the applicable `periodRules` segment; without a saved rule, the repository supplies a calendar-month rule. `CalendarMonthResolver` is also used by the fixture.

Budget and limit rows are looked up for a period using the latest applicable `periodStart`. A value is written only when saved, not when read. A null amount removes a budget or limit from that period onward. Historical values remain available. `transactions.at` is indexed; the local app has no `userId` or separate transaction-date column.

The salary marker is `categories.isPayday`. Period-related copy lives in `app_id.arb`; [copy_guard_test.dart](../apps/mobile/test/ui/copy_guard_test.dart) rejects a literal “bulan ini” in `lib/ui`.

Period-label and navigation work is tracked in [#20](https://github.com/choiruladamm/mibu/issues/20); payday detection is an idea in [#21](https://github.com/choiruladamm/mibu/issues/21). The original proposal is available in git history.
