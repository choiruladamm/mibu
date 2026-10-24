import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/models/app_lock.dart';
import 'package:mibu/ui/core/app_lock_providers.dart';
import 'package:mibu/ui/core/widgets/app_switch.dart';
import 'package:mibu/ui/features/lock/views/lock_settings_view.dart';

import '../../../lock.dart';

void main() {
  late LockHarness h;

  /// The kunci app screen. [on]: the lock is already set up (with face id when
  /// [useBio]); [bio]: what the phone has.
  Future<void> open(
    WidgetTester tester, {
    bool on = false,
    BioKind bio = BioKind.face,
    bool useBio = true,
    bool bioPasses = true,
  }) async {
    // Ahem is wider than Instrument Sans, so 390 wide overflows.
    tester.view
      ..physicalSize = const Size(900, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = LockHarness(bio: bio)..bio.passes = bioPasses;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      h.dispose();
    });
    if (on) await h.repo.enable(lockPin, bio: useBio);
    await h.load();
    await tester.pumpWidget(h.app(const LockSettingsView()));
    await tester.pumpAndSettle();
  }

  Finder switchAt(int i) => find.byType(AppSwitch).at(i);

  Future<void> tapSwitch(WidgetTester tester, int i) async {
    await tester.tap(switchAt(i));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String pin) async {
    await typePin(tester, pin);
    await tester.pumpAndSettle();
  }

  group('kunci mati (99.10e)', () {
    testWidgets('says why, and nothing else to set', (tester) async {
      await open(tester);
      expect(find.text('kunci mibu'), findsOne);
      expect(
        find.text(
          'biar orang lain yang pegang hp kamu nggak bisa buka catatan & nominal di mibu.',
        ),
        findsOne,
      );
      expect(find.text('cara buka'), findsNothing);
      expect(find.text('blur pas pindah app'), findsNothing);
      expect(find.text('pin nggak bisa direset'), findsOne);
      expect(find.text('export ke csv sekarang'), findsOne);
    });
  });

  group('nyalain (99.10f–i)', () {
    testWidgets('bikin pin, ketik lagi, face id, toast', (tester) async {
      await open(tester);
      await tapSwitch(tester, 0);
      expect(find.text('bikin pin'), findsOne);
      expect(find.text('1 dari 3'), findsOne);
      expect(find.text('pin nggak bisa direset, simpen baik-baik'), findsOne);

      await type(tester, '483917');
      expect(find.text('ketik sekali lagi'), findsOne);
      expect(find.text('2 dari 3'), findsOne);

      await type(tester, '483917');
      expect(find.text('pakai face id juga?'), findsOne);
      expect(find.text('3 dari 3'), findsOne);
      expect(h.lock.enabled, isFalse); // nothing saved before the end

      await tester.tap(find.text('pakai face id'));
      await tester.pumpAndSettle();
      expect(h.lock.enabled, isTrue);
      expect(h.lock.bio, isTrue);
      expect(h.bio.prompts, 1);
      expect(find.text('kunci nyala'), findsOne);
      expect(find.text('buka pakai face id atau pin'), findsOne);
      expect((await h.repo.verifyPin(lockPin, h.now)).outcome, PinOutcome.ok);
    });

    testWidgets('nanti aja: pin only, face id can come later', (tester) async {
      await open(tester);
      await tapSwitch(tester, 0);
      await type(tester, '483917');
      await type(tester, '483917');
      await tester.tap(find.text('nanti aja, pin aja'));
      await tester.pumpAndSettle();
      expect(h.lock.enabled, isTrue);
      expect(h.lock.bio, isFalse);
      expect(h.bio.prompts, 0);
      expect(
        find.text('buka pakai pin, face id bisa dinyalain nanti'),
        findsOne,
      );
    });

    testWidgets('face id refused by the system: on with the pin only', (
      tester,
    ) async {
      await open(tester, bioPasses: false);
      await tapSwitch(tester, 0);
      await type(tester, '483917');
      await type(tester, '483917');
      await tester.tap(find.text('pakai face id'));
      await tester.pumpAndSettle();
      expect(h.lock.enabled, isTrue);
      expect(h.lock.bio, isFalse);
    });

    testWidgets('a phone without face id: 2 steps, no question', (
      tester,
    ) async {
      await open(tester, bio: BioKind.none);
      await tapSwitch(tester, 0);
      expect(find.text('1 dari 2'), findsOne);
      await type(tester, '483917');
      expect(find.text('2 dari 2'), findsOne);
      await type(tester, '483917');
      expect(find.text('pakai face id juga?'), findsNothing);
      expect(h.lock.enabled, isTrue);
      expect(h.lock.bio, isFalse);
      expect(find.text('buka mibu pakai pin'), findsOne);
    });

    testWidgets('a different second pin starts over', (tester) async {
      await open(tester);
      await tapSwitch(tester, 0);
      await type(tester, '483917');
      await type(tester, '918273');
      expect(find.text('bikin pin'), findsOne);
      expect(find.text('pin nggak sama, ulang dari awal ya'), findsOne);
      expect(find.text('1 dari 3'), findsOne);
      expect(h.lock.enabled, isFalse);
    });

    testWidgets('a weak pin is turned down, same step', (tester) async {
      await open(tester);
      await tapSwitch(tester, 0);
      await type(tester, '123456');
      expect(find.text('bikin pin'), findsOne);
      expect(find.text('pin ini gampang ketebak, coba yang lain'), findsOne);
      await type(tester, '111111');
      expect(find.text('pin ini gampang ketebak, coba yang lain'), findsOne);
      await type(tester, '483917');
      expect(find.text('ketik sekali lagi'), findsOne);
    });

    testWidgets('closing the sheet half way saves nothing', (tester) async {
      await open(tester);
      await tapSwitch(tester, 0);
      await type(tester, '483917');
      await tester.tap(
        find.bySemanticsLabel('tutup').first,
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(find.text('ketik sekali lagi'), findsNothing); // sheet is gone
      expect(h.lock.enabled, isFalse);
    });
  });

  group('kunci nyala (99.10b–d)', () {
    testWidgets('how it opens, when it asks again, blur', (tester) async {
      await open(tester, on: true);
      expect(find.text('minta face id atau pin tiap buka'), findsOne);
      expect(find.text('cara buka'), findsOne);
      expect(find.text('pakai face id'), findsOne);
      expect(find.text('pin tetap bisa dipakai'), findsOne);
      expect(find.text('kunci lagi setelah ditinggal'), findsOne);
      expect(find.text('blur pas pindah app'), findsOne);
      expect(find.text('isi mibu nggak keliatan di daftar app'), findsNothing);
    });

    testWidgets('kunci lagi setelah: pick one, saved', (tester) async {
      await open(tester, on: true);
      expect(h.lock.after, const Duration(minutes: 1));
      await tester.tap(find.text('5 menit'));
      await tester.pumpAndSettle();
      expect(h.lock.after, const Duration(minutes: 5));
      await tester.tap(find.text('langsung'));
      await tester.pumpAndSettle();
      expect(h.lock.after, Duration.zero);
    });

    testWidgets('blur switch', (tester) async {
      await open(tester, on: true);
      expect(h.lock.blur, isTrue);
      await tapSwitch(tester, 2);
      expect(h.lock.blur, isFalse);
    });

    testWidgets('face id switch off, and on (asks the system once)', (
      tester,
    ) async {
      await open(tester, on: true);
      await tapSwitch(tester, 1);
      expect(h.lock.bio, isFalse);
      expect(find.text('minta pin tiap buka'), findsOne);

      await tapSwitch(tester, 1);
      expect(h.bio.prompts, 1);
      expect(h.lock.bio, isTrue);
    });

    testWidgets('face id switch on stays off when the system says no', (
      tester,
    ) async {
      await open(tester, on: true, useBio: false, bioPasses: false);
      await tapSwitch(tester, 1);
      expect(h.lock.bio, isFalse);
    });

    testWidgets('a phone without face id says how to get it', (tester) async {
      await open(tester, on: true, bio: BioKind.none, useBio: false);
      expect(find.byType(AppSwitch), findsNWidgets(2)); // kunci + blur
      expect(
        find.textContaining('hp ini belum ada face id / sidik jari'),
        findsOne,
      );
      expect(find.text('minta pin tiap buka'), findsOne);
    });

    testWidgets('sidik jari has its own words', (tester) async {
      await open(tester, on: true, bio: BioKind.finger);
      expect(find.text('pakai sidik jari'), findsOne);
      expect(find.text('minta sidik jari atau pin tiap buka'), findsOne);
    });

    testWidgets('the card names face id only while it is on', (tester) async {
      await open(tester, on: true);
      expect(
        find.textContaining('kalau lupa pin dan face id lagi nggak bisa'),
        findsOne,
      );
      await tapSwitch(tester, 1);
      expect(
        find.textContaining('kalau lupa pin, mibu harus diinstal ulang'),
        findsOne,
      );
    });
  });

  group('matiin (99.10e)', () {
    testWidgets('pin first, then off, toast', (tester) async {
      await open(tester, on: true);
      await tapSwitch(tester, 0);
      expect(find.text('matiin kunci?'), findsOne);
      expect(find.text('masukin pin dulu'), findsOne);

      await type(tester, '000001');
      expect(
        find.text('pin salah · 4× lagi sebelum ditahan sebentar'),
        findsOne,
      );
      expect(h.lock.enabled, isTrue);

      await type(tester, lockPin);
      expect(h.lock.enabled, isFalse);
      expect(find.text('kunci mati'), findsOne);
      expect(find.text('mibu kebuka tanpa pin'), findsOne);
      expect(find.text('cara buka'), findsNothing);
    });

    testWidgets('5 wrong holds the sheet, the close button still works', (
      tester,
    ) async {
      await open(tester, on: true);
      await tapSwitch(tester, 0);
      for (var i = 0; i < 5; i++) {
        await typePin(tester, '000001');
        await tester.pump();
      }
      expect(find.text('kebanyakan salah · coba lagi 0:30'), findsOne);

      await typePin(tester, lockPin);
      await tester.pump();
      expect(h.lock.enabled, isTrue); // held: even the right pin waits

      await tester.tap(
        find.bySemanticsLabel('tutup').first,
        warnIfMissed: false,
      );
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('matiin kunci?'), findsNothing);
      expect(h.lock.enabled, isTrue);
    });
  });

  group('ganti pin (99.10t)', () {
    testWidgets('pin lama, pin baru, ketik lagi', (tester) async {
      await open(tester, on: true);
      await tester.tap(find.text('ganti pin'));
      await tester.pumpAndSettle();
      expect(find.text('pin lama'), findsOne);
      expect(find.text('masukin pin yang sekarang'), findsOne);

      await type(tester, lockPin);
      expect(find.text('pin baru'), findsOne);

      await type(tester, '654321'); // weak
      expect(find.text('pin ini gampang ketebak, coba yang lain'), findsOne);

      await type(tester, '918273');
      expect(find.text('ketik pin baru lagi'), findsOne);

      await type(tester, '918273');
      expect(find.text('pin diganti'), findsOne);
      expect(find.text('pakai pin baru mulai sekarang'), findsOne);
      expect(
        (await h.repo.verifyPin(lockPin, h.now)).outcome,
        PinOutcome.wrong,
      );
      expect((await h.repo.verifyPin('918273', h.now)).outcome, PinOutcome.ok);
    });

    testWidgets('a wrong old pin does not get past the first step', (
      tester,
    ) async {
      await open(tester, on: true);
      await tester.tap(find.text('ganti pin'));
      await tester.pumpAndSettle();
      await type(tester, '000001');
      expect(find.text('pin lama'), findsOne);
      expect(
        find.text('pin salah · 4× lagi sebelum ditahan sebentar'),
        findsOne,
      );
    });

    testWidgets('new pins that differ start the new pin over', (tester) async {
      await open(tester, on: true);
      await tester.tap(find.text('ganti pin'));
      await tester.pumpAndSettle();
      await type(tester, lockPin);
      await type(tester, '918273');
      await type(tester, '372819');
      expect(find.text('pin baru'), findsOne);
      expect(find.text('pin nggak sama, ulang dari awal ya'), findsOne);
      expect((await h.repo.verifyPin(lockPin, h.now)).outcome, PinOutcome.ok);
    });
  });

  group('face id berubah (99.10s)', () {
    testWidgets('switch off with the reason, the pin brings it back', (
      tester,
    ) async {
      await open(tester, on: true);
      await h.container.read(appLockProvider.notifier).markBioChanged();
      await tester.pumpAndSettle();
      expect(
        find.text('face id berubah, masukin pin buat nyalain lagi'),
        findsOne,
      );

      await tapSwitch(tester, 1);
      expect(find.text('nyalain face id lagi?'), findsOne);
      expect(find.text('masukin pin dulu'), findsOne);

      await type(tester, lockPin);
      expect(h.lock.bio, isTrue);
      expect(h.lock.bioChanged, isFalse);
      expect(find.text('face id nyala lagi'), findsOne);
      expect(find.text('buka pakai face id atau pin'), findsOne);
      expect(
        find.text('face id berubah, masukin pin buat nyalain lagi'),
        findsNothing,
      );
    });

    testWidgets('the same hold applies', (tester) async {
      await open(tester, on: true);
      await h.container.read(appLockProvider.notifier).markBioChanged();
      await tester.pumpAndSettle();
      await tapSwitch(tester, 1);
      for (var i = 0; i < 5; i++) {
        await typePin(tester, '000001');
        await tester.pump();
      }
      expect(find.text('kebanyakan salah · coba lagi 0:30'), findsOne);
      expect(h.lock.bio, isFalse);
    });
  });
}
