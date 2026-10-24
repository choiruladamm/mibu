import '../../../../domain/models/app_lock.dart';
import '../../../../l10n/app_localizations.dart';

extension BioKindLabel on BioKind {
  /// "face id" / "sidik jari".
  String word(AppLocalizations l) =>
      this == BioKind.face ? l.lockBioFace : l.lockBioFinger;
}

extension AppLockLabels on AppLockState {
  /// How the lock opens, for the 05.1 row and the 99.10 header: "face id + pin",
  /// "pin aja" or "mati". [kind] is what the phone can do now.
  String modeLabel(AppLocalizations l, BioKind kind) {
    if (!enabled) return l.lockModeOff;
    if (bio && kind != BioKind.none) return l.lockModeBio(kind.word(l));
    return l.lockModePin;
  }
}
