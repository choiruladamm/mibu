# mibu — sembunyiin pemasukan

**Dipasang 2026-10-03.** Design: board 99.5a–f + note 99.5 di artifact "mibu". Ringkasannya di [MVP_PLAN › Sembunyiin nominal](MVP_PLAN.md#sembunyiin-nominal).

## Kenapa

Buka mibu di tempat rame (kantor, kafe, KRL). Pengeluaran harian aman diliat, yang sensitif itu **gaji / pemasukan**. Mode sekarang (semua jadi `Rp•••`) kebablasan: sisa budget, aman jajan, kepake ikut ketutup.

## Model: satu setting, tiga pilihan

`profiles.hideAmounts` bool → enum:

| nilai | label | yang di-mask |
|---|---|---|
| `none` | nggak | nggak ada |
| `income` | pemasukan aja | pemasukan + turunannya |
| `all` | semua nominal | semua, perilaku switch lama |

02.4 privasi (99.5a): switch diganti baris + ›, sub = mode sekarang. Tap → sheet 3 pilihan + contoh live 3 baris (99.5b). Simpan → toast + batalin.

## `pemasukan aja` nutup

- nominal tiap pemasukan: TxRow (amount > 0), struk 04.3 transaksi pemasukan.
- 04.1 kartu periode: pemasukan, sisa pemasukan (= pemasukan − pengeluaran), selisih "naik Rp… dari september", total hari yang ada gajian (99.5c).
- 03.1 catat pemasukan (99.5f): angka yang diketik tetap keliatan, "pemasukan periode ini jadi" → `Rp•••`, bar proporsi dikosongin.
- 04.2 cari: insight pemasukan + total hasil kalau isinya pemasukan. Ditambahin ke note 99.5 waktu build.

Nggak nutup: beranda (sisa budget, aman jajan, kepake), kantong, statistik, budget, pengeluaran per baris. Sejak [PERIOD_LEDGER_PLAN.md](PERIOD_LEDGER_PLAN.md) beranda udah nggak nampilin saldo, jadi nggak ada angka di sana yang bisa dipake ngitung gaji.

## Intip

- `income`: hero beranda nggak di-mask, jadi tap hero bukan pintu intip lagi → chip "intip 5 detik" di kartu ringkasan 04.1 (99.5d).
- Abis 5 detik / pindah layar → ketutup lagi. `peekProvider` + `Timer`, reset di router tetap.
- Tanpa face id.

## Skip

- notif "gajian masuk" / widget: app belum punya dua-duanya.
- screenshot & app switcher: di luar draft.
- ekspor CSV: angka asli.

## Keputusan

- Intip pakai timer 5 detik, berlaku di `income` dan `all`. Tap lagi = tutup.
- "tap ••• di mana aja" nggak dipasang: cuma angka utama (hero beranda / kantong / struk) + chip 04.1. Copy sheet & toast: "tap angka utama buat intip 5 detik".
- Tombol sheet "simpan" (bukan "simpan · mode", aturan tanpa "·" literal di copy).
- `hideAmounts` sekarang int enum (`HideAmounts`), diedit di tempat di `schemaVersion` 1.
