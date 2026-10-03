# mibu — gajian jatuh weekend: jumat atau tetap

Keputusan 2026-10-03, udah jalan (board 00.24, 02.4j–k). Nambahin [PAYDAY_CYCLE_PLAN.md](PAYDAY_CYCLE_PLAN.md) (v1: weekend digeser ke jumat otomatis) dan pakai mekanisme ganti tanggal di [PAYDAY_CHANGE_PLAN.md](PAYDAY_CHANGE_PLAN.md).

## Masalah

Gajian yang jatuh sabtu / minggu selalu dihitung jumat sebelumnya (`PaydayShift.previousWorkday`). Kebanyakan kantor memang begitu, tapi ada juga yang tetap transfer di hari sabtu. Buat user kayak gitu, mibu nutup periode di hari kamis, padahal gajinya baru masuk sabtu:

- dari jumat sampai sabtu, beranda nampilin "gajian telat 1 hari" (`paydayInfo`), padahal gajinya belum telat
- periode baru mulai di hari jumat, padahal duit gajinya belum masuk
- aman jajan di periode lama dihitung kurang 1–2 hari

## Keputusan

1. **Dua pilihan:** *mundur ke jumat* (default, kayak sekarang) dan *tetap di tanggalnya*. "Maju ke senin" belum dibikin, nunggu ada yang minta. Tanggal merah tetap fase 2 (butuh data kalender), jadi pengaturan ini cuma soal sabtu / minggu.
2. **Disimpan per aturan periode.** Tiap aturan di `periodRules` udah punya `shift`. Nggak perlu kolom baru, nggak perlu migrasi.
3. **Mulai berlaku kapan: sama kayak ganti tanggal gajian.** Pengaturan ini bisa ngegeser batas periode (contoh: 25 okt jatuh minggu, jadi 23 okt kalau "jumat", 25 okt kalau "tetap"). Jadi berlaku mulai periode berikutnya, kecuali masih di periode setup. Waktu mulainya diputusin `paydayChangeFrom`. Potongan periode, penggabungan, dan budget proporsi ikut jalan, karena buat mesin periode ini cuma satu aturan baru.
4. **Cuma bisa diatur di 02.4**, nggak ditanya pas setup 01.4. Default "jumat" udah pas buat kebanyakan orang, dan setup nggak perlu nambah pertanyaan.

## UI

**00.24 PaydaySheet**

- Di bawah kartu ink "gajian berikutnya" ada label kecil "kalau jatuh sabtu / minggu", di bawahnya dua chip [mundur ke jumat] [tetap tanggalnya] (`PaydayChip`, sama kayak chip tanggal). Kalau label dan chip dijejer satu baris, nggak muat di lebar 350. Bagian ini selalu tampil, karena pengaturannya berlaku buat bulan-bulan berikutnya juga, nggak cuma bulan ini.
- Kartu ink ngikutin pilihan:
  - jumat: "jum 23 okt" + catatan "tgl 25 jatuh hari minggu → dihitung jumat" (kayak sekarang)
  - tetap: "min 25 okt", tanpa catatan
- Tombol simpan aktif kalau tanggal **atau** pengaturan weekend berubah. Labelnya:
  - tanggal berubah: "simpan tgl 28"
  - cuma weekend yang berubah: "simpan"
  - nggak ada yang berubah: "oke"
- Preview "periode ini jadi …" (PAYDAY_CHANGE_PLAN) ikut ngitung pengaruh pengaturan weekend.
- Catatan di bawah: "budget & limit ngikut gajian. ganti tanggal atau weekend berlaku mulai periode berikutnya."

**Toast**

- Tanggal berubah: "gajian jadi tgl 28" (kayak sekarang)
- Cuma weekend yang berubah: "gajian tetap di tgl 25" / "weekend dihitung jumat". Dibikin pendek biar judulnya muat di samping tombol batalin.
- Subjudul toast sama kayak ganti tanggal: "berlaku mulai …, periode ini selesai dulu" atau "periode ini jadi sampai …"

**02.4 pengaturan**

Baris tanggal gajian tetap "tiap tgl 25". Kalau ditambah "• weekend tetap", lebarnya nggak muat. Lagian tanggal di subjudulnya udah ngikutin pengaturan ("min 25 okt" vs "jum 23 okt"), jadi bedanya tetap kelihatan.

**Contoh board** (hari ini 16 okt, gajian 25 "jumat" diganti ke "tetap", 02.4j–k): periode jalan 25 sep – 22 okt jadi 25 sep – 24 okt. Ujungnya pas sama siklus baru, jadi ini periode normal dan budgetnya nggak diproporsi. Preview: "periode ini jadi 25 sep – 24 okt", "30 hari • budget Rp8jt". Toast: "gajian tetap di tgl 25", subjudul "periode ini jadi sampai sab 24 okt".

## Yang udah ketangani tanpa kode baru

- **Pilih "tetap", tapi kantor ternyata transfer jumat:** aturan cair duluan (gaji dicatat ≤ 3 hari lebih awal) udah otomatis mulai periodenya dari hari jumat itu.
- **Pilih "jumat", tapi gaji baru masuk sabtu:** tetap muncul "telat 1 hari". Ini justru alasan pengaturan ini dibikin, dan pilihan "tetap" langsung beresin.

## Urutan kerja

1. ✅ **Desain:** 00.24 (pilihan weekend, kartu ink, label simpan, catatan), artboard baru 02.4j (sheet) dan 02.4k (kesimpen + batalin), toast, tanggal di 02.4, note baris 02.
2. ✅ **Domain + test:** `paydayInfo` nerima `shift` (sekarang hardcode `previousWorkday`). Provider yang ngasih tanggal gajian aktif juga ngasih shift aturan yang berlaku.
3. ✅ **Data:** `setPayday(day, shift)` nulis shift ke aturan (sekarang selalu `previousWorkday`). Sama kayak ganti tanggal: aturan yang udah antri diupdate.
4. ✅ **UI:** pilihan weekend di 00.24, catatan shift (`_shiftNote`) ikut pilihan, preview + toast, tanggal di 02.4 ikut shift, copy di `app_id.arb`.

Catatan implementasi:

- `activeShiftProvider` = shift aturan yang berlaku hari ini, dipakai `paydayInfo` di beranda dan 02.4. `paydayShiftProvider` = shift yang terakhir di-set, termasuk yang masih antri. Ini yang diedit di 00.24, sama kayak `Profile.payday` buat tanggal.
- Sheet ngembaliin `(day, shift)`. `setPayday(day, shift:)` nulis keduanya, dan batalin balik ke dua-duanya.
