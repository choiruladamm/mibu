import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/add_entry/views/add_entry_view.dart';
import 'package:mibu/ui/features/pockets/views/pockets_view.dart';

void main() {
  final now = DateTime(2026, 10, 14, 14, 50);

  Future<AppDatabase> pump(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
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
          home: home,
        ),
      ),
    );
    await settle(tester);
    return db;
  }

  Future<CategoryRow> row(AppDatabase db, String name) =>
      (db.select(db.categories)..where((c) => c.name.equals(name))).getSingle();

  final nameField = find.byType(TextField).first;

  testWidgets('03.4 from kantong: emoji follows the name, limit, saved', (
    tester,
  ) async {
    final db = await pump(tester, const PocketsView());
    await tester.tap(find.text('baru'));
    await settle(tester);
    expect(find.text('kategori baru'), findsOneWidget);

    await tester.enterText(nameField, 'Kopi Susu');
    await tester.pump();
    expect(find.text('buat “kopi susu”'), findsOneWidget);
    expect(find.text('bikin ☕ kopi susu'), findsOneWidget);

    // budget 8jt − other pockets 3,3jt = 4,7jt free; 300K ÷ 31 days.
    expect(find.text('sisa budget Rp4,7jt'), findsOneWidget);
    expect(find.text('≈ Rp9,7K sehari'), findsOneWidget);
    await tester.ensureVisible(find.text('Rp1jt'));
    await tester.tap(find.text('Rp1jt'));
    await tester.pump();
    expect(find.text('1.000.000'), findsOneWidget);

    // Typed past Rp100jt: capped, said so; emptied then left: restored.
    final limitField = find.byType(TextField).last;
    await tester.enterText(limitField, '250000000');
    await tester.pump();
    expect(find.text('maks Rp100jt per kantong'), findsOneWidget);
    expect(find.text('100.000.000'), findsOneWidget);
    await tester.enterText(limitField, '');
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(find.text('1.000.000'), findsOneWidget); // value when focused
    await tester.ensureVisible(find.text('Rp1jt'));
    await tester.tap(find.text('Rp1jt'));
    await tester.pump();

    // A picked emoji sticks when the name changes.
    await tester.tap(find.bySemanticsLabel('pakai 🎧'));
    await tester.enterText(nameField, 'kopi');
    await tester.pump();
    expect(find.text('bikin 🎧 kopi'), findsOneWidget);

    await tester.tap(find.text('bikin 🎧 kopi'));
    await settle(tester);
    final c = await row(db, 'kopi');
    expect((c.emoji, c.monthlyLimit), ('🎧', 1000000));
    // New pocket is the selected jar.
    expect(find.text('belum kepake'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('03.5 via atur kantong: usage, switch to income drops limit', (
    tester,
  ) async {
    final db = await pump(tester, const PocketsView());
    await tester.tap(find.text('atur kantong'));
    await settle(tester);
    expect(find.text('edit kategori'), findsOneWidget);
    expect(find.text('2 catatan · Rp900K tahun ini'), findsOneWidget);
    expect(find.text('1.000.000'), findsOneWidget); // anabul's limit

    await tester.tap(find.text('pemasukan'));
    await tester.pump();
    expect(find.text('kantong bulanan'), findsNothing);
    await tester.tap(find.text('simpan 🐶 anabul'));
    await settle(tester);

    final c = await row(db, 'anabul');
    expect((c.kind.name, c.monthlyLimit), ('income', null));

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('03.2 bikin "gym" comes back picked', (tester) async {
    final db = await pump(tester, const AddEntryView());
    await tester.tap(find.text('pilih kategori'));
    await settle(tester);
    await tester.enterText(find.byType(TextField).first, 'gym');
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('bikin “gym”'));
    await settle(tester);

    expect(find.text('bikin 🏋️ gym'), findsOneWidget);
    await tester.tap(find.text('bikin 🏋️ gym'));
    await settle(tester);
    expect(find.text('pakai 🏋️ gym'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}
