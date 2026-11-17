# mibu — feature catalog

Source: Claude Design “mibu” (https://claude.ai/artifact/25RLRcYScmmPDzjBvg9Zz8). Screen numbers are canvas IDs (boards reorganized 2026-10-10: one leading number per module, 02 home · 03 pockets · 04 stats · 05 settings · 06 entry · 07 categories · 08 search/detail/edit · 09 transactions · 10 showcase · 99 proposals); use them in issues. All amounts in the design are sample data.

This catalog records the design and current product rules. It is not an implementation checklist: implemented screens are marked **Built**, deferred or proposal items are labeled explicitly. Period and budget behavior follows [period-ledger.md](period-ledger.md) and [mvp.md](mvp.md); the app uses payday periods, not opening balances or a cumulative monthly-balance model.

## Global rules

- Locale `id-ID`, whole-rupiah IDR, thousands separator (`Rp4.530.000`), week starts Monday.
- Compact format: ≥1jt → `Rp4,53jt`, ≥100K → `Rp450K`, ≥1K → `Rp6,7K`. Expenses use `-`, income `+`, forecasts `± `. Tabular numerals.
- UI copy is lowercase and casual, in `app_id.arb`. Use “pengeluaran / pemasukan”, not “keluar / masuk”.
- Icons: HugeIcons, rounded stroke 1.5.
- Future dates cannot be selected for entries; available period navigation depends on the screen.

## 01 · Onboarding and account

- **01.1 onboarding — Built.** Three slides (pockets · daily allowance · log in 3 seconds), story-style progress, tap a segment to jump, `lewati` / `mulai sekarang` → 01.2.
- **01.2 sign in — Deferred.** One button for sign-in and sign-up, no email/password.
  - iOS: `lanjut pakai apple` (primary) + `lanjut pakai google`. Android: Google only.
  - Use official brand buttons. Emoji stickers rotate slowly in the illustration (40s).
  - 01.2c / 01.2d are system sheets (Google Credential Manager / Sign in with Apple), not app UI.
- **01.2e signed in — Deferred.** `halo, {nama} 👋`. New account → 01.4, existing account → 02.1.

## 01.4 · Initial setup

The shipped setup asks for a payday and optionally a period budget; it does not ask for an opening balance. See [period-ledger.md](period-ledger.md). First-run flow is implemented in `apps/mobile/lib/ui/features/onboarding/` and `setup/`.

- **01.4 payday and budget — Built.** Payday choices 1, 10, 15, 25, 28, end of month; budget may be skipped. `nanti aja` continues to home.
- **01.4b first pockets — Built.** “mau mulai pasang limit ke apa?”: multi-select presets (makan, ngopi, ojol, tagihan, hiburan, belanja, anabul, liburan) with monthly limits; “N dikasih limit”, “ringkasan limit”. Summary compares total limits with the budget when one is set.

## 02 · Home

**02.1 home — Built.** The hero shows remaining budget for the selected payday period; there is no opening-balance toggle or cumulative balance chart. The period budget is optional. See [period-ledger.md](period-ledger.md).

- Header: logo, MonthPicker, search button → 08.1.
- Hero: remaining budget; the “?” opens “dari mana angkanya?” explaining the calculation with the user’s values.
- Payday-period context and safe-to-spend chip follow [mvp.md](mvp.md#safe-to-spend-today); weekend paydays can be shifted to Friday or kept on their scheduled date. Payday income logged up to three days early starts the period on its actual date; a late payday does not extend a period.
- When the budget is exceeded, show `rem dulu ya · N hari lagi` and the amount over budget. On payday, show `gajian hari ini` + `udah gajian? catat`; when late, show `! gajian telat n hari` + `gajian belum masuk? catat`. These open 06.1 as income in the payday category, with the last salary shown as a hint; typing replaces it, and saving without typing uses that amount.
- For a prior period, `rata²/hari · Rp…`. The home view clamps its selected month to the current month.
- Four leading pockets (% used), `lihat semua` → 03.1.
- `baru aja`: up to five latest transactions → 08.2, `lihat semua` → 09.1.

## 03 · Pockets

**03.1 pockets — Built.** A pocket is an expense category with a limit; it is not a separate data entity. Budget and limits apply to the selected payday period.

- Hero `sisa jajan {bulan}` = sum of pocket limits − spending in those pockets.
- “?” explains pocket allowance (sum of limits minus pocket spending) versus remaining budget (budget minus all expenses, including expenses outside pockets). If pocket allowance exceeds remaining budget, show the warning and tell the user to follow the smaller amount.
- Jars represent limited categories, filled by percentage used and ordered by most spent. Categories without limits appear separately. Statuses: `aman`, `hampir abis` (≥85%), `belum kepake`; show remaining allowance and approximate daily amount through the period end. Over 100%: `! lewat limit`, amount over the limit, days remaining, and `naikin limit` → 07.3.
- `atur limit` → 07.3. `copot limit` opens LimitOffSheet; removing a limit keeps the category and its transactions. Confirmation reports the effect, and the toast has `batalin`.
- `+ pasang limit` opens a sheet listing expense categories without limits, ordered by current-period spending, with usage details. Selecting one opens PocketLimit; existing transactions count immediately. The empty state says `semua buat apa udah pakai limit`; `bikin kategori baru` → 07.2. Income categories cannot have limits.
- “belum ada limit · Rp… bulan ini” + `semua` → 07.1. If none exist, show `pasang limit pertama`.
- `isi ulang` is deferred. `impian` (goals) is a proposal; its flow is not designed.

## 04 · Statistics

**04.1 statistics — Built.** Period, yearly rhythm, and context work: [#33](https://github.com/choiruladamm/mibu/issues/33) (parent #6).

- Week / month / year toggle (04.1a/b/c), period navigation ‹ ›, total and change versus the prior period.
- Bar chart; future bars are `belum`, with average line and tap-to-see amount.
- `sekilas`: highest spend · lowest spend · daily / period / monthly averages.
- `ritme budget`: spending percentage versus elapsed-time percentage; states `aman` / `hampir abis` / `lewat budget` / `di bawah budget`. Uses the user-set period budget, not the sum of pocket limits; see [mvp.md](mvp.md#statistics). For week/month, `hampir abis` starts at ≥85%. If the current period has no budget, show `pasang budget bulanan biar mibu bisa ngecek ritme kamu` → BudgetSheet 00.16.
- `larinya ke mana`: four leading categories (stacked bar + list).

## 05 · Settings

**05.1 settings — Built.**

- Setup cards: `budget bulanan` → BudgetSheet 00.16, `N limit` → 03.1. The `mulai tgl 1` control is deferred and not in the build.
- Money: `buat apa aja · nama, ikon & limit` + stack of three frequently used icons (+n remaining) → 07.1; `limit bulanan` → 03.1.
- Payday: date and next-payday status → PaydaySheet 00.24 (05.1e–g), with choices 1 · 10 · 15 (tag `umum`) · 25 · 28 · end · other… (1–31 grid). Weekend dates can be shifted to the previous Friday or kept unchanged. Holiday-calendar support is an undecided idea ([#42](https://github.com/choiruladamm/mibu/issues/42)). Changes apply according to [payday-change.md](payday-change.md).
- Habits: `pengingat harian` (21.00, switch), `rekap mingguan` (switch) — deferred.
- Privacy: `sembunyiin nominal` → three modes in [hide-income.md](hide-income.md). `kunci app ›` → app-lock settings in [app-lock.md](app-lock.md).
- Appearance: light / dark / auto — deferred; current build is light only.
- Data: `ekspor ke csv`, `import dari csv` (05.1l–o, [import.md](import.md)). Full `backup & pulihin` is deferred.
- Version footer.

## 06 · Entry

- **06.1 add entry — Built.** Open from the + button on every tab.
  - Segmented expense / income control, calendar button → DateSheet, DayStrip for quick date selection.
  - Rupiah keypad: 1–9, `000`, 0, backspace. Maximum 10 digits; automatic thousands separators; font scales 68 → 54 → 44.
  - Impact bar: `🍜 jatah makan abis ini · sisa X` / `kelebihan X`. Income shows the period impact.
  - Category chip → 06.2, `+ catatan` → NoteSheet.
  - `simpan pengeluaran` / `simpan pemasukan` → home.
- **06.2 “buat apa?” sheet — Built.** Search or create categories; limited categories show `sisa Rp…` (bold at ≥85%). Category is optional. `terakhir` offers the last category + place in one tap; category grid, `di mana` field, `atur` → 07.1.

## 07 · Categories (“buat apa”)

- **07.1 manage categories — Built.** Grid; limited categories show `limit Rp…`, others show `N catatan` / `belum dipakai`. Footer: 🫙 “yang ada limit jadi toples di tab kantong…”. Tap icon (pencil badge) → IconSheet 00.21, saves immediately with undo toast; tap name → edit 07.3; long-press and drag to reorder. Trash button enters delete mode (07.1d): `hapus yang mana?`, − badge (tiles wobble), tap − → 07.4, `selesai` exits. `lain-lain` (uncategorized transactions; not a database row) is locked. `gajian` is locked only in delete mode; its name and icon remain editable. Neither can be deleted.
- **07.2 create / 07.3 edit — Built.** One widget (`mode=new|edit`). Name + emoji suggested from keywords (makan, kopi, kucing, bensin, …), with three emoji suggestions and a 16-icon palette. `masuk ke`: expense / income.
  - Optional monthly limit switch; default off except when opened from 03.1. Limits apply only to expense categories. PocketLimit 00.15 supports typing, slider, and presets Rp100K · 300K · 600K · 1jt.
  - Edit shows usage (e.g. `12 catatan · Rp840K tahun ini`) and delete action → 07.4. Removing a limit is immediate with undo and leaves the edit screen open.
- **07.4 delete category — Built.** Transactions must be moved to another category or left uncategorized. Hold `hapus` for one second; success state includes `batalin`.

## 08 · Search, detail, and edit

- **08.1 search — Built.** Search category/place in the selected period, type filter, SearchSummary (total, average, insight, draggable daily ticks to filter a day), first three results + `liat N lagi`, search suggestions, empty state.
- **08.2 receipt/detail — Built.** Receipt card: place, category, amount, time, type, recurring status, note, receipt photo (photo feature deferred). Pocket impact. Actions: delete, `patungan` (deferred), `catat lagi`, edit → 08.3.
- **08.2b/c delete — Built.** ConfirmModal shows before/after pocket impact, then a `dihapus` stamp and undo toast.
- **08.3 edit transaction — Built.** Amount, category (change or clear), place, date, note; recurring controls are deferred. Per-field `diubah` badge, `N perubahan · batalin`, and disabled `simpan perubahan` when unchanged.

## 09 · Transactions

**09.1 all transactions — Built.** Month carousel (swipe / left-right tap = ±1 month, cross-year label `des 24`); tap `oktober ▾` → MonthMenu 00.8, with months before the first transaction locked; `balik ke okt 2026 ›` when away from the current period; no dots. Tiles for income / expenses / difference; all / expense / income filters; daily groups (hari ini · kemarin · sen 12 okt) + daily total; empty state; end-of-list `liat {bulan lalu}`. “Month” navigation maps to payday periods; see [period-ledger.md](period-ledger.md).

## 00 · Shared components

| ID | Component | Notes |
|---|---|---|
| 00.3 | TabBar | Floating capsule, four tabs + separate + button |
| 00.4 | TxRow | Symmetric two columns, fixed height 64: left category + tag chip (first tag + “+n”) / place • note; right amount / time; default href 08.2, tap chip → 08.1 |
| 00.5 | NavHeader | Back, title, subtitle, search/close/edit actions |
| 00.6 | ConfirmModal | Before/after impact bar; paired with undo toast |
| 00.7–8 | MonthPicker + MonthMenu | 3×4 grid, mini bar per month, future periods locked in MonthMenu |
| 00.9 | TextField | Floating label; focus/error/disabled; text/search/rupiah types |
| 00.10 | AmountField | Large amount input + remaining/overage hint |
| 00.11 | DayStrip | One week, swipe to change week, relative caption |
| 00.12 | DateSheet | Month calendar, dots for transaction count, duplicate warning |
| 00.13 | NoteSheet | Max 80 characters, max 3 tags, recent notes |
| 00.14 | SearchSummary | Insight + draggable daily ticks |
| 00.15 | PocketLimit | Limit input (“limit per bulan”): typing, slider (remaining-budget line), preset chips; used in 07.2/07.3 and 01.4b |
| 00.16 | BudgetSheet | “budget bulanan”: AmountField + keypad (max 12 digits), live total limits and budget comparison; empty budget prefills sum of limits rounded up to Rp500K; `simpan` / `hapus budget`; opened from 00.15, 03.1, 04.1, 05.1 |
| 00.19 | MetaLine | One-line metadata separated by 3px round dots (#BDBDBD, #737373 on ink), never literal `·`; section title left (15/600), muted info right (13, + › if tappable) |
| 00.17 | AmountKeypad | Rupiah keypad: 1–9, `000`, 0, backspace |
| 00.18 | UndoToast | `batalin` toast |
| 00.20–21 | Icons + IconSheet | Icon library and icon picker sheet |
| 00.22 | LimitOffSheet | Remove limit; show impact before confirmation |
| 00.23 | HeroBudget | Home remaining-budget hero |
| 00.24 | PaydaySheet | Payday date; [payday-cycle.md](payday-cycle.md) |
| 00.25 | NumbersSheet | “dari mana angkanya” |
| 00.26 | PeriodBars | Spending by period |
| 00.29 | HideSheet | Hide amounts; [hide-income.md](hide-income.md) |
| 00.30 | ImportSheet | CSV import; [import.md](import.md) |
| 00.31 | PinPad | Six dots + 3×4 keypad; lower-left slot is biometrics (empty for PIN-only). States: normal / locked (digits + delete dimmed 35%, biometrics remains active) / bioHidden. Used by app lock (#3) |

## 99 · Proposals

Draft boards; not decided or implemented unless stated otherwise.

| ID | Proposal |
|---|---|
| 99.1 | Period income card and flow sheet ([#39](https://github.com/choiruladamm/mibu/issues/39)) |
| 99.2 | Access transactions from home ([#40](https://github.com/choiruladamm/mibu/issues/40)) |
| 99.3 | Notes + tags on transaction detail ([#5](https://github.com/choiruladamm/mibu/issues/5)) |
| 99.4 | (#4, #5) Tags: list, create, rename, merge, delete + undo, quick tags in NoteSheet, TagManage |
| 99.6 | Budget label and chart pill overlap ([#41](https://github.com/choiruladamm/mibu/issues/41)) |
| 99.10 | (#3) App lock: Face ID / fingerprint + PIN, lock screen, lockout from 30 sec → 15 min, PinPad (00.31), [app-lock.md](app-lock.md) |

## Data entities

- **User** — uid, name, email (may be Apple relay), Google/Apple provider. No account or backend in the current app.
- **Profile / budget** — payday, period budget, and period settings. There is no opening-balance field in the current model.
- **Category** — emoji, name, type (expense/income), order. In UI, called “buat apa”; expense categories with a limit appear as pockets. See [mvp.md](mvp.md#categories-limits-and-pockets).
- **Transaction** — type, amount (integer IDR), category, place, date + time, note (≤80), tags (≤3), recurring status, receipt photo, receipt number. Soft delete supports undo; recurring, receipt photo, and receipt number remain deferred/absent where not implemented.
- **Goal** — fields not defined; proposal only.
- **Settings** — reminders + time, weekly summary, hidden amounts, app lock (#3), theme. Several settings are deferred; see 05.1.

## Deferred and unresolved

- Backend, offline sync, and full backup/restore.
- Reminder schedule and weekly summary; recurring-entry engine and edit-one/edit-all behavior.
- Top-up, split payment, goals, receipt photo/number, logout, account deletion.
- Dark palette and Android biometric-specific behavior need device/design work.
- SearchSummary daily ticks are implemented; further interaction proposals are separate.
