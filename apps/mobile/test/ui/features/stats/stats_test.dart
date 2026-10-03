import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/core/widgets/app_emoji.dart';
import 'package:mibu/ui/features/stats/views/stats_view.dart';

import '../../../meta.dart';
import '../../../db.dart';

void main() {
  // Fixture, rab 14 okt 2026, budget Rp8jt: okt Rp4,06jt (tokopedia 2,4jt +
  // gojek 163K on the 11th, dokter hewan 450K 12th, warteg + kopi + petshop
  // 1,02jt 13th, gojek 27K today); september Rp2,61jt.
  Future<AppDatabase> pump(WidgetTester tester, {double width = 900}) async {
    tester.view.physicalSize = Size(width, 2400);
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
    // sekilas: the biggest bar (5–11 okt: tokopedia) and why
    expect(find.text('paling boros'), findsOneWidget);
    expect(find.text('gara-gara'), findsOneWidget);
    expect(find.text('belanja'), findsNWidgets(2)); // gara-gara + larinya
    expect(find.text('rata²/minggu'), findsOneWidget);
    expect(find.text('+ ngopi 4%'), findsOneWidget); // 5th of 5
  });

  testWidgets('02.3a minggu, then ‹ to last week', (tester) async {
    await pump(tester);
    await tester.tap(find.text('minggu'));
    await settle(tester);
    expect(findMeta(['keluar minggu ini', '12 – 18 okt']), findsOneWidget);
    expect(find.text('Rp1,5jt'), findsOneWidget);
    expect(find.text('selasa'), findsOneWidget); // paling boros
    expect(find.text('rata²/hari'), findsOneWidget);
    expect(find.text('senin'), findsOneWidget); // paling hemat (rab runs)
    expect(find.text('dari 3 hari'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('periode sebelumnya'));
    await settle(tester);
    expect(findMeta(['keluar', '5 – 11 okt']), findsOneWidget);
    expect(find.text('Rp2,56jt'), findsNWidgets(2)); // total + boros (min 11)
    expect(find.text('lewat budget'), findsOneWidget); // > Rp1,81jt
  });

  testWidgets('02.3c tahun: amount chip isn\'t squeezed to the bar column', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.text('tahun'));
    await settle(tester);
    await tester.tap(find.bySemanticsLabel(RegExp('^september, ')));
    await settle(tester);
    final chip = tester.getRect(find.text('Rp2,61jt').first);
    final column = tester.getRect(
      find.bySemanticsLabel(RegExp('^september, ')),
    );
    expect(chip.width, greaterThan(column.width)); // not clipped to 1/12
    expect(chip.left, greaterThan(16)); // still inside the card
    expect(chip.right, lessThan(900 - 16));
  });

  testWidgets('sekilas fits a 390 wide phone in every period', (tester) async {
    // Ahem (tests) is 1em per glyph, so the chart legend overflows here:
    // only the sekilas widgets are held to fit.
    final errors = <String>[];
    final onError = FlutterError.onError;
    FlutterError.onError = (d) => errors.add(d.toString());
    addTearDown(() => FlutterError.onError = onError);

    await pump(tester, width: 390);
    for (final p in ['minggu', 'tahun', 'bulan']) {
      await tester.tap(find.text(p));
      await settle(tester);
      expect(find.text('gara-gara'), findsOneWidget);
    }
    expect(
      errors.where((e) => e.contains('_MiniTile') || e.contains('_PeakCard')),
      isEmpty,
    );
  });

  testWidgets('paling boros emoji sits 27px from the card corner', (
    tester,
  ) async {
    await pump(tester);
    final card = tester.getRect(
      find.bySemanticsLabel(RegExp('^paling boros ')),
    );
    // the decorative circle's emoji (the bar badge is a different widget)
    final emoji = tester.getCenter(
      find.byWidgetPredicate((w) => w is AppEmoji && w.size == 34),
    );
    expect(card.right - emoji.dx, closeTo(27, 0.5));
    expect(emoji.dy - card.top, closeTo(27, 0.5));
  });

  testWidgets('02.3d no budget: pasang budget card', (tester) async {
    final db = await pump(tester);
    await tester.runAsync(() => setBudgetOf(db, null));
    await settle(tester);
    expect(find.text('pasang budget'), findsOneWidget);
    expect(find.text('aman'), findsNothing);
  });

  // Budgets are per period: a past one keeps its own budget, not today's.
  testWidgets('on track in a past period uses that period\'s budget', (
    tester,
  ) async {
    final db = await pump(tester);
    // Oktober gets Rp5jt; september still has the Rp8jt from july on.
    await tester.runAsync(() => setBudgetOf(db, 5000000));
    await settle(tester);
    expect(findMeta(['budget Rp5jt', 'jatah sebulan']), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('periode sebelumnya'));
    await settle(tester);
    expect(findMeta(['budget Rp8jt', 'jatah sebulan']), findsOneWidget);
  });
}

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}
