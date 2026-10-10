# mibu — sembunyiin pemasukan

**Dipasang 2026-10-03.** Design: board 05.1h–i, 06.1e, 09.1f–h, 00.29 HideSheet + note di baris 02 (dulu proposal 99.5) di artifact "mibu". Ringkasannya di [mvp.md › Sembunyiin nominal](mvp.md#sembunyiin-nominal).

## Kenapa

Buka mibu di tempat rame (kantor, kafe, KRL). Pengeluaran harian aman diliat, yang sensitif itu **gaji / pemasukan**. Mode sekarang (semua jadi `Rp•••`) kebablasan: sisa budget, aman jajan, kepake ikut ketutup.

## Model: satu setting, tiga pilihan

`profiles.hideAmounts` bool → enum:

| nilai | label | yang di-mask |
|---|---|---|
| `none` | nggak | nggak ada |
| `income` | pemasukan aja | pemasukan + turunannya |
| `all` | semua nominal | semua, perilaku switch lama |

05.1 privasi (05.1h): switch diganti baris + ›, sub = mode sekarang. Tap → sheet 3 pilihan + contoh live 3 baris (05.1i). Simpan → toast + batalin.

## `pemasukan aja` nutup

- nominal tiap pemasukan: TxRow (amount > 0), struk 08.2 transaksi pemasukan.
- 09.1 kartu periode: pemasukan, sisa pemasukan (= pemasukan − pengeluaran), selisih "naik Rp… dari september", total hari yang ada gajian (09.1f).
- 06.1 catat pemasukan (06.1e): angka yang diketik tetap keliatan, "pemasukan periode ini jadi" → `Rp•••`, bar proporsi dikosongin.
- 08.1 cari: insight pemasukan + total hasil kalau isinya pemasukan. Ditambahin ke note waktu build.

Nggak nutup: beranda (sisa budget, aman jajan, kepake), kantong, statistik, budget, pengeluaran per baris. Sejak [period-ledger.md](period-ledger.md) beranda udah nggak nampilin saldo, jadi nggak ada angka di sana yang bisa dipake ngitung gaji.

## Intip

- `income`: hero beranda nggak di-mask, jadi tap hero bukan pintu intip lagi → chip "intip 5 detik" di kartu ringkasan 09.1 (09.1g).
- Abis 5 detik / pindah layar → ketutup lagi. `peekProvider` + `Timer`, reset di router tetap.
- Tanpa face id.

## Skip

- notif "gajian masuk" / widget: app belum punya dua-duanya.
- screenshot & app switcher: di luar draft.
- ekspor CSV: angka asli.

## Keputusan

- Intip pakai timer 5 detik, berlaku di `income` dan `all`. Tap lagi = tutup.
- "tap ••• di mana aja" nggak dipasang: cuma angka utama (hero beranda / kantong / struk) + chip 09.1. Copy sheet & toast: "tap angka utama buat intip 5 detik".
- Tombol sheet "simpan" (bukan "simpan · mode", aturan tanpa "·" literal di copy).
- `hideAmounts` sekarang int enum (`HideAmounts`), diedit di tempat di `schemaVersion` 1.
