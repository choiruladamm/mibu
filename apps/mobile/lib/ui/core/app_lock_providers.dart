import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/app_lock_repository.dart';
import '../../domain/models/app_lock.dart';
import 'clock.dart';

/// Kunci app state: loaded in `bootstrap` so the first frame already knows
/// whether to lock. Every change goes through the repository and lands here.
class AppLockController extends AsyncNotifier<LockState> {
  AppLockRepository get _repo => ref.read(appLockRepositoryProvider);

  @override
  Future<LockState> build() => _repo.load();

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

final appLockProvider = AsyncNotifierProvider<AppLockController, LockState>(
  AppLockController.new,
);
