import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';

import '../../../../data/repositories/finance_repository.dart';
import '../../../../domain/models/finance.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/clock.dart';
import '../../../core/measure.dart';
import '../../../core/money.dart';
import '../../../core/tokens.dart';

final _dots = NumberFormat('#,##0', 'id_ID');

const _quick = [500000, 1000000, 2500000, 5000000];
const _paydays = [1, 10, 15, 25, 28, 0]; // 0 = akhir bulan
const _maxDigits = 12;

/// 01.4 atur awal (saldo + gajian) → 01.4b kantong pertama.
class SetupView extends ConsumerStatefulWidget {
  const SetupView({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends ConsumerState<SetupView> {
  final _balance = TextEditingController();
  int _step = 1;
  int _payday = 25;
  final _pockets = {'makan', 'ngopi', 'ojol', 'tagihan'};
  bool _saving = false;

  int get _value =>
      int.tryParse(_balance.text.replaceAll(RegExp('[^0-9]'), '')) ?? 0;

  @override
  void dispose() {
    _balance.dispose();
    super.dispose();
  }

  void _setBalance(int v) {
    final shown = v == 0 ? '' : _dots.format(v);
    _balance.value = TextEditingValue(
      text: shown,
      selection: TextSelection.collapsed(offset: shown.length),
    );
    setState(() {});
  }

  void _typed(String s) {
    var digits = s.replaceAll(RegExp('[^0-9]'), '');
    if (digits.length > _maxDigits) digits = digits.substring(0, _maxDigits);
    _setBalance(int.tryParse(digits) ?? 0);
  }

  /// "nanti aja" keeps what's filled in so far, minus the kantong on step 1.
  Future<void> _finish({required bool withPockets}) async {
    if (_saving) return;
    setState(() => _saving = true);
    await ref
        .read(financeRepositoryProvider)
        .completeSetup(
          openingBalance: _value,
          payday: _payday,
          pockets: withPockets ? _pockets : const {},
          now: ref.read(clockProvider)(),
        );
    if (mounted) widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pill = TextButton.styleFrom(
      backgroundColor: AppColors.mist,
      foregroundColor: AppColors.ink,
      minimumSize: const Size(0, 36),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      shape: const StadiumBorder(),
      textStyle: AppText.label.copyWith(fontSize: 14),
    );

    return PopScope(
      // System back on 01.4b goes to 01.4, not out of the app.
      canPop: _step == 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step = 1);
      },
      child: Scaffold(
        body: SafeArea(
          minimum: const EdgeInsets.fromLTRB(24, 56, 24, 28),
          // Button pinned at the bottom; only the step's content scrolls.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExcludeSemantics(
                child: Row(
                  spacing: 6,
                  children: [
                    for (var i = 1; i <= 2; i++)
                      Expanded(
                        child: AnimatedContainer(
                          duration: AppMotion.select,
                          curve: AppMotion.ease,
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= _step ? AppColors.ink : AppColors.track,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: _step == 1
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                l.setupCounter('01'),
                                style: AppText.caption.copyWith(
                                  color: AppColors.muted,
                                ),
                              ),
                            )
                          : Semantics(
                              label: l.setupBack,
                              button: true,
                              excludeSemantics: true,
                              child: TextButton(
                                onPressed: () => setState(() => _step = 1),
                                style: pill.copyWith(
                                  padding: const WidgetStatePropertyAll(
                                    EdgeInsets.fromLTRB(8, 0, 14, 0),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  spacing: 2,
                                  children: [
                                    const HugeIcon(
                                      icon: HugeIcons.strokeRoundedArrowLeft01,
                                      size: 18,
                                      strokeWidth: AppStroke.icon,
                                      color: AppColors.ink,
                                    ),
                                    Flexible(
                                      child: Text(
                                        l.setupCounter('02'),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                    ),
                    TextButton(
                      onPressed: () => _finish(withPockets: false),
                      style: pill,
                      child: Text(l.setupLater),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: _step == 1 ? _balanceStep(l) : _pocketStep(l),
                ),
              ),
              const SizedBox(height: 16),
              if (_step == 1)
                _next(l.setupNext, () {
                  FocusScope.of(context).unfocus();
                  setState(() => _step = 2);
                })
              else
                _next(
                  l.setupDone,
                  _saving ? null : () => _finish(withPockets: true),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title(String text) => Text(
    text,
    style: AppText.title.copyWith(
      fontSize: 30,
      letterSpacing: -0.9,
      height: 1.1,
    ),
  );

  Widget _next(String label, VoidCallback? onPressed) => FilledButton(
    onPressed: onPressed,
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.ink,
      foregroundColor: AppColors.paper,
      minimumSize: const Size.fromHeight(56),
      shape: const StadiumBorder(),
      textStyle: AppText.body.copyWith(fontSize: 17),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        const HugeIcon(
          icon: HugeIcons.strokeRoundedArrowRight02,
          size: 20,
          strokeWidth: AppStroke.iconOnInkSmall,
          color: AppColors.paper,
        ),
      ],
    ),
  );

  Widget _balanceStep(AppLocalizations l) {
    final v = _value;
    final text = _balance.text;
    final size = text.length > 11
        ? 40.0
        : text.length > 9
        ? 46.0
        : 52.0;
    final style = AppText.display.copyWith(
      fontSize: size,
      letterSpacing: -0.04 * size,
    );
    final left = daysUntilPayday(ref.read(clockProvider)(), _payday);
    final muted = AppText.caption.copyWith(color: AppColors.muted);

    Widget chip({
      required String label,
      required bool on,
      required VoidCallback onTap,
      String? semantics,
      double? width,
      double height = 40,
      TextStyle? textStyle,
    }) => Semantics(
      button: true,
      selected: on,
      label: semantics,
      excludeSemantics: semantics != null,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.select,
          curve: AppMotion.ease,
          width: width,
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? AppColors.ink : AppColors.paper,
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(color: AppColors.ink, width: AppStroke.outline),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: (textStyle ?? AppText.label.copyWith(fontSize: 14))
                  .copyWith(color: on ? AppColors.paper : AppColors.ink),
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(l.setupBalanceTitle),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.only(bottom: 10),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.ink,
                width: AppStroke.outline,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            spacing: 4,
            children: [
              Text(
                'Rp',
                style: AppText.inputXl.copyWith(
                  fontSize: 26,
                  letterSpacing: -0.52,
                  color: AppColors.muted,
                ),
              ),
              Flexible(
                child: SizedBox(
                  // Hugs the digits so "Rp" sits next to them.
                  width: (textWidth(text, style) + 4).clamp(40, 270),
                  child: Semantics(
                    label: l.setupBalanceLabel,
                    child: TextField(
                      controller: _balance,
                      onChanged: _typed,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[0-9.]')),
                      ],
                      textAlign: TextAlign.center,
                      style: style,
                      decoration: InputDecoration.collapsed(
                        hintText: '0',
                        hintStyle: style.copyWith(color: AppColors.grey400),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          spacing: 8,
          children: [
            for (final q in _quick)
              Expanded(
                child: chip(
                  label: rupiahCompact(q),
                  on: v == q,
                  onTap: () => _setBalance(q),
                ),
              ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          l.setupPaydayTitle,
          style: AppText.label.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 2),
        Text(l.setupPaydayBody, style: muted),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (final d in _paydays)
              chip(
                label: d == 0 ? l.setupPaydayEnd : '$d',
                semantics: d == 0
                    ? l.setupPaydayEndLabel
                    : l.setupPaydayLabel(d),
                on: _payday == d,
                width: d == 0 ? 72 : 48,
                height: 48,
                textStyle: AppText.label.copyWith(fontWeight: FontWeight.w500),
                onTap: () => setState(() => _payday = d),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Semantics(
          container: true,
          label: l.setupDaily,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(AppRadius.groupCard),
            ),
            child: Row(
              spacing: 12,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(l.setupDaily, style: muted),
                      Text(
                        rupiahCompact(v ~/ left),
                        style: AppText.title.copyWith(
                          fontSize: 30,
                          letterSpacing: -0.9,
                          height: 1,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(l.setupUntil(left), style: muted),
                    ],
                  ),
                ),
                ExcludeSemantics(
                  child: SizedBox(
                    width: 84,
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (var i = 0; i < 18; i++)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i < left
                                  ? AppColors.ink
                                  : Colors.transparent,
                              border: i < left
                                  ? null
                                  : Border.all(
                                      color: AppColors.line,
                                      width: AppStroke.hairline,
                                    ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _pocketStep(AppLocalizations l) {
    final saldo = _value;
    final chosen = [
      for (final p in setupPockets)
        if (_pockets.contains(p.$2)) p,
    ];
    final total = chosen.fold(0, (s, p) => s + p.$3);
    final base = [saldo, total, 1].reduce((a, b) => a > b ? a : b);
    const shades = [
      AppColors.paper,
      AppColors.pressed,
      AppColors.onInkMuted,
      AppColors.grey400,
    ];
    final strong = AppText.label.copyWith(
      fontWeight: FontWeight.w600,
      color: AppColors.paper,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _title(l.setupPocketsTitle),
        const SizedBox(height: 8),
        Text(
          l.setupPocketsBody,
          style: AppText.label.copyWith(fontSize: 15, color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        for (var r = 0; r < setupPockets.length; r += 2) ...[
          if (r > 0) const SizedBox(height: 8),
          Row(
            spacing: 8,
            children: [
              for (final p in setupPockets.skip(r).take(2))
                Expanded(
                  child: _PocketTile(
                    emoji: p.$1,
                    name: p.$2,
                    amount: l.setupPerMonth(rupiahCompact(p.$3)),
                    on: _pockets.contains(p.$2),
                    onTap: () => setState(
                      () => _pockets.contains(p.$2)
                          ? _pockets.remove(p.$2)
                          : _pockets.add(p.$2),
                    ),
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Semantics(
          container: true,
          label: l.setupSummary,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(AppRadius.groupCard),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 12,
                  children: [
                    Flexible(
                      child: Text(
                        chosen.isEmpty
                            ? l.setupNoPockets
                            : l.setupPocketCount(chosen.length),
                        overflow: TextOverflow.ellipsis,
                        style: strong,
                      ),
                    ),
                    Text(l.setupPerMonth(rupiahCompact(total)), style: strong),
                  ],
                ),
                ExcludeSemantics(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      height: 12,
                      color: AppColors.onInk12,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 2,
                        children: [
                          // Widths are shares of max(saldo, total).
                          for (final (i, p) in chosen.indexed)
                            Expanded(
                              flex: p.$3 ~/ 1000,
                              child: ColoredBox(
                                color: shades[i % shades.length],
                              ),
                            ),
                          if ((base - total) ~/ 1000 > 0)
                            Spacer(flex: (base - total) ~/ 1000),
                        ],
                      ),
                    ),
                  ),
                ),
                Text(
                  chosen.isEmpty
                      ? l.setupTapHint
                      : total <= saldo
                      ? l.setupFree(
                          rupiahCompact(saldo - total),
                          rupiahCompact(saldo),
                        )
                      : l.setupOver(rupiahCompact(total - saldo)),
                  style: AppText.caption.copyWith(color: AppColors.onInkMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PocketTile extends StatelessWidget {
  const _PocketTile({
    required this.emoji,
    required this.name,
    required this.amount,
    required this.on,
    required this.onTap,
  });

  final String emoji, name, amount;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.select,
          curve: AppMotion.ease,
          height: 64,
          padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
          decoration: BoxDecoration(
            color: on ? AppColors.ink : AppColors.paper,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: on ? AppColors.ink : AppColors.line,
              width: AppStroke.outline,
            ),
          ),
          child: Stack(
            children: [
              Row(
                spacing: 10,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? AppColors.paper : AppColors.mist,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 20)),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 1,
                      children: [
                        Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.label.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: on ? AppColors.paper : AppColors.ink,
                          ),
                        ),
                        Text(
                          amount,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption.copyWith(
                            fontSize: 12,
                            color: on ? AppColors.onInkMuted : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Positioned(
                right: -4,
                top: 10,
                child: AnimatedOpacity(
                  duration: AppMotion.select,
                  opacity: on ? 1 : 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.paper,
                      shape: BoxShape.circle,
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedTick02,
                      size: 12,
                      strokeWidth: 2.5,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
