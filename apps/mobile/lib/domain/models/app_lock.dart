/// App lock state for the UI (99.10). The PIN hash stays in the repository.
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

  /// Lock is disabled; nothing is stored.
  static const off = AppLockState();

  final bool enabled;

  /// Face ID or fingerprint is enabled in addition to the PIN.
  final bool bio;

  /// A new face / fingerprint was enrolled: [bio] went off until the pin
  /// turns it back on.
  final bool bioChanged;

  /// "kunci lagi setelah ditinggal"; zero means immediately.
  final Duration after;

  /// "blur pas pindah app" setting.
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
