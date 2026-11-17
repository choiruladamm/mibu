# mibu

A personal finance app for iOS and Android (Indonesia, IDR, used daily): record money and organize it into pockets. Fully local, with no login or backend.

## Sources of truth

- **Product, calculations, and flows:** [docs/](docs/README.md), one file per topic. Read the relevant file before working on a feature. Product ideas belong in GitHub issues and are implemented only when requested. Formulas (safe to spend, statistics, CSV, periods) are documented there; do not reinvent them. Refer to docs by path, not section number.
- **UI design:** Claude Design “mibu”, https://claude.ai/artifact/25RLRcYScmmPDzjBvg9Zz8. Read the relevant screen board with the Artifact tool, not WebFetch. Screen IDs (02.1, 07.2, etc.) are board titles; use them in comments and issues. The boards were reorganized on 2026-10-10; `docs/features.md` maps the old IDs in git history.
- **Tasks:** GitHub issues labeled `area:*`. One issue is one unit of work. All dependencies on the **Depends on** / **Tergantung** line must be closed. Check off scope items as they are completed.

## Workflow

- Skip auth (01.2) and features deferred in `docs/mvp.md` unless requested.
- Issue status labels: `status:ready` means the plan is ready to implement; `status:deferred` waits for the trigger in **Dibuka kalau** (change to ready once triggered); `status:idea` is undecided and may be closed as `wontfix`.
- For a new issue, idea, or deferred item, create an issue with the appropriate status label, add it to the appropriate parent, and link it as `(#N)` in the docs.
- No AI attribution in commits, PRs, issues, or code: no `Co-Authored-By` or “Generated with …” lines. This overrides default attribution.

## Project

The Flutter app is in `apps/mobile`; FVM pins Flutter in `.fvmrc`. Use the root `Makefile` (`make help`), or run `fvm flutter` / `fvm dart` from `apps/mobile`.

- After changing Drift tables, run `make gen` (build_runner) and commit `*.g.dart` files.
- **The schema is released and real data exists on phones** (`com.mibu.mibu`). v1 is the baseline from tag `release-baseline` (commit `937e55f`). Never edit a released table in place or delete data. For each table change, increment `schemaVersion`, add a `from < N` step to `onUpgrade` in `app_database.dart`, and add the old schema as `vN` plus a case in `test/data/migration_test.dart` (old SQL fixture versus fresh install, preserving data). Do not use `drift_dev make-migrations`. Drift cannot downgrade.
- Never change the production application ID or bundle ID (`com.mibu.mibu`).
- Run only tests relevant to the change. For small changes, run `dart format` and `dart analyze` on touched files and only the tests covering them (`fvm flutter test <test files or dirs> --timeout 30s`). Run full `make check` only for wide changes such as schema/migrations, models/codegen, shared widgets, routing/theme, or many features. Do not repeat the full suite solely for a small follow-up. Commit only after the checks run exit 0; report the checks and whether the full suite was skipped.

### Device builds

The apps have separate data:

| App | ID | iOS | Android | Branch |
| --- | --- | --- | --- | --- |
| **mibu** (real data) | `com.mibu.mibu` | `make release` | `make release-android`, `make apk` | `main` only |
| **mibu dev** (different icon color) | `com.mibu.mibu.dev` | `make dev`, debug `make run f=dev` | `make dev-android`, debug `make run-android f=dev` | feature branches |

Always use mibu dev on feature branches: unstable migrations could affect real data. Android always requires a flavor (`prod` or `dev`). Android release signing uses gitignored `android/key.properties`; without it, the build uses the debug key, which signs the currently installed build. Changing signatures prevents an update install.

Debug sample data (`seed.dart`, only in `kDebugMode`): `seedFixture` uses design numbers asserted by tests (do not change them); `seedDemo` uses realistic data and is used by `appDatabaseProvider` on devices. Select with `make run seed=demo|fixture|none`. `make fresh` wipes data on every launch without seeding (01.1 → 01.4); `make reset` wipes and reseeds. A new release installation starts empty.

## Architecture

Layered UI → data, with a hybrid structure:

```text
lib/
├── data/database/      # Drift AppDatabase, appDatabaseProvider, seed.dart
├── data/repositories/  # map Drift rows to domain models and expose streams
├── domain/             # pure period, safe-to-spend, stats, and CSV logic; models/
├── l10n/               # app_id.arb and generated AppLocalizations
├── routing/router.dart # routerProvider and Routes
└── ui/
    ├── core/           # tokens, theme, money, dates, clock, shared widgets/
    └── features/<feature>/{views,view_models}/
```

- State uses Riverpod (`flutter_riverpod`) with manually written providers beside their classes. Pin time via `clockProvider` (`ui/core/clock.dart`); `nowProvider` is the app-start time for queries.
- Use go_router and `Routes` constants. Sheets use `showAppSheet` + `SheetFrame` (`widgets/sheet.dart`): `showModalBottomSheet`, radius 32, 45% scrim.
- Use `ui/core/tokens.dart` (board 00.1); add new colors or sizes as tokens first. Light theme only. Use `hugeicons` (rounded 1.5 stroke); custom icons go through `AppIcons` in `tokens.dart`.
- Reuse shared components in `ui/core/widgets/`: `PrimaryButton` / `CircleButton` (`sheet.dart`), `ConfirmModal`, `toast` (undo), `NoteSheet`, `DateSheet`, `DayStrip`, `AmountKeypad`, `PocketLimit`, `TxRow`, `NavHeader`, `MonthPicker` / `MonthMenu`, and `MetaLine`. Feature-specific components stay in their feature folder.
- Use `MetaLine` (00.19) for single-line metadata separators, never a literal “·” in UI copy. Section headers have a left title and right information without a dot. The floating TabBar is in a Stack; give lists `AppSpace.tabBarClearance` bottom padding.

## Dart conditional logic

- Limit ternaries in widget trees to one level.
- For more than two branches or labels derived from model state, extract a getter in a model extension with sequential `if`/`return` statements.
- For state that can grow, use an enum and switch expression.

## Tests

`apps/mobile/test/` mirrors `lib/`:

- `test/domain/`: pure logic; required for every formula. Keep `lib/domain/use_cases/` empty.
- `test/data/`: repositories, migrations (`migration_test.dart`), and seed, with in-memory DBs.
- `test/ui/core/`: shared widgets; `test/ui/features/<feature>/<screen>_test.dart`: screen widget tests.
- Shared helpers: `test/db.dart`, `test/meta.dart`, and `test/flutter_test_config.dart`.

Create the test DB with `AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true), () => now, seed)` and override `appDatabaseProvider`. Pin `clockProvider` to the same time, since it also determines debug seed time. Use `fixtureNow` (`test/db.dart`) for `seedFixture` values.

Widget test pitfalls (see `home_test.dart` and `settings_test.dart` for complete patterns):

- `testWidgets` uses a fake clock; Drift queries need the real event loop. After `pumpWidget` and each DB action, run `await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50))); await tester.pumpAndSettle();` (each file wraps this in `settle()`). Read the DB inside widget tests using `tester.runAsync(() => db.select(...))`; use Futures, not `watch().first`, in `test/db.dart` and repository tests.
- Tests use Ahem (1em per glyph), wider than the real font. Use 390 × 844 for home, `Size(900, 1400)` for dense screens such as settings, `devicePixelRatio = 1`, and `addTearDown(tester.view.reset)`. Treat test overflow as a test layout issue unless the test explicitly checks it (`expect(tester.takeException(), isNull)`, as in `tx_row_test.dart`).
- Stop streams before closing the DB: `addTearDown(() async { await tester.pumpWidget(const SizedBox()); await db.close(); })`.
- Test MaterialApps need `AppTheme.light`, `locale: Locale('id')`, and `AppLocalizations.localizationsDelegates`. Open views directly (`home: const HomeView()`), unless testing navigation.
- Mock platform plugins, e.g. `PackageInfo.setMockInitialValues(...)` for settings. Use `tester.ensureVisible(finder)` before tapping below-the-fold items.
- Find `MetaLine` / `EmojiText` content with `findMeta` / `findEmojiText` from `test/meta.dart`, not `find.text`.
- Run `test/ui/copy_guard_test.dart` from `apps/mobile` because it reads `lib/ui` using relative paths (`make test` does this). Do not write the literal “bulan ini” in `lib/ui`; period copy belongs in `app_id.arb`.
- `make test` uses `--timeout 30s`. Hangs usually need the real event loop or an `appDatabaseProvider` override. `flutter_test_config.dart` enables `dontWarnAboutMultipleDatabases`.
- Integration tests are outside the default scope.

## Easily missed data rules

- Each table has a UUID text `id`, `createdAt`, `updatedAt`, and `deletedAt` (soft deletion supports undo and future sync). No autoincrement.
- Never store derived amounts (balance, spending, monthly balance); calculate them from `transactions`. A pocket is a category with a limit; see `docs/mvp.md`.
- Business calculations are pure functions in `domain/` with unit tests, following the formulas in docs.
- Money is whole rupiah in an `int`. `rupiah` → `Rp4.530.000`, `rupiahCompact` → `Rp580K` / `Rp4,53jt`; use tabular figures.
- Locale is `id-ID`; weeks start Monday (set explicitly in `dates.dart`, since locale `id` defaults to Sunday).
- `purgeDeleted` removes rows soft-deleted more than a day ago; categories remain while referenced by transactions.

## Copy

UI text is lowercase, casual Indonesian, and stored in `lib/l10n/app_id.arb` (gen-l10n), never hard-coded. Use exact design board copy where available. Write “pengeluaran / pemasukan”, not “keluar / masuk”.
