import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';
import 'package:mibu/data/repositories/app_lock_repository.dart';
import 'package:mibu/main.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lock_store.dart';

void main() {
  // Regression: the listener was a `late final` field first read in dispose,
  // so it never existed while the app ran and "now" never refreshed on resume.
  testWidgets('coming back to the app on a new day refreshes "now"', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    var clock = DateTime(2026, 10, 14, 23, 50);
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
      () => clock,
      seedFixture,
    );
    final container = await tester.runAsync(
      () => bootstrap(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => clock),
          lockStoreProvider.overrideWithValue(MemoryLockStore()),
        ],
      ),
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      container!.dispose();
      await db.close();
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container!, child: const MibuApp()),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(container.read(nowProvider).day, 14);

    final b = tester.binding;
    b.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    b.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    b.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    clock = DateTime(2026, 10, 15, 8);
    expect(container.read(nowProvider).day, 14); // nothing moves while away

    b.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    b.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    b.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(container.read(nowProvider).day, 15);
  });
}
