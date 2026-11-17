# mibu — data import

**Implemented on 3 Oct 2026** (05.1l–o, ImportSheet 00.30). Included in [mvp.md](mvp.md#csv-import).

## Principles

mibu users are casual. Import should take **one tap, with no decisions**. Guess what can be guessed. If a guess is wrong, the user can fix it later with existing features (manage categories, undo).

## Scope

| option | effort | notes |
|---|---|---|
| **A. mibu's own CSV** (export round-trip) | small | format is fixed ([mvp.md › CSV export](mvp.md#csv-export)); parser is the inverse of `transactionsCsv` |
| B. Other apps' CSV (Money Lover, Spendee, Wallet) | medium | columns vary by app; needs column mapping / presets per app ([#44](https://github.com/choiruladamm/mibu/issues/44)) |
| C. Bank statements (BCA/Mandiri PDF/CSV) | large | messy formats; categories must be guessed from descriptions ([#44](https://github.com/choiruladamm/mibu/issues/44)) |
| D. Full backup (JSON of all tables, #13) | medium | includes budget, limits, period rules, and profile. This is the deferred "backup & pulihin" feature |

**Start with A.**

- Real use case: changing phones / reinstalling. Transaction history is what hurts to lose. Budget + limits take 1 minute to set up again (01.4).
- D connects to "backup & pulihin" later. The formats differ, so keep them separate.
- B helps bring in new users. Later, column mappings can be added on top of parser A, without wasting the work on A.

## Flow

`pengaturan 05.1 → impor dari csv → pilih file → sheet ringkasan → impor → toast "142 masuk" + batalin`

1. `impor dari csv` tile below `ekspor ke csv`.
2. File picker → parse.
3. Summary sheet (read-only):
   - `142 transaksi baru` + date range
   - `5 udah ada, dilewatin`
   - `3 buat apa baru` + emoji + name
   - `2 baris nggak kebaca` (if any)
4. Tap `impor` → insert in one Drift `transaction()`.
5. Toast + `batalin`.

The user makes only one decision: import or not.

## Parsing

Pure function `parseTransactionsCsv` in `domain/csv.dart`.

- Remove BOM, accept CRLF/LF, RFC 4180 quoting (including multiline fields).
- Header must exactly match `csvHeader`. If it differs → reject with a clear message; do not guess.
- `jenis`: `pengeluaran` → negative amount, `pemasukan` → positive.
- `tanggal` + `jam` → local `at` time.
- Files re-saved by Excel (id) remain readable: separator `;` (detected from the header), date `d/M/yyyy`, time `H:mm` / `HH:mm:ss` (seconds are dropped). `MM/dd` (US) is unsupported because it is ambiguous with `dd/MM`.
- `tag` is space-separated.
- Corrupt rows: skip and count them; do not fail the entire import.
- Amounts are limited to 1–9,999,999,999 rupiah, matching the 10-digit input limit; amounts outside the limit count as corrupt rows ([#35](https://github.com/choiruladamm/mibu/issues/35)). Future dates are still stored; statistics count them when their date arrives.

## Duplicates: skip automatically

- Key: `at` (minute) + `amount` + category name + `note`.
- Existing rows are skipped; only the count appears in the summary. No per-row review.
- Importing the same file twice is safe (idempotent).
- Ceiling: two identical transactions in the same minute are deduplicated into one. Rare, accepted.

## Categories: create automatically

- Match name + `jenis` against existing categories (case-insensitive, trim). Re-importing mibu's own export matches 100%, adding nothing.
- No match → create a new one using `emoji` from the CSV (empty → miscellaneous emoji). No limit (not a pocket).
- Empty `kategori` → miscellaneous.
- Merge / rename → use the existing category management screen. No mapping UI in the summary.

## Excluded

- Budget, limits, period rules, and profile. CSV contains transactions only.
- Imported income is included in its period totals ([period-ledger.md](period-ledger.md)).

## Undo

Keep transaction IDs + new categories in memory. `batalin` = soft-delete those IDs. Use the existing undo toast pattern; no `importId` column is needed.

## Code

- `domain/csv.dart`: `parseTransactionsCsv` (`null` = different header) + `planImport` (duplicates, new categories).
- Repo: `importCsv(plan)` → IDs written; `undoImport` = soft delete.
- UI: `settings/views/import_sheet.dart` (`importCsv`, ImportSheet 00.30), row in 05.1.
- Dependency: `file_picker` (`FilePicker.pickFile`, `.csv` filter).
