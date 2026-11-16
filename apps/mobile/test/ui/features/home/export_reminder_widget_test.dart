import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';
import 'package:mibu/data/repositories/app_lock_repository.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/home/view_models/export_reminder.dart';
import 'package:mibu/ui/features/home/views/home_view.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import '../../../lock_store.dart';

class FakeShare extends SharePlatform {
  ShareResult result = ShareResult.unavailable;
  bool fail = false;
  int calls = 0;
  ShareParams? params;

  @override
  Future<ShareResult> share(ShareParams params) async {
    calls++;
    this.params = params;
    if (fail) throw Exception('share failed');
    return result;
  }
}

void main() {
  final now = DateTime(2026, 10, 14, 14, 50);
  final fake = FakeShare();
  late SharePlatform original;

  setUpAll(() {
    original = SharePlatform.instance;
    SharePlatform.instance = fake;
  });
  tearDownAll(() => SharePlatform.instance = original);

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<MemoryLockStore> pumpHome(WidgetTester tester) async {
    fake.calls = 0;
    fake.fail = false;
    fake.params = null;
    final store = MemoryLockStore();
    store.values[exportReminderKey] = now
        .subtract(const Duration(days: 14))
        .toIso8601String();
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
      () => now,
      seedFixture,
    );
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await db.close();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
          lockStoreProvider.overrideWithValue(store),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeView(),
        ),
      ),
    );
    await settle(tester);
    return store;
  }

  testWidgets('due banner explains CSV scope and can be dismissed', (
    tester,
  ) async {
    await pumpHome(tester);
    expect(find.text('export catatan transaksi'), findsOneWidget);
    expect(
      find.text(
        'udah 14 hari belum export. csv cuma berisi transaksi, bukan pengaturan.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip('tutup pengingat'));
    await settle(tester);
    expect(find.text('export catatan transaksi'), findsNothing);
    expect(fake.calls, 0);
    expect(find.text('kantong'), findsOneWidget);
  });

  for (final status in ShareResultStatus.values) {
    testWidgets('banner export records only share success: $status', (
      tester,
    ) async {
      fake.result = ShareResult('result', status);
      final store = await pumpHome(tester);
      final baseline = store.values[exportReminderKey];
      await tester.tap(find.text('export catatan transaksi'));
      await settle(tester);
      expect(fake.calls, 1);
      expect(fake.params!.files, hasLength(1));
      expect(fake.params!.fileNameOverrides, ['mibu-20261014.csv']);
      expect(
        store.values[exportReminderKey],
        status == ShareResultStatus.success ? now.toIso8601String() : baseline,
      );
      expect(find.text('kantong'), findsOneWidget);
    });
  }

  testWidgets('share failure shows localized error and leaves screen usable', (
    tester,
  ) async {
    final store = await pumpHome(tester);
    final baseline = store.values[exportReminderKey];
    fake.fail = true;
    await tester.tap(find.text('export catatan transaksi'));
    await settle(tester);
    expect(fake.calls, 1);
    expect(store.values[exportReminderKey], baseline);
    expect(find.text('belum bisa disimpan'), findsOneWidget);
    await tester.tap(find.byTooltip('tutup pengingat'));
    await settle(tester);
    expect(find.text('export catatan transaksi'), findsNothing);
    expect(find.text('kantong'), findsOneWidget);
  });
}
