# mibu — impor data

**Draft ide, belum fix.** Belum masuk [MVP_PLAN.md](MVP_PLAN.md). Kalau udah fix mau dieksekusi, baru di-mention di sana (ganti baris "Belum ada impor" di Risiko).

## Prinsip

User mibu itu casual. Impor harus **satu tap, nol keputusan**. Yang bisa ditebak, tebak. Kalau tebakannya salah, user benerin belakangan pakai fitur yang udah ada (kelola buat apa, undo).

## Scope

| opsi | effort | catatan |
|---|---|---|
| **A. CSV mibu sendiri** (round-trip ekspor) | kecil | format udah fix ([MVP_PLAN › Ekspor CSV](MVP_PLAN.md#ekspor-csv)), parser = kebalikan `transactionsCsv` |
| B. CSV app lain (Money Lover, Spendee, Wallet) | sedang | tiap app beda kolom, perlu mapping kolom / preset per app |
| C. mutasi bank (BCA/Mandiri PDF/CSV) | besar | format berantakan, kategori harus ditebak dari deskripsi. skip |
| D. backup penuh (JSON semua tabel) | sedang | ikut budget, limit, period rules, profile. ini fitur "backup & pulihin" yang ditunda |

**Pilih A dulu.**

- Kasus nyata: ganti HP / reinstall. Yang sakit kalau ilang itu riwayat transaksi. Budget + limit 1 menit diset ulang (01.4).
- D nyambung ke "backup & pulihin" nanti. Format beda, jangan dicampur.
- B buat narik user baru. Nanti tinggal nambah mapping kolom di atas parser A, kerjaan A nggak kebuang.

## Flow

`pengaturan 02.4 → impor dari csv → pilih file → sheet ringkasan → impor → toast "142 masuk" + batalin`

1. Tile `impor dari csv` di bawah `ekspor ke csv`.
2. File picker → parse.
3. Sheet ringkasan (read-only):
   - `142 transaksi baru` + rentang tanggal
   - `5 udah ada, dilewatin`
   - `3 buat apa baru` + emoji + nama
   - `2 baris nggak kebaca` (kalau ada)
4. Tap `impor` → insert dalam satu Drift `transaction()`.
5. Toast + `batalin`.

Keputusan user cuma satu: jadi impor atau nggak.

## Parsing

Fungsi murni `parseTransactionsCsv` di `domain/csv.dart`.

- Buang BOM, terima CRLF/LF, quoting RFC 4180 (field multiline juga).
- Header wajib persis `csvHeader`. Beda → tolak dengan pesan jelas, jangan nebak.
- `jenis`: `pengeluaran` → amount negatif, `pemasukan` → positif.
- `tanggal` + `jam` → `at` waktu lokal.
- `tag` dipisah spasi.
- Baris rusak: dilewatin + dihitung, impor nggak gagal semua.

## Duplikat: lewatin otomatis

- Key: `at` (menit) + `amount` + nama kategori + `note`.
- Yang udah ada dilewatin, cuma tampil jumlahnya di ringkasan. Nggak ada review per baris.
- Impor file yang sama dua kali aman (idempotent).
- Ceiling: dua transaksi identik di menit yang sama ke-dedup jadi satu. Jarang, diterima.

## Buat apa: bikin otomatis

- Cocokin nama + `jenis` ke kategori yang ada (case-insensitive, trim). Impor balik dari ekspor mibu sendiri = 100% nyambung, nggak nambah apa-apa.
- Nggak ketemu → bikin baru pakai `emoji` dari CSV (kosong → emoji lain-lain). Tanpa limit (bukan kantong).
- `kategori` kosong → lain-lain.
- Gabung / ganti nama → layar kelola buat apa yang udah ada. Nggak ada UI mapping di ringkasan.

## Yang nggak ikut

- Budget, limit, period rules, profile. CSV cuma transaksi.
- Saldo tetap dihitung dari transaksi ([PERIOD_LEDGER_PLAN.md](PERIOD_LEDGER_PLAN.md)), jadi pemasukan yang diimpor otomatis kebaca di periodenya.

## Undo

Simpen ID transaksi + kategori baru di memori. `batalin` = soft delete ID itu. Pola toast undo yang udah ada, nggak perlu kolom `importId`.

## Kerjaan (kalau jadi)

- Dep: `file_selector` (first-party) atau `file_picker`.
- `domain/csv.dart`: parser + test round-trip `parse(transactionsCsv(x)) == x`.
- Repo: `importTransactions(rows)` → `{inserted, skipped, newCategories, ids}`.
- UI: tile 02.4 + sheet ringkasan + string di `app_id.arb`.
- Docs: section "Impor CSV" di MVP_PLAN, update baris Risiko "Belum ada impor".

## Pertanyaan terbuka

- Design board buat sheet ringkasan belum ada. Perlu dibikin di artifact "mibu" dulu?
- Impor transaksi tanggal di masa depan: tolak atau terima?
- Batas ukuran file / jumlah baris?
