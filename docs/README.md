# mibu: dokumentasi

> Aplikasi: **mibu**, pencatat keuangan pribadi (Indonesia, IDR), fully local.
> Desain: Claude Design "mibu" (https://claude.ai/artifact/25RLRcYScmmPDzjBvg9Zz8). Nomor screen (02.1, 07.2 …) = id board.

> **Untuk Claude Code:** folder `docs/` adalah sumber kebenaran untuk keputusan produk, aturan hitungan, dan alur. File inti ada di tabel di bawah. `docs/ideas/` adalah ide yang belum diputusin, **jangan dikerjakan** kecuali diminta. Rumus (aman jajan, statistik, CSV, periode) sudah ada di sini, jangan bikin ulang.

| File | Isi |
|------|-----|
| [mvp.md](mvp.md) | Scope MVP, arsitektur, model data, rumus (aman jajan, statistik, CSV) |
| [features.md](features.md) | Daftar fitur per screen (id board), komponen bersama, entitas |
| [payday-cycle.md](payday-cycle.md) | Siklus gajian: aturan periode, resolver |
| [payday-change.md](payday-change.md) | Ganti tanggal gajian: potongan periode |
| [payday-weekend.md](payday-weekend.md) | Gajian jatuh weekend: geser ke jumat atau tetap |
| [period-ledger.md](period-ledger.md) | Saldo = pemasukan − pengeluaran per periode gajian, tanpa carryover |
| [hide-income.md](hide-income.md) | Sembunyiin nominal pemasukan |
| [import.md](import.md) | Import CSV (mibu sendiri + Excel) |
| [app-lock.md](app-lock.md) | Kunci app: pin 6 digit + face id / sidik jari, penahanan, penyimpanan |
| [ideas/need-want.md](ideas/need-want.md) | Draft: kebutuhan vs keinginan |

Aturan docs: satu file per topik, nama kecil dengan tanda hubung. Ide belum fix masuk `ideas/`, pindah ke root `docs/` setelah diputusin. Nomor screen mengikuti board (direstrukturisasi 2026-10-10).
