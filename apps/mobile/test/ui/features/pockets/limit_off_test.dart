import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/pockets/views/limit_off_sheet.dart';

void main() {
  Future<void> open(WidgetTester tester, int count) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showLimitOff(
              context,
              emoji: '☕',
              name: 'ngopi',
              limit: 600000,
              spent: 360000,
              count: count,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('sering dicatat card from $busyEntries entries this month', (
    tester,
  ) async {
    await open(tester, busyEntries);
    expect(find.text('kamu udah 10× catat ngopi bulan ini'), findsOneWidget);
    expect(
      find.text('Rp600K balik jadi belum dijatah di budget'),
      findsOneWidget,
    );
    expect(
      find.text('10 catatan (Rp360K) tetap aman, nggak kehapus'),
      findsOneWidget,
    );

    await tester.tap(find.text('nggak jadi'));
    await tester.pumpAndSettle();
    await open(tester, busyEntries - 1);
    expect(find.textContaining('× catat'), findsNothing);
  });
}
