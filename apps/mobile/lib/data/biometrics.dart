import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../domain/models/app_lock.dart';

/// Face ID or fingerprint support needed by the app lock. The app uses its
/// own PIN, so the device passcode is never offered as a fallback.
abstract interface class Biometrics {
  /// Biometrics currently available (none = unavailable or not enrolled).
  Future<BioKind> kind();

  /// Shows the system prompt; false on failure, cancel or anything odd.
  Future<bool> authenticate(String reason);

  /// Records current enrollment as the biometrics trusted by the lock.
  Future<void> snapshot();

  /// Whether biometrics were enrolled since [snapshot]. False if there is
  /// nothing to compare or enrollment changes cannot be detected.
  Future<bool> enrollmentChanged();
}

/// Native side in AppDelegate.swift and MainActivity.kt: `local_auth` does not
/// expose enrollment changes, nor FLAG_SECURE.
const lockChannel = MethodChannel('com.mibu/lock');

class LocalAuthBiometrics implements Biometrics {
  final _auth = LocalAuthentication();

  @override
  Future<BioKind> kind() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      if (types.contains(BiometricType.face)) return BioKind.face;
      if (types.contains(BiometricType.fingerprint)) return BioKind.finger;
      // Android reports strength, usually for fingerprints; iOS names the type.
      if (types.isNotEmpty && defaultTargetPlatform != TargetPlatform.iOS) {
        return BioKind.finger;
      }
    } on Exception {
      // Treat unavailable as none.
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

  @override
  Future<void> snapshot() async {
    try {
      await lockChannel.invokeMethod<void>('snapshot');
    } on Exception {
      // no native side (tests, unsupported platform): nothing to remember
    }
  }

  @override
  Future<bool> enrollmentChanged() async {
    try {
      return await lockChannel.invokeMethod<bool>('enrollmentChanged') ?? false;
    } on Exception {
      return false;
    }
  }
}

final biometricsProvider = Provider<Biometrics>((_) => LocalAuthBiometrics());
