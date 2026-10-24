import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/biometrics.dart';
import 'package:mibu/data/repositories/app_lock_repository.dart';
import 'package:mibu/domain/models/app_lock.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/app_lock_providers.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';

import 'lock_store.dart';

const lockPin = '483917';

/// A phone with face id / sidik jari, or none; counts how often the system
/// prompt came up.
class FakeBiometrics implements Biometrics {
  FakeBiometrics({this.has = BioKind.none, this.passes = true});

  BioKind has;
  bool passes;
  int prompts = 0;

  @override
  Future<BioKind> kind() async => has;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return passes;
  }
}

/// A lock in memory: store, repository, pinned clock, fake biometrics.
class LockHarness {
  LockHarness({BioKind bio = BioKind.none}) : bio = FakeBiometrics(has: bio);

  final store = MemoryLockStore();
  final FakeBiometrics bio;
  DateTime now = DateTime(2026, 10, 24, 12);

  late final repo = AppLockRepository(store);
  late final container = ProviderContainer(
    overrides: <Override>[
      lockStoreProvider.overrideWithValue(store),
      biometricsProvider.overrideWithValue(bio),
      clockProvider.overrideWithValue(() => now),
    ],
  );

  /// Loads the lock like `bootstrap` does, so the session starts right.
  Future<void> load() async {
    container.listen(appLockProvider, (_, _) {});
    await container.read(appLockProvider.future);
  }

  AppLockState get lock => container.read(appLockProvider).value!;
  bool get locked => container.read(lockSessionProvider);

  Widget app(Widget home) => UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('id'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );

  void dispose() => container.dispose();
}

/// Types [pin] on the pin pad.
Future<void> typePin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.text(d));
    await tester.pump();
  }
}
