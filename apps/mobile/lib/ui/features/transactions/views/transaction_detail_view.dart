import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../routing/router.dart';
import '../../../core/clock.dart';
import '../../../core/dashed.dart';
import '../../../core/dates.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/nav_header.dart';
import '../../../core/widgets/note_sheet.dart';
import '../../../core/widgets/toast.dart';

final transactionProvider = StreamProvider.autoDispose
    .family<Transaction?, String>(
      (ref, id) => ref.watch(financeRepositoryProvider).watchTransaction(id),
    );

/// The pocket [t] counts toward (its category, in its month); null = none.
Pocket? pocketOf(WidgetRef ref, Transaction t) => ref
    .watch(pocketsInMonthProvider(DateTime(t.at.year, t.at.month)))
    .value
    ?.where((p) => p.id == t.categoryId)
    .firstOrNull;

final _time = DateFormat.Hm('id');
final _headerDay = DateFormat('EEE d MMM', 'id');

/// 04.3 struk, with 04.3b confirm and 04.3c dihapus + batalin.
class TransactionDetailView extends ConsumerWidget {
  const TransactionDetailView({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final t = ref.watch(transactionProvider(id)).value;
    if (t == null) return const Scaffold(backgroundColor: AppColors.mist);
    final pocket = t.amount < 0 ? pocketOf(ref, t) : null;

    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        minimum: const EdgeInsets.only(top: 12, bottom: 28),
        child: Column(
          children: [
            NavHeader(
              title: l.receiptTitle,
              sub: _headerDay.format(t.at).toLowerCase(),
              backLabel: l.txTitle,
              actionIcon: HugeIcons.strokeRoundedPencilEdit02,
              actionLabel: l.receiptEdit,
              onAction: t.deleted
                  ? null
                  : () => context.push(Routes.editEntry(id)),
              onMist: true,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                child: AnimatedOpacity(
                  duration: AppMotion.select,
                  opacity: t.deleted ? 0.4 : 1,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _Receipt(
                        tx: t,
                        pocket: pocket,
                        onNote: t.deleted ? null : () => _note(context, ref, t),
                      ),
                      if (t.deleted)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 150,
                          child: Center(child: _Stamp(l.receiptDeleted)),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (t.deleted)
              Semantics(
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.of(context).maybePop(),
                  child: SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: Center(
                      child: Text(l.receiptBack, style: AppText.label),
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  spacing: 10,
                  children: [
                    Semantics(
                      button: true,
                      label: l.entryDelete,
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: () => _delete(context, ref, t, pocket),
                        child: Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.ink,
                              width: AppStroke.outline,
                            ),
                          ),
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedDelete02,
                            size: 22,
                            strokeWidth: AppStroke.icon,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                    // ponytail: "patungan" button waits for split bills.
                    Expanded(
                      child: FilledButton(
                        onPressed: () =>
                            context.push(Routes.addEntry, extra: t),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: AppColors.paper,
                          minimumSize: const Size.fromHeight(56),
                          shape: const StadiumBorder(),
                          textStyle: AppText.body.copyWith(fontSize: 17),
                        ),
                        child: Text(l.receiptAgain),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _note(BuildContext context, WidgetRef ref, Transaction t) async {
    final note = await showNoteSheet(
      context,
      initial: (text: t.note, tags: t.tags),
      entryContext: [
        rupiahSigned(t.amount),
        if (t.place.isNotEmpty) t.place,
        dayLabel(t.at),
      ].join(' · '),
      today: dateOnly(ref.read(clockProvider)()),
    );
    if (note == null) return;
    await ref
        .read(financeRepositoryProvider)
        .updateTransaction(
          t.id,
          amount: t.amount,
          categoryId: t.categoryId,
          place: t.place,
          note: note.text,
          tags: note.tags,
          at: t.at,
        );
  }
}

/// 04.3b → 04.3c, shared with 04.4. True = deleted.
Future<bool> confirmDeleteEntry(
  BuildContext context,
  WidgetRef ref,
  Transaction t,
  Pocket? pocket, {
  double toastBottom = 28,
}) async {
  final l = AppLocalizations.of(context)!;
  final cost = -t.amount;
  final ok = await showConfirmModal(
    context,
    emoji: t.emoji,
    title: l.confirmDeleteTitle,
    body: l.confirmDeleteBody(
      rupiah(t.amount),
      t.place.isNotEmpty ? t.place : t.category ?? l.uncategorized,
      _headerDay.format(t.at).toLowerCase(),
    ),
    impact: pocket == null
        ? null
        : (
            label: l.confirmPocket(pocket.emoji, pocket.name),
            value: l.confirmPocketAfter(rupiahCompact(pocket.left + cost)),
            fromPct: pocket.usedPct,
            toPct: ((pocket.spent - cost) * 100 / pocket.budget).round(),
          ),
  );
  if (!ok || !context.mounted) return false;
  final repo = ref.read(financeRepositoryProvider);
  await repo.deleteTransaction(t.id);
  if (!context.mounted) return true;
  showToast(
    context,
    icon: ToastIcon.trash,
    title: l.entryDeletedToast,
    sub: pocket == null
        ? '${rupiah(t.amount)} · ${dayLabel(t.at)}'
        : l.entryDeletedPocket(pocket.name, rupiahCompact(pocket.left + cost)),
    onUndo: () => repo.restoreTransaction(t.id),
    bottom: toastBottom,
  );
  return true;
}

// Toast sits above "balik ke transaksi" (48) like the board.
Future<void> _delete(
  BuildContext context,
  WidgetRef ref,
  Transaction t,
  Pocket? pocket,
) => confirmDeleteEntry(context, ref, t, pocket, toastBottom: 28 + 48 + 10);

class _Receipt extends StatelessWidget {
  const _Receipt({
    required this.tx,
    required this.pocket,
    required this.onNote,
  });

  final Transaction tx;
  final Pocket? pocket;
  final VoidCallback? onNote;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final t = tx;
    final muted = AppText.label.copyWith(color: AppColors.muted);
    final link = AppText.label.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: AppColors.ink,
    );
    final p = pocket;
    Widget row(String k, Widget v) => Row(
      spacing: 16,
      children: [
        Text(k, style: muted),
        Expanded(
          child: Align(alignment: Alignment.centerRight, child: v),
        ),
      ],
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
          decoration: const BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.groupCard),
            ),
            boxShadow: AppShadows.paper,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.mist,
                    shape: BoxShape.circle,
                  ),
                  child: Text(t.emoji, style: const TextStyle(fontSize: 34)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                t.place.isNotEmpty ? t.place : t.category ?? l.uncategorized,
                textAlign: TextAlign.center,
                style: AppText.label.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.22,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  height: 30,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: AppColors.ink,
                      width: AppStroke.outline,
                    ),
                  ),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      t.category ?? l.uncategorized,
                      style: AppText.label.copyWith(fontSize: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: t.amount < 0 ? '-Rp' : '+Rp',
                        style: AppText.inputXl.copyWith(
                          fontSize: 26,
                          letterSpacing: -0.52,
                          color: AppColors.muted,
                        ),
                      ),
                      const WidgetSpan(child: SizedBox(width: 4)),
                      TextSpan(
                        text: rupiah(t.amount.abs()).substring(2),
                        style: AppText.display.copyWith(
                          letterSpacing: -1.68,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                (t.amount < 0 ? l.receiptPaid : l.receiptReceived)(
                  '${dayLabel(t.at)} · ${_time.format(t.at)}',
                ),
                textAlign: TextAlign.center,
                style: muted.copyWith(fontSize: 14),
              ),
              const _Perforation(),
              Column(
                spacing: 14,
                children: [
                  row(
                    l.receiptKind,
                    Text(
                      t.amount < 0 ? l.expense : l.income,
                      style: AppText.label,
                    ),
                  ),
                  row(
                    l.receiptNote,
                    Semantics(
                      button: onNote != null,
                      child: GestureDetector(
                        onTap: onNote,
                        child: Text(
                          t.note.isEmpty ? l.receiptAddNote : t.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.note.isEmpty ? link : AppText.label,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (p != null) ...[
                const _Perforation(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      spacing: 12,
                      children: [
                        Text(
                          l.receiptPocket(p.emoji, p.name),
                          style: AppText.label.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            p.left < 0
                                ? l.receiptOverOf(
                                    rupiahCompact(-p.left),
                                    rupiahCompact(p.budget),
                                  )
                                : l.receiptLeftOf(
                                    rupiahCompact(p.left),
                                    rupiahCompact(p.budget),
                                  ),
                            overflow: TextOverflow.ellipsis,
                            style: muted.copyWith(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    _PocketBar(pct: p.usedPct),
                    Text(
                      l.receiptShare(
                        (-t.amount * 100 / p.budget).round(),
                        p.name,
                      ),
                      style: AppText.caption.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(
          height: 12,
          width: double.infinity,
          child: CustomPaint(painter: _Zigzag()),
        ),
      ],
    );
  }
}

/// Dashed tear line with mist notches poking into both card edges.
class _Perforation extends StatelessWidget {
  const _Perforation();

  @override
  Widget build(BuildContext context) {
    Widget notch() => Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: AppColors.mist,
        shape: BoxShape.circle,
      ),
    );
    return SizedBox(
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          const Positioned(
            left: -2,
            right: -2,
            child: SizedBox(
              height: 1.5,
              child: CustomPaint(painter: _DashedRule()),
            ),
          ),
          Positioned(left: -34, child: notch()),
          Positioned(right: -34, child: notch()),
        ],
      ),
    );
  }
}

class _DashedRule extends CustomPainter {
  const _DashedRule();

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    dashPath(Path()..lineTo(size.width, 0), dash: 4, gap: 4),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppStroke.outline
      ..color = AppColors.line,
  );

  @override
  bool shouldRepaint(_DashedRule old) => false;
}

/// Receipt's torn bottom edge, 9px teeth.
class _Zigzag extends CustomPainter {
  const _Zigzag();

  @override
  void paint(Canvas canvas, Size size) {
    final n = math.max(1, (size.width / 18).round());
    final w = size.width / n;
    final path = Path()..moveTo(0, 0);
    for (var i = 0; i < n; i++) {
      path
        ..lineTo(w * i + w / 2, size.height)
        ..lineTo(w * (i + 1), 0);
    }
    canvas.drawPath(path..close(), Paint()..color = AppColors.paper);
  }

  @override
  bool shouldRepaint(_Zigzag old) => false;
}

class _PocketBar extends StatelessWidget {
  const _PocketBar({required this.pct});

  final int pct;

  @override
  Widget build(BuildContext context) {
    final f = pct.clamp(0, 100) / 100;
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 10,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: (f * 1000).round(),
              child: const ColoredBox(color: AppColors.ink),
            ),
            if (f < 1) ...[
              const SizedBox(
                width: 2,
                child: ColoredBox(color: AppColors.paper),
              ),
              Expanded(
                flex: ((1 - f) * 1000).round(),
                child: const ColoredBox(color: AppColors.track),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -8 * math.pi / 180,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.ink, width: 3),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: AppText.label.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.76,
            ),
          ),
        ),
      ),
    );
  }
}
