/// Kunci app (99.10) as the UI sees it. The pin hash never leaves the
/// repository.
class AppLockState {
  const AppLockState({
    this.enabled = false,
    this.bio = false,
    this.bioChanged = false,
    this.after = const Duration(minutes: 1),
    this.blur = true,
    this.wrongTries = 0,
    this.heldUntil,
  });

  /// Kunci mati: nothing stored.
  static const off = AppLockState();

  final bool enabled;

  /// Face id / sidik jari on top of the pin.
  final bool bio;

  /// A new face / fingerprint was enrolled: [bio] went off until the pin
  /// turns it back on.
  final bool bioChanged;

  /// "kunci lagi setelah ditinggal"; zero = langsung.
  final Duration after;

  /// "blur pas pindah app".
  final bool blur;

  /// Wrong pins since the last success, across restarts.
  final int wrongTries;

  /// The pin pad is held until then (null = not held).
  final DateTime? heldUntil;

  /// Time left on the hold at [now]; null when not held.
  Duration? holdLeft(DateTime now) {
    final until = heldUntil;
    if (until == null || !until.isAfter(now)) return null;
    return until.difference(now);
  }
}

/// What a pin attempt did.
enum PinOutcome { ok, wrong, held }

/// Which biometric this phone has for the lock (none = unavailable).
enum BioKind { none, face, finger }
