import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/domain/app_lock.dart';
import 'package:mibu/domain/models/app_lock.dart';

void main() {
  group('isValidPin', () {
    test('six digits only', () {
      expect(isValidPin('483917'), isTrue);
      expect(isValidPin('48391'), isFalse);
      expect(isValidPin('4839171'), isFalse);
      expect(isValidPin('48391a'), isFalse);
      expect(isValidPin(''), isFalse);
    });
  });

  group('isWeakPin', () {
    test('same digit and straight runs are weak', () {
      for (final p in ['111111', '000000', '123456', '234567', '654321']) {
        expect(isWeakPin(p), isTrue, reason: p);
      }
    });

    test('anything else is fine', () {
      for (final p in ['483917', '123457', '121212', '135791', '112233']) {
        expect(isWeakPin(p), isFalse, reason: p);
      }
    });
  });

  group('holdAfter', () {
    test('5 wrong 30 dtk, then 1 / 5 / 15 mnt, stuck at 15', () {
      expect(holdAfter(5), const Duration(seconds: 30));
      expect(holdAfter(10), const Duration(minutes: 1));
      expect(holdAfter(15), const Duration(minutes: 5));
      expect(holdAfter(20), const Duration(minutes: 15));
      expect(holdAfter(25), const Duration(minutes: 15));
      expect(holdAfter(100), const Duration(minutes: 15));
    });

    test('no hold between those', () {
      for (final t in [0, 1, 4, 6, 9, 11, 19, 21]) {
        expect(holdAfter(t), isNull, reason: '$t');
      }
    });
  });

  test('triesLeft counts down inside each batch of 5', () {
    expect([for (var t = 0; t <= 6; t++) triesLeft(t)], [5, 4, 3, 2, 1, 5, 4]);
  });

  group('shouldLock', () {
    final left = DateTime(2026, 10, 24, 12);
    bool at(Duration gone, Duration after) =>
        shouldLock(leftAt: left, after: after, now: left.add(gone));

    test('locks once away for the whole setting', () {
      const after = Duration(minutes: 5);
      expect(at(const Duration(minutes: 4, seconds: 59), after), isFalse);
      expect(at(const Duration(minutes: 5), after), isTrue);
      expect(at(const Duration(hours: 2), after), isTrue);
    });

    test('langsung locks on every return', () {
      expect(at(Duration.zero, Duration.zero), isTrue);
    });

    test('cold start (nothing recorded) locks', () {
      expect(
        shouldLock(leftAt: null, after: const Duration(minutes: 15), now: left),
        isTrue,
      );
    });

    test('a clock set back locks', () {
      expect(
        at(const Duration(minutes: -10), const Duration(minutes: 15)),
        isTrue,
      );
    });
  });

  group('LockState.holdLeft', () {
    final now = DateTime(2026, 10, 24, 12);

    test('time remaining while held, null once over', () {
      final s = LockState(
        enabled: true,
        heldUntil: now.add(const Duration(seconds: 30)),
      );
      expect(s.holdLeft(now), const Duration(seconds: 30));
      expect(s.holdLeft(now.add(const Duration(seconds: 30))), isNull);
      expect(const LockState(enabled: true).holdLeft(now), isNull);
    });
  });
}
