# mibu — kebutuhan vs keinginan

**Draft ide, belum fix.** Belum masuk [MVP_PLAN.md](MVP_PLAN.md), belum ada board design, belum ada kode. Kalau udah fix mau dieksekusi, baru di-mention di sana.

## Ide

Tiap pengeluaran bisa dilabel `#kebutuhan` atau `#keinginan`. Buat apa = "apa", label ini = "kenapa". Ngopi + kebutuhan (WFC) beda cerita dari ngopi + keinginan (nongkrong).

Tujuannya data buat analisis nanti: seberapa besar porsi keinginan dibanding kebutuhan per periode, dan di buat apa mana paling banyak.

## Keputusan

1. **Disimpen sebagai tag, bukan kolom.** Nggak ada perubahan skema dan nggak ada perubahan format CSV. Import, export, dan cari udah jalan (`transactions.tags`, NoteSheet 00.13, kolom `tag` di CSV).
2. **Dua tag khusus:** `kebutuhan` dan `keinginan`.
   - Saling meniadakan, satu catatan paling banyak satu dari dua.
   - Nggak bisa di-rename, dihapus, atau digabung. Kalau bisa, analisisnya rusak.
   - Nggak masuk daftar tag cepet. Mereka punya chip sendiri.
3. **Nggak dihitung ke batas 3 tag.** Batas `noteMaxTags` cuma buat tag bebas, jadi kolom `tags` bisa berisi maksimal 4. Alasannya: orang yang udah pakai 3 tag bebas tetap bisa ngelabelin, dan data analisis nggak bolong karena batas UI.
4. **Boleh kosong.** Yang belum dilabel dihitung terpisah ("belum dilabel"), bukan dianggap kebutuhan. Kos, tagihan, dan sejenisnya bisa aja nggak dilabel.

## Input

Dua chip tetap di paling atas NoteSheet 00.13, sebelum tag cepet. Tap = pilih, tap lagi = lepas, tap yang satunya = pindah. Satu tap, opsional.

## Analisis (nanti)

- Kartu di statistik 02.3: kebutuhan vs keinginan per periode (persen dan rupiah), dipecah per buat apa, dibanding periode lalu. "Belum dilabel" ditampilin terpisah.
- Hitungannya fungsi murni di `domain/` dan di-unit-test, sesuai aturan proyek. Nggak nyimpen angka turunan.
- Sebelum kartunya ada: cari "keinginan" di 04.2 udah nyocokin tag, jadi total sementara bisa diintip dari sana.
- Kartunya dinamain **"keinginan"**, bukan "impulsif". Keinginan belum tentu impulsif. Ngukur impulsif butuh sinyal lain.

## Data lama

Catatan lama dari app lain masuk lewat [import CSV](IMPORT_PLAN.md). Kolom `tag` diisi `kebutuhan` atau `keinginan` dari data asalnya, jadi analisis langsung punya riwayat.

## Kalau pindah ke kolom

Alternatifnya kolom `need` (enum nullable) di tabel transaksi plus kolom baru di CSV. Aturan "satu pilihan saja" kejaga otomatis dan nggak bisa rusak lewat rename tag.

Pindah kalau pengecualian tag di atas jadi banyak dan ngerepotin (rename, gabung, tag cepet, batas 3). Biayanya: edit skema, header CSV berubah (parser harus tetap nerima header lama), dan satu langkah migrasi tag → kolom.

## Pertanyaan terbuka

- Board design buat dua chip di NoteSheet belum ada.
- Chip juga di layar catat 03.1 langsung, atau cukup di NoteSheet?
- Draft 99.4 (CRUD tag) perlu catatan pengecualian buat dua tag ini.
- Import: kalau satu baris CSV punya dua-duanya, ambil yang mana?
