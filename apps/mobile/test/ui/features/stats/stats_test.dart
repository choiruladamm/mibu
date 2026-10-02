import 'package:drift/drift.dart' show DatabaseConnection, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/stats/views/stats_view.dart';

import '../../../meta.dart';

void main() {
  // Fixture, rab 14 okt 2026, budget Rp8jt: okt Rp4,06jt (tokopedia 2,4jt +
  // gojek 163K on the 11th, dokter hewan 450K 12th, warteg + kopi + petshop
  // 1,02jt 13th, gojek 27K today); september Rp2,61jt.
  Future<AppDatabase> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final now = DateTime(2026, 10, 14, 14, 50);
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
      () => now,
      seedFixture,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const StatsView(),
        ),
      ),
    );
    await settle(tester);
    return db;
  }

  testWidgets('02.3b bulan: total, delta, sekilas, on track, larinya', (
    tester,
  ) async {
    await pump(tester);
    expect(findMeta(['keluar bulan ini', 'oktober 2026']), findsOneWidget);
    expect(find.text('Rp4,06jt'), findsOneWidget);
    expect(find.text('↑ Rp1,45jt vs september'), findsOneWidget);
    expect(find.text('aman'), findsOneWidget);
    expect(find.text('masih ada Rp3,94jt buat 17 hari lagi'), findsOneWidget);
    expect(findMeta(['budget Rp8jt', 'jatah sebulan']), findsOneWidget);
    expect(find.text('dari 3 minggu'), findsOneWidget);
    expect(find.text('belanja'), findsOneWidget); // top category
    expect(find.text('+ ngopi 4%'), findsOneWidget); // 5th of 5
  });

  testWidgets('02.3a minggu, then ‹ to last week', (tester) async {
    await pump(tester);
    await tester.tap(find.text('minggu'));
    await settle(tester);
    expect(findMeta(['keluar minggu ini', '12 – 18 okt']), findsOneWidget);
    expect(find.text('Rp1,5jt'), findsOneWidget);
    expect(find.text('selasa'), findsOneWidget); // paling boros
    expect(find.text('senin'), findsOneWidget); // paling hemat (rab runs)
    expect(find.text('dari 3 hari'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('periode sebelumnya'));
    await settle(tester);
    expect(findMeta(['keluar', '5 – 11 okt']), findsOneWidget);
    expect(find.text('Rp2,56jt'), findsNWidgets(2)); // total + boros (min 11)
    expect(find.text('lewat budget'), findsOneWidget); // > Rp1,81jt
  });

  testWidgets('02.3d no budget: pasang budget card', (tester) async {
    final db = await pump(tester);
    await tester.runAsync(
      () => db
          .update(db.profiles)
          .write(const ProfilesCompanion(monthlyBudget: Value(null))),
    );
    await settle(tester);
    expect(find.text('pasang budget'), findsOneWidget);
    expect(find.text('aman'), findsNothing);
  });
}

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}
