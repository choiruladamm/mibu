import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';
import 'package:mibu/data/repositories/app_lock_repository.dart';
import 'package:mibu/main.dart';
import 'package:mibu/ui/core/app_lock_providers.dart';
import 'package:mibu/ui/core/finance_providers.dart';

import 'lock_store.dart';

AppDatabase _db(Seed seed) => AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
  DateTime.now,
  seed,
);

void main() {
  // Regression: main() awaited a provider nobody listened to; Riverpod 3
  // paused it, runApp never ran → blank white screen.
  for (final (name, seed, onboarded) in [
    ('fresh install', (_, _) async {}, false),
    ('seeded', seedFixture, true),
  ]) {
    test('bootstrap finishes: $name', () async {
      final db = _db(seed);
      final c = await bootstrap(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          lockStoreProvider.overrideWithValue(MemoryLockStore()),
        ],
      ).timeout(const Duration(seconds: 5));
      expect(c.read(profileProvider).value?.onboarded, onboarded);
      c.dispose();
      await db.close();
    });
  }

  // iOS keeps keychain items after an uninstall, the database goes: a fresh
  // install must not inherit the old pin (its card says "instal ulang").
  test('a fresh install drops a leftover pin', () async {
    final store = MemoryLockStore();
    await AppLockRepository(store).enable('483917', bio: true);
    final db = _db((_, _) async {});
    final c = await bootstrap(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        lockStoreProvider.overrideWithValue(store),
      ],
    ).timeout(const Duration(seconds: 5));
    expect(c.read(appLockProvider).value?.enabled, isFalse);
    expect(store.values, isEmpty);
    c.dispose();
    await db.close();
  });

  test(
    'an onboarded install keeps its pin, loaded before the first frame',
    () async {
      final store = MemoryLockStore();
      await AppLockRepository(store).enable('483917', bio: true);
      final db = _db(seedFixture);
      final c = await bootstrap(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          lockStoreProvider.overrideWithValue(store),
        ],
      ).timeout(const Duration(seconds: 5));
      final lock = c.read(appLockProvider).value;
      expect(lock?.enabled, isTrue);
      expect(lock?.bio, isTrue);
      c.dispose();
      await db.close();
    },
  );
}
