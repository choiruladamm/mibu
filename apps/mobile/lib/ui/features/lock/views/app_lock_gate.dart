import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/screen_secure.dart';
import '../../../core/app_lock_providers.dart';
import '../../../core/tokens.dart';
import 'lock_screen.dart';

/// Covers the app while locked. [child] (the router) stays mounted so the user
/// returns to the same screen, hidden from interaction until unlock. When
/// "blur when leaving the app" is on, the switcher snapshot shows the wordmark.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  var _covered = false;
  bool? _secure; // last FLAG_SECURE sent, so the channel is not hit per frame

  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // hidden = really in the background; the system prompt (face id) only
    // makes the app inactive, and must not count as leaving.
    _lifecycle = AppLifecycleListener(
      onInactive: () => setState(() => _covered = true),
      onHide: () => ref.read(lockSessionProvider.notifier).left(),
      onResume: () {
        ref.read(lockSessionProvider.notifier).returned();
        setState(() => _covered = false);
      },
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lock = ref.watch(appLockProvider).value;
    // Android: no screenshots, no content in the app list (iOS: no-op).
    final secure = (lock?.enabled ?? false) && (lock?.blur ?? false);
    if (secure != _secure) {
      _secure = secure;
      unawaited(ref.read(screenSecureProvider).set(secure));
    }
    final locked = ref.watch(lockSessionProvider) && (lock?.enabled ?? false);
    final cover = _covered && !locked && (lock?.enabled ?? false) && lock!.blur;
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(offstage: locked, child: widget.child),
        if (locked) const LockScreen(),
        if (cover) const _Cover(),
      ],
    );
  }
}

/// What the app switcher shows: the native splash (ink, white mark + wordmark,
/// `flutter_native_splash` in pubspec) so it looks like the app closing, and
/// no notes in the snapshot. 512 px drawn at 4x density = 128.
class _Cover extends StatelessWidget {
  const _Cover();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    key: Key('lock-cover'),
    color: AppColors.ink,
    child: Center(
      child: Image(
        image: AssetImage('assets/branding/splash_ios.png'),
        width: 128,
        height: 128,
        excludeFromSemantics: true,
      ),
    ),
  );
}
