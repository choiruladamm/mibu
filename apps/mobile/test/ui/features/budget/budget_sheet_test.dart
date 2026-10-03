import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/budget/views/budget_sheet.dart';

void main() {
  // Ahem is 1em per glyph, hence the wide view. 00.16 fits its 640 board with the hapus link and the last-period hint:
  // no overflow, nothing scrolls under the keypad.
  testWidgets('00.16: edit sheet with hint fits without scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(
          body: BudgetSheet(
            budget: 8000000,
            pocketsTotal: 7400000,
            lastSpent: 6200000,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsNothing);
  });
}
