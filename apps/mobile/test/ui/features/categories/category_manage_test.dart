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

void main() {
  testWidgets('03.3 from the picker: usage and the income note', (
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
          home: const AddEntryView(),
        ),
      ),
    );
    // Tiles wiggle forever, so no pumpAndSettle.
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    await settle();
    await tester.tap(find.text('pilih kategori'));
    await settle();
    await tester.tap(find.text('atur'));
    await settle();

    expect(find.text('kategori kamu'), findsOneWidget);
    expect(find.text('4 catatan'), findsOneWidget); // belanja
    expect(find.text('3 catatan'), findsOneWidget); // gajian
    expect(
      find.text(
        'gajian itu buat pemasukan, jadi cuma muncul pas kamu catat pemasukan.',
      ),
      findsOneWidget,
    );

    // ponytail: tahan & geser is checked by hand on device; after a
    // simulated drag the next frame never returns under flutter_test.
    // Cover reorderCategories in the repo test; revisit the widget drag.

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
