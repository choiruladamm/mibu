import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/repositories/finance_repository.dart';
import 'package:mibu/domain/models/finance.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/pockets/views/pockets_view.dart';

import '../../../meta.dart';

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
        'Rp1,66jt dari Rp3,3jt kepake\uFFFCbudget Rp8jt', // dot = placeholder
        findRichText: true,
      ),
      findsOneWidget,
    );

    // anabul 90% → hampir abis
    expect(find.text('anabul'), findsOneWidget);
    expect(find.text('hampir abis'), findsOneWidget);
    expect(find.text('Rp100K'), findsOneWidget);
    expect(find.text('jatah sisa dari limit Rp1jt'), findsOneWidget);
    expect(find.text('≈ Rp5,6K/hari sampai akhir bulan'), findsOneWidget);

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
      await tester.tap(find.textContaining('kepake', findRichText: true));
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
      find.text('total limit kamu Rp3,3jt · sisa bebas Rp1,7jt'),
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
    expect(find.text('saran dari total limit'), findsOneWidget);
    expect(find.text('diisi otomatis'), findsOneWidget);
    expect(find.text('3.500.000'), findsOneWidget);
    expect(find.text('hapus budget'), findsNothing);
    await tester.tap(find.bySemanticsLabel('kosongin semua'));
    await tester.pump();
    expect(
      find.text('total limit kamu Rp3,3jt · ketik budget kamu'),
      findsOneWidget,
    );
    await tester.tap(find.bySemanticsLabel('1'));
    await tester.tap(find.bySemanticsLabel('tambah tiga nol'));
    await tester.tap(find.bySemanticsLabel('tambah tiga nol'));
    await tester.pump();
    expect(find.text('kurang Rp2,3jt buat nutup semua limit'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('budget sheet: drags on the keypad stay, the handle closes', (
    tester,
  ) async {
    final db = await pump(tester, const Size(390, 844));
    await tester.tap(find.textContaining('kepake', findRichText: true));
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

  testWidgets('kantong: count row, dashed limit jar, belum ada limit section', (
    tester,
  ) async {
    final db = await pump(tester, const Size(390, 844));

    expect(find.text('4 pakai limit'), findsOneWidget);
    // 4 jars + limit fit in 342px: nothing to swipe to.
    expect(find.text('geser'), findsNothing);
    expect(find.bySemanticsLabel('pasang limit ke yang lain'), findsOneWidget);

    // belanja is the only expense category without a limit; income stays out.
    expect(find.text('belum ada limit'), findsOneWidget);
    expect(find.text('Rp2,4jt bulan ini', findRichText: true), findsOneWidget);
    expect(find.bySemanticsLabel('pasang limit buat belanja'), findsOneWidget);
    expect(find.text('gajian'), findsNothing);
    expect(find.textContaining('+'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('kantong: many pockets scroll, geser hint goes at the end', (
    tester,
  ) async {
    final db = await pump(tester, const Size(390, 844));
    for (final (i, name) in ['kos', 'tagihan', 'hiburan'].indexed) {
      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              emoji: '🏠',
              name: name,
              kind: CategoryKind.expense,
              monthlyLimit: Value(500000 + i),
              sortOrder: Value(10 + i),
            ),
          );
    }
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.text('geser'), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView).at(1),
      const Offset(-600, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('geser'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('kantong: no pockets shows the first-pocket card', (
    tester,
  ) async {
    final db = await pump(tester, const Size(390, 844));
    await (db.update(db.categories))
        .write(const CategoriesCompanion(monthlyLimit: Value(null)));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.text('pasang limit pertama'), findsOneWidget);
    expect(find.text('geser'), findsNothing);
    // all five expense categories are now free: top 2 + "+3"
    expect(find.text('+3'), findsOneWidget);

    await tester.tap(find.text('pasang limit pertama'));
    await tester.pumpAndSettle();
    expect(find.text('pasang limit ke…'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  Future<int?> limitOf(AppDatabase db, String name) async => (await (db.select(
    db.categories,
  )..where((c) => c.name.equals(name))).getSingle()).monthlyLimit;

  testWidgets('pasang limit: list → limit step → jar + toast, batalin', (
    tester,
  ) async {
    final db = await pump(tester, const Size(390, 844));

    await tester.tap(find.text('pasang limit'));
    await tester.pumpAndSettle();
    expect(find.text('pasang limit ke…'), findsOneWidget);
    expect(find.text('1 catatan'), findsOne); // row; amount on the right
    expect(find.text('gajian'), findsNothing); // income never shows
    expect(find.text('bikin baru'), findsOneWidget);

    await tester.tap(find.text('belanja').last); // the sheet row
    await tester.pumpAndSettle();
    // 2.399.000 × 1,4 rounded up to 100K
    expect(find.text('pasang limit Rp3,4jt'), findsOneWidget);
    expect(findMeta(['keisi 71%', 'sisa jatah Rp1jt']), findsOneWidget);

    await tester.tap(find.text('pasang limit Rp3,4jt'));
    await settle(tester);
    expect(await limitOf(db, 'belanja'), 3400000);
    expect(find.text('limit belanja Rp3,4jt kepasang'), findsOneWidget);
    expect(find.text('1 catatan langsung keitung'), findsOneWidget);
    expect(find.text('belanja'), findsOneWidget); // its jar got selected
    expect(find.textContaining('belum ada limit'), findsNothing);

    await tester.tap(find.text('batalin'));
    await settle(tester);
    expect(await limitOf(db, 'belanja'), isNull);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('pasang limit from a chip opens its limit step; ganti → list', (
    tester,
  ) async {
    final db = await pump(tester, const Size(390, 844));

    final chip = find.bySemanticsLabel('pasang limit buat belanja');
    await tester.ensureVisible(chip);
    await tester.pumpAndSettle();
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(find.text('pasang limit Rp3,4jt'), findsOneWidget);

    await tester.tap(find.text('ganti'));
    await tester.pumpAndSettle();
    expect(find.text('pasang limit ke…'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('pasang limit: nothing left → empty state', (tester) async {
    final db = await pump(tester, const Size(390, 844));
    await tester.runAsync(() async {
      final id = (await (db.select(
        db.categories,
      )..where((c) => c.name.equals('belanja'))).getSingle()).id;
      await FinanceRepository(db).setLimit(id, 500000);
    });
    await settle(tester);

    await tester.tap(find.text('pasang limit'));
    await tester.pumpAndSettle();
    expect(find.text('semua udah pakai limit'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('lepas limit: jar leaves, entries stay, batalin restores', (
    tester,
  ) async {
    final db = await pump(tester, const Size(390, 844));

    await tester.ensureVisible(find.text('lepas limit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('lepas limit'));
    await settle(tester);
    expect(await limitOf(db, 'anabul'), isNull);
    expect(find.text('limit anabul dilepas'), findsOneWidget);
    expect(find.text('anabul & 2 catatannya tetap ada'), findsOneWidget);
    expect(find.bySemanticsLabel('anabul, 90% kepake'), findsNothing);

    await tester.tap(find.text('batalin'));
    await settle(tester);
    expect(await limitOf(db, 'anabul'), 1000000);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  // Regression: the selected jar's fill used to start from the previously
  // selected jar's level (a GlobalKey hopping between jars carried the
  // animation state along) and then settle on its own.
  testWidgets('kantong: tapping a jar never animates its fill from another', (
    tester,
  ) async {
    final db = await pump(tester, const Size(390, 844));
    final makan = find.bySemanticsLabel('makan, 26% kepake');
    final fill = find.descendant(
      of: makan,
      matching: find.byType(AnimatedContainer),
    );
    final before = tester.getSize(fill).height;

    await tester.tap(makan);
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.getSize(fill).height, before);
    expect(before, closeTo(176 * 0.26, 0.5));

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
