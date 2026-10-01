import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/onboarding/views/onboarding_view.dart';

// Test font (Ahem) wraps wider than Instrument Sans, so scroll before tapping.
Future<void> _tap(WidgetTester tester, String text) async {
  await tester.ensureVisible(find.text(text));
  await tester.pump(); // relayout after the jump, else tap() hits the old offset
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding: lanjut → step 3 → mulai sekarang calls onDone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    var done = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingView(onDone: () => done++),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('01 / 03'), findsOneWidget);
    expect(find.text('duit kamu, ada kantongnya.'), findsOneWidget);
    expect(find.text('Rp1,5jt'), findsOneWidget);

    await _tap(tester, 'lanjut');
    expect(find.text('02 / 03'), findsOneWidget);
    await _tap(tester, 'lanjut');

    expect(find.text('03 / 03'), findsOneWidget);
    expect(find.text('lewati'), findsNothing);

    await _tap(tester, 'mulai sekarang');
    expect(done, 1);
  });

  testWidgets('onboarding: no overflow on short screen (375×667)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OnboardingView(onDone: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
