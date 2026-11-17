# mibu — app lock

Design: boards 99.10a–u + component 00.31 PinPad in the “mibu” artifact. Issues: #3 (parent), #25–#28.

## Why

A phone may be borrowed or taken. The app lock protects mibu’s records and amounts without requiring an account (all data stays local).

## Model

A 6-digit PIN is required; Face ID (iPhone) / fingerprint (Android) is optional on top of it. All lock state is stored in `flutter_secure_storage` as one JSON value (`lock.v1`): PIN hash + salt (HMAC-SHA256), failed-attempt count, lockout expiry, biometrics enabled, biometrics changed, relock delay, and blur. **Not in Drift**: `schemaVersion` stays the same, with no migration. Turning the lock off deletes this value (settings are removed too).

iOS Keychain data survives uninstall; the database does not. `bootstrap()` clears secure storage when the profile has not been onboarded (a fresh install), then loads lock state before the first frame. On Android, secure-storage files are excluded from auto-backup (`backup_rules.xml`, `data_extraction_rules.xml`); `allowBackup` stays enabled for the database.

## Rules

| Item | Rule |
|---|---|
| PIN | Exactly 6 digits. Reject all identical digits and ascending/descending sequences (including wraparound 9→0): 111111, 123456, 654321, 890123 |
| Lockout | 5 failures → 30 sec, 10 → 1 min, 15 → 5 min, 20 and above → 15 min (maximum). “N attempts left” = 5 − (failures mod 5) |
| Reset counter | Only after a correct PIN or successful biometrics. Force-quitting the app does not reset it |
| Shared counter | Lock screen, turn-off sheet, change PIN (old PIN), re-enable biometrics |
| During lockout | Digits and delete are dimmed to 35% and disabled; the biometrics button stays active |
| Clock | `locked until` is stored as a timestamp. Moving the phone clock backward does not end the lockout |
| When to lock | Always on cold start. On return from background, lock if away for at least the configured delay (immediately / 1 / 5 / 15 min; default 1). Use `hidden`, not `inactive`: a Face ID prompt does not count as leaving the app. Clock moved backward = lock |
| Enabling in settings | The session that enabled the lock is not locked immediately |
| Blur | On by default. When the app is not in front, replace it with the wordmark in the app switcher |
| Biometrics changed | Newly enrolled Face ID / fingerprint disables biometrics until the PIN is entered again (`bioChanged` flag) |
| Forgotten PIN | No reset. Reinstall is the only option; records can only be restored from an exported CSV file |

Rules are in `lib/domain/app_lock.dart` (tests: `test/domain/app_lock_test.dart`).

## Flows

- **Enable:** create PIN → enter it again (if different, restart) → “use Face ID too?” (if supported) → toast. Save the new PIN only at the final step. The system biometrics prompt is shown once (iOS permission); if declined, enable PIN-only.
- **Disable:** enter PIN first.
- **Change PIN:** old PIN → new PIN → enter it again.
- **Re-enable biometrics** (after enrollment changed): enter PIN first.
- **Lock screen:** show biometrics immediately; on failure or cancellation, switch to the PIN pad. “forgot PIN?” opens an explanatory sheet (built in place; the lock screen is above the Navigator).

## Native implementation

One method channel, `com.mibu/lock` (Dart: `lockChannel` in `lib/data/biometrics.dart`), with native code in `ios/Runner/AppDelegate.swift` and `android/.../MainActivity.kt`:

| Method | iOS | Android |
|---|---|---|
| `snapshot` | Store `evaluatedPolicyDomainState` in UserDefaults | Create a Keystore AES key invalidated by new biometric enrollment (`setInvalidatedByBiometricEnrollment`) |
| `enrollmentChanged` | Compare current domain state with the stored state | Run `Cipher.init` with that key; `KeyPermanentlyInvalidatedException` means enrollment changed |
| `secure(bool)` | No operation | Enable `FLAG_SECURE` while the lock and blur are on |

Call `snapshot` whenever biometrics are enabled (`AppLockController.enable` / `setBio(true)`), and `enrollmentChanged` whenever the lock screen appears, before the automatic prompt. If there is no baseline, treat enrollment as unchanged. Native errors are treated as unchanged / no-op.

Swift was type-checked against Flutter headers (`swiftc -typecheck`). Kotlin and on-device behavior have not been run; manual checks are in #30.
