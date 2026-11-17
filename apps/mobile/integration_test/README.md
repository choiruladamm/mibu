# Statistics verification

From `apps/mobile`, run the focused tests:

```sh
fvm flutter test test/domain/stats_test.dart test/domain/period_test.dart test/ui/features/stats/stats_test.dart test/ui/features/budget test/ui/copy_guard_test.dart --timeout 30s
```

Run the integration test on an available simulator or emulator:

```sh
fvm flutter test integration_test/stats_test.dart --flavor dev -d <device-id> --timeout 60s
```

Main expense entry flow:

```sh
fvm flutter test integration_test/entry_flow_test.dart --flavor dev -d <device-id> --timeout 60s
```

`stats_test.dart` uses mibu dev, an in-memory SQLite database, fixture data, and a fixed clock. It does not read or change production data. It exercises the statistics screen with providers, repositories, the database, and native rendering; it does not traverse onboarding or app lock.

Coverage includes week, month, and year navigation, previous-period values, database stream updates, bar selection, category scrolling, and future CSV transactions becoming visible when the date changes. Widget tests cover loading, errors, retry, historical budgets, empty states, and 360/390 layouts with bundled fonts. Domain tests cover payday periods, budget boundaries, averages, and yearly time bases.

`entry_flow_test.dart` opens the add-entry form from Home, records a categorized expense, and confirms the saved row. It uses a seeded in-memory database and does not read or change production data.

These tests do not cover every app flow, full accessibility, or biometric hardware behavior.
