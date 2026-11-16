import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/domain/period.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/core/widgets/month_menu.dart';

void main() {
  testWidgets('menu shows and selects a shortened payday transition', (
    tester,
  ) async {
    final periods = SegmentedResolver([
      calendarBase,
      (
        effectiveFrom: periodsFromStart,
        mode: PeriodMode.payday,
        paydayDay: 15,
        shift: PaydayShift.none,
      ),
      (
        effectiveFrom: DateTime(2026, 11, 15),
        mode: PeriodMode.payday,
        paydayDay: 16,
        shift: PaydayShift.none,
      ),
    ]);
    final picked = <DateTime>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: MonthMenu(
              selected: DateTime(2026, 10),
              now: DateTime(2026, 12),
              spent: const {},
              periods: periods,
              onPick: picked.add,
            ),
          ),
        ),
      ),
    );
    expect(find.text('15 nov – 15 nov'), findsOneWidget);
    await tester.tap(find.text('nov'));
    expect(picked.single, DateTime(2026, 11));
    await tester.tap(find.text('bulan ini'));
    expect(picked.last, DateTime(2026, 12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('00.8 min: earlier months and the year step lock', (
    tester,
  ) async {
    final picked = <DateTime>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: MonthMenu(
              selected: DateTime(2026, 10),
              now: DateTime(2026, 10, 14),
              spent: const {},
              min: DateTime(2025, 3),
              onPick: picked.add,
            ),
          ),
        ),
      ),
    );

    // Already on 2026: step back to 2025, the first year, then stop.
    await tester.tap(find.bySemanticsLabel('tahun sebelumnya'));
    await tester.pump();
    expect(find.text('2025'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('tahun sebelumnya'));
    await tester.pump();
    expect(find.text('2025'), findsOneWidget);

    // Before march 2025: locked, tap does nothing. From march on: pickable.
    expect(
      find.bySemanticsLabel('februari 2025, belum ada catatan, 1 feb – 28 feb'),
      findsOneWidget,
    );
    await tester.tap(find.text('feb'));
    expect(picked, isEmpty);
    await tester.tap(find.text('mar'));
    expect(picked, [DateTime(2025, 3)]);
  });
}
