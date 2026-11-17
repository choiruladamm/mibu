import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/routing/router.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/core/widgets/app_emoji.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('record an expense from home and confirm it is saved', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 14, 14, 50);
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
      () => now,
      seedFixture,
    );
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await db.close();
    });

    final router = container.read(routerProvider)..go(Routes.home);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: AppTheme.light,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    Future<void> settle() async {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }

    await settle();
    await tester.tap(find.bySemanticsLabel('catat'));
    await settle();

    for (final key in ['5', '000']) {
      await tester.tap(
        find.bySemanticsLabel(key == '000' ? 'tambah tiga nol' : key),
      );
      await tester.pump();
    }
    await tester.tap(find.text('buat apa?'));
    await settle();
    await tester.tap(find.bySemanticsLabel('makan'));
    await settle();
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is EmojiText && widget.text == 'pakai 🍜 makan',
      ),
    );
    await settle();
    await tester.tap(find.bySemanticsLabel('simpan pengeluaran'));
    await settle();

    final rows = await db.select(db.transactions).get();
    expect(rows.where((row) => row.amount == -5000), hasLength(1));
    final expense = rows.singleWhere((row) => row.amount == -5000);
    expect(expense.at, now);
    final category = await (db.select(
      db.categories,
    )..where((row) => row.id.equals(expense.categoryId!))).getSingle();
    expect(category.name, 'makan');
  });
}
