import 'package:drift/drift.dart' hide isNull, isNotNull;
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
  testWidgets('03.6 from 03.5: move to makan, hold, batalin, then beres', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
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
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    Future<CategoryRow> anabul() => (db.select(
      db.categories,
    )..where((c) => c.name.equals('anabul'))).getSingle();
    Future<int> makanEntries() async {
      final makan = await (db.select(
        db.categories,
      )..where((c) => c.name.equals('makan'))).getSingle();
      return (await (db.select(
        db.transactions,
      )..where((t) => t.categoryId.equals(makan.id))).get()).length;
    }

    final hold = find.bySemanticsLabel('tahan buat hapus anabul');
    Future<void> holdFor(Duration d) async {
      final g = await tester.startGesture(tester.getCenter(hold));
      await tester.pump(); // ticker starts on this frame
      await tester.pump(d);
      await g.up();
    }

    await settle();
    await tester.ensureVisible(find.text('atur limit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('atur limit')); // anabul is selected
    await settle();
    await tester.tap(find.bySemanticsLabel('hapus kategori'));
    await settle();

    expect(find.text('hapus anabul?'), findsOneWidget);
    expect(find.text('2 catatan · Rp900K pakai kategori ini'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('makan').last);
    await tester.pump();

    // Letting go early resets.
    await holdFor(const Duration(milliseconds: 500));
    await settle();
    expect(find.text('hapus anabul?'), findsOneWidget);
    expect((await tester.runAsync(anabul))!.deletedAt, isNull);

    await holdFor(const Duration(milliseconds: 1100));
    await settle();
    expect(find.text('anabul udah dihapus'), findsOneWidget);
    expect(find.text('2 catatan sekarang pindah ke 🍜 makan.'), findsOneWidget);
    expect((await tester.runAsync(anabul))!.deletedAt, isNotNull);
    expect(await tester.runAsync(makanEntries), 1 + 2);

    // batalin: both come back, the form stays open.
    await tester.tap(find.text('batalin'));
    await settle();
    expect((await tester.runAsync(anabul))!.deletedAt, isNull);
    expect(await tester.runAsync(makanEntries), 1);
    expect(find.text('edit'), findsOneWidget);

    // Again, then beres closes the form too.
    await tester.tap(find.bySemanticsLabel('hapus kategori'));
    await settle();
    await holdFor(const Duration(milliseconds: 1100));
    await settle();
    await tester.tap(find.text('beres'));
    await settle();
    expect(find.text('edit'), findsNothing);
    expect(find.text('anabul'), findsNothing);
    expect(find.text('ngopi'), findsOneWidget); // next pocket selected

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
