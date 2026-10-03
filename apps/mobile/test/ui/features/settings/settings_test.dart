import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/database/app_database.dart';
import 'package:mibu/domain/models/finance.dart';
import 'package:mibu/domain/period.dart';
import 'package:mibu/l10n/app_localizations.dart';
import 'package:mibu/ui/core/clock.dart';
import 'package:mibu/ui/core/finance_providers.dart';
import 'package:mibu/ui/core/money.dart';
import 'package:mibu/ui/core/theme.dart';
import 'package:mibu/ui/core/widgets/app_emoji.dart';
import 'package:mibu/ui/features/settings/views/settings_view.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:mibu/ui/core/widgets/meta_line.dart';

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
              hide:
                  ref.watch(profileProvider).value?.hideAmounts ??
                  HideAmounts.none,
              peek: ref.watch(peekProvider),
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
    expect(find.text('budget per periode'), findsOneWidget);
    // buat apa aja: hint + the 3 most used icons stacked, then the rest.
    expect(find.text('nama, ikon & limit'), findsOneWidget);
    expect(find.text('+3'), findsOneWidget); // fixture: 6 buat apa
    final row = find.ancestor(
      of: find.text('nama, ikon & limit'),
      matching: find.byType(InkWell),
    );
    expect(
      find.descendant(of: row, matching: find.byType(AppEmoji)),
      findsNWidgets(3),
    );
    expect(find.text('Rp8jt'), findsOneWidget);
    expect(find.text('/ periode'), findsOneWidget);
    // Chips: the running period (fixture: calendar months) and the kantong.
    expect(find.text('periode 1 okt – 31 okt'), findsOneWidget);
    expect(find.text('4 kantong'), findsOneWidget);
    expect(find.text('buat apa aja'), findsOneWidget);
    expect(find.text('limit kantong'), findsOneWidget);
    expect(find.text('sembunyiin nominal'), findsOneWidget);
    expect(find.text('export ke csv'), findsOneWidget);
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

  testWidgets('02.4h–i: sembunyiin nominal sheet, 3 modes, simpan + batalin', (
    tester,
  ) async {
    final db = await pump(tester);
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }

    Future<HideAmounts> saved() async =>
        (await tester.runAsync(() => db.select(db.profiles).getSingle()))!
            .hideAmounts;

    expect(find.text('nggak'), findsOneWidget); // row hint = the mode
    await tester.tap(find.text('sembunyiin nominal'));
    await settle();
    expect(find.text('buat yang suka buka app di tempat rame'), findsOneWidget);
    expect(find.text('oke'), findsOneWidget); // nothing changed yet
    expect(find.text('+Rp20jt'), findsOneWidget);

    // Live example: pemasukan aja hides the salary, not the spending.
    await tester.tap(find.text('pemasukan aja'));
    await tester.pumpAndSettle();
    expect(find.text('+Rp•••'), findsOneWidget);
    expect(find.text('-Rp25K'), findsOneWidget);
    await tester.tap(find.text('simpan'));
    await settle();
    expect(await saved(), HideAmounts.income);
    expect(find.text('pemasukan disembunyiin'), findsOneWidget);
    expect(find.text('Rp8jt'), findsOneWidget); // budget isn't pemasukan

    await tester.tap(find.text('batalin'));
    await settle();
    expect(await saved(), HideAmounts.none);

    await tester.tap(find.text('sembunyiin nominal'));
    await settle();
    await tester.tap(find.text('semua nominal'));
    await tester.pumpAndSettle();
    expect(find.text('-Rp•••'), findsNWidgets(2));
    await tester.tap(find.text('simpan'));
    await settle();
    expect(await saved(), HideAmounts.all);
    expect(find.text('Rp8jt'), findsNothing);
    expect(find.text('Rp•••'), findsOneWidget);
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

    // 25 okt 2026 is a Sunday → paid Fri 23: 14 → 23 okt = 9 days. The row
    // names the date, so "tiap tgl 25" doesn't look miscounted.
    expect(find.text('tiap tgl 25'), findsOneWidget);
    expect(findMeta(['jum 23 okt', '9 hari lagi']), findsOneWidget);

    // The period chip on the budget card opens the same sheet.
    await tester.tap(find.text('periode 1 okt – 31 okt'));
    await settle();
    expect(find.text('gajian tiap tanggal berapa?'), findsOneWidget);
    await tester.tap(find.text('nggak jadi'));
    await settle();

    await tester.tap(find.text('tanggal gajian'));
    await settle();
    expect(find.text('gajian tiap tanggal berapa?'), findsOneWidget);
    expect(find.text('umum'), findsOneWidget); // tag on 25
    // Chips flow in a row, not one per line.
    final row1 = tester.getTopLeft(find.text('1')).dy;
    for (final d in ['10', '15', '25', '28']) {
      expect(tester.getTopLeft(find.text(d)).dy, row1, reason: 'chip $d');
    }
    expect(find.text('oke'), findsOneWidget); // nothing changed yet
    expect(find.text('jum 23 okt'), findsOneWidget);
    expect(find.text('9 hari lagi'), findsOneWidget);
    // Sunday payday, paid the Friday before: the card says so.
    expect(
      find.text('tgl 25 jatuh hari minggu → dihitung jumat'),
      findsOneWidget,
    );

    // 28 okt is a Wednesday, 14 days out, no shift.
    await tester.tap(find.text('28'));
    await tester.pump();
    expect(find.text('rab 28 okt'), findsOneWidget);
    expect(find.text('14 hari lagi'), findsOneWidget);
    expect(find.textContaining('jatuh hari'), findsNothing);
    expect(
      find.text(
        'budget & limit ngikut gajian. ganti tanggal atau weekend berlaku mulai periode berikutnya.',
      ),
      findsOneWidget,
    );
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

    // lainnya → grid 1–31; akhir; nggak jadi changes nothing.
    await tester.tap(find.text('tanggal gajian'));
    await settle();
    await tester.tap(find.text('lainnya'));
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

  testWidgets('tanggal gajian: after the first period it starts next period', (
    tester,
  ) async {
    final db = await pump(tester);
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }

    // A lived-in setup: gajian 25 since January (not in its first period).
    await tester.runAsync(
      () => db
          .into(db.periodRules)
          .insert(
            PeriodRulesCompanion.insert(
              effectiveFrom: DateTime(2026, 1, 1),
              mode: PeriodMode.payday,
              paydayDay: 25,
              shift: const Value(PaydayShift.previousWorkday),
            ),
          ),
    );
    await settle();
    Future<List<PeriodRuleRow>> rules() async =>
        (await tester.runAsync(() => db.select(db.periodRules).get()))!;

    await tester.tap(find.text('tanggal gajian'));
    await settle();
    await tester.tap(find.text('10'));
    await tester.pump();
    // 14 okt: the running period ("oktober", 25 sep – 22 okt) ends 23 okt.
    // The 10th's cycle there (9 okt – 9 nov) is "oktober" too, so it joins
    // the running period; the preview says so before saving.
    expect(find.text('periode ini jadi 25 sep – 9 nov'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is MetaLine && w.spans.first.toPlainText() == '46 hari',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('simpan tgl 10'));
    await settle();

    // The 10th starts from 23 okt; what's lived stays.
    final rows = await rules();
    expect(rows, hasLength(2));
    final queued = rows.firstWhere(
      (r) => r.effectiveFrom == DateTime(2026, 10, 23),
    );
    expect((queued.mode, queued.paydayDay), (PeriodMode.payday, 10));
    expect(find.text('gajian jadi tgl 10'), findsOneWidget);
    expect(find.text('periode ini jadi sampai sen 9 nov'), findsOneWidget);
    // Today still counts to the old payday.
    expect(findMeta(['jum 23 okt', '9 hari lagi']), findsOneWidget);

    // Changing again before then updates the queued rule, not a third one.
    await tester.tap(find.text('tanggal gajian'));
    await settle();
    await tester.tap(find.text('15'));
    await tester.pump();
    await tester.tap(find.text('simpan tgl 15'));
    await settle();
    final again = await rules();
    expect(again, hasLength(2));
    expect(
      again
          .firstWhere((r) => r.effectiveFrom == DateTime(2026, 10, 23))
          .paydayDay,
      15,
    );

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });

  testWidgets('tanggal gajian: weekend tetap tanggalnya (02.4j–k)', (
    tester,
  ) async {
    final db = await pump(tester);
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
    }

    // Lived-in: gajian 25, jumat. 25 okt 2026 is a Sunday → jum 23 okt.
    await tester.runAsync(
      () => db
          .into(db.periodRules)
          .insert(
            PeriodRulesCompanion.insert(
              effectiveFrom: DateTime(2026, 1, 1),
              mode: PeriodMode.payday,
              paydayDay: 25,
              shift: const Value(PaydayShift.previousWorkday),
            ),
          ),
    );
    await settle();

    await tester.tap(find.text('tanggal gajian'));
    await settle();
    expect(find.text('jum 23 okt'), findsOneWidget);
    expect(find.text('oke'), findsOneWidget);

    await tester.tap(find.text('tetap tanggalnya'));
    await tester.pump();
    // The card shows Sunday, the shift note is gone, saving says "simpan".
    expect(find.text('min 25 okt'), findsOneWidget);
    expect(find.textContaining('dihitung jumat'), findsNothing);
    expect(find.text('periode ini jadi 25 sep – 24 okt'), findsOneWidget);
    expect(find.text('simpan'), findsOneWidget);
    await tester.tap(find.text('simpan'));
    await settle();

    final rows = (await tester.runAsync(
      () => db.select(db.periodRules).get(),
    ))!;
    final queued = rows.firstWhere(
      (r) => r.effectiveFrom == DateTime(2026, 10, 23),
    );
    expect((queued.paydayDay, queued.shift), (25, PaydayShift.none));
    expect(find.text('gajian tetap di tgl 25'), findsOneWidget);
    expect(find.text('periode ini jadi sampai sab 24 okt'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await db.close();
  });
}
