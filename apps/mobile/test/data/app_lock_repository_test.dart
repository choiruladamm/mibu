import 'package:flutter_test/flutter_test.dart';
import 'package:mibu/data/repositories/app_lock_repository.dart';
import 'package:mibu/domain/models/app_lock.dart';

import '../lock_store.dart';

const _pin = '483917';
final _now = DateTime(2026, 10, 24, 12);

void main() {
  late MemoryLockStore store;
  late AppLockRepository repo;

  setUp(() {
    store = MemoryLockStore();
    repo = AppLockRepository(store);
  });

  /// [times] wrong pins, [gap] apart from [_now].
  Future<PinOutcome> wrong(int times, {Duration gap = Duration.zero}) async {
    var last = PinOutcome.wrong;
    for (var i = 0; i < times; i++) {
      last = (await repo.verifyPin('000001', _now.add(gap))).outcome;
    }
    return last;
  }

  test('starts off', () async {
    final s = await repo.load();
    expect(s.enabled, isFalse);
    expect(store.values, isEmpty);
  });

  test('enable stores a hash, never the pin', () async {
    final s = await repo.enable(_pin, bio: true);
    expect(s.enabled, isTrue);
    expect(s.bio, isTrue);
    expect(s.after, const Duration(minutes: 1));
    expect(s.blur, isTrue);
    expect(store.values.values.join(), isNot(contains(_pin)));
  });

  test('enable turns down a weak or malformed pin', () {
    expect(repo.enable('123456', bio: false), throwsArgumentError);
    expect(repo.enable('111111', bio: false), throwsArgumentError);
    expect(repo.enable('1234', bio: false), throwsArgumentError);
  });

  test('the state survives a new repository on the same store', () async {
    await repo.enable(_pin, bio: false);
    await repo.setAfter(const Duration(minutes: 5));
    await wrong(3);
    final s = await AppLockRepository(store).load();
    expect(s.enabled, isTrue);
    expect(s.after, const Duration(minutes: 5));
    expect(s.wrongTries, 3);
  });

  group('verifyPin', () {
    setUp(() => repo.enable(_pin, bio: false));

    test('right pin opens', () async {
      final r = await repo.verifyPin(_pin, _now);
      expect(r.outcome, PinOutcome.ok);
    });

    test('wrong pins count, the fifth holds 30 dtk', () async {
      expect(await wrong(4), PinOutcome.wrong);
      expect((await repo.load()).wrongTries, 4);
      final r = await repo.verifyPin('000001', _now);
      expect(r.outcome, PinOutcome.wrong);
      expect(r.state.wrongTries, 5);
      expect(r.state.holdLeft(_now), const Duration(seconds: 30));
    });

    test(
      'held: even the right pin is refused and nothing is counted',
      () async {
        await wrong(5);
        final during = _now.add(const Duration(seconds: 10));
        final r = await repo.verifyPin(_pin, during);
        expect(r.outcome, PinOutcome.held);
        expect(r.state.wrongTries, 5);
        expect(
          (await repo.verifyPin('000001', during)).outcome,
          PinOutcome.held,
        );
        expect((await repo.load()).wrongTries, 5);
      },
    );

    test('after the hold the right pin opens and clears the count', () async {
      await wrong(5);
      final after = _now.add(const Duration(seconds: 30));
      final r = await repo.verifyPin(_pin, after);
      expect(r.outcome, PinOutcome.ok);
      expect(r.state.wrongTries, 0);
      expect(r.state.heldUntil, isNull);
    });

    test('keeps climbing: 10 wrong 1 mnt, 20 wrong 15 mnt', () async {
      await wrong(5);
      var t = _now.add(const Duration(seconds: 30));
      for (var i = 0; i < 5; i++) {
        await repo.verifyPin('000001', t);
      }
      expect((await repo.load()).holdLeft(t), const Duration(minutes: 1));
      t = t.add(const Duration(minutes: 1));
      for (var i = 0; i < 5; i++) {
        await repo.verifyPin('000001', t);
      }
      expect((await repo.load()).holdLeft(t), const Duration(minutes: 5));
      t = t.add(const Duration(minutes: 5));
      for (var i = 0; i < 5; i++) {
        await repo.verifyPin('000001', t);
      }
      expect((await repo.load()).holdLeft(t), const Duration(minutes: 15));
    });

    test('a clock set back keeps the hold', () async {
      await wrong(5);
      final back = _now.subtract(const Duration(hours: 3));
      expect((await repo.verifyPin(_pin, back)).outcome, PinOutcome.held);
    });

    test('face id success clears the count', () async {
      await wrong(3);
      expect((await repo.bioSucceeded()).wrongTries, 0);
    });
  });

  group('settings', () {
    setUp(() => repo.enable(_pin, bio: true));

    test('after, blur and bio', () async {
      await repo.setAfter(Duration.zero);
      await repo.setBlur(false);
      final s = await repo.setBio(false);
      expect(s.after, Duration.zero);
      expect(s.blur, isFalse);
      expect(s.bio, isFalse);
    });

    test('changePin swaps the pin and clears the count', () async {
      await wrong(3);
      await repo.changePin('918273');
      expect((await repo.verifyPin(_pin, _now)).outcome, PinOutcome.wrong);
      expect((await repo.verifyPin('918273', _now)).outcome, PinOutcome.ok);
    });

    test('a new biometric turns face id off until it is switched on', () async {
      final s = await repo.markBioChanged();
      expect(s.bio, isFalse);
      expect(s.bioChanged, isTrue);
      final back = await repo.setBio(true);
      expect(back.bio, isTrue);
      expect(back.bioChanged, isFalse);
    });

    test('disable forgets everything', () async {
      await repo.setAfter(const Duration(minutes: 15));
      expect((await repo.disable()).enabled, isFalse);
      expect(store.values, isEmpty);
      final s = await repo.enable(_pin, bio: false);
      expect(s.after, const Duration(minutes: 1));
    });

    test('changing settings with the lock off is a bug', () async {
      await repo.disable();
      expect(repo.setBlur(false), throwsStateError);
      expect(repo.verifyPin(_pin, _now), throwsStateError);
    });
  });

  test('wipe clears every stored value', () async {
    await repo.enable(_pin, bio: true);
    store.values['other'] = 'x';
    await repo.wipe();
    expect(store.values, isEmpty);
    expect((await repo.load()).enabled, isFalse);
  });

  test('an unreadable value counts as no lock', () async {
    store.values['lock.v1'] = 'not json';
    expect((await repo.load()).enabled, isFalse);
  });
}
