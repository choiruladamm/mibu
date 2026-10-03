# mibu — ganti tanggal gajian: potongan periode

Keputusan 2026-10-03, udah jalan. Board desain 00.24 / 00.25 belum disamain. Nambahin [PAYDAY_CYCLE_PLAN.md](PAYDAY_CYCLE_PLAN.md) (aturan 4: ganti gajian mulai periode berikutnya) dan [PERIOD_LEDGER_PLAN.md](PERIOD_LEDGER_PLAN.md) kasus 7. Di sana nama dobel ditulis "jarang, dibiarin dulu". Ternyata efeknya lebih dari sekadar nama.

## Masalah

Ganti tanggal gajian nulis aturan baru mulai `current.end` (`setPayday`). `SegmentedResolver` ngitung siklus aturan baru di tanggal itu, lalu awalnya dipotong. Hasilnya ada **potongan (S)** antara periode jalan (P) dan periode penuh pertama aturan baru (Q).

Contoh periode jalan di oktober 2026, tanpa geser weekend:

| ganti | P | S | Q | nama S |
|---|---|---|---|---|
| 25→1 | okt 25/9–25/10 | 25/10–1/11, 7 hari | nov 1/11–1/12 | **okt (dobel)** |
| 25→10 | okt 25/9–25/10 | 25/10–10/11, 16 hari | nov 10/11–10/12 | **okt (dobel)** |
| 28→15 | okt 28/9–28/10 | 28/10–15/11, 18 hari | nov 15/11–15/12 | **okt (dobel)** |
| 16→15 | nov 16/10–16/11 | 16/11–15/12, 29 hari | des 15/12–15/1 | **nov (dobel)** |
| 31→1 | okt 30/9–31/10 | 31/10–1/11, 1 hari | nov 1/11–1/12 | **okt (dobel)** |
| 25→20 | okt 25/9–25/10 | 25/10–20/11, 26 hari | des 20/11–20/12 | nov |
| 15→16 | okt 15/10–15/11 | 15/11–16/11, **1 hari** | des 16/11–16/12 | nov |
| 10→25 | okt 10/10–10/11 | 10/11–25/11, 15 hari | des 25/11–25/12 | nov |
| 1→25 | okt 1/10–1/11 | 1/11–25/11, 24 hari | des 25/11–25/12 | nov |

Polanya: kalau gajian dimundurin ke tanggal yang lebih awal (atau nyebrang 16 ke bawah), S kebagian **nama yang sama** dengan P. Kalau dimajuin, nama tetap urut, tapi S bisa sependek 1 hari.

## Efek ke fitur yang ada

Nama dobel (S = P):

- **04.1, menu bulan, search:** `periodForMonth(okt)` balikin P, jadi S nggak bisa dibuka. Catatan di S kelihatan hilang dari daftar, walau di DB aman. Ini berlaku juga sesudah S lewat, selamanya di riwayat.
- **Beranda:** `totals.spent` dikunci per nama, jadi pengeluaran P + S digabung di "okt" dengan budget 1×. Hari tersisa pakai S.
- **Kantong:** pakai `currentPeriodProvider` = S aja, dengan budget penuh lagi. Angkanya beda dengan beranda.
- **Stats:** aman, navigasinya lewat `periodOf`.

S pendek (nama urut):

- Budget penuh buat periode 1 hari, jadi aman jajan hari itu = seluruh budget. Ini yang mau dicegah aturan "mulai periode berikutnya".
- Limit mingguan stats = `budget × 7 ÷ panjang`, jadi 7× budget.

Frekuensi: cuma pas user ganti tanggal gajian di luar periode setup. Jarang, dan nggak ada data yang hilang. Tapi kalau kejadian, kelihatannya kayak data hilang.

## Batasan

- Kode nyari periode lewat nama bulan (`homeMonthProvider`, `monthTransactionsProvider(month)`, `totals.spent[key]`). Jadi **satu nama = satu periode** wajib dijaga, atau semua tempat itu harus diubah.
- Periode yang udah lewat nggak boleh berubah (aturan 4).
- Kenyataannya, S itu periode antara dua gaji asli (gaji 25 okt lalu 1 nov). Jadi periode pendek nggak salah. Yang salah cuma nama dan budgetnya.

## Opsi

**A. S dobel digabung ke P.** Kalau nama S = nama P, P diperpanjang sampai awal Q. Untuk 25→1: okt = 25/9–1/11, 37 hari. Nama tetap unik, budget nggak dobel, cukup ubah `SegmentedResolver.periodOf` (+ `prev`).
Kurangnya: makin jauh mundurnya, makin panjang P (25→10: 46 hari, 16→15: 60 hari). Dua gaji juga masuk satu periode, jadi sisa pemasukan P kegedean.

**B. A + budget S diproporsi.** S yang namanya urut tetap periode sendiri, tapi budgetnya `budget × panjang S ÷ panjang Q`. Contoh 15→16, 1 hari: budget/31. Nambah satu titik di `watchBudget` / view model dan kalimat di "dari mana angkanya?".

**C. Nama S digeser (+1), Q dan seterusnya ikut geser.** Semua periode tetap pendek atau normal, tapi nama sesudah ganti meleset sebulan selamanya (16→15: 15/12–15/1 jadi "jan"). Aturan nama "bulan yang paling banyak harinya" jadi rusak.

**D. Ubah semua kunci dari nama bulan ke periode.** Paling benar, tapi kena hampir semua provider dan menu bulan. Kegedean buat pre-release.

## Keputusan

Opsi **B**. Yang belum kepake di sini:

1. **S dobel digabung ke P.** Kalau nama S = nama P, P diperpanjang sampai awal Q (25→1: okt = 25/9–1/11). S yang namanya urut tetap periode sendiri. Kalau S urut ikut digabung, namanya hilang di menu bulan (15→16: okt sampai 16/11, lalu des, jadi nov kelewat).
2. **Periode panjang boleh, nggak ditolak.** Tanggal gajian biasanya diganti kantor, bukan pilihan user. Rentang itu memang berisi dua gaji, jadi periode 46–60 hari itu bener. Yang bikin aneh cuma budget, dan itu ditangani di poin 3. Biar user nggak kaget, rentang barunya ditampilin sebelum simpan (poin 4).
3. **Budget periode transisi diproporsi.** Periode transisi = periode yang ada batas aturan di dalamnya atau di ujungnya: P yang digabung, atau S yang berdiri sendiri. Q = periode penuh pertama dari aturan baru.
   - Budget = `budget × panjang periode transisi ÷ panjang Q`, dibulatkan ke rupiah. Satu rumus buat yang pendek maupun yang panjang: 7 hari dapet 7/30, 60 hari dapet 60/30, jadi aman jajan per hari tetap sama dengan periode normal.
   - Pembaginya Q, bukan rata-rata 30, karena Q itu periode normal pertama dengan ritme gajian yang baru.
   - **Limit kantong pakai faktor yang sama.** Kalau nggak, total limit kantong bisa lebih gede dari budget, dan angka kantong beda dengan beranda. Kurangnya: kantong yang bayarnya sekali sebulan (kos) ikut kepotong di periode pendek. Cuma sekali kejadian, dan limitnya bisa diubah di periode itu.
   - Faktornya dihitung, nggak disimpan (aturan nilai turunan). Budget dan limit yang disimpan tetap angka per periode normal. 00.16 dan "dari mana angkanya?" nampilin angka hasil proporsi plus satu baris penjelasan.
4. **Preview di sheet 00.24, bukan sheet konfirmasi tambahan.** Begitu user milih tanggal, di bawah pilihan tanggal langsung muncul "periode ini jadi 25 sep – 31 okt", diikuti "37 hari" dan "budget Rp…", disusun pakai `MetaLine`. Baris ini cuma muncul kalau periode jalan memang berubah (di luar periode setup). Toast + batalin tetap jadi jaring pengaman.

Hasilnya: satu nama = satu periode tetap terjaga, nggak ada bulan yang kelewat, dan nggak ada periode yang dapet budget penuh di luar panjang normalnya.

## Urutan kerja

1. ✅ **Domain + test:** `SegmentedResolver` gabung S dobel ke P (`periodOf`, `prev`, `next`). Ditambah fungsi murni faktor periode transisi (null buat periode normal). Satu test per baris tabel [Masalah](#masalah): rentang, nama, faktor.
2. ✅ **Data:** faktor dipakai di titik baca budget (`budgetInPeriodProvider` / `watchBudget`) dan limit kantong (`watchPockets`, `watchCategories`). Stats ikut otomatis lewat budget periode.
3. ✅ **UI:** preview 00.24, baris penjelasan di 00.16 dan "dari mana angkanya?", copy di `app_id.arb`.

Catatan implementasi:

- `Period.normalDays` (null = periode normal) dan `prorate(amount, period)` ada di `domain/period.dart`. Angka yang diproporsi: `budgetInPeriodProvider`, budget di kantong, dan `Pocket.budget`. Sheet edit (00.16, limit, form kategori, total limit di 02.4) tetap pakai angka yang di-set: `Profile.monthlyBudget` dan `Pocket.limit`.
- `setPayday`: kalau udah ada aturan yang antri, aturan itu yang diupdate (tanggal mulainya nggak berubah). Habis digabung, `current.end` bisa lewat dari tanggal aturan itu, jadi kalau masih pakai `current.end` bakal kebikin aturan ketiga.
- Kapan ganti gajian mulai berlaku diputusin `paydayChangeFrom` (domain), dipakai `setPayday` dan preview 00.24. Preview ngitung periode lewat `withPayday` + `SegmentedResolver`, jadi angkanya sama persis dengan yang kesimpen.
- Toast 00.24: kalau periode jalan berubah, bunyinya "periode ini jadi sampai sen 9 nov". Kalau nggak berubah, tetap "berlaku mulai …, periode ini selesai dulu".
- 00.25: kartu sisa budget dapet catatan "periode peralihan n hari, budget dihitung n/30".
