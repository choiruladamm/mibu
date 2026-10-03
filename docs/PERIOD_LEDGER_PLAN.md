# mibu — buku catatan per periode gajian

Keputusan 2026-10-03. Logic sama UI sementaranya udah jalan, desain final nyusul (lihat [Status](#status)). Gantiin model "saldo kumulatif" (saldo awal + semua catatan) yang ada di [MVP_PLAN.md](MVP_PLAN.md) dan hero toggle di [FEATURES.md](FEATURES.md). Dasar periodenya tetap [PAYDAY_CYCLE_PLAN.md](PAYDAY_CYCLE_PLAN.md).

## Ringkasan

mibu itu **buku catatan pemasukan dan pengeluaran per periode gajian**, bukan cermin rekening bank. Saldo bank bukan urusan app ini. Tugasnya: nyatet, batesin budget per periode, dan ngasih tau berapa jajan yang aman.

User-nya orang kantoran, atau kantoran + freelance, yang tau kapan gajiannya. Tanggal gajian itu patokan satu-satunya buat semua angka. Nggak ada angka yang kebawa lintas periode.

## Status

Logic + desain final (canvas 2026-10-03) udah masuk:

| Bagian | Board | Isi |
|---|---|---|
| Domain + skema + repository | — | saldo, saldo awal, hero toggle dibuang; `Totals` = `income` + `spent` per periode; aman jajan budget aja |
| Hero | HeroBudget 00.23 / 00.23b | sisa budget + "?" di samping label · "dari budget Rp… • gajian lagi N hari" (periode lalu: range tanggal) · budget kosong → kartu putus-putus "atur budget periode ini" + chip "isi budget biar dapet aman jajan" |
| Grafik beranda | PeriodBars 00.26 (opsi a) | kepake per periode, garis putus-putus = budget periode berjalan, 6 periode sampai yang berjalan, pill "berjalan • okt" / "lewat budget", nggak ada prediksi |
| Dari mana angkanya | NumbersSheet 00.25 | 3 kartu (sisa budget · aman jajan per hari · sisa jajan kantong), kartu dari layar pembuka di-ink, dipakai beranda & kantong |
| Setup | 01.4 / 01.4c / 01.4d | tanggal gajian dulu + kartu "periode sekarang", budget opsional tanpa chip cepat, preview aman jajan cuma kalau diisi; 01.4b "/periode", tanpa budget "total limit per periode" |
| Sheet budget | 00.16 | "budget per periode", "periode lalu kepake Rp…", "Rp… / periode" |
| Sheet gajian | 00.24 | tanpa baris aman jajan, catatan "tgl 25 jatuh hari minggu → dihitung jumat" |
| Catat | 03.1b–d | "sisa budget abis ini" / "pemasukan periode ini jadi" / bar ilang tanpa budget |
| 04.1 | 04.1 / 04.1d | range di bawah judul, kartu ink sisa pemasukan + naik/turun, pemasukan & pengeluaran vs periode lalu, "—" + "catat gajian dulu" |

Belum: nama user di judul 01.4 (app belum punya nama), toast budget versi beranda ("budget Rp… kepasang"), dan MVP_PLAN / FEATURES ditulis ulang (masih nunjuk ke sini).

Ganti tanggal gajian tetap berlaku **mulai periode berikutnya** (kecuali masih di periode setup), diputusin 2026-10-03 dan catatan di sheet 00.24 udah disamain. Alasannya: kalau langsung, periode yang lagi jalan ganti panjang di tengah jalan, catatan pindah periode, dan budget periode itu bisa kepake dobel (25 → 10 tgl 16 okt: periode lama tutup 9 okt, periode baru dapet budget penuh lagi).

## Kenapa ganti

Saldo kumulatif = `openingBalance` + catatan sejak `openingAt`. Di pemakaian nyata itu bermasalah:

- Gajian tgl 25 sep dicatat tgl 3 okt nggak masuk saldo (`at < openingAt`), padahal user nganggep itu bagian periodenya.
- Kalau dihitung semua, angkanya dobel dengan saldo awal yang diketik user (udah termasuk gaji itu).
- Skip saldo awal (0) bikin saldo cuma dari catatan, tapi catatan lama tetap dibuang.
- "Saldo" kebaca saldo bank, padahal mibu nggak tau isi rekening.
- Pemasukan itu bukan budget. Gaji 20jt nggak berarti boleh dihabisin 20jt.

Semua itu hilang kalau angkanya murni "catatan di periode ini".

## Keputusan

1. **Periode gajian mutlak.** Satu-satunya sumbu waktu di seluruh app (budget, limit, kantong, aman jajan, statistik, cari, grafik).
2. **Nggak ada saldo kumulatif, saldo awal, atau carryover.** Sisa uang periode lalu nggak kebawa. Bank bukan urusan mibu.
3. **Sisa pemasukan = analitik.** Label "sisa pemasukan", bukan "sisa gaji", karena freelance, bonus, dan lain-lain ikut. Tampil di statistik, bukan di hero.
4. **Budget acuan harian.** Hero cuma sisa budget. Aman jajan cuma turun dari budget, **nggak pernah** ditebak dari pemasukan.
5. **Budget kosong → ajakan, bukan tebakan.** Hero dan chip ngajak "atur budget periode ini". Fitur lain tetap jalan.
6. **Onboarding nggak ngewajibin apa pun.** Semua boleh dilewatin, default aman. Budget nggak harus diisi di setup.
7. **Pemasukan non-gaji ikut** dihitung ke pemasukan periode.
8. **Sheet budget nunjukin "periode lalu kepake Rp…"** sebagai petunjuk (mulai periode kedua). Pemasukan nggak dipakai buat saran budget, biar nggak kesan "habisin gaji".

## Rumus

Semua per periode `P` (aturan periode: [period.dart](../apps/mobile/lib/domain/period.dart)), tanggal catatan yang nentuin masuk periode mana, `deletedAt` null, **nggak ada filter `openingAt`**.

```
pemasukan(P)      = Σ amount transaksi pemasukan di P
kepake(P)         = Σ pengeluaran di P
sisaPemasukan(P)  = pemasukan(P) − kepake(P)              -- analitik
sisaBudget(P)     = budget yang berlaku di P − kepake(P)
sisaJajan(P)      = Σ limit kantong − kepake di kantong   -- 02.2, nggak berubah

aman = floor((sisaBudget + pengeluaranHariIni) / hariSisaPeriode) − pengeluaranHariIni
```

`hariSisaPeriode` = hari sampai akhir periode, hari ini ikut (`period.daysLeft`). Aturan lain aman jajan tetap: budget kelewat → "rem dulu ya", `aman ≤ 0` → "kebablasan", hari gajian / telat → ajakan catat gajian (`paydayInfo`). Beda sekarang: **nggak ada sisi saldo**, jadi nggak ada `min(saldo, budget)`.

Contoh: gaji 15jt tgl 25 sep, freelance 2jt tgl 2 okt, budget 7jt, udah kepake 3jt.

| | Nilai |
|---|---|
| pemasukan periode | 15jt + 2jt = 17jt |
| sisa pemasukan | 17jt − 3jt = **14jt** |
| sisa budget | 7jt − 3jt = **4jt** |
| selisih gaji − budget | jatah yang nggak dialokasiin (tabungan) |

Freelance naikin sisa pemasukan, **nggak nyentuh budget** kecuali user naikin sendiri.

## Yang gugur

- Saldo kumulatif, `profiles.openingBalance`, `profiles.openingAt`, dan langkah saldo di 01.4.
- Hero toggle saldo ⇄ sisa budget: `BalanceMode`, `profiles.heroMode`, `profiles.heroHintSeen`, hint "tap buat liat sisa budget".
- Sisi saldo di aman jajan (`safeShare` jadi budget aja).
- Prediksi saldo bulan depan (butuh saldo kumulatif).
- Catatan "saldo tetap cuma ngitung sejak saldo awal" di MVP_PLAN.

## Perubahan per area

| Area | Perubahan |
|---|---|
| Skema ([app_database.dart](../apps/mobile/lib/data/database/app_database.dart)) | Drop `openingBalance`, `openingAt`, `heroMode`, `heroHintSeen`. Pre-release: edit di tempat di `schemaVersion` 1, data dev di-wipe, `build_runner`. |
| Repository ([finance_repository.dart](../apps/mobile/lib/data/repositories/finance_repository.dart)) | `watchTotals`: per periode `income`, `spent`, `nets` tanpa filter `openingAt`; `balance` dibuang, `spentToday` tetap. `completeSetup` tanpa saldo. `setHeroMode` / `markHeroHintSeen` dibuang. |
| Domain ([finance.dart](../apps/mobile/lib/domain/models/finance.dart)) | `safeShare` / `safeToSpendToday` budget aja, budget null → null (bukan 0). `monthEndBalance`, `balanceSeries`, prediksi diganti seri per periode atau dibuang. Fungsi murni + unit test. |
| Hero 02.1 | Sisa budget, tanpa pill toggle. Budget kosong → kartu "atur budget periode ini" → sheet budget yang udah ada. Chip aman jajan: ajakan yang sama. Baris kecil: "gajian lagi N hari" / "dari budget Rp…". |
| Info dialog | Isi diganti: sisa budget, aman jajan (sisa budget ÷ hari sisa), sisa jajan kantong. Nggak ada lagi penjelasan "saldo". |
| Setup 01.4 | Tanggal gajian (25 udah kepilih) + budget per periode **opsional** (boleh kosong). Nggak ada saldo. `nanti aja` tetap. 01.4b kantong tetap, opsional. |
| Ringkasan 01.4b | "belum dijatah … dari saldo" / "lebih … dari saldo" dibandingin ke budget (kalau diisi), tanpa budget cuma total limit. |
| Bar dampak 03.1 | "saldo abis ini" (pengeluaran non-kantong + pemasukan) diganti: pengeluaran → "sisa budget abis ini", pemasukan → "pemasukan periode ini jadi Rp…". Tanpa budget: bar disembunyiin. |
| Copy (`app_id.arb`) | 16 key yang nyebut "saldo" (`balanceLabel`, `homeMonthlyBalance`, `infoSaldo*`, `infoSafeBody*`, `heroModeSaldo`, `homeBalanceEnd`, `balanceAfter`, `setupBalance*`, `setupFree`, `setupOver`, `setupBack`, …) dibuang atau ditulis ulang. |
| Sheet budget (02.4) | Petunjuk "periode lalu kepake Rp…" kalau periode sebelumnya punya pengeluaran. Teks aja, nggak ngisi otomatis. |
| Sheet tanggal gajian (02.4e–g) | Kartu "aman jajan sebelum → sesudah" bergantung saldo. Usulan: sisain tanggal berikutnya + "N hari lagi", buang before/after (sisi budget hampir nggak gerak). |
| Statistik 04.1 | Kartu per periode: pemasukan, pengeluaran, sisa pemasukan, dibanding periode sebelumnya. |
| Grafik 02.1 | Grafik "saldo per bulan" nggak punya basis. Usulan: grafik pindah ke statistik jadi sisa pemasukan per periode; posisinya di beranda diputusin bareng desain. |
| Seed & test | `seedFixture` / `seedDemo` tanpa saldo awal. Test yang nge-assert saldo ditulis ulang (hero fixture "design numbers" ikut berubah, desainnya diupdate dulu). |
| Docs | MVP_PLAN (Turunan, Aman jajan), FEATURES (01.4, 02.1), memory. |

## Edge case

| # | Kasus | Penanganan |
|---|---|---|
| 1 | Gaji belum dicatat di periode baru | Pemasukan periode 0 → sisa pemasukan tampil "—", bukan angka negatif. Chip "catat gajian" yang udah ada jadi pengingat. |
| 2 | Pengeluaran > pemasukan di periode | Sisa pemasukan negatif, ditampilin apa adanya di statistik. |
| 3 | Pemasukan sehari sebelum gajian (mis. freelance tgl 23) | Jatuh ke periode sebelumnya. Wajar, tanggal yang nentuin. |
| 4 | Gaji cair duluan | Aturan `paydayEarlyDays` tetap: periode mulai di tanggal gaji dicatat, pemasukannya ikut periode baru. |
| 5 | Catat mundur sebelum install / sebelum gajian pertama | Tetap punya periode lewat `periodsFromStart`, masuk riwayat dan statistik. Nggak perlu hint khusus lagi. |
| 6 | Budget kosong, aman jajan | Ajakan atur budget, nggak ada angka. |
| 7 | Ganti tanggal gajian di tengah periode | Aturan lama: berlaku periode berikutnya (langsung kalau masih periode setup). |
| 8 | Data lama (punya saldo awal) | Kolom dibuang, saldo nggak dihitung. Pre-release, jadi cukup `make fresh` / `make reset`. |

## Urutan kerja

1. **Domain + test:** aman jajan budget aja, sisa pemasukan per periode (fungsi murni).
2. **Skema + seed:** drop kolom, `build_runner`, seed tanpa saldo awal.
3. **Repository:** `watchTotals`, `completeSetup`, buang hero mode.
4. **Hero + chip + info dialog:** sisa budget, state budget kosong.
5. **Setup 01.4:** tanggal gajian + budget opsional.
6. **Sheet budget:** petunjuk periode lalu.
7. **Kantong 02.2:** cuma copy dialog yang nyebut saldo. Perilaku kantong nggak diubah (lihat [Ditunda](#ditunda)).
8. **Sheet tanggal gajian:** sederhanain preview.
9. **Statistik:** kartu sisa pemasukan + banding.
10. **Grafik beranda:** setelah desain.
11. **Docs:** sinkronin MVP_PLAN, FEATURES, hapus catatan lama.

## Ditunda

**Kantong (02.2) nggak ikut dirombak** di putaran ini, fiturnya belakangan. Yang tetap: kantong = kategori yang punya limit, seksi "belum ada limit", dan "!" waktu sisa jajan > sisa budget. Entri lain-lain (tanpa kategori) tetap cuma ngurangin sisa budget dan belum tampil di 02.2.

Ide yang diparkir buat nanti:

- **Kantong virtual "lain-lain"**: limit = budget − Σ limit kantong asli, kepake = entri tanpa kategori + kategori tanpa limit. Hasilnya Σ limit = budget dan sisa jajan = sisa budget, jadi dua angka itu nggak bisa beda lagi. Tanpa kantong sama sekali, tab jadi satu kantong yang isinya sama dengan sisa budget. Tanpa budget: ajakan atur budget.
- Σ limit > budget: nggak diblok, limit lain-lain tampil 0 dan peringatan yang ada tetap muncul.

## Butuh desain dulu

Hero tanpa toggle + state budget kosong · 01.4 baru · petunjuk di sheet budget · kartu sisa pemasukan di statistik · info dialog baru · pengganti grafik saldo di beranda · sheet tanggal gajian yang disederhanain.

## Terbuka

- **Grafik beranda:** pindah ke statistik, diganti pengeluaran vs budget per periode, atau dibuang.
- **Preview sheet tanggal gajian:** setuju dibuang jadi tanggal + "N hari lagi"?
- **Petunjuk "periode lalu kepake":** teks aja, atau bisa di-tap buat ngisi angkanya.
- **Label range tanggal** ("25 sep – 24 okt") di menu bulan / 04.1 / statistik, masih utang dari periode gajian.
