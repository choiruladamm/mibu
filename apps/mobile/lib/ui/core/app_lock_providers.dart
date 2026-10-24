import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/biometrics.dart';
import '../../data/repositories/app_lock_repository.dart';
import '../../domain/app_lock.dart';
import '../../domain/models/app_lock.dart';
import 'clock.dart';

/// Kunci app state: loaded in `bootstrap` so the first frame already knows
/// whether to lock. Every change goes through the repository and lands here.
class AppLockController extends AsyncNotifier<AppLockState> {
  AppLockRepository get _repo => ref.read(appLockRepositoryProvider);

  @override
  Future<AppLockState> build() => _repo.load();

  Future<void> enable(String pin, {required bool bio}) async =>
      state = AsyncData(await _repo.enable(pin, bio: bio));

  Future<void> disable() async => state = AsyncData(await _repo.disable());

  Future<void> changePin(String pin) async =>
      state = AsyncData(await _repo.changePin(pin));

  Future<void> setBio(bool on) async =>
      state = AsyncData(await _repo.setBio(on));

  Future<void> markBioChanged() async =>
      state = AsyncData(await _repo.markBioChanged());

  Future<void> setAfter(Duration after) async =>
      state = AsyncData(await _repo.setAfter(after));

  Future<void> setBlur(bool on) async =>
      state = AsyncData(await _repo.setBlur(on));

  Future<void> bioSucceeded() async =>
      state = AsyncData(await _repo.bioSucceeded());

  /// One pin attempt at the clock's "now".
  Future<PinOutcome> verifyPin(String pin) async {
    final r = await _repo.verifyPin(pin, ref.read(clockProvider)());
    state = AsyncData(r.state);
    return r.outcome;
  }
}

final appLockProvider = AsyncNotifierProvider<AppLockController, AppLockState>(
  AppLockController.new,
);

/// Whether the lock screen is up (true = locked). Starts locked when the lock
/// is on (a cold start always asks); coming back to the app locks it again
/// once the app was away for the "kunci lagi setelah" time. Switching the
/// lock on in settings does not lock the session that just set it.
class LockSession extends Notifier<bool> {
  DateTime? _leftAt;

  @override
  bool build() => ref.read(appLockProvider).value?.enabled ?? false;

  /// The app left the screen (hidden / background).
  void left() => _leftAt = ref.read(clockProvider)();

  /// The app is back in front.
  void returned() {
    final at = _leftAt;
    _leftAt = null;
    final lock = ref.read(appLockProvider).value;
    if (at == null || lock == null || !lock.enabled) return;
    final now = ref.read(clockProvider)();
    if (shouldLock(leftAt: at, after: lock.after, now: now)) state = true;
  }

  void unlock() => state = false;
}

final lockSessionProvider = NotifierProvider<LockSession, bool>(
  LockSession.new,
);

/// Which biometric the phone can use right now.
final bioKindProvider = FutureProvider<BioKind>(
  (ref) => ref.watch(biometricsProvider).kind(),
);
