# mibu — kunci app

Design: board 99.10a–u + komponen 00.31 PinPad di artifact "mibu". Issue: #3 (induk), #25–#28.

## Kenapa

Hp bisa dipinjem atau diambil orang. Kunci app nutup catatan dan nominal di mibu tanpa login (semua data lokal).

## Model

PIN 6 digit wajib; face id (iPhone) / sidik jari (Android) opsional di atasnya. Semua state kunci disimpen di `flutter_secure_storage` sebagai satu nilai JSON (`lock.v1`): hash pin + salt (HMAC-SHA256), hitungan salah, ditahan sampai, nyala bio, bio berubah, kunci lagi setelah, blur. **Bukan di Drift**: `schemaVersion` tetap, nggak ada migrasi. Kunci mati = nilainya dihapus (setelan ikut hilang).

Keychain iOS bertahan setelah uninstall, database enggak. `bootstrap()` kosongin secure storage kalau profil belum onboarded (instal baru), lalu muat state kunci sebelum frame pertama. Android: file secure storage dikecualikan dari auto-backup (`backup_rules.xml`, `data_extraction_rules.xml`), `allowBackup` tetap nyala buat database.

## Aturan

| apa | aturan |
|---|---|
| pin | tepat 6 digit. Ditolak: semua digit sama, atau urut naik / turun (boleh nyebrang 9→0): 111111, 123456, 654321, 890123 |
| penahanan | salah 5× → 30 dtk, 10× → 1 mnt, 15× → 5 mnt, 20× dst → 15 mnt (mentok). Sisa "N× lagi" = 5 − (salah mod 5) |
| reset hitungan | cuma kalau pin bener atau biometrik berhasil. Matiin paksa app nggak mereset |
| satu counter | layar kunci, sheet matiin, ganti pin (pin lama), nyalain biometrik lagi |
| pas ditahan | digit + hapus redup 35% dan nggak jalan, tombol biometrik tetap jalan |
| jam | `ditahan sampai` disimpen sebagai timestamp. Jam hp dimundurin tetap ditahan |
| kapan kunci | cold start selalu. Balik dari background kunci kalau ditinggal ≥ "kunci lagi setelah" (langsung / 1 / 5 / 15 mnt, default 1). `hidden`, bukan `inactive`: prompt face id nggak dihitung ninggalin app. Jam mundur = kunci |
| nyalain lewat pengaturan | sesi yang baru nyalain nggak langsung kekunci |
| blur | default nyala. App ketutup wordmark tiap nggak di depan (daftar app) |
| biometrik berubah | face id / sidik jari baru ke-enroll → biometrik mati sampai pin masukin lagi (flag `bioChanged`) |
| lupa pin | nggak ada reset. Jalan satu-satunya instal ulang, catatan balik cuma dari file export csv |

Rumus ada di `lib/domain/app_lock.dart` (tes: `test/domain/app_lock_test.dart`).

## Alur

- **Nyalain:** bikin pin → ketik lagi (beda = ulang dari awal) → "pakai face id juga?" (kalau hp punya) → toast. Pin baru disimpen di langkah terakhir. Sistem diminta sekali buat biometrik (izin iOS); kalau ditolak, nyala dengan pin aja.
- **Matiin:** masukin pin dulu.
- **Ganti pin:** pin lama → pin baru → ketik lagi.
- **Nyalain biometrik lagi** (setelah berubah): masukin pin dulu.
- **Layar kunci:** biometrik langsung muncul, gagal / batal pindah ke pin pad. Link "lupa pin?" buka sheet penjelasan (digambar di tempat, layar kunci ada di atas Navigator).

## Belum

- Deteksi face id / sidik jari baru ke-enroll (butuh kode native: iOS `evaluatedPolicyDomainState`, Android key Keystore). Repository dan UI-nya udah siap (`markBioChanged`), pemicunya belum ada.
- Android `FLAG_SECURE` buat blur di daftar app dan blokir screenshot. Android belum dicek di device.
