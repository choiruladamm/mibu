import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/home/view_models/home_view_model.dart';
import 'package:mibu/ui/features/home/views/home_view.dart';

void main() {
  testWidgets('beranda renders seeded data; tapping a future month shows ±', (
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
          nowProvider.overrideWithValue(now),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const HomeView(),
        ),
      ),
    );
    // Drift runs queries off the fake clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.text('4.530.000'), findsOneWidget);
    expect(find.text('oktober'), findsOneWidget);
    expect(find.text('hari ini · okt'), findsOneWidget);
    expect(find.text('🐶 90%'), findsOneWidget);
    expect(find.text('-Rp27K'), findsOneWidget); // gojek today, newest
    expect(find.text('-Rp450K'), findsOneWidget);
    // (4.530.000 + 27.000) ÷ 11 days to payday − 27.000
    expect(find.textContaining('Rp387K', findRichText: true), findsOneWidget);

    await tester.tap(find.text('nov'));
    await tester.pumpAndSettle();

    expect(find.text('prediksi · nov'), findsOneWidget);
    expect(find.text('± Rp6,39jt'), findsOneWidget);
    expect(find.text('november'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
