import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/finance_providers.dart';
import 'package:mibu/ui/core/money.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/features/settings/views/settings_view.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../meta.dart';

void main() {
  Future<AppDatabase> pump(WidgetTester tester) async {
    // Tests render with Ahem (1em per glyph), so 390 wide overflows rows that
    // fit with Instrument Sans.
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    PackageInfo.setMockInitialValues(
      appName: 'mibu',
      packageName: 'id.mibu',
      version: '0.2.0',
      buildNumber: '1',
      buildSignature: '',
    );

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
          // Same wiring as MibuApp.
          builder: (_, child) => Consumer(
            builder: (_, ref, _) => AmountMask(
              hidden: ref.watch(profileProvider).value?.hideAmounts ?? false,
              child: child!,
            ),
          ),
          home: const SettingsView(),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    return db;
  }

  testWidgets('02.4: budget hero, group rows, version; no deferred rows', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('pengaturan'), findsWidgets); // title + tab
    expect(find.text('budget bulanan'), findsOneWidget);
    expect(find.text('Rp8jt'), findsOneWidget);
    expect(find.text('/ bulan'), findsOneWidget);
    expect(find.text('buat apa aja'), findsOneWidget);
    expect(find.text('limit bulanan'), findsOneWidget);
    expect(find.text('sembunyiin nominal'), findsOneWidget);
    expect(find.text('ekspor ke csv'), findsOneWidget);
    expect(findMeta(['versi 0.2.0', 'lisensi']), findsOneWidget);
    // Fluent Emoji (MIT) is credited on the licenses page behind it.
    final footer = findMeta(['versi 0.2.0', 'lisensi']);
    await tester.ensureVisible(footer);
    await tester.tap(footer);
    await tester.pumpAndSettle();
    expect(find.byType(LicensePage), findsOneWidget);
    Navigator.of(tester.element(find.byType(LicensePage))).pop();
    await tester.pumpAndSettle();

    for (final deferred in [
      'reminder harian',
      'rekap mingguan',
      'kunci pakai face id',
      'mode',
      'backup & pulihin',
    ]) {
      expect(find.text(deferred), findsNothing);
    }
  });

  testWidgets('02.4: sembunyiin nominal flips profile and masks the hero', (
    tester,
  ) async {
    final db = await pump(tester);

    await tester.tap(find.text('sembunyiin nominal'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    final row = await tester.runAsync(() => db.select(db.profiles).getSingle());
    expect(row!.hideAmounts, isTrue);
    expect(find.text('Rp•••'), findsOneWidget);
    expect(find.text('Rp8jt'), findsNothing);
  });

  testWidgets('02.4e–g tanggal gajian: row, sheet, simpan + batalin', (
    tester,
  ) async {
    final db = await pump(tester);
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }

    Future<int> saved() async =>
        (await tester.runAsync(() => db.select(db.profiles).getSingle()))!
            .payday;

    // 25 okt 2026 is a Sunday → paid Fri 23: 14 → 23 okt = 9 days.
    expect(find.text('tiap tgl 25'), findsOneWidget);
    expect(find.text('gajian lagi 9 hari'), findsOneWidget);

    await tester.tap(find.text('tanggal gajian'));
    await settle();
    expect(find.text('gajian tiap tanggal berapa?'), findsOneWidget);
    expect(find.text('umum'), findsOneWidget); // tag on 25
    expect(find.text('oke'), findsOneWidget); // nothing changed yet
    expect(find.text('jum 23 okt'), findsOneWidget);
    expect(find.text('9 hari lagi'), findsOneWidget);

    // 28 okt is a Wednesday, 14 days out; aman jajan shrinks to match.
    await tester.tap(find.text('28'));
    await tester.pump();
    expect(find.text('rab 28 okt'), findsOneWidget);
    expect(find.text('14 hari lagi'), findsOneWidget);
    expect(find.textContaining('/hari', findRichText: true), findsOneWidget);
    expect(find.text('budget & limit tetap per bulan, 1–31.'), findsOneWidget);
    await tester.tap(find.text('simpan tgl 28'));
    await settle();
    expect(await saved(), 28);
    expect(find.text('gajian jadi tgl 28'), findsOneWidget);
    expect(
      find.text('aman jajan dihitung sampai 14 hari lagi'),
      findsOneWidget,
    );
    expect(find.text('tiap tgl 28'), findsOneWidget);

    await tester.tap(find.text('batalin'));
    await settle();
    expect(await saved(), 25);

    // lain… → grid 1–31; akhir; nggak jadi changes nothing.
    await tester.tap(find.text('tanggal gajian'));
    await settle();
    await tester.tap(find.text('lain…'));
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('tanggal 7'));
    await tester.pump();
    expect(find.text('tgl 7'), findsOneWidget); // the chip took the pick
    expect(find.text('simpan tgl 7'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('akhir bulan'));
    await tester.pump();
    // 31 okt is a Saturday → paid Fri 30.
    expect(find.text('jum 30 okt'), findsOneWidget);
    await tester.tap(find.text('nggak jadi'));
    await settle();
    expect(await saved(), 25);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
