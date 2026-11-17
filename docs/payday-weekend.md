# mibu — payday on a weekend: Friday or keep the date

Decision made 2026-10-03 and implemented (boards 00.24, 05.1j–k). This adds to [payday-cycle.md](payday-cycle.md) (weekends are shifted to Friday in v1) and uses the change mechanism in [payday-change.md](payday-change.md).

## Problem

A payday falling on Saturday or Sunday is always treated as the previous Friday (`PaydayShift.previousWorkday`). Most employers do that, but some transfer on Saturday. For those users, mibu closes the period on Thursday even though the salary arrives Saturday:

- From Friday to Saturday, the home screen says “gajian telat 1 hari” (`paydayInfo`) even though payday is not late.
- The new period starts Friday, before the salary arrives.
- Safe-to-spend for the old period is calculated with one or two fewer days.

## Decision

1. **Two choices:** *shift back to Friday* (default, current behavior) and *keep the date*. “Shift forward to Monday” is not implemented unless requested. Public holidays remain phase 2 (calendar data is needed), so this setting covers Saturday and Sunday only.
2. **Stored per period rule.** Each `periodRules` row already has `shift`; no new column or migration is needed.
3. **Effective date follows payday changes.** This setting can move a period boundary (for example, Sunday Oct 25 becomes Oct 23 with “Friday”, or Oct 25 with “keep date”). It therefore takes effect from the next period, except while still in the setup period. `paydayChangeFrom` determines when. Period splits, merges, and prorated budgets apply too: the period engine sees one new rule.
4. **Configured only in 05.1**, not asked during setup 01.4. The default “Friday” fits most users and avoids another setup question.

## UI

**00.24 PaydaySheet**

- Below the ink “next payday” card, show the small label “kalau jatuh sabtu / minggu” and two chips [mundur ke jumat] [tetap tanggalnya] (`PaydayChip`, same as date chips). The label and chips do not fit together on a 350-wide line. Always show this setting because it applies to future months too.
- The ink card reflects the choice:
  - Friday: “jum 23 okt” with note “tgl 25 jatuh hari minggu → dihitung jumat” (current behavior).
  - Keep date: “min 25 okt”, without a note.
- Enable save when either the date **or** weekend setting changes. Labels:
  - Date changed: “simpan tgl 28”
  - Only weekend setting changed: “simpan”
  - No changes: “oke”
- The “periode ini jadi …” preview ([payday-change.md](payday-change.md)) also accounts for the weekend setting.
- Note below: “budget & limit ngikut gajian. ganti tanggal atau weekend berlaku mulai periode berikutnya.”

**Toast**

- Date changed: “gajian jadi tgl 28” (as before).
- Only weekend setting changed: “gajian tetap di tgl 25” / “weekend dihitung jumat”. Keep it short so the title fits beside the undo button.
- Toast subtitle follows payday changes: “berlaku mulai …, periode ini selesai dulu” or “periode ini jadi sampai …”.

**05.1 settings**

The payday row stays “tiap tgl 25”. Adding “• weekend tetap” would not fit. The date in its subtitle already reflects the setting (“min 25 okt” vs “jum 23 okt”), so the difference remains visible.

**Board example** (today is Oct 16; payday is the 25th, changed from “Friday” to “keep date”, 05.1j–k): the current period changes from Sep 25–Oct 22 to Sep 25–Oct 24. It now ends at the new cycle boundary, so this is a normal period and its budget is not prorated. Preview: “periode ini jadi 25 sep – 24 okt”, “30 hari • budget Rp8jt”. Toast: “gajian tetap di tgl 25”, subtitle “periode ini jadi sampai sab 24 okt”.

## Already handled without new code

- **“Keep date” is selected, but the employer transfers Friday:** the early-payday rule (salary recorded up to 3 days early) already starts the period on Friday.
- **“Friday” is selected, but salary arrives Saturday:** it still shows “telat 1 hari”. This is the reason for the setting; choosing “keep date” resolves it.

## Work sequence

1. ✅ **Design:** 00.24 (weekend choice, ink card, save label, note), new 05.1j (sheet) and 05.1k (saved + undo) boards, toast, date in 05.1, note in row 02.
2. ✅ **Domain + test:** `paydayInfo` accepts `shift` (previously hardcoded to `previousWorkday`). The provider supplying the active payday date also supplies the applicable shift.
3. ✅ **Data:** `setPayday(day, shift)` writes the shift (previously always `previousWorkday`). A queued rule is updated, as with date changes.
4. ✅ **UI:** weekend choice in 00.24, `_shiftNote` follows the choice, preview and toast, date in 05.1 follows shift, copy in `app_id.arb`.

Implementation notes:

- `activeShiftProvider` is the shift rule effective today, used by `paydayInfo` on home and 05.1. `paydayShiftProvider` is the most recently selected shift, including one queued for later. 00.24 edits this, just as `Profile.payday` holds the date.
- The sheet returns `(day, shift)`. `setPayday(day, shift:)` writes both; undo restores both.
