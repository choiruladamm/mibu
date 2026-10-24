import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../domain/models/app_lock.dart';

/// Face id / sidik jari, as far as the lock needs it. The pin is our own, so
/// the phone's passcode is never offered as a fallback.
abstract interface class Biometrics {
  /// What the phone can use right now (none = nothing enrolled / allowed).
  Future<BioKind> kind();

  /// Shows the system prompt; false on failure, cancel or anything odd.
  Future<bool> authenticate(String reason);
}

class LocalAuthBiometrics implements Biometrics {
  final _auth = LocalAuthentication();

  @override
  Future<BioKind> kind() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return BioKind.face;
      if (types.contains(BiometricType.fingerprint)) return BioKind.finger;
      // Android reports "strong" / "weak" for whatever is enrolled: in
      // practice a fingerprint. iOS names its biometrics.
      if (types.isNotEmpty && defaultTargetPlatform != TargetPlatform.iOS) {
        return BioKind.finger;
      }
    } on Exception {
      // unavailable: same as none
    }
    return BioKind.none;
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
      );
    } on Exception {
      return false;
    }
  }
}

final biometricsProvider = Provider<Biometrics>((_) => LocalAuthBiometrics());
