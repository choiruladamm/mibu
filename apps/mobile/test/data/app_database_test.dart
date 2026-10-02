import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';

void main() {
  test(
    'MIBU_RESET: an existing database is wiped, then seeded again',
    () async {
      final dir = await Directory.systemTemp.createTemp('mibu');
      addTearDown(() => dir.delete(recursive: true));
      final file = File('${dir.path}/mibu.sqlite');
      final now = DateTime(2026, 10, 14, 14, 50);

      final seeded = AppDatabase(NativeDatabase(file), () => now, seedFixture);
      expect(await seeded.select(seeded.transactions).get(), isNotEmpty);
      await seeded.close();

      // Reopened with reset + no seed: a fresh install.
      final fresh = AppDatabase(
        NativeDatabase(file),
        () => now,
        (_, _) async {},
        true,
      );
      addTearDown(fresh.close);
      expect(await fresh.select(fresh.transactions).get(), isEmpty);
      expect(await fresh.select(fresh.categories).get(), isEmpty);
      expect(await fresh.select(fresh.profiles).get(), isEmpty);
    },
  );
}
