import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/clock.dart';
import '../../../core/finance_providers.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
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
    sub: startsOn != null
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
    final totals = ref.watch(totalsProvider).value;
    PaydayInfo infoFor(int d) =>
        paydayInfo(now: now, payday: d, salaries: salaries);
    // Same figure as the beranda chip: the smaller of the saldo and budget
    // shares, so only the saldo side moves with the date.
    final period = ref.watch(currentPeriodProvider);
    final budget = ref.watch(budgetInPeriodProvider(period)).value;
    final monthSpent = totals?.spent[period.key] ?? 0;
    int jajan(PaydayInfo i) => safeToSpendToday(
      balance: totals?.balance ?? 0,
      spentToday: totals?.spentToday ?? 0,
      days: i.daysToNext,
      budgetLeft: budget == null ? null : budget - monthSpent,
      budgetDays: period.daysLeft(now),
    );

    final info = infoFor(_sel);
    final today = info.status == PaydayStatus.today;
    final nextDate = today ? DateTime(now.year, now.month, now.day) : info.next;
    final changed = _sel != widget.saved;
    final before = jajan(infoFor(widget.saved));
    final after = jajan(info);
    final custom = !paydayChoices.contains(_sel);
    final muted = AppText.label.copyWith(color: AppColors.muted);

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
            // Struck through only when the figure really moves (a binding
            // budget keeps it the same).
            before: changed && before != after ? rupiahCompact(before) : null,
            after: rupiahCompact(after),
          ),
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

/// Ink card: the payday it'll count to, and aman jajan before → after.
class _NextCard extends StatelessWidget {
  const _NextCard({
    required this.date,
    required this.inText,
    required this.before,
    required this.after,
  });

  final String date, inText, after;
  final String? before; // null = unchanged

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
          const Divider(height: 1, color: Color(0xFF333333)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.paydayJajanBecomes, style: soft.copyWith(fontSize: 14)),
              Text.rich(
                TextSpan(
                  children: [
                    if (before != null)
                      TextSpan(
                        text: '$before  ',
                        style: const TextStyle(
                          color: AppColors.subtle,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    TextSpan(
                      text: l.paydayPerDay(after),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                style: AppText.label.copyWith(
                  fontSize: 15,
                  color: AppColors.paper,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
