# mibu

Pencatat keuangan pribadi iOS + Android (Indonesia, IDR, dipakai sendiri tiap hari): catat duit, ada kantongnya. Fully local, tanpa login dan tanpa backend.

## Sumber kebenaran

- **Produk, aturan hitungan, alur:** [docs/](docs/README.md), satu file per topik (indeks di `docs/README.md`). Baca file yang relevan sebelum mengerjakan fitur apa pun. `docs/ideas/` dikerjakan hanya kalau diminta. Rumus (aman jajan, statistik, CSV, periode) ada di docs, jangan bikin ulang. Rujuk docs pakai path file (`docs/mvp.md`), bukan nomor bagian.
- **Desain UI:** Claude Design "mibu", https://claude.ai/artifact/25RLRcYScmmPDzjBvg9Zz8. Baca board layar yang dikerjakan lewat Artifact tool, bukan WebFetch. Id screen (02.1, 07.2 …) = judul board; pakai di komentar dan issue. Board direstrukturisasi 2026-10-10 (modul 02–09, 10 showcase, 99 proposal); id lama di git history dipetakan di `docs/features.md`.
- **Task:** GitHub issues, label `area:*`. Satu issue = satu unit kerja. Semua dependensi di baris **Tergantung** harus udah closed. Centang checklist scope saat selesai.

## Urutan kerja

- Skip auth (01.2) dan fitur yang ditunda di `docs/mvp.md` kecuali diminta.
- Label status issue:
  - `status:ready`: plan jelas, tinggal dikerjain.
  - `status:deferred`: nunggu pemicu (baris **Dibuka kalau** di issue). Pemicu kejadian → ganti ke `status:ready`.
  - `status:idea`: belum diputusin; bisa ditutup `wontfix`.
- Issue / ide / item ditunda baru: bikin issue dengan label status yang cocok, sisipin di induk yang cocok, tambah link `(#N)` di docs-nya.
- Tanpa AI di commit, PR, issue, atau kode: tidak ada `Co-Authored-By`, tidak ada baris "Generated with …". Ini menimpa atribusi default.

## Project

App Flutter di `apps/mobile`, Flutter dikunci lewat FVM (`.fvmrc`). Perintah lewat `Makefile` di root (`make help`); di luar itu `fvm flutter` / `fvm dart` dari `apps/mobile`.

- Setelah ubah tabel Drift: `make gen` (`build_runner`). File `*.g.dart` ikut di-commit.
- **Schema = udah rilis, data asli ada di HP** (`com.mibu.mibu`). v1 = baseline, diambil dari tag `release-baseline` (commit `937e55f`). Tabel gak pernah diedit di tempat dan data gak pernah dihapus. Tiap ubah tabel wajib: naikin `schemaVersion`, tambah langkah `from < N` di `onUpgrade` (`app_database.dart`), tambah schema lama sebagai `vN` + satu case di `test/data/migration_test.dart` (fixture SQL versi lama vs install baru, data tetap ada). `drift_dev make-migrations` gak dipakai. Drift gak bisa turun versi.
- `applicationId` / bundle id prod (`com.mibu.mibu`) gak boleh berubah.
- `make check` (format, analyze, test) harus bersih sebelum commit.

### Build ke device

Dua app terpisah (data sendiri-sendiri):

| App | Id | iOS | Android | Dari |
|---|---|---|---|---|
| **mibu** (data asli) | `com.mibu.mibu` | `make release` | `make release-android`, `make apk` | `main` doang |
| **mibu dev** (ikon beda warna) | `com.mibu.mibu.dev` | `make dev`, debug `make run f=dev` | `make dev-android`, debug `make run-android f=dev` | branch fitur |

Branch fitur selalu ke mibu dev: migrasi yang belum stabil bakal nyentuh data asli. Android selalu pakai `--flavor` (`prod` / `dev`). Release Android ditandatangani lewat `android/key.properties` (gitignored); tanpa file itu jatuh ke debug key, yaitu signature build yang sekarang ter-install, jadi jangan diganti sembarangan (update-install gagal).

Data contoh buat debug (`seed.dart`, cuma `kDebugMode`): `seedFixture` (default; angka desain, test meng-assert-nya, jangan diubah) dan `seedDemo` (data realistis, dipakai `appDatabaseProvider` di device). Pilih lewat `make run seed=demo|fixture|none`. `make fresh` = install baru tiap launch (hapus data + tanpa seed → 01.1 → 01.4), `make reset` = hapus data + seed ulang. Build release mulai kosong.

## Arsitektur

Layered (UI → data), struktur hybrid:

```
lib/
├── data/database/      # Drift AppDatabase + appDatabaseProvider, seed.dart
├── data/repositories/  # sumber kebenaran, ubah row Drift → domain model, expose stream
├── domain/             # logika pure (periode, aman jajan, stats, csv); models/ = model polos
├── l10n/               # app_id.arb + AppLocalizations (gen-l10n)
├── routing/router.dart # routerProvider + Routes
└── ui/
    ├── core/           # tokens, theme, money, dates, clock, widgets/ shared
    └── features/<fitur>/{views,view_models}/
```

- State: Riverpod (`flutter_riverpod`), provider ditulis manual (tanpa `riverpod_generator`), dideklarasikan di sebelah class yang diekspos. Waktu dipin lewat `clockProvider` (`ui/core/clock.dart`); `nowProvider` = "sekarang" saat app start buat query.
- Routing: go_router, navigasi pakai konstanta `Routes`. Sheet = `showAppSheet` + `SheetFrame` (`widgets/sheet.dart`): `showModalBottomSheet`, radius 32, scrim 45%.
- Token dari `ui/core/tokens.dart` (board 00.1), gak ada warna/ukuran baru di luar itu. Tema terang doang. Nilai baru = tambah jadi token dulu. Ikon: `hugeicons` (stroke rounded 1.5); ikon gambar sendiri lewat `AppIcons` di `tokens.dart`.
- Komponen shared di `ui/core/widgets/`, pakai ulang: `PrimaryButton` / `CircleButton` (di `sheet.dart`), `ConfirmModal`, `toast` (batalin), `NoteSheet`, `DateSheet`, `DayStrip`, `AmountKeypad`, `PocketLimit`, `TxRow`, `NavHeader`, `MonthPicker` / `MonthMenu`, `MetaLine`. Komponen khusus satu fitur tinggal di folder fiturnya.
- Pemisah metadata 1 baris = `MetaLine` (00.19), jangan pernah "·" literal di copy UI. Judul section = judul kiri + info kanan, tanpa titik.
- TabBar ngambang di Stack; list dikasih padding bawah `AppSpace.tabBarClearance`.

## Kode Dart: logika kondisional

- Ternary maksimal 1 level di widget tree.
- Kondisi lebih dari 2 cabang, atau label/teks dari state model: extract ke getter di extension pada model, isinya `if/return` berurutan.
- State yang bisa nambah: enum + switch expression.

## Test

Struktur `apps/mobile/test/` ikut `lib/`:

- `test/domain/`: logika pure (periode, aman jajan, stats, csv). Wajib buat tiap rumus.
- `test/data/`: repository, migrasi (`migration_test.dart`), seed, dengan DB in-memory.
- `test/ui/core/`: widget shared.
- `test/ui/features/<fitur>/<layar>_test.dart`: widget test per layar.
- Helper bersama: `test/db.dart` (query/set limit, budget langsung ke DB), `test/meta.dart` (finder `MetaLine`, `EmojiText`), `test/flutter_test_config.dart`.

DB test = `AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true), () => now, seed)`, `appDatabaseProvider` di-override ke situ. Jam dipin lewat `clockProvider`; clock itu juga yang menaruh seed debug, jadi `now` DB dan `clockProvider` harus sama. Pin ke `fixtureNow` (`test/db.dart`) biar angka seedFixture cocok.

Jebakan widget test (pola ada di `test/ui/features/home/home_test.dart`):
- `testWidgets` jalan di jam palsu: query Drift tidak maju sendiri. Habis `pumpWidget`, tunggu di `tester.runAsync(() => Future.delayed(...))`, baru `pump()`. Di `test/db.dart` baca pakai Future, bukan `watch().first` (stream query butuh timer yang gak jalan di jam palsu).
- Set layar HP: `tester.view.physicalSize = Size(390, 844)`, `devicePixelRatio = 1`, `addTearDown(tester.view.reset)`.
- Tutup DB di tearDown **setelah** `pumpWidget(const SizedBox())` supaya stream berhenti dulu: `addTearDown(() async { await tester.pumpWidget(const SizedBox()); await db.close(); })`.
- MaterialApp test butuh `AppTheme.light`, `locale: Locale('id')`, dan `AppLocalizations.localizationsDelegates`; tanpa itu copy dan format salah.
- `flutter_test_config.dart` menyalakan `dontWarnAboutMultipleDatabases` (tiap test buka DB sendiri).
- Integration test di luar scope.

## Aturan data yang gampang terlewat

- Tiap tabel: `id` UUID text, `createdAt`, `updatedAt`, `deletedAt` (soft delete: bahan undo dan sync nanti). Gak ada autoincrement.
- Gak pernah nyimpen nilai turunan (saldo, kepake, saldo bulanan): hitung dari `transactions`. Kantong = category dengan limit (UI: "buat apa" + "limit"); lihat `docs/mvp.md`.
- Hitungan bisnis (aman jajan, stats, CSV, periode) = fungsi pure di `domain/`, ada unit test. Rumus di docs.
- Uang = int rupiah utuh. `rupiah` → `Rp4.530.000`, `rupiahCompact` → `Rp580K` / `Rp4,53jt`; angka tabular.
- Locale `id-ID`; minggu mulai Senin (locale `id` defaultnya Minggu, set eksplisit di `dates.dart`).
- `purgeDeleted` menghapus baris soft-delete yang lebih dari sehari; kategori tetap ada selama masih ada transaksi yang menunjuknya.

## Copy

Semua teks UI huruf kecil, santai, ada di `lib/l10n/app_id.arb` (gen-l10n), gak pernah hard-coded. Ambil teks persis dari board desain kalau ada. Tulis "pengeluaran / pemasukan", bukan "keluar / masuk".
