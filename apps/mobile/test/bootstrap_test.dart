import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';
import 'package:mibu/main.dart';
import 'package:mibu/ui/core/finance_providers.dart';

void main() {
  // Regression: main() awaited a provider nobody listened to; Riverpod 3
  // paused it, runApp never ran → blank white screen.
  for (final (name, seed, onboarded) in [
    ('fresh install', (_, _) async {}, false),
    ('seeded', seedFixture, true),
  ]) {
    test('bootstrap finishes: $name', () async {
      final db = AppDatabase(
        DatabaseConnection(
          NativeDatabase.memory(),
          closeStreamsSynchronously: true,
        ),
        DateTime.now,
        seed,
      );
      final c = await bootstrap(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      ).timeout(const Duration(seconds: 5));
      expect(c.read(profileProvider).value?.onboarded, onboarded);
      c.dispose();
      await db.close();
    });
  }
}
