import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../data/biometrics.dart';
import '../../../../domain/app_lock.dart';
import '../../../../domain/models/app_lock.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/app_lock_providers.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets/pin_pad.dart';
import '../../../core/widgets/sheet.dart';
import '../hold_clock.dart';

/// 99.10j–n: what stands between the app and its notes. Face id / sidik jari
/// comes up by itself; a miss or a cancel leaves the pin pad. Five wrong pins
/// hold the pad (the biometric key stays live), longer each round.
///
/// Sits above the Navigator (see AppLockGate), so "lupa pin?" draws its
/// sheet in place instead of pushing one.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> with HoldClock {
  var _pin = '';
  var _wrong = false; // the last pin was wrong
  var _busy = false; // a pin is being checked, or the system prompt is up
  var _forgot = false;
  var _kind = BioKind.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  bool get _bioUsable =>
      lockNow.bio && !lockNow.bioChanged && _kind != BioKind.none;

  Future<void> _start() async {
    final kind = await ref.read(biometricsProvider).kind();
    if (!mounted) return;
    setState(() => _kind = kind);
    syncHold(onEnd: () => _wrong = false);
    if (_bioUsable) await _tryBio();
  }

  Future<void> _tryBio() async {
    if (_busy) return;
    _busy = true;
    final ok = await ref
        .read(biometricsProvider)
        .authenticate(AppLocalizations.of(context)!.lockBioReason);
    _busy = false;
    if (!ok || !mounted) return;
    await ref.read(appLockProvider.notifier).bioSucceeded();
    ref.read(lockSessionProvider.notifier).unlock();
  }

  Future<void> _key(String k) async {
    if (_busy || lockNow.holdLeft(holdNow) != null) return;
    setState(() {
      _pin += k;
      _wrong = false;
    });
    if (_pin.length < pinLength) return;
    _busy = true;
    final pin = _pin;
    final outcome = await ref.read(appLockProvider.notifier).verifyPin(pin);
    _busy = false;
    if (!mounted) return;
    if (outcome == PinOutcome.ok) {
      ref.read(lockSessionProvider.notifier).unlock();
      return;
    }
    setState(() {
      _pin = '';
      _wrong = outcome == PinOutcome.wrong;
    });
    syncHold(onEnd: () => _wrong = false);
  }

  void _back() {
    if (_busy || _pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _wrong = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lock = ref.watch(appLockProvider).value ?? AppLockState.off;
    final left = lock.holdLeft(holdNow);
    final bioName = _kind == BioKind.face ? l.lockBioFace : l.lockBioFinger;
    final message = left != null
        ? (lock.wrongTries <= triesPerHold
              ? l.lockHeld(holdClock(left))
              : l.lockHeldAgain(holdClock(left)))
        : _wrong
        ? l.lockWrong(triesLeft(lock.wrongTries))
        : '';

    return Material(
      color: AppColors.paper,
      child: Stack(
        children: [
          SafeArea(
            minimum: const EdgeInsets.fromLTRB(0, 96, 0, 28),
            child: Center(
              child: Column(
                children: [
                  Text(l.appTitle, style: AppText.wordmark(34)),
                  const SizedBox(height: 18),
                  Semantics(
                    header: true,
                    child: Text(
                      l.lockTitle,
                      style: AppText.title.copyWith(
                        fontSize: 24,
                        letterSpacing: -0.48,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _bioUsable ? l.lockHintBio(bioName) : l.lockHintPin,
                    style: AppText.label.copyWith(
                      fontSize: 15,
                      color: AppColors.muted,
                    ),
                  ),
                  const Spacer(),
                  PinPad(
                    filled: _pin.length,
                    message: message,
                    error: _wrong,
                    state: left != null
                        ? PinPadState.locked
                        : lock.bioChanged
                        ? PinPadState.bioHidden
                        : PinPadState.normal,
                    bio: _bioUsable ? _kind : BioKind.none,
                    onKey: _key,
                    onBackspace: _back,
                    onBio: _tryBio,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() => _forgot = true),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, AppSpace.minTouch),
                      foregroundColor: AppColors.muted,
                      textStyle: AppText.label.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.muted,
                      ),
                    ),
                    child: Text(l.lockForgot),
                  ),
                ],
              ),
            ),
          ),
          if (_forgot)
            _ForgotSheet(onClose: () => setState(() => _forgot = false)),
        ],
      ),
    );
  }
}

/// 99.10q: why there is no reset, drawn over the lock screen.
class _ForgotSheet extends StatelessWidget {
  const _ForgotSheet({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final rows = [
      (HugeIcons.strokeRoundedSmartPhone01, l.lockForgotLocal),
      (HugeIcons.strokeRoundedRefresh, l.lockForgotReinstall),
      (HugeIcons.strokeRoundedFile01, l.lockForgotExport),
    ];
    return Stack(
      children: [
        Semantics(
          button: true,
          label: l.close,
          child: GestureDetector(
            onTap: onClose,
            child: const ColoredBox(
              color: AppColors.scrim,
              child: SizedBox.expand(),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: EdgeInsets.fromLTRB(
              20,
              10,
              20,
              28 + MediaQuery.paddingOf(context).bottom,
            ),
            decoration: const BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.sheet),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          l.lockForgotTitle,
                          style: AppText.sheetTitle.copyWith(fontSize: 22),
                        ),
                      ),
                    ),
                    CircleButton(
                      icon: HugeIcons.strokeRoundedCancel01,
                      label: l.close,
                      size: 40,
                      onTap: onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(AppRadius.groupCard),
                  ),
                  child: Column(
                    children: [
                      for (final (i, (icon, text)) in rows.indexed) ...[
                        if (i > 0)
                          const Divider(
                            height: AppStroke.hairline,
                            thickness: AppStroke.hairline,
                            indent: 64,
                            color: AppColors.divider,
                          ),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 64),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpace.s16,
                              vertical: 12,
                            ),
                            child: Row(
                              spacing: 12,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: AppColors.paper,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: HugeIcon(
                                      icon: icon,
                                      size: 20,
                                      strokeWidth: AppStroke.icon,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    text,
                                    style: AppText.label.copyWith(
                                      fontSize: 15,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                PrimaryButton(label: l.lockForgotOk, onPressed: onClose),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
