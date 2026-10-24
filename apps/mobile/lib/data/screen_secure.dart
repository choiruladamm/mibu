import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometrics.dart';

/// Android FLAG_SECURE: the app list shows no content and screenshots are
/// blocked. iOS has no such flag (the gate covers the app itself).
abstract interface class ScreenSecure {
  Future<void> set(bool on);
}

class ChannelScreenSecure implements ScreenSecure {
  const ChannelScreenSecure();

  @override
  Future<void> set(bool on) async {
    try {
      await lockChannel.invokeMethod<void>('secure', on);
    } on Exception {
      // no native side (tests, unsupported platform)
    }
  }
}

final screenSecureProvider = Provider<ScreenSecure>(
  (_) => const ChannelScreenSecure(),
);
