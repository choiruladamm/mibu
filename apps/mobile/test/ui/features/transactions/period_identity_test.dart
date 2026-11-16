import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mibu/ui/features/search/views/search_view.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/domain/period.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/routing/router.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/finance_providers.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/core/widgets/month_menu.dart';
import 'package:mibu/ui/features/transactions/view_models/transactions_view_model.dart';
import 'package:mibu/ui/features/transactions/views/transactions_view.dart';

import '../../../meta.dart';

class SplitOctober extends PeriodResolver {
  const SplitOctober();
  @override
  Period periodOf(DateTime date) {
    if (date.year == 2026 && date.month == 10) {
      return date.day < 13
          ? Period('2026-10', DateTime(2026, 10, 1), DateTime(2026, 10, 13))
          : Period('2026-10', DateTime(2026, 10, 13), DateTime(2026, 11));
    }
    return const CalendarMonthResolver().periodOf(date);
  }
}

void main() {
  testWidgets('same-label periods remain distinct in menu and carousel', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
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
    const resolver = SplitOctober();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
          periodsProvider.overrideWithValue(resolver),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const TransactionsView(),
        ),
      ),
    );
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }

    await settle();
    expect(find.text('4 catatan'), findsNWidgets(2));
    expect(find.text('13 okt – 31 okt'), findsWidgets);
    await tester.tap(find.text('okt').first);
    await settle();
    expect(find.text('3 catatan'), findsNWidgets(2));
    expect(find.text('1 okt – 12 okt'), findsWidgets);
    await tester.tap(find.text('oktober').first);
    await tester.pumpAndSettle();
    expect(find.byType(MonthMenu), findsOneWidget);
    expect(find.text('1 okt – 12 okt'), findsWidgets);
    expect(find.text('13 okt – 31 okt'), findsOneWidget);
    await tester.tap(find.text('bulan ini'));
    await settle();
    expect(find.text('4 catatan'), findsNWidgets(2));
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('search keeps the exact period in its results and route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1400);
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
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => SearchView(periodStart: DateTime(2026, 10, 13)),
        ),
      ],
      errorBuilder: (_, state) => Scaffold(body: Text('→ ${state.uri}')),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => now),
          periodsProvider.overrideWithValue(const SplitOctober()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }

    await settle();
    await tester.enterText(find.byType(TextField), 'o');
    await settle();
    expect(findMeta(['di oktober', '13 okt – 31 okt']), findsOneWidget);
    expect(
      Routes.transactionsFound(DateTime(2026, 10, 13), 'o', exact: true),
      contains('at=2026-10-13'),
    );
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await db.close();
  });

  test('period navigation crosses year and keeps duplicate labels', () {
    const resolver = SplitOctober();
    final periods = txPeriods(
      DateTime(2026, 10, 1),
      resolver.periodOf(DateTime(2027, 1, 5)),
      resolver,
    );
    expect(periods.take(2).map((p) => p.key), [
      DateTime(2026, 10),
      DateTime(2026, 10),
    ]);
    expect(periods.map((p) => p.start), contains(DateTime(2027, 1)));
  });
}
