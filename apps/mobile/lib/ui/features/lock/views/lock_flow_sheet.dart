import 'package:flutter/foundation.dart';
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
import '../view_models/lock_labels.dart';

/// The pin sheets of 99.10 kunci app.
enum LockFlow {
  /// 99.10f–i: bikin pin, ketik lagi, pakai face id juga?
  enable,

  /// 99.10e: masukin pin dulu, then off.
  disable,

  /// 99.10t: pin lama, pin baru, ketik lagi.
  change,

  /// 99.10s-b: face id changed, the pin turns it back on.
  bioAgain,
}

/// What the screen toasts once a flow is done.
typedef LockToast = ({String title, String sub});

/// Runs [flow] in a sheet. Null = closed before finishing. [kind] is what the
/// phone can do now (none = no biometric step).
Future<LockToast?> showLockFlow(
  BuildContext context,
  LockFlow flow, {
  required BioKind kind,
}) => showAppSheet<LockToast>(
  context,
  _LockFlowSheet(flow: flow, kind: kind),
  enableDrag: false,
);

enum _Step { make, again, bio, verify, newMake, newAgain }

enum _Err { none, weak, mismatch, wrong }

class _LockFlowSheet extends ConsumerStatefulWidget {
  const _LockFlowSheet({required this.flow, required this.kind});

  final LockFlow flow;
  final BioKind kind;

  @override
  ConsumerState<_LockFlowSheet> createState() => _LockFlowSheetState();
}

class _LockFlowSheetState extends ConsumerState<_LockFlowSheet> with HoldClock {
  late var _step = widget.flow == LockFlow.enable ? _Step.make : _Step.verify;
  var _pin = '';
  var _first = ''; // the pin typed twice, kept until the flow ends
  var _err = _Err.none;
  var _busy = false;

  bool get _hasBio => widget.kind != BioKind.none;
  bool get _verifying => _step == _Step.verify;

  AppLockController get _lock => ref.read(appLockProvider.notifier);

  void _finish(LockToast toast) => Navigator.of(context).pop(toast);

  Future<void> _key(String k) async {
    if (_busy || (_verifying && lockNow.holdLeft(holdNow) != null)) return;
    setState(() {
      _pin += k;
      _err = _Err.none;
    });
    if (_pin.length < pinLength) return;
    final v = _pin;
    switch (_step) {
      case _Step.make || _Step.newMake:
        if (isWeakPin(v)) {
          return setState(() {
            _pin = '';
            _err = _Err.weak;
          });
        }
        setState(() {
          _step = _step == _Step.make ? _Step.again : _Step.newAgain;
          _first = v;
          _pin = '';
        });
      case _Step.again || _Step.newAgain:
        final back = _step == _Step.again ? _Step.make : _Step.newMake;
        if (v != _first) {
          return setState(() {
            _step = back;
            _pin = '';
            _first = '';
            _err = _Err.mismatch;
          });
        }
        if (widget.flow == LockFlow.change) {
          _busy = true;
          await _lock.changePin(v);
          if (!mounted) return;
          return _finish(_toastChanged());
        }
        if (_hasBio) {
          return setState(() {
            _step = _Step.bio;
            _pin = '';
          });
        }
        _busy = true;
        await _lock.enable(v, bio: false);
        if (!mounted) return;
        _finish(_toastOn(bio: false));
      case _Step.verify:
        _busy = true;
        final outcome = await _lock.verifyPin(v);
        _busy = false;
        if (!mounted) return;
        if (outcome != PinOutcome.ok) {
          setState(() {
            _pin = '';
            _err = outcome == PinOutcome.wrong ? _Err.wrong : _Err.none;
          });
          return syncHold(onEnd: () => _err = _Err.none);
        }
        await _verified();
      case _Step.bio:
        break;
    }
  }

  /// The pin was right.
  Future<void> _verified() async {
    final l = AppLocalizations.of(context)!;
    switch (widget.flow) {
      case LockFlow.disable:
        await _lock.disable();
        if (!mounted) return;
        _finish((title: l.lockToastOff, sub: l.lockToastOffSub));
      case LockFlow.bioAgain:
        final ok = await ref
            .read(biometricsProvider)
            .authenticate(l.lockBioReason);
        if (!mounted) return;
        if (!ok) return Navigator.of(context).pop();
        await _lock.setBio(true);
        if (!mounted) return;
        final bio = widget.kind.word(l);
        _finish((title: l.lockToastBioOn(bio), sub: l.lockToastOnBio(bio)));
      case LockFlow.change:
        setState(() {
          _step = _Step.newMake;
          _pin = '';
          _err = _Err.none;
        });
      case LockFlow.enable:
        break; // never verifies
    }
  }

  Future<void> _bioChoice(bool yes) async {
    final l = AppLocalizations.of(context)!;
    _busy = true;
    // Asking once also shows the system permission on iOS.
    final ok =
        yes && await ref.read(biometricsProvider).authenticate(l.lockBioReason);
    await _lock.enable(_first, bio: ok);
    if (!mounted) return;
    _finish(_toastOn(bio: ok));
  }

  LockToast _toastOn({required bool bio}) {
    final l = AppLocalizations.of(context)!;
    final name = widget.kind.word(l);
    if (bio) return (title: l.lockToastOn, sub: l.lockToastOnBio(name));
    return (
      title: l.lockToastOn,
      sub: _hasBio ? l.lockToastOnLater(name) : l.lockToastOnPin,
    );
  }

  LockToast _toastChanged() {
    final l = AppLocalizations.of(context)!;
    return (title: l.lockToastChanged, sub: l.lockToastChangedSub);
  }

  void _back() {
    if (_busy || _pin.isEmpty) return;
    if (_verifying && lockNow.holdLeft(holdNow) != null) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _err = _Err.none;
    });
  }

  /// (eyebrow, title, sub) for the step.
  (String, String, String) _header(AppLocalizations l) {
    final bio = widget.kind.word(l);
    final total = _hasBio ? 3 : 2;
    final flow = widget.flow;
    return switch (_step) {
      _Step.make => (l.lockStep(1, total), l.lockMakeTitle, l.lockMakeSub),
      _Step.again => (l.lockStep(2, total), l.lockAgainTitle, l.lockAgainSub),
      _Step.bio => (l.lockStep(3, 3), l.lockBioTitle(bio), ''),
      _Step.verify when flow == LockFlow.change => (
        l.lockChangeEyebrow,
        l.lockOldTitle,
        l.lockOldSub,
      ),
      _Step.verify when flow == LockFlow.bioAgain => (
        '',
        l.lockBioAgainTitle(bio),
        l.lockVerifySub,
      ),
      _Step.verify => ('', l.lockOffTitle, l.lockVerifySub),
      _Step.newMake => (l.lockChangeEyebrow, l.lockNewTitle, l.lockNewSub),
      _Step.newAgain => (
        l.lockChangeEyebrow,
        l.lockNewAgainTitle,
        l.lockAgainSub,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lock = ref.watch(appLockProvider).value ?? AppLockState.off;
    final left = _verifying ? lock.holdLeft(holdNow) : null;
    final (eyebrow, title, sub) = _header(l);
    final message = left != null
        ? (lock.wrongTries <= triesPerHold
              ? l.lockHeld(holdClock(left))
              : l.lockHeldAgain(holdClock(left)))
        : switch (_err) {
            _Err.mismatch => l.lockPadMismatch,
            _Err.weak => l.lockPadWeak,
            _Err.wrong => l.lockWrong(triesLeft(lock.wrongTries)),
            _Err.none =>
              widget.flow == LockFlow.enable && _step == _Step.make
                  ? l.lockPadKeep
                  : '',
          };
    return SheetFrame(
      title: title,
      eyebrow: eyebrow,
      sub: sub.isEmpty ? null : sub,
      titleSize: 22,
      height: 620,
      handleDrag: true,
      child: _step == _Step.bio
          ? _BioChoice(kind: widget.kind, onChoose: _bioChoice)
          : Padding(
              padding: const EdgeInsets.only(top: 26),
              child: Align(
                alignment: Alignment.topCenter,
                child: PinPad(
                  filled: _pin.length,
                  message: message,
                  error: _err != _Err.none && left == null,
                  state: left != null ? PinPadState.locked : PinPadState.normal,
                  onKey: _key,
                  onBackspace: _back,
                ),
              ),
            ),
    );
  }
}

/// 99.10h: pakai face id juga? Yes asks the system once.
class _BioChoice extends StatelessWidget {
  const _BioChoice({required this.kind, required this.onChoose});

  final BioKind kind;
  final ValueChanged<bool> onChoose;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final bio = kind.word(l);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.mist,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: HugeIcon(
                icon: kind == BioKind.face
                    ? AppIcons.faceId
                    : AppIcons.fingerprint,
                size: 44,
                strokeWidth: 1.3,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            l.lockBioBody(
              bio,
              defaultTargetPlatform == TargetPlatform.iOS
                  ? l.lockBioIosNote
                  : '',
            ),
            textAlign: TextAlign.center,
            style: AppText.label.copyWith(
              fontSize: 14,
              height: 1.4,
              color: AppColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: l.lockBioYes(bio),
          onPressed: () => onChoose(true),
        ),
        const SizedBox(height: 6),
        TextButton(
          onPressed: () => onChoose(false),
          style: TextButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            foregroundColor: AppColors.ink,
            textStyle: AppText.body.copyWith(fontSize: 16),
            shape: const StadiumBorder(),
          ),
          child: Text(l.lockBioNo),
        ),
      ],
    );
  }
}
