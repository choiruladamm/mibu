import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/app_lock.dart';
import '../../domain/models/app_lock.dart';

/// Where the lock lives. Not the database: the keychain / Keystore survives a
/// force-quit with its wrong-pin count, and needs no migration.
abstract interface class LockStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> clear();
}

class SecureLockStore implements LockStore {
  const SecureLockStore();

  // Keychain items outlive an uninstall, so the bootstrap wipes them on a
  // fresh install (see main.dart); `_this_device` keeps them out of backups.
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } on Exception {
      return null; // unreadable (Keystore key gone) = no lock, same as wiped
    }
  }

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> clear() => _storage.deleteAll();
}

final lockStoreProvider = Provider<LockStore>((_) => const SecureLockStore());

/// Kunci app: the pin (hash + salt), its settings and the wrong-pin count,
/// kept as one JSON value so every change is a single write. Time comes in as
/// an argument (the caller's clock).
class AppLockRepository {
  AppLockRepository(this._store);

  final LockStore _store;

  static const _key = 'lock.v1';

  Future<Map<String, Object?>> _read() async {
    final raw = await _store.read(_key);
    if (raw == null) return {};
    try {
      return Map<String, Object?>.from(jsonDecode(raw) as Map);
    } on FormatException {
      return {};
    }
  }

  Future<LockState> _write(Map<String, Object?> m) async {
    await _store.write(_key, jsonEncode(m));
    return _state(m);
  }

  LockState _state(Map<String, Object?> m) {
    if (m['hash'] == null) return LockState.off;
    final until = m['heldUntil'] as int?;
    return LockState(
      enabled: true,
      bio: m['bio'] == true,
      bioChanged: m['bioChanged'] == true,
      after: Duration(minutes: m['afterMin'] as int? ?? 1),
      blur: m['blur'] != false,
      wrongTries: m['tries'] as int? ?? 0,
      heldUntil: until == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(until),
    );
  }

  Future<LockState> load() async => _state(await _read());

  /// Turns the lock on with a fresh pin (settings back to their defaults).
  Future<LockState> enable(String pin, {required bool bio}) async =>
      _write({..._hashed(pin), 'bio': bio});

  /// Kunci mati: everything stored goes, settings included.
  Future<LockState> disable() async {
    await _store.delete(_key);
    return LockState.off;
  }

  /// Every lock value, for a fresh install that found a leftover keychain.
  Future<void> wipe() => _store.clear();

  Future<LockState> changePin(String pin) async {
    final m = await _read();
    _need(m);
    return _write({...m, ..._hashed(pin), 'tries': 0, 'heldUntil': null});
  }

  Future<LockState> setBio(bool on) async {
    final m = await _read();
    _need(m);
    return _write({...m, 'bio': on, if (on) 'bioChanged': false});
  }

  /// A new face / fingerprint was enrolled: biometrics off until the pin
  /// turns them back on.
  Future<LockState> markBioChanged() async {
    final m = await _read();
    _need(m);
    return _write({...m, 'bio': false, 'bioChanged': true});
  }

  Future<LockState> setAfter(Duration after) async {
    final m = await _read();
    _need(m);
    return _write({...m, 'afterMin': after.inMinutes});
  }

  Future<LockState> setBlur(bool on) async {
    final m = await _read();
    _need(m);
    return _write({...m, 'blur': on});
  }

  /// Checks [pin] at [now]. While held nothing is checked or counted; a right
  /// pin clears the count, a wrong one adds to it (and may start a hold).
  Future<({PinOutcome outcome, LockState state})> verifyPin(
    String pin,
    DateTime now,
  ) async {
    final m = await _read();
    _need(m);
    final held = _state(m);
    if (held.holdLeft(now) != null) {
      return (outcome: PinOutcome.held, state: held);
    }
    if (_hash(pin, m['salt'] as String) == m['hash']) {
      return (outcome: PinOutcome.ok, state: await _clearTries(m));
    }
    final tries = (m['tries'] as int? ?? 0) + 1;
    final hold = holdAfter(tries);
    final state = await _write({
      ...m,
      'tries': tries,
      'heldUntil': hold == null ? null : now.add(hold).millisecondsSinceEpoch,
    });
    return (outcome: PinOutcome.wrong, state: state);
  }

  /// Face id / sidik jari worked: same as a right pin for the count.
  Future<LockState> bioSucceeded() async {
    final m = await _read();
    _need(m);
    return _clearTries(m);
  }

  Future<LockState> _clearTries(Map<String, Object?> m) =>
      (m['tries'] as int? ?? 0) == 0 && m['heldUntil'] == null
      ? Future.value(_state(m))
      : _write({...m, 'tries': 0, 'heldUntil': null});

  void _need(Map<String, Object?> m) {
    if (m['hash'] == null) throw StateError('kunci app belum nyala');
  }

  Map<String, Object?> _hashed(String pin) {
    if (!isValidPin(pin) || isWeakPin(pin)) {
      throw ArgumentError.value(pin, 'pin', 'not a usable pin');
    }
    final salt = base64Url.encode(
      List<int>.generate(16, (_) => Random.secure().nextInt(256)),
    );
    return {'hash': _hash(pin, salt), 'salt': salt};
  }

  String _hash(String pin, String salt) =>
      Hmac(sha256, utf8.encode(salt)).convert(utf8.encode(pin)).toString();
}

final appLockRepositoryProvider = Provider<AppLockRepository>(
  (ref) => AppLockRepository(ref.watch(lockStoreProvider)),
);
