import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/period.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/data/repositories/finance_repository.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/setup/views/setup_view.dart';

import '../../../meta.dart';

Period cal(DateTime d) => const CalendarMonthResolver().periodOf(d);

void main() {
  final now = DateTime(2026, 10, 14, 14, 50);

  Future<(AppDatabase, List<int>)> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
      () => now,
      (_, _) async {}, // real first run: nothing seeded
    );
    final done = <int>[];
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
          home: SetupView(onDone: () => done.add(1)),
        ),
      ),
    );
    return (db, done);
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('01.4 → 01.4b: daily preview, kantong summary, beres saves', (
    tester,
  ) async {
    final (db, done) = await pump(tester);
    final repo = FinanceRepository(db);

    // Budget is optional: nothing to preview until one is typed.
    expect(find.text('aman jajan per hari'), findsNothing);
    await tester.tap(find.text('Rp3jt'));
    await tester.pump();
    expect(find.text('3.000.000'), findsOneWidget);
    // 25 okt is a Sunday → paid Fri 23: 9 days incl. today → 3.000.000 ÷ 9
    expect(find.text('Rp333K'), findsOneWidget);
    expect(findMeta(['sampai gajian', '9 hari lagi']), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('akhir bulan'));
    await tester.pump();
    expect(
      findMeta(['sampai gajian', '16 hari lagi']),
      findsOneWidget,
    ); // sat 31 → fri 30

    await tester.enterText(find.byType(TextField), '3000000');
    await tester.pump();
    expect(find.text('3.000.000'), findsOneWidget);
    expect(find.text('Rp188K'), findsOneWidget); // 3.000.000 ÷ 16

    await tester.ensureVisible(find.text('lanjut'));
    await tester.tap(find.text('lanjut'));
    await settle(tester);
    expect(find.text('mau mulai pasang limit ke apa?'), findsOneWidget);
    // Default 4: 1,5jt + 300K + 500K + 600K = 2,9jt.
    expect(find.text('4 dikasih limit'), findsOneWidget);
    expect(find.text('Rp2,9jt/bln'), findsOneWidget);
    expect(find.text('belum dijatah Rp100K dari budget Rp3jt'), findsOneWidget);

    await tester.tap(find.text('hiburan'));
    await tester.pump();
    expect(find.text('5 dikasih limit'), findsOneWidget);
    expect(
      find.text('lebih Rp300K dari budget'),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('beres, ke beranda'));
    await tester.tap(find.text('beres, ke beranda'));
    await settle(tester);
    expect(done, [1]);
    final p = (await tester.runAsync(() => repo.watchProfile(cal(now)).first))!;
    expect(
      (p.onboarded, p.monthlyBudget, p.payday),
      (true, 3000000, 31),
    ); // akhir = 31
    final pockets = (await tester.runAsync(
      () => repo.watchPockets(cal(now)).first,
    ))!;
    expect(pockets.map((p) => p.name), [
      'makan',
      'ngopi',
      'ojol',
      'tagihan',
      'hiburan',
    ]);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('nanti aja on 01.4: onboarded, no kantong', (tester) async {
    final (db, done) = await pump(tester);
    final repo = FinanceRepository(db);
    await tester.tap(find.text('nanti aja'));
    await settle(tester);
    expect(done, [1]);
    final p = (await tester.runAsync(() => repo.watchProfile(cal(now)).first))!;
    // Nothing is required: no budget, no kantong.
    expect((p.onboarded, p.monthlyBudget, p.payday), (true, null, 25));
    expect(
      await tester.runAsync(() => repo.watchPockets(cal(now)).first),
      isEmpty,
    );
    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
