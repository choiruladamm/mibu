/// Kunci app rules (99.10): pin shape, wrong-pin holds, when to lock again.
/// Pure; the repository stores the state, the UI shows it.
library;

const pinLength = 6;

/// Wrong pins before each hold.
const triesPerHold = 5;

const _holds = [
  Duration(seconds: 30),
  Duration(minutes: 1),
  Duration(minutes: 5),
  Duration(minutes: 15), // stays here
];

bool isValidPin(String pin) => RegExp('^\\d{$pinLength}\$').hasMatch(pin);

/// Same digit all through, or a straight run up or down (111111, 123456,
/// 654321): turned down when making a pin.
bool isWeakPin(String pin) {
  final d = pin.codeUnits;
  if (d.length < 2) return true;
  final step = d[1] - d[0];
  if (step.abs() > 1) return false;
  for (var i = 1; i < d.length; i++) {
    if (d[i] - d[i - 1] != step) return false;
  }
  return true;
}

/// The hold a wrong pin starts: 5 wrong → 30 dtk, 10 → 1 mnt, 15 → 5 mnt,
/// 20 and on → 15 mnt. Null between those.
Duration? holdAfter(int wrongTries) {
  if (wrongTries <= 0 || wrongTries % triesPerHold != 0) return null;
  final i = wrongTries ~/ triesPerHold - 1;
  return _holds[i < _holds.length ? i : _holds.length - 1];
}

/// "N× lagi sebelum ditahan sebentar".
int triesLeft(int wrongTries) => triesPerHold - wrongTries % triesPerHold;

/// Whether coming back to the app needs the pin. [leftAt] null (cold start,
/// nothing recorded) locks, and so does a clock set back past [leftAt].
bool shouldLock({
  required DateTime? leftAt,
  required Duration after,
  required DateTime now,
}) {
  if (leftAt == null || now.isBefore(leftAt)) return true;
  return now.difference(leftAt) >= after;
}
