import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/core/widgets/month_menu.dart';

void main() {
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
      find.bySemanticsLabel('februari 2025, belum ada catatan'),
      findsOneWidget,
    );
    await tester.tap(find.text('feb'));
    expect(picked, isEmpty);
    await tester.tap(find.text('mar'));
    expect(picked, [DateTime(2025, 3)]);
  });
}
