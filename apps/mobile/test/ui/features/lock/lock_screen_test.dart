import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/models/app_lock.dart';
import 'package:mibu/ui/core/app_lock_providers.dart';
import 'package:mibu/ui/features/lock/views/lock_screen.dart';

import '../../../lock.dart';

void main() {
  late LockHarness h;

  /// A lock that is on, the screen up. [bio] = the phone has it and the lock
  /// uses it.
  Future<void> open(
    WidgetTester tester, {
    BioKind bio = BioKind.none,
    bool useBio = false,
    bool bioPasses = true,
  }) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = LockHarness(bio: bio)..bio.passes = bioPasses;
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      h.dispose();
    });
    await h.repo.enable(lockPin, bio: useBio);
    await h.load();
    await tester.pumpWidget(h.app(const LockScreen()));
    await tester.pump();
  }

  Future<void> wrong(WidgetTester tester, int times) async {
    for (var i = 0; i < times; i++) {
      await typePin(tester, '000001');
      await tester.pump();
    }
  }

  testWidgets('99.10j: the right pin opens', (tester) async {
    await open(tester);
    expect(find.text('buka mibu'), findsOne);
    expect(find.text('masukin pin kamu'), findsOne);
    expect(h.locked, isTrue);

    await typePin(tester, lockPin);
    await tester.pump();
    expect(h.locked, isFalse);
  });

  testWidgets('99.10l: a wrong pin says how many tries are left', (
    tester,
  ) async {
    await open(tester);
    await wrong(tester, 1);
    expect(find.text('pin salah · 4× lagi sebelum ditahan sebentar'), findsOne);
    expect(h.locked, isTrue);
    expect(h.lock.wrongTries, 1);

    await wrong(tester, 3);
    expect(find.text('pin salah · 1× lagi sebelum ditahan sebentar'), findsOne);

    // typing again clears the message
    await tester.tap(find.text('4'));
    await tester.pump();
    expect(find.textContaining('pin salah'), findsNothing);
  });

  testWidgets('99.10m: 5 wrong holds the pad, counting down to the end', (
    tester,
  ) async {
    await open(tester);
    await wrong(tester, 5);
    expect(find.text('kebanyakan salah · coba lagi 0:30'), findsOne);

    // held: digits do nothing, even the right pin
    await typePin(tester, lockPin);
    expect(h.locked, isTrue);
    expect(h.lock.wrongTries, 5);

    h.now = h.now.add(const Duration(seconds: 10));
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('kebanyakan salah · coba lagi 0:20'), findsOne);

    h.now = h.now.add(const Duration(seconds: 20));
    await tester.pump(const Duration(seconds: 20));
    expect(find.textContaining('coba lagi'), findsNothing);
    expect(find.textContaining('pin salah'), findsNothing);

    await typePin(tester, lockPin);
    await tester.pump();
    expect(h.locked, isFalse);
    expect(h.lock.wrongTries, 0);
  });

  testWidgets('99.10m: a later hold says "salah lagi", longer', (tester) async {
    await open(tester);
    await wrong(tester, 5);
    h.now = h.now.add(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 30));
    expect(find.textContaining('coba lagi'), findsNothing);

    await wrong(tester, 5);
    expect(find.text('salah lagi · coba lagi 1:00'), findsOne);
  });

  group('face id / sidik jari', () {
    testWidgets('comes up by itself and opens', (tester) async {
      await open(tester, bio: BioKind.face, useBio: true);
      expect(h.bio.prompts, 1);
      expect(h.locked, isFalse);
    });

    testWidgets('a miss leaves the pin pad, the key calls it again', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester, bio: BioKind.face, useBio: true, bioPasses: false);
      expect(h.bio.prompts, 1);
      expect(find.text('pakai face id atau pin'), findsOne);
      expect(find.bySemanticsLabel('pakai face id'), findsOne);
      final before = h.bio.prompts;

      await tester.tap(find.bySemanticsLabel('pakai face id'));
      await tester.pump();
      expect(h.bio.prompts, before + 1);
      expect(h.locked, isTrue);

      h.bio.passes = true;
      await tester.tap(find.bySemanticsLabel('pakai face id'));
      await tester.pump();
      expect(h.locked, isFalse);
      handle.dispose();
    });

    testWidgets('sidik jari has its own words', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester, bio: BioKind.finger, useBio: true, bioPasses: false);
      expect(find.text('pakai sidik jari atau pin'), findsOne);
      expect(find.bySemanticsLabel('pakai sidik jari'), findsOne);
      handle.dispose();
    });

    testWidgets('still works while the pad is held, and clears the count', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester, bio: BioKind.face, useBio: true, bioPasses: false);
      await wrong(tester, 5);
      expect(find.textContaining('kebanyakan salah'), findsOne);
      expect(h.lock.wrongTries, 5);

      final before = h.bio.prompts;
      h.bio.passes = true;
      await tester.tap(find.bySemanticsLabel('pakai face id'));
      await tester.pump();
      expect(h.bio.prompts, before + 1);
      expect(h.locked, isFalse);
      expect(h.lock.wrongTries, 0);
      expect(h.lock.heldUntil, isNull);
      handle.dispose();
    });

    testWidgets('a new face / fingerprint: key gone, no prompt, pin only', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester, bio: BioKind.face, useBio: true, bioPasses: false);
      await h.container.read(appLockProvider.notifier).markBioChanged();
      await tester.pumpWidget(h.app(const LockScreen()));
      await tester.pump();
      final prompts = h.bio.prompts;

      expect(h.bio.prompts, prompts);
      expect(find.text('masukin pin kamu'), findsOne);
      expect(find.bySemanticsLabel('pakai face id'), findsNothing);
      handle.dispose();
    });

    testWidgets('a phone without it: pin only', (tester) async {
      final handle = tester.ensureSemantics();
      await open(tester, useBio: true); // the lock wants it, the phone has none
      expect(h.bio.prompts, 0);
      expect(find.text('masukin pin kamu'), findsOne);
      expect(find.bySemanticsLabel('pakai face id'), findsNothing);
      handle.dispose();
    });
  });

  testWidgets('99.10q: lupa pin? explains there is no reset', (tester) async {
    await open(tester);
    await tester.tap(find.text('lupa pin?'));
    await tester.pump();
    expect(find.text('pin nggak bisa direset'), findsOne);
    expect(find.text('mibu cuma nyimpen data di hp ini'), findsOne);
    expect(find.text('jalan satu-satunya: instal ulang mibu'), findsOne);
    expect(
      find.text('catatan cuma bisa balik kalau kamu punya file export csv'),
      findsOne,
    );

    await tester.tap(find.text('ngerti'));
    await tester.pump();
    expect(find.text('pin nggak bisa direset'), findsNothing);
    expect(h.locked, isTrue);
  });
}
