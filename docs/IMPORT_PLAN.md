# mibu — impor data

**Udah dieksekusi 3 okt 2026** (02.4l–o, ImportSheet 00.30). Masuk [MVP_PLAN.md](MVP_PLAN.md#import-csv).

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
- File yang di-save ulang Excel (id) tetap kebaca: separator `;` (dilihat dari header), tanggal `d/M/yyyy`, jam `H:mm` / `HH:mm:ss` (detik dibuang). `MM/dd` (US) nggak didukung, ambigu sama `dd/MM`.
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

## Kode

- `domain/csv.dart`: `parseTransactionsCsv` (null = header beda) + `planImport` (dobel, buat apa baru).
- Repo: `importCsv(plan)` → ID yang ditulis; `undoImport` = soft delete.
- UI: `settings/views/import_sheet.dart` (`importCsv`, ImportSheet 00.30), baris di 02.4.
- Dep: `file_picker` (`FilePicker.pickFile`, filter `.csv`).

## Design brief: 99.7 import dari csv

Draft di artifact "mibu", baris 99 proposal: 99.7a alur, 99.7b–d state sheet, 99.7e `ImportSheet` (calon komponen 00.30). Copy ngikut app: "import dari csv" (pasangan "export ke csv"). Kalau acc: pindah ke baris 02.4 (02.4l–o), hapus [DRAFT]. Gaya sheet 02.4h (sembunyiin nominal). Pakai komponen yang ada: `SheetFrame`, `PrimaryButton`, `AppEmoji`, `MetaLine` 00.19, toast 00.18. Tile `impor dari csv` di section data, di bawah ekspor (ikon upload). Copy di bawah cuma draft.

| state | isi | tombol |
|---|---|---|
| j1 normal | judul `impor dari csv`, angka besar `142 transaksi`, rentang `1 jan – 3 okt 2026`, list buat apa baru (emoji + nama), `MetaLine`: `5 udah ada` · `2 nggak kebaca` | `impor 142` |
| j2 semua udah ada | `semua udah ada di mibu`, sub `nggak ada yang baru dari file ini` | `oke` |
| j3 file salah | `file-nya bukan dari mibu`, sub `ekspor dulu dari mibu, terus impor file itu` | `oke` |

Setelah impor: toast `142 transaksi masuk` + `batalin`.

## Pertanyaan terbuka (usul default)

- Tanggal masa depan: **terima** (back-fill udah didukung).
- Batas ukuran file: **skip**, tambah kalau kerasa lambat.
