import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:intl/intl.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../../domain/period.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/clock.dart';
import '../../../core/dates.dart';
import '../../../core/finance_providers.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/meta_line.dart';
import '../../../core/widgets/payday_chip.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/toast.dart';

final _nextDay = DateFormat('EEE d MMM', 'id');

/// 02.4e–g tanggal gajian: PaydaySheet (00.24), save → toast with batalin.
Future<void> editPayday(BuildContext context, WidgetRef ref) async {
  final repo = ref.read(financeRepositoryProvider);
  final saved = _normal(ref.read(profileProvider).value?.payday ?? 25);
  final day = await showAppSheet<int>(context, _PaydaySheet(saved: saved));
  if (day == null || day == saved || !context.mounted) return;

  final now = ref.read(clockProvider)();
  final after = _runningAfter(ref.read, day);
  final startsOn = await repo.setPayday(
    day,
    periods: ref.read(periodsProvider),
    now: now,
  );
  if (!context.mounted) return;
  final l = AppLocalizations.of(context)!;
  final info = paydayInfo(
    now: ref.read(clockProvider)(),
    payday: day,
    salaries: ref.read(salaryDatesProvider).value ?? const [],
  );
  showToast(
    context,
    icon: ToastIcon.check,
    title: l.paydaySavedTitle(_label(l, day)),
    sub: after != null
        ? l.paydaySavedSubMerged(_lastDay(after))
        : startsOn != null
        ? l.paydaySavedSubLater(_nextDay.format(startsOn).toLowerCase())
        : info.status == PaydayStatus.today
        ? l.paydaySavedSubToday
        : l.paydaySavedSub(info.daysToNext),
    onUndo: () => repo.setPayday(
      saved,
      periods: ref.read(periodsProvider),
      now: ref.read(clockProvider)(),
    ),
  );
}

/// The running period if [day] were saved now, when that changes it (a
/// sliver merged in, docs/PAYDAY_CHANGE_PLAN.md); null = it stays, or the
/// change applies at once. [get] = ref.watch in build, ref.read otherwise.
Period? _runningAfter(T Function<T>(ProviderListenable<T>) get, int day) {
  final rules = get(periodRulesProvider).value;
  if (rules == null) return null;
  final current = get(currentPeriodProvider);
  final today = dateOnly(get(nowProvider));
  final at = get(profileProvider).value?.onboardedAt;
  final from = paydayChangeFrom(
    rules,
    current: current,
    today: today,
    setUpOn: at == null ? today : dateOnly(at),
  );
  if (from == null) return null;
  final after = SegmentedResolver([
    calendarBase,
    ...withPayday(rules, day, from),
  ], salaries: get(salaryDatesProvider).value ?? const []).periodOf(today);
  return after == current ? null : after;
}

String _lastDay(Period p) => _nextDay
    .format(DateTime(p.end.year, p.end.month, p.end.day - 1))
    .toLowerCase();

/// Legacy 0 (akhir) reads as 31.
int _normal(int day) => day == 0 ? 31 : day;

String _label(AppLocalizations l, int day) =>
    day == 31 ? l.settingsPaydayEnd : l.paydayOtherDay(day);

class _PaydaySheet extends ConsumerStatefulWidget {
  const _PaydaySheet({required this.saved});

  final int saved;

  @override
  ConsumerState<_PaydaySheet> createState() => _PaydaySheetState();
}

class _PaydaySheetState extends ConsumerState<_PaydaySheet> {
  late int _sel = widget.saved;
  bool _grid = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final now = ref.watch(nowProvider);
    final salaries = ref.watch(salaryDatesProvider).value ?? const [];
    final info = paydayInfo(now: now, payday: _sel, salaries: salaries);
    final today = info.status == PaydayStatus.today;
    final nextDate = today ? DateTime(now.year, now.month, now.day) : info.next;
    final changed = _sel != widget.saved;
    final custom = !paydayChoices.contains(_sel);
    final muted = AppText.label.copyWith(color: AppColors.muted);
    final after = changed ? _runningAfter(ref.watch, _sel) : null;
    final budget = ref.watch(profileProvider).value?.monthlyBudget;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.line,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Semantics(
            header: true,
            child: Text(
              l.paydaySheetTitle,
              style: AppText.sheetTitle.copyWith(fontSize: 24),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l.paydaySheetBody,
            style: muted.copyWith(fontSize: 15, height: 1.4),
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 8,
            runSpacing: 14,
            children: [
              for (final d in paydayChoices)
                PaydayChip(
                  day: d,
                  on: _sel == d && !_grid,
                  onTap: () => setState(() {
                    _sel = d;
                    _grid = false;
                  }),
                ),
              PaydayChip(
                day: _sel,
                label: custom ? l.paydayOtherDay(_sel) : l.paydayOther,
                on: _grid || custom,
                onTap: () => setState(() => _grid = !_grid),
              ),
            ],
          ),
          if (_grid) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(AppRadius.statTile),
              ),
              child: GridView.count(
                crossAxisCount: 7,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                mainAxisExtent: 36,
                children: [
                  for (var d = 1; d <= 31; d++)
                    Semantics(
                      button: true,
                      selected: _sel == d,
                      label: l.paydayDayLabel(d),
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: () => setState(() => _sel = d),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: _sel == d ? AppColors.ink : null,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$d',
                            style: AppText.label.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _sel == d
                                  ? AppColors.paper
                                  : AppColors.ink,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          _NextCard(
            date: _nextDay.format(nextDate).toLowerCase(),
            inText: today ? l.paydayNextToday : l.paydayNextIn(info.daysToNext),
            shift: _shiftNote(l, _sel, info.next),
          ),
          if (after != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: MetaLine([
                l.paydayPreviewRange(periodRange(after.start, after.end)),
                l.paydayPreviewDays(after.length),
                if (budget != null)
                  l.paydayPreviewBudget(
                    context.rpCompact(prorate(budget, after)),
                  ),
              ], style: AppText.label.copyWith(fontWeight: FontWeight.w500)),
            ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l.paydayBudgetNote,
              style: AppText.caption.copyWith(
                color: AppColors.muted,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: changed ? l.paydaySave(_label(l, _sel)) : l.paydayOk,
            onPressed: () => Navigator.of(context).pop(_sel),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.ink,
                shape: const StadiumBorder(),
              ),
              child: Text(
                l.confirmCancel,
                style: AppText.label.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "tgl 25 jatuh hari minggu → dihitung jumat" when [next] is a weekend
/// payday paid early; null otherwise.
String? _shiftNote(AppLocalizations l, int day, DateTime next) {
  final r = PaydayCycleResolver(day, shift: PaydayShift.previousWorkday);
  // Shifting only moves a payday back, at most into the month before.
  for (final m in [next.month, next.month + 1]) {
    if (r.anchor(next.year, m) != next) continue;
    final last = DateTime(next.year, m + 1, 0).day;
    final raw = DateTime(next.year, m, day > last ? last : day);
    if (raw == next) return null;
    return l.paydayShiftNote(
      _label(l, day),
      raw.weekday == DateTime.sunday ? l.paydaySunday : l.paydaySaturday,
    );
  }
  return null;
}

/// Ink card: the payday it'll count to, and why it moved off a weekend.
class _NextCard extends StatelessWidget {
  const _NextCard({
    required this.date,
    required this.inText,
    required this.shift,
  });

  final String date, inText;
  final String? shift; // "… jatuh hari minggu → dihitung jumat"

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final soft = AppText.caption.copyWith(
      fontSize: 13,
      color: AppColors.onInkMuted,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.paydayNext, style: soft),
              Text(inText, style: soft),
            ],
          ),
          Text(
            date,
            style: AppText.label.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.paper,
            ),
          ),
          if (shift case final note?) Text(note, style: soft),
        ],
      ),
    );
  }
}
