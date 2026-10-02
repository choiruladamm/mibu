import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/database/seed.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/core/widgets/app_emoji.dart';
import 'package:mibu/ui/core/widgets/icon_sheet.dart';

import '../../meta.dart';

void main() {
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  /// Opens the sheet on [selected]; returns what it resolved to.
  Future<String? Function()> open(WidgetTester tester, String selected) async {
    tester.view.physicalSize = const Size(900, 1600);
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
    String? picked;
    var done = false;
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
                onPressed: () async {
                  picked = await showIconSheet(context, selected: selected);
                  done = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await settle(tester);
    return () => done ? picked : 'still open';
  }

  Finder cell(String label) => find.bySemanticsLabel(label);

  testWidgets('00.21: browse by group, pick, pakai returns the emoji', (
    tester,
  ) async {
    final result = await open(tester, '☕');
    expect(find.text('pilih ikon'), findsOneWidget);
    expect(find.text('terakhir dipakai'), findsOneWidget);
    expect(findEmojiText('pakai ☕ kopi'), findsOneWidget);

    await tester.tap(find.text('makan'));
    await settle(tester);
    expect(cell('boba'), findsWidgets);
    expect(cell('taksi'), findsNothing); // jalan, filtered out

    await tester.tap(cell('boba').first);
    await settle(tester);
    expect(findEmojiText('pakai 🧋 boba'), findsOneWidget);
    await tester.tap(findEmojiText('pakai 🧋 boba'));
    await settle(tester);
    expect(result(), '🧋');
  });

  testWidgets('00.21: search, nothing found, try a suggested word', (
    tester,
  ) async {
    final result = await open(tester, '☕');
    await tester.enterText(find.byType(TextField), 'motor');
    await settle(tester);
    expect(find.textContaining(RegExp(r'^\d+ ikon$')), findsOneWidget);
    expect(find.text('terakhir dipakai'), findsNothing);

    await tester.enterText(find.byType(TextField), 'mobil listrik');
    await settle(tester);
    expect(find.text('belum ada ikon “mobil listrik”'), findsOneWidget);
    await tester.tap(find.text('mobil'));
    await settle(tester);
    expect(cell('mobil'), findsWidgets);

    await tester.tap(find.bySemanticsLabel('tutup'));
    await settle(tester);
    expect(result(), isNull);
  });

  testWidgets('00.21: an emoji outside the catalog opens on the fallback', (
    tester,
  ) async {
    await open(tester, '🦖');
    expect(findEmojiText('pakai 🫙 toples'), findsOneWidget);
    expect(find.byType(AppEmoji), findsWidgets);
  });
}
