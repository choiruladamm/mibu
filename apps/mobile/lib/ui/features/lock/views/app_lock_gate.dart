import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../core/app_lock_providers.dart';
import '../../../core/tokens.dart';
import 'lock_screen.dart';

/// Kunci app over the whole app. [child] (the router) stays mounted, so
/// opening mibu again lands where the user was, but it is hidden and out of
/// reach while the lock screen is up. With "blur pas pindah app" on, the
/// content is covered whenever the app is not in front, so the app switcher
/// snapshot shows the wordmark instead of notes.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  var _covered = false;

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

/// The wordmark on paper: what the app switcher shows.
class _Cover extends StatelessWidget {
  const _Cover();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.paper,
    child: Center(
      child: Text(
        AppLocalizations.of(context)!.appTitle,
        style: AppText.wordmark(34),
      ),
    ),
  );
}
