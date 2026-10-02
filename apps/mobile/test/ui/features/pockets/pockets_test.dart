import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/repositories/finance_repository.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/pockets/views/pockets_view.dart';

void main() {
  Future<AppDatabase> pump(
    WidgetTester tester,
    Size size, {
    Future<String?> Function(AppDatabase db)? initial,
  }) async {
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
    final initialId = initial == null
        ? null
        : await tester.runAsync(() => initial(db));
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
          home: PocketsView(initial: initialId),
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
    expect(find.text('18 hari lagi'), findsOneWidget);
    expect(
      find.text(
        'Rp1,66jt dari Rp3,3jt kepake · budget Rp8jt',
        findRichText: true,
      ),
      findsOneWidget,
    );

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

  testWidgets('budget: edit, hapus + batalin, prefill when empty', (
    tester,
  ) async {
    final db = await pump(tester, const Size(390, 844));
    Future<int?> budget() async =>
        (await db.select(db.profiles).getSingle()).monthlyBudget;
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }

    Future<void> openSheet() async {
      await tester.tap(find.textContaining('kepake ·', findRichText: true));
      await tester.pumpAndSettle();
    }

    // Edit: first key replaces the current Rp8jt.
    await openSheet();
    expect(find.text('budget sekarang'), findsOneWidget);
    expect(find.text('8.000.000'), findsOneWidget);
    for (final k in ['5', '000', '000']) {
      await tester.tap(
        find.bySemanticsLabel(k == '000' ? 'tambah tiga nol' : k),
      );
      await tester.pump();
    }
    expect(find.text('5.000.000'), findsOneWidget);
    expect(
      find.text('kantong kamu total Rp3,3jt · sisa bebas Rp1,7jt'),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel('simpan Rp5jt / bln'));
    await settle();
    expect(await budget(), 5000000);
    expect(find.text('budget Rp5jt kesimpen'), findsOneWidget);
    expect(
      find.textContaining('budget Rp5jt', findRichText: true),
      findsWidgets,
    );

    // Hapus → toast with batalin.
    await openSheet();
    await tester.tap(find.text('hapus budget'));
    await settle();
    expect(await budget(), isNull);
    expect(find.text('budget dihapus'), findsOneWidget);
    expect(find.textContaining('pasang budget', findRichText: true), findsOne);
    await tester.tap(find.text('batalin'));
    await settle();
    expect(await budget(), 5000000);

    // Empty: prefill Σ limits 3,3jt → 3,5jt; short of the pockets is bold.
    await tester.runAsync(() => FinanceRepository(db).setMonthlyBudget(null));
    await settle();
    await openSheet();
    expect(find.text('saran dari total kantong'), findsOneWidget);
    expect(find.text('diisi otomatis'), findsOneWidget);
    expect(find.text('3.500.000'), findsOneWidget);
    expect(find.text('hapus budget'), findsNothing);
    await tester.tap(find.bySemanticsLabel('kosongin semua'));
    await tester.pump();
    expect(
      find.text('kantong kamu total Rp3,3jt · ketik budget kamu'),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel('1'));
    await tester.tap(find.bySemanticsLabel('tambah tiga nol'));
    await tester.tap(find.bySemanticsLabel('tambah tiga nol'));
    await tester.pump();
    expect(
      find.text('kurang Rp2,3jt buat nutup semua kantong'),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('budget sheet: drags on the keypad stay, the handle closes', (
    tester,
  ) async {
    final db = await pump(tester, const Size(390, 844));
    await tester.tap(find.textContaining('kepake ·', findRichText: true));
    await tester.pumpAndSettle();
    expect(find.text('budget bulanan'), findsOneWidget);

    await tester.drag(find.bySemanticsLabel('5'), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(find.text('budget bulanan'), findsOneWidget);

    final handle =
        tester.getTopLeft(find.text('budget bulanan')) + const Offset(150, -30);
    await tester.dragFrom(handle, const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(find.text('budget bulanan'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('kantong fits a short screen (375×667)', (tester) async {
    final db = await pump(tester, const Size(375, 667));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('kantong: opens on the pocket from a 02.1 pill link', (
    tester,
  ) async {
    await pump(
      tester,
      const Size(390, 844),
      initial: (db) async => (await (db.select(
        db.categories,
      )..where((c) => c.name.equals('ojol'))).getSingle()).id,
    );

    expect(find.text('ojol'), findsOneWidget); // detail card title
    expect(find.text('hampir abis'), findsNothing);
  });

  testWidgets('kantong: an unknown pocket id falls back to most used', (
    tester,
  ) async {
    await pump(tester, const Size(390, 844), initial: (_) async => 'gone');

    expect(find.text('anabul'), findsOneWidget);
    expect(find.text('hampir abis'), findsOneWidget);
  });
}
