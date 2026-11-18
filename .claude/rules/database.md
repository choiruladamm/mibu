---
paths:
  - "apps/mobile/lib/data/**"
  - "apps/mobile/test/data/**"
---

# Drift schema and migrations

v1 is the released baseline (tag `release-baseline`, commit `937e55f`). Real data exists on phones, so every table change follows this procedure:

1. Bump `schemaVersion` in `app_database.dart`.
2. Add a `from < N` step to `onUpgrade` (the commented template shows the shape).
3. Add the old schema as `vN` plus a case in `test/data/migration_test.dart`: old SQL fixture versus fresh install, asserting data is preserved.
4. Run `make gen` and commit the `*.g.dart` files.

Write migrations by hand; `drift_dev make-migrations` is not used here.

## Test databases

```dart
AppDatabase(
  DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
  () => now,
  seed,
)
```

Override `appDatabaseProvider` with it and pin `clockProvider` to the same `now` (it also drives debug seed time). For `seedFixture` values use `fixtureNow` from `test/db.dart`. In repository tests and `test/db.dart`, read with Futures (`.get()`), not `watch().first`.
