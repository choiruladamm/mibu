# Verifikasi statistik

Skill testing yang dipakai sudah terpasang: `flutter-add-widget-test` dan `flutter-add-integration-test`.

Dari `apps/mobile`, jalankan test cepat:

```sh
fvm flutter test test/domain/stats_test.dart test/domain/period_test.dart test/ui/features/stats/stats_test.dart test/ui/features/budget test/ui/copy_guard_test.dart --timeout 30s
```

Integration test pada simulator/emulator yang tersedia:

```sh
fvm flutter test integration_test/stats_test.dart --flavor dev -d <device-id> --timeout 60s
```

Test menggunakan mibu dev, database SQLite in-memory, seed fixture, dan waktu tetap. Data produksi tidak dibaca atau diubah. Entry point khusus ini menguji layar statistik bersama provider, repository, database, dan rendering native; tidak melewati onboarding atau kunci aplikasi.

Cakupan: navigasi minggu/bulan/tahun, nilai periode sebelumnya, pembaruan total melalui stream database, pemilihan bar, scroll ke kategori, serta transaksi CSV masa depan yang tersimpan dan muncul setelah tanggal berganti. Widget test mencakup loading/error/retry transaksi dan budget, budget historis, empty state, serta layout 360/390 dengan font bundled. Domain test memeriksa periode gajian, batas budget, rata-rata, dan basis waktu tahunan.

Test tidak membuktikan semua flow aplikasi, aksesibilitas penuh, atau perilaku hardware biometrik.
