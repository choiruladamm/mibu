import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/pockets/views/pockets_view.dart';

void main() {
  Future<AppDatabase> pump(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final now = DateTime(2026, 10, 14, 14, 50);
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
      () => now,
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
          home: const PocketsView(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    return db;
  }

  testWidgets('kantong: totals, first jar selected, tap a jar to switch', (
    tester,
  ) async {
    final db = await pump(tester, const Size(390, 844));

    // Σ limit 3,3jt − Σ kepake 1,66jt; 14 okt → 18 days incl. today
    expect(find.text('sisa jajan oktober'), findsOneWidget);
    expect(find.text('1.640.000'), findsOneWidget);
    expect(find.text('Rp1,66jt dari Rp3,3jt kepake · 18 hari lagi'), findsOne);

    // anabul 90% → hampir abis
    expect(find.text('anabul'), findsOneWidget);
    expect(find.text('hampir abis'), findsOneWidget);
    expect(find.text('Rp100K'), findsOneWidget);
    expect(find.text('sisa dari Rp1jt'), findsOneWidget);
    expect(
      find.text('kira-kira Rp5,6K sehari buat 18 hari ke depan'),
      findsOneWidget,
    );

    await tester.tap(find.bySemanticsLabel('ngopi, 60% kepake'));
    await tester.pumpAndSettle();
    expect(find.text('ngopi'), findsOneWidget);
    expect(find.text('aman'), findsOneWidget);
    expect(find.text('Rp120K'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('kantong fits a short screen (375×667)', (tester) async {
    final db = await pump(tester, const Size(375, 667));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
