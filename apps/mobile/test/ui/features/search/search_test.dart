import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/search/views/search_view.dart';
import 'package:drift/drift.dart' show DatabaseConnection;

import '../../../meta.dart';

void main() {
  Future<void> pump(WidgetTester tester) async {
    // Tests render with Ahem (1em per glyph): keep the surface wide.
    tester.view.physicalSize = const Size(900, 1400);
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
          home: const SearchView(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String q) async {
    await tester.enterText(find.byType(TextField), q);
    await tester.pumpAndSettle();
  }

  testWidgets('04.2: idle shows ideas; a hit shows summary and row', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('cari'), findsOneWidget);
    expect(find.text('di oktober'), findsOneWidget);
    expect(find.text('coba cari'), findsOneWidget);
    expect(find.text('ngopi'), findsOneWidget); // idea chip

    await type(tester, 'dokter hewan');
    expect(find.text('coba cari'), findsNothing);
    expect(findMeta(['1 hasil']), findsOneWidget);
    expect(find.text('-Rp450K'), findsNWidgets(2)); // summary total + row
    expect(find.text('anabul'), findsOneWidget);
  });

  testWidgets('04.2: no hits, then hapus pencarian clears the query', (
    tester,
  ) async {
    await pump(tester);
    await type(tester, 'zzz');
    expect(find.text('“zzz” nggak ketemu di oktober'), findsOneWidget);
    expect(find.text('Rp0'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('hapus pencarian'));
    await tester.pumpAndSettle();
    expect(find.text('coba cari'), findsOneWidget);
  });

  testWidgets('04.2: type filter and "liat N lagi"', (tester) async {
    await pump(tester);
    await type(tester, 'a'); // matches nearly everything this month
    expect(find.textContaining('liat '), findsOneWidget);
    await tester.tap(find.textContaining('liat '));
    await tester.pumpAndSettle();
    expect(find.textContaining('liat '), findsNothing);

    await tester.tap(find.text('pemasukan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('liat '), findsNothing);
  });
}
