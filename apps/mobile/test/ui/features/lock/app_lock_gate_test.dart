import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/ui/core/app_lock_providers.dart';
import 'package:mibu/ui/features/lock/views/app_lock_gate.dart';

import '../../../lock.dart';

void main() {
  late LockHarness h;

  /// The gate around a one-line "app", [after] minutes of grace (0 =
  /// langsung). Lock off when [on] is false.
  Future<void> open(
    WidgetTester tester, {
    bool on = true,
    int after = 5,
    bool blur = true,
  }) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    h = LockHarness();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      h.dispose();
    });
    if (on) {
      await h.repo.enable(lockPin, bio: false);
      await h.repo.setAfter(Duration(minutes: after));
      await h.repo.setBlur(blur);
    }
    await h.load();
    await tester.pumpWidget(
      h.app(const AppLockGate(child: Scaffold(body: Text('beranda')))),
    );
    await tester.pump();
  }

  Future<void> unlock(WidgetTester tester) async {
    await typePin(tester, lockPin);
    await tester.pump();
  }

  /// Leaves for [away], then comes back, like the OS would tell it.
  Future<void> leaveAndReturn(WidgetTester tester, Duration away) async {
    final b = tester.binding;
    b.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    b.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    b.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    h.now = h.now.add(away);
    b.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    b.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    b.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
  }

  testWidgets('lock off: the app, no lock screen', (tester) async {
    await open(tester, on: false);
    expect(find.text('beranda'), findsOne);
    expect(find.text('buka mibu'), findsNothing);
  });

  testWidgets('cold start with the lock on: lock screen, app out of reach', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('buka mibu'), findsOne);
    expect(find.text('beranda'), findsNothing); // mounted, but offstage
    expect(find.text('beranda', skipOffstage: false), findsOne);

    await unlock(tester);
    expect(find.text('beranda'), findsOne);
    expect(find.text('buka mibu'), findsNothing);
  });

  group('coming back', () {
    testWidgets('inside the grace time: still open', (tester) async {
      await open(tester);
      await unlock(tester);
      await leaveAndReturn(tester, const Duration(minutes: 4, seconds: 59));
      expect(find.text('beranda'), findsOne);
      expect(find.text('buka mibu'), findsNothing);
    });

    testWidgets('after the grace time: locked again', (tester) async {
      await open(tester);
      await unlock(tester);
      await leaveAndReturn(tester, const Duration(minutes: 5));
      expect(find.text('buka mibu'), findsOne);
      expect(find.text('beranda'), findsNothing);
    });

    testWidgets('langsung: locked on every return', (tester) async {
      await open(tester, after: 0);
      await unlock(tester);
      await leaveAndReturn(tester, Duration.zero);
      expect(find.text('buka mibu'), findsOne);
    });

    testWidgets('a clock set back while away: locked', (tester) async {
      await open(tester, after: 15);
      await unlock(tester);
      await leaveAndReturn(tester, const Duration(hours: -1));
      expect(find.text('buka mibu'), findsOne);
    });

    testWidgets('lock off: never locks', (tester) async {
      await open(tester, on: false);
      await leaveAndReturn(tester, const Duration(days: 2));
      expect(find.text('beranda'), findsOne);
      expect(h.locked, isFalse);
    });

    testWidgets('the system prompt (inactive, never hidden) is not leaving', (
      tester,
    ) async {
      await open(tester, after: 0);
      await unlock(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('beranda'), findsOne);
    });

    testWidgets('turning the lock on does not lock the session', (
      tester,
    ) async {
      await open(tester, on: false);
      await h.container
          .read(appLockProvider.notifier)
          .enable(lockPin, bio: false);
      await tester.pump();
      expect(find.text('beranda'), findsOne);
      expect(find.text('buka mibu'), findsNothing);
    });
  });

  group('blur pas pindah app', () {
    testWidgets('covers the app while it is not in front', (tester) async {
      await open(tester);
      await unlock(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('mibu'), findsOne); // the wordmark, over the app

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.text('mibu'), findsNothing);
    });

    testWidgets('off: nothing covers it', (tester) async {
      await open(tester, blur: false);
      await unlock(tester);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('mibu'), findsNothing);
    });

    testWidgets('lock off: nothing covers it', (tester) async {
      await open(tester, on: false);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(find.text('mibu'), findsNothing);
    });
  });
}
