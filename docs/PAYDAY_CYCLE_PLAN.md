# mibu — rencana siklus gajian

Sumber: Claude Doc "mibu · rencana siklus gajian" (https://claude.ai/artifact/WonfHvLYgTC29wNk9p7LBv), versi 2026-10-02. Doc itu pegangan utamanya; file ini salinan di repo plus [penyesuaian ke kode](#penyesuaian-di-repo) di bagian akhir.

## Ringkasan

Siklus gajian nggak masuk v1, tapi fondasinya dipasang dari sekarang: semua logic "bulan ini" lewat satu `Period` (start–end). Nanti nambah siklus cukup bikin `PeriodResolver` baru, nggak perlu bongkar query, data, atau UI satu-satu.

Siklus gajian = periode dari tanggal gajian ke gajian berikutnya. Contoh gajian tgl 25: siklus 25 okt – 24 nov. Di v1, mibu pakai bulan kalender (1–31) buat budget, limit kantong, statistik, dan sisa budget. Saldo tetap kumulatif dan nggak tergantung periode, jadi udah aman buat orang yang gajian tgl 25.

Kenapa ditunda: siklus nambah konsep baru di semua screen, dan butuh data dulu (berapa banyak user yang tanggal gajiannya bukan tgl 1, dan seberapa sering gaji cair lebih awal).

## Prinsip

1. **Satu periode buat semua.** Budget, sisa budget, reset limit kantong, chip aman jajan, statistik "bulan", dan month picker selalu pakai periode yang sama. Nggak boleh ada screen yang pakai siklus sementara screen lain pakai kalender.
2. **Default bulan kalender.** Siklus gajian itu opsi di pengaturan, bukan paksaan. Freelance dan yang gajinya nggak tentu tetap di kalender.
3. **Nama periode tetap pakai bulan.** Siklus 25 okt – 24 nov tetap disebut "oktober", dengan subjudul range tanggal. Nggak ada istilah baru kayak "siklus #12".
4. **Saldo nggak pernah ikut periode.** Saldo selalu kumulatif. Yang berubah cuma angka yang ada di dalam periode.
5. **Masa lalu nggak dihitung ulang.** Periode yang udah lewat dikunci sesuai aturan waktu itu, biar statistik lama nggak loncat waktu setting diganti.

## Fase 0 — fondasi di v1 (wajib sekarang)

Ini yang bikin nanti nggak pain. Semuanya masih pakai bulan kalender, user nggak liat bedanya.

- [ ] Bikin `Period(start, end)` half-open `[start, end)`, cuma tanggal tanpa jam. `id` (`"2026-10"`) cuma buat label & analytics, **nggak pernah jadi key di database**.
- [ ] Bikin interface `PeriodResolver` + `SegmentedResolver` yang baca `periodRules`. Di v1 isinya satu segmen kalender. Nggak ada yang ngitung `DateTime(year, month, 1)` sendiri.
- [ ] Tabel `periodRules(id, effectiveFrom, mode, paydayDay, shift, createdAt)`, append-only. Aturan baru selalu berlaku mulai `end` periode yang lagi jalan.
- [ ] Semua query transaksi pakai range `date >= start && date < end` + index komposit `(userId, date)`. Jangan filter pakai `month == 10`.
- [ ] Budget dan limit simpan `start` + `end` di tiap baris (`budgets(start, end, amount)`, `limits(categoryId, start, end, amount)`). Lookup pakai range yang sama persis; kalau belum ada, salin dari baris terakhir dengan range baru. Data lama nggak pernah disentuh.
- [ ] Transaksi simpan `date` lokal (yyyy-mm-dd) terpisah dari `createdAt`. Periode ditentukan dari `date`, bukan dari jam server atau UTC.
- [ ] Copy periode lewat helper `periodNoun()` ("bulan ini"), `periodLabel()`, `periodRange()`. CI grep nolak string "bulan ini" di luar file helper.
- [ ] Jumlah hari tersisa (chip aman jajan, "15 hari lagi" di kantong) dari `period.end`, bukan dari `daysInMonth`.
- [ ] Tanggal gajian dari atur awal 01.4 tetap disimpan (`paydayDay`, 1–31), walaupun di v1 cuma dipakai buat "gajian lagi n hari". Default 25 (payday paling umum di Indonesia), udah kepilih di chip 01.4. User yang skip atau data lama juga diisi 25.
- [ ] Pemasukan bisa ditandai "gajian" (kategori atau flag). Ini nanti dipakai buat mulai siklus dan auto-detect.

Perkiraan biaya: kecil kalau dikerjain dari awal, karena cuma disiplin bikin helper. Kalau ditambahin setelah v1 rilis, harus migrasi data budget/limit dan audit semua query.

## Model data & algoritma

Nama periode diambil dari bulan **nominal** gajiannya, bukan dari tanggal mulai setelah digeser. Contoh: gajian tgl 1 nov jatuh hari Minggu dan cair Jum 30 okt, periodenya tetap "november".

Implementasi di repo: [`lib/domain/period.dart`](../apps/mobile/lib/domain/period.dart) (beda dari draft doc, lihat penyesuaian). Draft dari doc:

```dart
class Period {
  final String id;          // "2026-10" = bulan nominal
  final DateTime start;     // inklusif, date-only
  final DateTime end;       // eksklusif
  bool contains(DateTime d) => !d.isBefore(start) && d.isBefore(end);
  int daysLeft(DateTime today) => end.difference(today).inDays; // termasuk hari ini
}

abstract class PeriodResolver {
  Period periodOf(DateTime date);
  Period next(Period p) => periodOf(p.end);
  Period prev(Period p) => periodOf(p.start.subtract(const Duration(days: 1)));
}

class CalendarMonthResolver extends PeriodResolver { … }   // [1 bln, 1 bln berikutnya)

enum PaydayShift { none, previousWorkday }

class PaydayCycleResolver extends PeriodResolver {
  // anchor(y, m) = tanggal gajian beneran buat bulan nominal (y, m):
  //   paydayDay > hari terakhir → dipotong (31 → 30 / 28)
  //   previousWorkday → mundur selama sabtu/minggu/tanggal merah
  // periodOf(d) cek bulan nominal +1, 0, −1: anchor bulan depan bisa maju ke bulan ini kalau digeser
}
```

Catatan buat implementasi:

- Contoh `PaydayCycleResolver()` (gajian 25): tgl 16 okt masuk periode `2026-09` (25 sep – 24 okt), tgl 25 okt masuk `2026-10` (25 okt – 24 nov). Penamaan ini perlu diputusin, lihat bagian terakhir.
- Setting periode disimpan sebagai segmen di `periodRules`, bukan satu nilai. `SegmentedResolver` milih aturan yang `effectiveFrom`-nya paling akhir ≤ tanggal itu, jadi periode lama selalu dihitung pakai aturan waktu itu.
- Budget: `budgets(start, end, amount)`. Limit: `limits(categoryId, start, end, amount)`, defaultnya disalin dari baris terakhir waktu periode baru mulai. Key-nya range, bukan id, biar ganti mode nggak bikin bentrok.

## Roadmap

Fondasi masuk v1, siklus gajian baru dibuka kalau datanya dukung.

| Fase | Kapan | Isi | Gate buat lanjut |
|---|---|---|---|
| 0 · fondasi | masuk v1, sekarang | `Period` + resolver, query pakai range, budget per periode | semua query lewat resolver, test hijau |
| 1 · validasi | v1.x, setelah rilis | ukur tgl gajian user, tandai pemasukan sebagai gajian | cukup user gajian bukan tgl 1 |
| 2 · fitur | di balik flag | `PaydayCycleResolver`, row di pengaturan, label range tanggal | beta tanpa selisih angka antar screen |
| 3 · rollout | semua user | buka flag bertahap, auto-detect tgl dari pemasukan | — |

Cuma fase 0 yang punya jadwal (masuk v1). Fase 1–3 jalan kalau gate sebelumnya lolos, dan bisa berhenti di fase 1 kalau datanya nunjukin hampir semua user gajian tgl 1.

## Edge case & aturan

| kasus | aturan | yang user liat |
|---|---|---|
| gajian tgl 29–31 | dipotong ke hari terakhir bulan itu | feb: siklus mulai 28 feb |
| gajian jatuh weekend / tanggal merah | opsi `previousWorkday` (default off) | "cair duluan kalau libur" di pengaturan |
| gaji cair lebih awal dari jadwal | v1 fitur: tetap ikut jadwal. Opsional: pemasukan "gajian" yang dicatat ≤ 3 hari sebelum anchor nawarin "mulai siklus baru sekarang?" | toast + batalin |
| gaji telat | siklus baru tetap mulai di anchor | hero tetap jalan (saldo kumulatif), chip aman jajan pakai sisa budget siklus baru |
| ganti tanggal gajian | siklus yang lagi jalan dipanjangin/dipendekin sampai anchor baru, siklus lama dikunci | sheet konfirmasi "siklus ini jadi 25 okt – 9 nov" |
| pindah calendar ↔ siklus | berlaku mulai periode berikutnya, periode yang jalan selesai pakai aturan lama | "mulai 25 nov" |
| siklus pertama user baru | dimulai dari tanggal daftar, label "siklus pertama" | "15 hari" di subjudul |
| edit tanggal transaksi lewat batas siklus | transaksi pindah periode, budget/limit dua periode dihitung ulang | toast "pindah ke siklus september" |
| transaksi di periode yang udah dikunci | boleh, angka periode itu ikut berubah, tapi limit/budget snapshot nggak | nggak ada perubahan UI khusus |
| freelance / pemasukan nggak tentu | tetap calendar, opsi siklus nggak disaranin | copy di pengaturan: "cocok kalau gaji tetap tiap bulan" |
| pemasukan lebih dari satu (gaji + sampingan) | siklus cuma ngikut satu tanggal gajian utama | — |
| zona waktu / jam 00:00 | periode dari `date` lokal transaksi, bukan UTC | — |

## Dampak ke screen & testing

Screen yang perlu disentuh pas fase 2. Kalau fase 0 rapi, sebagian besar cuma ganti label.

| board | yang berubah |
|---|---|
| 01.4 atur awal | setelah pilih tanggal gajian: "hitung budget per bulan atau per gajian?" (default bulan) |
| 02.4 pengaturan | row baru "periode · per bulan / per gajian tgl 25" + sheet pilih + opsi cair duluan kalau libur |
| 02.1 beranda | HeroSaldo: sisa budget "akhir siklus", baris kecil "gajian lagi n hari" udah ada |
| 00.7 month picker / 00.8 MonthMenu | item "oktober" + sub "25 okt – 24 nov" |
| 02.2 kantong | "sisa jajan oktober" + "15 hari lagi" dari `period.end` |
| 02.3 statistik | tab "bulan" = periode, judul range tanggal, minggu tetap sen–min |
| 04.1 semua transaksi | grup per periode, header range tanggal |
| 00.16 BudgetSheet | copy "budget per gajian" kalau mode siklus |

Testing matrix (unit test resolver, jalan di CI):

- [x] paydayDay 1, 15, 25, 28, akhir × tiap bulan 2026–2028 (termasuk feb kabisat 2028)
- [x] shift `previousWorkday` waktu anchor jatuh sabtu, minggu, dan tanggal merah berturut-turut
- [x] anchor yang mundur ke bulan sebelumnya (gajian tgl 1 jatuh minggu)
- [x] `next(prev(p)) == p` dan nggak ada tanggal yang masuk dua periode atau nggak masuk sama sekali, di range 3 tahun
- [x] ganti paydayDay di tengah siklus: periode lama nggak berubah
- [x] `CalendarMonthResolver` dan query lama ngasih angka yang sama persis (regression waktu migrasi fase 0: semua test lama lolos tanpa diubah angkanya)

## Keputusan terbuka & risiko

Yang perlu diputusin sebelum fase 2:

- [ ] **Penamaan periode:** siklus 25 okt – 24 nov disebut "oktober" (bulan gajian masuk) atau "november" (bulan yang paling banyak hari-nya)? Draft di atas pakai bulan gajian masuk.
- [ ] **Mulai siklus dari jadwal atau dari pemasukan "gajian" pertama yang dicatat?** Jadwal lebih bisa diprediksi, pemasukan lebih akurat tapi bisa telat dicatat.
- [ ] **Sumber tanggal merah:** list statis per tahun di app, atau nggak usah (cuma weekend)?
- [ ] **Mode siklus buat user tanpa budget:** perlu nggak, atau mode siklus cuma muncul kalau udah pasang budget?
- [ ] **Data buat validasi:** berapa persen user yang isi tanggal gajian selain tgl 1 di atur awal. Kalau kecil, fase 2 bisa ditunda terus.

Risiko — nomor 1–5 masuk fase 0, wajib di v1 (struktur data + copy). Sisanya nunggu fase 2–3.

| # | risiko | solusi | fase |
|---|---|---|---|
| 1 | id periode bentrok pas ganti mode (`2026-10` kalender ≠ siklus) | budget & limit simpan `start`/`end`, lookup pakai range persis, salin dari baris terakhir kalau belum ada; id cuma buat label | 0 |
| 2 | periode lama ikut berubah waktu setting diganti | `periodRules` append-only + `SegmentedResolver`; aturan baru berlaku mulai `end` periode yang jalan | 0 |
| 3 | query yang lolos dari helper | semua lewat resolver, code review checklist, test regression kalender vs query lama | 0 |
| 4 | copy "bulan ini" nyebar di mana-mana | helper `periodNoun()` / `periodLabel()` / `periodRange()` + CI grep nolak literal "bulan ini" | 0 |
| 5 | query range lambat | index `(userId, date)`; total per periode di-cache pakai key `start`/`end`, dibuang tiap ada transaksi di range itu | 0 |
| 6 | dua device beda periode setelah ganti setting offline | `periodRules` di-sync, konflik `effectiveFrom` sama → `createdAt` terakhir menang; periode selalu dihitung ulang, nggak disimpan | 2 |
| 7 | reset limit & notif nembak di tanggal 1 | satu `scheduleForPeriod(period)`, dipanggil pas app dibuka, setting berubah, dan sync selesai; id job tetap per jenis biar nggak dobel | 2 |
| 8 | tagihan rutin kena 0 atau 2× dalam satu siklus | jatuh tempo tetap tanggalnya sendiri; sisa budget ngitung tagihan yang belum jatuh tempo di periode itu; hint "kos kena 2× di siklus ini" | 2 |
| 9 | statistik antar periode nggak sebanding (28–31 hari, siklus pertama pendek) | bandingin pakai rata²/hari, label "siklus pertama · n hari" | 2 |
| 10 | user bingung waktu ganti mode | berlaku mulai periode berikutnya + sheet konfirmasi dengan range tanggalnya | 2 |
| 11 | tanggal merah & cuti bersama berubah tiap tahun | default weekend aja; kalau pakai tanggal merah, remote config + fallback di app; `start` yang udah kepakai kesimpen di baris budget | 2 |
| 12 | tanggal gajian basi (ganti kerja) | 2× gajian berturut-turut lewat > 3 hari dari jadwal → tawarin ganti; ditolak = diem 3 bulan | 3 |

## Penyesuaian di repo

Fase 0 dikerjain dengan penyesuaian ini, biar cocok sama aturan repo (CLAUDE.md, [MVP_PLAN.md](MVP_PLAN.md)):

1. **Semua tabel baru pakai `SyncColumns`**: UUID `id`, `createdAt`, `updatedAt`, `deletedAt`. Undo tetap jalan.
2. **Lookup budget/limit**: baris dengan range persis, kalau nggak ada = baris terakhir sebelumnya. Baris cuma dibikin pas user nyimpen, bukan pas baca (baca nggak pernah nulis). Hasilnya sama kayak "salin dari baris terakhir".
3. **Copot limit / hapus budget** = baris periode ini dengan `amount` null. Periode lama utuh.
4. **Nggak ada `userId`**: app full lokal, belum ada login. Index cukup di `transactions.at` (udah ada).
5. **Nggak ada kolom `date` terpisah**: `transactions.at` udah waktu lokal, periode dihitung dari tanggal lokalnya. Aturan "dari tanggal lokal, bukan UTC" tetap kepenuhi.
6. **`paydayDay` 1–31, 31 = akhir** (design 00.24: chip 1 · 10 · 15 · 25 · 28 · akhir + grid 1–31). Tanggal lewat panjang bulan dipotong ke hari terakhir; nilai lama `0` tetap dibaca sebagai akhir. `PaydayCycleResolver` nerima `paydayDay` wajib (nggak ada default sendiri); default 25 cuma di 01.4.
7. **Tanda "gajian"**: kolom `categories.isPayday` (bool); seed gajian = true. Belum ada UI.
8. **`periodRules` kosong = kalender**: repository selalu naruh aturan dasar kalender paling awal, jadi v1 nggak nulis baris apa-apa.
9. **"CI grep" = test** yang nolak literal "bulan ini" di `lib/ui` (copy tinggal di `app_id.arb`, jadi arb dikecualiin).
10. **Jendela yang tetap kalender**: DateSheet, DayStrip, grid MonthMenu, grafik saldo per bulan + prediksi (saldo nggak punya periode), minggu & tahun di statistik, "Rp… tahun ini" di 03.5.

Di v1 (di luar fase 0) tanggal gajian udah dipakai buat aman jajan: weekend digeser ke jumat sebelumnya otomatis (`previousWorkday`, tanpa tanggal merah), gaji dicatat ≤ 3 hari sebelum gajian = udah gajian, state hari-H / telat lihat MVP_PLAN › Aman jajan. Toggle "cair duluan kalau libur" + tanggal merah tetap fase 2.

Status fase 0:

| # | Isi | Status |
|---|---|---|
| F0.1 | `Period` + resolver + unit test | ✅ |
| F0.2 | tabel `periodRules` + `periodsProvider` / `currentPeriodProvider` | ✅ |
| F0.3 | jendela "bulan ini" lewat resolver + test regression | ✅ |
| F0.4 | tabel `budgets` + `limits` gantiin `profile.monthlyBudget` + `categories.monthlyLimit` | ✅ |
| F0.5 | test yang nolak literal "bulan ini" di `lib/ui` ([copy_guard_test.dart](../apps/mobile/test/ui/copy_guard_test.dart)). `periodLabel` / `periodRange` nunggu pemakai pertamanya di fase 2; `periodNoun` nggak perlu karena prinsip 3 (nama tetap bulan) bikin "bulan ini" tetap bener | ✅ |
| F0.6 | sisa hari dari `period.end` (udah di F0.3), `categories.isPayday` (gajian dari seed + atur awal) | ✅ |

Masih asumsi bulan kalender (aman di v1, dibenerin pas fase 2 bareng labelnya):

- Navigasi bulan (MonthMenu beranda, carousel 04.1, cari 04.2) masih pakai awal bulan sebagai kunci, lalu diubah ke `Period` lewat `periodOf`. Datanya udah per periode; label & lompat antar periode belum.
- Ringkasan cari 04.2 (tick per tanggal 1–31, "liat bulan lain").
- `monthLeft` beranda bulan lalu (`Totals.spent` per bulan kalender). Diganti hero sisa budget 02.1p.
