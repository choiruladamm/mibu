import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/transactions/views/edit_entry_view.dart';

import '../../../meta.dart';

void main() {
  testWidgets('04.4: diubah badges, batalin, simpan, hapus', (tester) async {
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
    // Seed petshop entry (place changes to "vet" midway).
    Future<TransactionRow> petshop() => (db.select(
      db.transactions,
    )..where((t) => t.at.equals(DateTime(2026, 10, 13, 14, 32)))).getSingle();
    final id = (await tester.runAsync(petshop))!.id;

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
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditEntryView(id: id),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
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

    await tester.tap(find.text('open'));
    await settle();
    expect(findMeta(['petshop', 'sel 13 okt']), findsOneWidget);
    expect(find.text('450.000'), findsOneWidget);
    expect(find.text('belum ada perubahan'), findsOneWidget);
    expect(find.text('diubah'), findsNothing);

    await tester.enterText(find.bySemanticsLabel('nominal').last, '500000');
    await tester.tap(find.text('ngopi'));
    await settle();
    expect(find.text('500.000'), findsOneWidget); // dots as you type
    expect(find.text('diubah'), findsNWidgets(2));
    await tester.tap(find.text('2 perubahan · batalin'));
    await settle();
    expect(find.text('450.000'), findsOneWidget);
    expect(find.text('belum ada perubahan'), findsOneWidget);

    await tester.enterText(find.bySemanticsLabel('nominal').last, '500000');
    await tester.enterText(find.bySemanticsLabel('di mana').last, 'vet');
    await settle();
    await tester.tap(find.text('simpan'));
    await settle();
    expect(find.text('open'), findsOneWidget); // popped
    final row = (await tester.runAsync(petshop))!;
    expect((row.amount, row.place), (-500000, 'vet'));

    await tester.tap(find.text('open'));
    await settle();
    await tester.tap(find.text('hapus catatan ini'));
    await settle();
    await tester.tap(find.text('hapus'));
    await settle();
    expect(find.text('open'), findsOneWidget);
    expect(find.text('catatan dihapus'), findsOneWidget);
    expect((await tester.runAsync(petshop))!.deletedAt, isNotNull);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
