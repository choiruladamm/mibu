import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/core/widgets/sheet.dart';
import 'package:mibu/ui/core/widgets/tap_outside_unfocus.dart';
import 'package:mibu/ui/features/search/views/search_view.dart';
import 'package:drift/drift.dart' show DatabaseConnection;

import '../../../meta.dart';

void main() {
  // Fixture, 14 okt: gojek 11 + 14, tokopedia 11, dokter hewan 12, warteg +
  // kopi kenangan + petshop 13; kantor (gajian) on the 25th of past months.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pump(WidgetTester tester, {Seed seed = seedFixture}) async {
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
      seed,
    );
    final router = GoRouter(
      routes: [GoRoute(path: '/', builder: (_, _) => const SearchView())],
      // Anywhere else: show where we went.
      errorBuilder: (_, state) => Scaffold(body: Text('→ ${state.uri}')),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
        ],
        child: TapOutsideUnfocus(
          child: MaterialApp.router(
            theme: AppTheme.light,
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      ),
    );
    await settle(tester);
  }

  Future<void> type(WidgetTester tester, String q) async {
    await tester.enterText(find.byType(TextField), q);
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.tap(f);
    await settle(tester);
  }

  testWidgets('04.2b idle: coba cari, no type pills; a hit shows summary', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text('cari'), findsOneWidget);
    expect(findMeta(['di oktober']), findsOneWidget);
    expect(find.text('paling sering bulan ini'), findsOneWidget);
    for (final idea in ['gojek', 'petshop', 'warteg', 'ngopi', 'belanja']) {
      expect(find.text(idea), findsOneWidget);
    }
    expect(find.text('pemasukan'), findsNothing); // pills only while typing
    expect(find.text('terakhir dicari'), findsNothing);

    await type(tester, 'dokter hewan');
    expect(find.text('coba cari'), findsNothing);
    expect(find.text('pemasukan'), findsOneWidget);
    // pills sit in one row, each as wide as its label
    final pills = [
      'semua',
      'pengeluaran',
      'pemasukan',
    ].map((t) => tester.getRect(find.text(t))).toList();
    expect(pills.map((r) => r.top).toSet(), hasLength(1));
    expect(pills[0].right, lessThan(pills[1].left));
    expect(findMeta(['1 hasil']), findsOneWidget);
    expect(find.text('-Rp450K'), findsNWidgets(2)); // summary total + row
  });

  testWidgets('04.2b2 user baru: nothing to search yet → catat', (
    tester,
  ) async {
    await pump(tester, seed: (_, _) async {});
    expect(find.text('belum ada yang bisa dicari'), findsOneWidget);
    expect(find.text('coba cari'), findsNothing);
    await tap(tester, find.text('belum ada yang bisa dicari'));
    expect(find.text('→ /catat'), findsOneWidget);
  });

  testWidgets('04.2c nggak ketemu: typo fix, other kind, other months', (
    tester,
  ) async {
    await pump(tester);
    await type(tester, 'zzz');
    expect(find.text('“zzz” nggak ketemu'), findsOneWidget);
    expect(find.text('di oktober'), findsNWidgets(2)); // header + sub
    expect(find.textContaining('ada ', findRichText: true), findsNothing);

    await type(tester, 'petshp');
    await tap(tester, find.text('maksud kamu “petshop”?', findRichText: true));
    expect(findMeta(['1 hasil']), findsOneWidget);

    await type(tester, 'kopi');
    await tap(tester, find.text('pemasukan'));
    expect(find.text('di pemasukan oktober'), findsOneWidget);
    await tap(tester, find.text('ada 1 di pengeluaran', findRichText: true));
    expect(findMeta(['1 hasil']), findsOneWidget);

    await type(tester, 'kantor'); // gajian, past months only
    await tap(tester, find.text('ada 3 di bulan lain', findRichText: true));
    expect(findMeta(['di semua bulan']), findsOneWidget);
    expect(find.text('3 hasil di semua bulan'), findsOneWidget);
    await tap(tester, find.text('balik ke oktober'));
    expect(find.text('“kantor” nggak ketemu'), findsOneWidget);

    await tap(tester, find.bySemanticsLabel('hapus pencarian'));
    expect(find.text('coba cari'), findsOneWidget);
  });

  testWidgets('04.2b terakhir dicari: saved on submit, tap ×, hapus semua', (
    tester,
  ) async {
    await pump(tester);
    await type(tester, 'warteg');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    await tap(tester, find.bySemanticsLabel('hapus pencarian'));
    await tap(tester, find.text('gojek')); // idea chip searches + remembers
    await tap(tester, find.bySemanticsLabel('hapus pencarian'));
    expect(find.text('terakhir dicari'), findsOneWidget);
    expect(find.text('warteg'), findsNWidgets(2)); // recent + idea

    await tap(tester, find.bySemanticsLabel('hapus warteg dari riwayat'));
    expect(find.text('warteg'), findsOneWidget);
    await tap(tester, find.text('hapus semua'));
    expect(find.text('terakhir dicari'), findsNothing);
  });

  testWidgets('00.14: tap the ticks to pick a day, semua hari drops it', (
    tester,
  ) async {
    await pump(tester);
    await type(tester, 'gojek'); // 11 + 14 okt
    expect(findMeta(['2 hasil', '2 hari']), findsOneWidget);

    final ticks = tester.getRect(
      find.byWidgetPredicate(
        (w) => w is GestureDetector && w.onHorizontalDragUpdate != null,
      ),
    );
    await tester.tapAt(ticks.centerLeft + const Offset(2, 0)); // 1 okt → 11
    await tester.pumpAndSettle();
    expect(find.text('semua hari'), findsOneWidget);
    expect(find.text('min 11 okt'), findsOneWidget);
    expect(findMeta(['1×', '-Rp163K']), findsOneWidget);
    expect(find.text('geser buat ganti hari'), findsOneWidget);

    await tap(tester, find.text('semua hari'));
    expect(find.text('semua hari'), findsNothing);
  });

  testWidgets('04.2: "liat N lagi" opens 04.1 narrowed to the search', (
    tester,
  ) async {
    await pump(tester);
    await type(tester, 'o'); // nearly everything this month
    await tap(tester, find.text('pengeluaran'));
    await tap(tester, find.textContaining('liat '));
    expect(
      find.text('→ /transaksi?month=2026-10&q=o&filter=expenses'),
      findsOneWidget,
    );
  });

  testWidgets('04.2: × in the field clears the query and the filter', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byType(TextField));
    await type(tester, 'gojek');
    expect(findMeta(['2 hasil', '2 hari']), findsOneWidget);
    await tap(tester, find.text('pemasukan'));
    await tap(tester, find.byType(CircleButton)); // × in the field
    expect(find.text('gojek'), findsOneWidget); // idea chip only
    expect(find.text('coba cari'), findsOneWidget);
    expect(find.byType(CircleButton), findsNothing); // only while typing

    await type(tester, 'gojek'); // filter went back to semua
    expect(findMeta(['2 hasil', '2 hari']), findsOneWidget);
  });
}
