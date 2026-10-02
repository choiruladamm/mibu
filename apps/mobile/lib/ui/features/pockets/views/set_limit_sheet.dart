import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/clock.dart';
import '../../../core/dashed.dart';
import '../../../core/finance_providers.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/pocket_limit.dart';
import '../../../core/widgets/sheet.dart';
import '../../../core/widgets/toast.dart';
import '../../budget/views/budget_sheet.dart';
import '../../categories/views/category_form_sheet.dart';
import '../view_models/pockets_view_model.dart';
import '../../../core/widgets/meta_line.dart';
import '../../../core/widgets/app_emoji.dart';

/// 02.2 "pasang limit ke…". With [pick] it opens straight on its limit step
/// (the "belum ada limit" chips). Saves, selects the jar and shows the toast
/// with batalin; "bikin kategori baru" hands over to 03.4 (from kantong).
Future<void> showSetLimit(
  BuildContext context,
  WidgetRef ref, {
  FreeCategory? pick,
}) async {
  final r = await showAppSheet<Object>(context, SetLimitSheet(pick: pick));
  if (r == null || !context.mounted) return;
  final select = ref.read(selectedPocketProvider.notifier).select;
  if (r is! _Picked) {
    final c = await showCategoryForm(context, origin: CategoryOrigin.kantong);
    if (c?.monthlyLimit != null) select(c!.id);
    return;
  }
  final l = AppLocalizations.of(context)!;
  final repo = ref.read(financeRepositoryProvider);
  final c = r.free.category;
  await repo.setLimit(c.id, r.limit);
  select(c.id);
  if (!context.mounted) return;
  showToast(
    context,
    icon: ToastIcon.check,
    title: l.limitSetTitle(c.name, rupiahCompact(r.limit)),
    sub: l.limitSetSub(r.free.count),
    onUndo: () => repo.setLimit(c.id, null),
  );
}

/// Lepas limit (02.2 kartu detail, 03.5): clears it right away, toast with
/// batalin puts [limit] back. Shows the toast before returning, so a sheet
/// can pop right after.
Future<void> releaseLimit(
  BuildContext context,
  WidgetRef ref, {
  required String id,
  required String name,
  required int limit,
}) async {
  final repo = ref.read(financeRepositoryProvider);
  await repo.setLimit(id, null);
  final usage = await repo.watchCategoryUsage(ref.read(nowProvider)).first;
  if (!context.mounted) return;
  final l = AppLocalizations.of(context)!;
  showToast(
    context,
    icon: ToastIcon.check,
    title: l.limitReleasedTitle(name),
    sub: l.limitReleasedSub(usage[id]?.count ?? 0, name),
    onUndo: () => repo.setLimit(id, limit),
  );
}

class _Picked {
  const _Picked(this.free, this.limit);

  final FreeCategory free;
  final int limit;
}

const _create = Object(); // "bikin kategori baru"

class SetLimitSheet extends ConsumerStatefulWidget {
  const SetLimitSheet({super.key, this.pick});

  final FreeCategory? pick;

  @override
  ConsumerState<SetLimitSheet> createState() => _SetLimitSheetState();
}

class _SetLimitSheetState extends ConsumerState<SetLimitSheet> {
  late FreeCategory? _pick = widget.pick;
  late int _limit = _suggest(widget.pick);

  static int _suggest(FreeCategory? f) => suggestedLimit(f?.spent ?? 0);

  void _choose(FreeCategory f) => setState(() {
    _pick = f;
    _limit = _suggest(f);
  });

  @override
  Widget build(BuildContext context) {
    final now = ref.watch(nowProvider);
    final free = ref.watch(freeCategoriesProvider(now)).value ?? const [];
    final pick = _pick;
    if (pick != null) return _limitStep(context, pick, now);
    return _ListStep(
      free: free,
      onPick: _choose,
      onCreate: () => Navigator.of(context).pop(_create),
    );
  }

  Widget _limitStep(BuildContext context, FreeCategory f, DateTime now) {
    final l = AppLocalizations.of(context)!;
    final others = [
      for (final p in ref.watch(pocketsProvider).value ?? const <Pocket>[])
        p.budget,
    ].fold(0, (a, b) => a + b);
    final pct = _limit == 0 ? 100 : (f.spent * 100 / _limit).round();
    return SizedBox(
      height: 660,
      child: Padding(
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
            const SizedBox(height: 10),
            Row(
              children: [
                SizedBox(
                  width: 72,
                  height: AppSpace.minTouch,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _pick = null),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      foregroundColor: AppColors.ink,
                    ),
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowLeft01,
                      size: 18,
                      strokeWidth: AppStroke.icon,
                      color: AppColors.ink,
                    ),
                    label: Text(l.setLimitBack, style: AppText.label),
                  ),
                ),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      l.pocketsSetLimit,
                      textAlign: TextAlign.center,
                      style: AppText.label.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 72),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        width: 88,
                        height: 88,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.mist,
                          shape: BoxShape.circle,
                        ),
                        child: AppEmoji(f.category.emoji, size: 53),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      f.category.name,
                      textAlign: TextAlign.center,
                      style: AppText.sheetTitle.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: _Pill(
                        f.count == 0
                            ? [l.setLimitUnused]
                            : [
                                l.setLimitCount(f.count),
                                l.setLimitSpent(rupiahCompact(f.spent)),
                              ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    PocketLimit(
                      value: _limit,
                      budget: ref.watch(profileProvider).value?.monthlyBudget,
                      others: others,
                      monthDays: DateTime(now.year, now.month + 1, 0).day,
                      onChanged: (v) => setState(() => _limit = v),
                      onSetBudget: () => editBudget(context, ref),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.mist,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: MetaLine(
                        [
                          l.setLimitFilled(pct.clamp(0, 100)),
                          l.setLimitLeft(
                            rupiahCompact((_limit - f.spent).clamp(0, _limit)),
                          ),
                        ],
                        style: AppText.label.copyWith(
                          fontSize: 14,
                          height: 1.4,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: l.setLimitSave(rupiahCompact(_limit)),
              onPressed: _limit == 0
                  ? null
                  : () => Navigator.of(context).pop(_Picked(f, _limit)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListStep extends StatelessWidget {
  const _ListStep({
    required this.free,
    required this.onPick,
    required this.onCreate,
  });

  final List<FreeCategory> free; // most spent first
  final ValueChanged<FreeCategory> onPick;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final muted = AppText.label.copyWith(
      fontSize: 14,
      height: 1.4,
      color: AppColors.muted,
    );
    return SheetFrame(
      title: l.setLimitTitle,
      titleSize: 24,
      height: free.isEmpty ? 440 : 660,
      scrollable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (free.isEmpty) ...[
            const SizedBox(height: 28),
            const AppEmoji('🫙', size: 46),
            const SizedBox(height: 10),
            Text(
              l.setLimitEmptyTitle,
              textAlign: TextAlign.center,
              style: AppText.label.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l.setLimitEmptyBody,
              textAlign: TextAlign.center,
              style: muted,
            ),
            const Spacer(),
          ] else ...[
            const SizedBox(height: 6),
            MetaLine([l.setLimitHintOrder, l.setLimitHintCounts], style: muted),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [for (final f in free) _Row(f, () => onPick(f))],
              ),
            ),
            const SizedBox(height: 12),
          ],
          _DashedButton(label: l.setLimitNewCategory, onTap: onCreate),
          const SizedBox(height: 10),
          Text(
            l.setLimitIncomeNote,
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(
              fontSize: 12,
              color: AppColors.subtle,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.f, this.onTap);

  final FreeCategory f;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 64,
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.track, width: 1),
            ),
          ),
          child: Row(
            spacing: 12,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.mist,
                  shape: BoxShape.circle,
                ),
                child: AppEmoji(f.category.emoji, size: 25),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      f.category.name,
                      style: AppText.label.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      l.setLimitCount(f.count), // the amount sits on the right
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Text(
                rupiahCompact(f.spent),
                style: AppText.label.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 16,
                strokeWidth: AppStroke.icon,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.parts);

  final List<String> parts;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.mist,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: MetaLine(
        parts,
        style: AppText.caption.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _DashedButton extends StatelessWidget {
  const _DashedButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: const _DashedPill(),
          child: SizedBox(
            height: 56,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedAdd01,
                  size: 18,
                  strokeWidth: AppStroke.iconOnInkSmall,
                  color: AppColors.ink,
                ),
                Text(
                  label,
                  style: AppText.label.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedPill extends CustomPainter {
  const _DashedPill();

  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(AppStroke.outline / 2),
      Radius.circular(size.height / 2),
    );
    canvas.drawPath(
      dashPath(Path()..addRRect(r)),
      Paint()
        ..color = AppColors.ink
        ..strokeWidth = AppStroke.outline
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_DashedPill old) => false;
}
