import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/transactions/view_models/transactions_view_model.dart';
import 'package:mibu/ui/features/transactions/views/transactions_view.dart';

void main() {
  // The router wraps 04.1 in its own ProviderScope to pass the deep link's
  // month; the month must still be switchable inside it.
  testWidgets('04.1 switches month inside the router scope', (tester) async {
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
          home: ProviderScope(
            overrides: [
              txMonthProvider.overrideWith(() => TxMonth(DateTime(2026, 9))),
            ],
            child: const TransactionsView(),
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

    await settle();
    expect(find.text('september'), findsOneWidget); // the deep link
    await tester.tap(find.text('agu'));
    await settle();
    expect(find.text('agustus'), findsOneWidget);
    await tester.tap(find.text('sep'));
    await settle();
    expect(find.text('september'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
