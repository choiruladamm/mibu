# mibu — hide income

**Implemented 2026-10-03.** Design: boards 05.1h–i, 06.1e, 09.1f–h, 00.29 HideSheet + note on row 02 (formerly proposal 99.5) in the “mibu” artifact. Summary in [mvp.md › Hide amounts](mvp.md#hide-amounts).

## Why

You may open mibu in a crowded place (office, café, commuter train). Daily expenses are fine to show; **salary / income** is sensitive. The old mode (`Rp•••` for everything) hid too much: remaining budget, safe-to-spend, and spending were hidden as well.

## Model: one setting, three choices

`profiles.hideAmounts` changed from bool to enum:

| Value | Label | What is masked |
|---|---|---|
| `none` | `nggak` | Nothing |
| `income` | `pemasukan aja` | Income + derived values |
| `all` | `semua nominal` | All amounts, preserving the old switch behavior |

Settings privacy (05.1h): replace the switch with a row + ›, with the current mode as its subtitle. Tap to open a sheet with three choices and a live three-row preview (05.1i). Save → toast with undo.

## What `pemasukan aja` hides

- Each income amount: TxRow (`amount > 0`), and income transaction receipts (08.2).
- Period card in 09.1: income, remaining income (= income − expenses), the difference “up Rp… from September”, and the total for days with payday (09.1f).
- Income entry in 06.1 (06.1e): the amount being typed stays visible; “income this period becomes” is masked as `Rp•••`, and the proportion bar is emptied.
- Search (08.1): income insight + total when results contain income. Added to the note during implementation.

Does not hide: home (remaining budget, safe-to-spend, spending), pockets, statistics, budget, or individual expense rows. Since [period-ledger.md](period-ledger.md), the home screen no longer shows a balance, so it has no amount that can be used to infer salary.

## Peek

- In `income` mode, the home hero is not masked, so tapping it is no longer a way to peek. Instead, add a “peek for 5 seconds” chip to the 09.1 summary card (09.1g).
- After 5 seconds / when switching screens → mask again. `peekProvider` + `Timer`, reset on router changes.
- No Face ID.

## Out of scope

- “Payday received” notification / widget: the app has neither.
- Screenshots and app switcher: outside this proposal.
- CSV export: contains original amounts.

## Decisions

- Peek uses a 5-second timer in both `income` and `all` modes. Tap again to close.
- No “tap ••• anywhere”: only primary amounts (home hero / pocket / receipt) and the 09.1 chip. Sheet and toast copy: “tap angka utama buat intip 5 detik”.
- Sheet button is `simpan` (not “simpan · mode”; UI copy must not contain a literal “·”).
- `hideAmounts` is now an integer enum (`HideAmounts`), edited in place in `schemaVersion` 1.
