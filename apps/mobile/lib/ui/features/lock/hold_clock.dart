import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/app_lock.dart';
import '../../core/app_lock_providers.dart';
import '../../core/clock.dart';

/// A screen with a pin pad that can be held after too many wrong pins: keeps
/// [holdNow] ticking once a second while the hold lasts, so the countdown
/// shows and the pad frees itself. Call [syncHold] after anything that may
/// start or end a hold.
mixin HoldClock<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  late DateTime holdNow = ref.read(clockProvider)();
  Timer? _tick;

  AppLockState get lockNow =>
      ref.read(appLockProvider).value ?? AppLockState.off;

  /// [onEnd] runs (inside setState) when the hold runs out.
  void syncHold({VoidCallback? onEnd}) {
    holdNow = ref.read(clockProvider)();
    final held = lockNow.holdLeft(holdNow) != null;
    if (held && _tick == null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {
          holdNow = ref.read(clockProvider)();
          if (lockNow.holdLeft(holdNow) == null) {
            onEnd?.call();
            _tick?.cancel();
            _tick = null;
          }
        });
      });
    } else if (!held) {
      _tick?.cancel();
      _tick = null;
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }
}
