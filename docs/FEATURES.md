# mibu — daftar fitur

Sumber: Claude Design "mibu" (https://claude.ai/artifact/25RLRcYScmmPDzjBvg9Zz8). Nomor = id screen di canvas, pakai di tiket.
Semua nominal di design = data contoh.

Tanda: **[diupdate]** = aturan/perilaku berubah dari design, **[perlu design]** = belum ada di canvas, nunggu board.

## Aturan global

- Locale `id-ID`, IDR tanpa desimal, titik ribuan (`Rp4.530.000`), minggu mulai senin.
- Format pendek: ≥1jt → `Rp4,53jt`, ≥100K → `Rp450K`, ≥1K → `Rp6,7K`. Pengeluaran `-`, pemasukan `+`, prediksi `± `. Angka tabular.
- Copy huruf kecil, santai, di `id.arb`. Pakai "pengeluaran / pemasukan", bukan "keluar / masuk".
- Ikon: hugeicons, stroke rounded 1.5.
- Tanggal/bulan masa depan nggak bisa dipilih di mana pun.

## 01 · Onboarding & auth

- [ ] **01.1 onboarding** — 3 slide (kantong · jatah harian · catat 3 detik), progress ala stories, tap segmen buat lompat, `lewati` / `mulai sekarang` → 01.2.
- [ ] **01.2 masuk** — satu tombol buat masuk & daftar, tanpa email/password.
  - iOS: `lanjut pakai apple` (utama) + `lanjut pakai google`. Android: google aja.
  - Pakai tombol resmi brand. Stiker emoji muter pelan di ilustrasi (40s).
  - 01.2c / 01.2d = sheet sistem (Google Credential Manager / Sign in with Apple), bukan UI kita.
- [ ] **01.2e berhasil masuk** — `halo, {nama} 👋`. Akun baru → 01.4, akun lama → 02.1.

## 01.4 · Atur awal

- [ ] **01.4 saldo + gajian** — input saldo (maks 12 digit, font mengecil), chip cepat 500K/1jt/2,5jt/5jt, tanggal gajian (1, 10, 15, 25, 28, akhir). Preview live "aman jajan per hari" = saldo ÷ hari sampai gajian. `nanti aja` → beranda.
- [ ] **01.4b kantong pertama** — "mau mulai pasang limit ke apa?": multi-select preset (makan, ngopi, ojol, tagihan, hiburan, belanja, anabul, liburan) dengan limit bulanan, "N dikasih limit", "ringkasan limit". Ringkasan total vs saldo ("sisa bebas …" / "lebih … dari saldo").

## 02 · Tab utama

- [ ] **02.1 beranda**
  - Header: logo, MonthPicker, tombol cari → 04.2.
  - Hero `saldo kamu` + chip `aman jajan hari ini · Rp580K`.
  - Grafik `saldo per bulan` 6 bulan, tap bulan buat intip; bulan depan = prediksi (±). Sinkron dua arah sama MonthMenu.
  - 4 kantong teratas (% kepake), `lihat semua` → 02.2.
  - `baru aja`: 2 transaksi terakhir → 04.3, `lihat semua` → 04.1.
- [ ] **02.2 kantong**
  - Hero `sisa jajan {bulan}` = Σlimit − Σkepake.
  - **[perlu design]** Sub-baris hero bisa di-tap: "Rp2,34jt dari Rp7,4jt kepake · budget Rp6,9jt" → BudgetSheet 00.16. Budget kosong → "pasang budget".
  - **[v2]** Toples per buat apa yang pakai limit (isi = % kepake, animasi 300ms), "N pakai limit · urut dari yang paling kepake", toples putus-putus `limit` → sheet pasang limit. Pilih satu → kartu detail: status `aman` / `hampir abis` (≥85%) / `belum kepake`, "jatah sisa dari Rp…", "kira-kira Rp… sehari".
  - **[v2]** Kartu detail: `atur limit` → 03.5, `lepas limit` → langsung + toast "limit X dilepas · X & N catatannya tetap ada · batalin".
  - **[v2]** Header `+ pasang limit` → sheet "pasang limit ke…": buat apa pengeluaran yang belum pakai limit, urut paling kepake bulan ini ("N catatan · Rp… udah kepake bulan ini"), pilih → PocketLimit + "toples langsung keisi X% · sisa jatah Rp…" → `pasang limit Rp…` + toast "limit X Rp… kepasang · N catatan bulan ini langsung keitung · batalin". Kosong: "semua buat apa udah pakai limit". Bawah: `bikin kategori baru` → 03.4, "pemasukan (gajian dkk) nggak bisa dikasih limit".
  - **[v2]** "belum ada limit · Rp… bulan ini" + `semua` → 03.3: 2 chip teratas → langsung ke step limit, `+N` → sheet. Belum ada sama sekali → kartu "pasang limit pertama".
  - `isi ulang` ditunda.
  - `impian` (goals): kartu kosong `pasang target` — flow belum didesain.
- [ ] **02.3 statistik** — toggle minggu / bulan / tahun (02.3a/b/c).
  - Navigasi periode ‹ ›, total + delta vs periode lalu.
  - Bar chart (bar masa depan = `belum`), garis rata², tap bar → pill nominal.
  - `sekilas`: paling boros · paling hemat · rata² harian/mingguan/bulanan.
  - `ritme budget`: uang kepake % vs waktu jalan %, status `aman` / `hampir abis` / `lewat budget` / `di bawah budget`. Basisnya `monthlyBudget` (lihat MVP_PLAN › Statistik).
    - **[diupdate]** Status `hampir abis` (≥85% limit, minggu/bulan) ditambah.
    - **[perlu design]** Budget kosong → section diganti kartu "pasang budget bulanan biar mibu bisa ngecek ritme kamu" → BudgetSheet 00.16.
  - `larinya ke mana`: 4 kategori teratas (stacked bar + list).
- [ ] **02.4 pengaturan**
  - Kartu setup: `budget bulanan` → BudgetSheet 00.16, `N limit` → 02.2 (board masih "N kantong"). Chip `mulai tgl 1` nggak bisa di-tap, **[ditunda]** dibuang dari build.
  - duit: `buat apa aja` → 03.3, `limit bulanan` → 02.2.
  - kebiasaan: `pengingat harian` (21.00, switch), `rekap mingguan` (switch). **[ditunda]**
  - privasi: `sembunyiin nominal` (tampil ••• sampai di-tap). `kunci pakai face id` **[ditunda]**.
  - tampilan: `mode` terang / gelap / auto. **[ditunda]** (light only)
  - data: `ekspor ke csv` (board nulis "export"). `backup & pulihin` (iCloud) **[ditunda]**.
  - Footer versi.

## 03 · Catat & buat apa

- [ ] **03.1 catat** (dari tombol + di semua tab)
  - Segmented pengeluaran / pemasukan, tombol kalender → DateSheet, DayStrip buat pilih tanggal cepat.
  - Keypad rupiah: 1–9, `000`, 0, backspace. Maks 10 digit, titik ribuan otomatis, font 68 → 54 → 44.
  - Bar dampak: "🍜 jatah makan abis ini · sisa X" / "kelebihan X". Pemasukan: "saldo abis ini".
  - Chip buat apa → 03.2, `+ catatan` → NoteSheet.
  - `simpan pengeluaran` / `simpan pemasukan` → 02.1.
- [ ] **03.2 buat apa?** (sheet) — **[v2]** judul "buat apa?", "cari atau bikin…", chip yang pakai limit dapet "sisa Rp…" (tebal kalau ≥85%), boleh dilewati (tanpa kategori), `terakhir` (kategori + tempat sekali tap), grid kategori, field `di mana`, `atur` → 03.3.
- [ ] **03.3 buat apa aja** — **[v2]** grid; yang pakai limit dapet chip ink "limit Rp…", sisanya "N catatan" / "belum dipakai"; footer 🫙 "yang ada limit jadi toples di tab kantong…"; tap = edit, `−` = hapus, tahan & geser = urutin (tile goyang di mode edit).
- [ ] **03.4 bikin baru / 03.5 edit** (satu widget, `mode=new|edit`)
  - Nama + emoji otomatis dari kata kunci (makan, kopi, kucing, bensin, …) sampai user pilih manual. Saran 3 emoji + palet 16.
  - `masuk ke`: pengeluaran / pemasukan.
  - **[v2]** Switch `limit bulanan` (hint "nggak wajib, bisa dipasang nanti" / "jadi toples · mibu ngingetin kalau mau abis"), default mati kecuali dari 02.2. Edit + limit nyala → link `lepas limit` (langsung kesimpan + toast batalin).
  - PocketLimit 00.15 (ketik / geser / preset Rp100K · 300K · 600K · 1jt). **[diupdate]** Switch cuma buat kategori pengeluaran. Kategori pemasukan (gajian) cuma muncul pas catat pemasukan.
  - Edit: info pemakaian ("12 catatan · Rp840K tahun ini") + tombol hapus → 03.6.
- [ ] **03.6 hapus kategori** — wajib pindahin catatan ke kategori lain / tanpa kategori, tombol **tahan buat hapus** (1 detik), state sukses + `batalin`.

## 04 · Transaksi

- [ ] **04.1 semua transaksi** — carousel bulan (swipe / tap kiri-kanan = ±1 bulan, label lintas tahun `des 24`; tap judul `oktober ▾` → MonthMenu 00.8 dengan bulan sebelum transaksi pertama dikunci; chip `balik ke okt 2026 ›` kalau bukan bulan ini; tanpa dots), tile pemasukan / pengeluaran / selisih, filter semua / pengeluaran / pemasukan, grup per hari (hari ini · kemarin · sen 12 okt) + total harian, empty state, akhir list `liat {bulan lalu}`.
- [ ] **04.2 cari** — cari kategori/tempat di bulan ini, filter tipe, SearchSummary (total, rata², insight, tick per hari yang bisa di-drag buat filter hari), 3 hasil pertama + `liat N lagi`, saran pencarian, empty state.
- [ ] **04.3 struk (detail)** — kartu struk: tempat, kategori, nominal, waktu, jenis, berulang, catatan, foto struk. Dampak ke kantong. Aksi: hapus, `patungan`, `catat lagi`, edit → 04.4.
- [ ] **04.3b/c hapus** — ConfirmModal (dampak kantong sebelum → sesudah), lalu kartu stempel `dihapus` + toast `batalin`.
- [ ] **04.4 edit catatan** — nominal, buat apa (bisa diganti / dikosongin), di mana, kapan, catatan, berulang (nggak / mingguan / bulanan). Badge `diubah` per field, "N perubahan · batalin", `simpan perubahan` nonaktif kalau belum ada perubahan.

## 00 · Komponen bersama

| id | komponen | catatan |
|---|---|---|
| 00.3 | TabBar | kapsul ngambang 4 tab + tombol + terpisah |
| 00.4 | TxRow | emoji, label, sub, nominal, href (default 04.3) |
| 00.5 | NavHeader | back, title, sub, aksi search/close/edit |
| 00.6 | ConfirmModal | bar dampak before/after, selalu dipasangin toast undo |
| 00.7–8 | MonthPicker + MonthMenu | grid 3×4, mini bar per bulan, bulan depan dikunci |
| 00.9 | TextField | floating label, state focus/error/disabled, tipe text/search/rupiah |
| 00.10 | AmountField | input nominal besar + hint sisa/kelebihan |
| 00.11 | DayStrip | 1 minggu, swipe ganti minggu, caption relatif |
| 00.12 | DateSheet | kalender bulan, titik jumlah catatan, peringatan dobel |
| 00.13 | NoteSheet | maks 80 karakter, maks 3 tag, catatan terakhir |
| 00.14 | SearchSummary | insight + tick harian yang bisa di-drag |
| 00.15 | PocketLimit | input limit ("limit per bulan"): ketik, slider (garis sisa budget), preset chip. Dipakai 03.4/03.5, nanti 01.4b. **[perlu design]** budget kosong → garis diganti link "pasang budget bulanan" → 00.16 |
| 00.16 | BudgetSheet | **[perlu design]** sheet "budget bulanan": AmountField + keypad (maks 12 digit), info live kiri "total limit Rp…", kanan "ketik budget kamu" / "belum dijatah Rp…" / "kurang Rp…" (tebal), prefill Σlimit dibulatin ke atas per 500K kalau kosong, `simpan` / `hapus budget`. Dibuka dari 00.15, 02.2, 02.3, 02.4 |
| 00.19 | MetaLine | metadata 1 baris dipisah titik bulat 3px (#BDBDBD, di ink #737373), bukan karakter "·". Judul section nggak pakai titik: judul 15/600 kiri, info 13 muted kanan (+ › kalau bisa di-tap) |

## Entitas

- **User** — uid, nama, email (bisa relay Apple), provider google/apple.
- **Profil budget** — saldo, tanggal gajian, budget bulanan, awal siklus.
- **Category** — emoji, nama, jenis (pengeluaran/pemasukan), `monthlyLimit` (null = cuma dicatat), urutan. Di UI namanya "buat apa"; yang pakai limit = toples di tab kantong. Lihat MVP_PLAN › Buat apa, limit, kantong.
- **Transaction** — tipe, nominal (int IDR), kategori, tempat, tanggal + jam, catatan (≤80), tag (≤3), berulang, foto struk, no. struk. Perlu soft delete buat undo.
- **Goal (impian)** — field belum jelas.
- **Settings** — pengingat + jam, rekap mingguan, kunci biometrik, sembunyiin nominal, tema.

## Belum jelas / belum didesain

- Backend: Firebase vs Supabase, offline/sync, backup Android (iCloud doang di design).
- Rumus "aman jajan hari ini": basisnya saldo atau sisa budget? Angka di beranda nggak cocok sama dua-duanya.
- Siklus budget: tanggal 1 vs tanggal gajian. Budget bulanan = angka yang diisi user (02.4), bukan Σlimit kantong.
- Flow belum ada: edit gajian/saldo (budget → 00.16), pilih jam pengingat, isi ulang, patungan, target impian, foto struk, logout, hapus akun.
- Algoritma prediksi saldo bulan depan.
- Threshold notif kantong (asumsi 85%).
- Recurring: engine auto-create, edit satu vs semua. Catat (03.1) belum ada kontrol berulang.
- Durasi undo, Face ID versi Android, palet dark mode.
- State loading/error/empty pertama kali (beranda/statistik/kantong tanpa data).
- Inkonsisten kecil: "jajan" di daftar pindah kategori nggak ada di set kategori; "gajian" muncul di picker mode pengeluaran; 04.4 nggak pakai DayStrip (build pakai DayStrip 00.11); tombol 04.4 "simpan perubahan" + pill "2 perubahan · batalin" nggak muat di 390 (build: "simpan"); ConfirmModal 00.6 masih copy inggris "now 90% used / after 45%" (build: "sekarang 90% kepake / abis ini 45%"); struk 04.3 "#0413" belum ada kolom no. struk (build: tanggal aja).
