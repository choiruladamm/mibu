# mibu

Personal finance app for iOS and Android (Indonesia, IDR, used daily): record money and organize it into pockets. Fully local: no login, no backend. Flutter app lives in `apps/mobile`; run `make help` at the root, or `fvm flutter` / `fvm dart` from `apps/mobile`.

## Sources of truth

- **Product, formulas, flows:** [docs/](docs/README.md), one file per topic. Read the relevant file before working on a feature, and take formulas (safe to spend, statistics, CSV, periods) from there. Cite docs by path, not section number. `docs/features.md` mixes shipped features with undecided proposals; build a proposal only when asked.
- **UI design:** Claude Design "mibu", https://claude.ai/artifact/25RLRcYScmmPDzjBvg9Zz8. Read the relevant screen board with the Artifact tool. Screen IDs (02.1, 07.2) are board titles; use them in comments and issues. Boards were renumbered on 2026-10-10; `docs/features.md` maps old IDs.
- **Tasks:** GitHub issues labeled `area:*`, one issue per unit of work. Start one only when every issue on its **Depends on** / **Tergantung** line is closed; tick scope items as you finish them.

## Workflow

- Skip auth (01.2) and features deferred in `docs/mvp.md` unless asked.
- Issue labels: `status:ready` = planned, implement it; `status:deferred` = waits for the trigger under **Dibuka kalau** (switch to ready once it fires); `status:idea` = undecided, may close as `wontfix`.
- New idea or deferred item: open an issue with the right status label, attach it to its parent, and link it as `(#N)` in docs.

## Real data on phones

The schema is released and people's data lives in `com.mibu.mibu`.

- Every table change is a migration: bump `schemaVersion`, add a `from < N` step in `onUpgrade`, add a migration test. Full procedure in `.claude/rules/database.md`. Released tables and existing rows are never edited in place or deleted. Drift cannot downgrade.
- Production IDs `com.mibu.mibu` (app and bundle) stay fixed.
- Feature branches build only the dev app, so unstable migrations never touch real data:

| App | ID | iOS | Android | Branch |
| --- | --- | --- | --- | --- |
| mibu (real data) | `com.mibu.mibu` | `make release` | `make release-android`, `make apk` | `main` only |
| mibu dev | `com.mibu.mibu.dev` | `make dev`, debug `make run f=dev` | `make dev-android`, debug `make run-android f=dev` | feature branches |

- Android always needs a flavor (`prod` or `dev`); `make run-android` defaults to prod, so pass `f=dev` on branches. Release signing reads gitignored `android/key.properties`; without it the build falls back to the debug key, and a signature change blocks update installs.
- Debug seeding (`seed.dart`, `kDebugMode` only): `seedFixture` holds design numbers that tests assert, so leave its values alone; `seedDemo` is realistic data used on devices. Pick with `make run seed=demo|fixture|none`; `make fresh` wipes on every launch with no seed, `make reset` wipes and reseeds. Release installs start empty.

## Checks

- After changing Drift tables run `make gen` and commit the `*.g.dart` files.
- Small change: `dart format` + `dart analyze` on touched files, then only the covering tests (`fvm flutter test <paths> --timeout 30s`).
- Full `make check` only for wide changes: schema/migrations, models/codegen, shared widgets, routing/theme, or many features. Skip re-running it for a small follow-up.
- `test/ui/copy_guard_test.dart` reads `lib/ui` by relative path; run it from `apps/mobile` (`make test` does).
- Commit once the checks you ran exit 0, and report which ran and whether the full suite was skipped.

## Code conventions

- State: Riverpod with hand-written providers next to their classes. Read time from `clockProvider` (`ui/core/clock.dart`); `nowProvider` is app-start time for queries.
- Navigation: go_router with `Routes` constants. Sheets: `showAppSheet` + `SheetFrame` (`widgets/sheet.dart`).
- Look in `ui/core/widgets/` before writing a shared component (sheets, keypad, toast with undo, confirm modal, month picker, tx row, pin pad …). Most are opened through a `show*` function. Feature-only components stay in their feature folder.
- Styling: values from `ui/core/tokens.dart` (board 00.1); add a new color or size as a token first. Light theme only. Icons: `hugeicons` rounded 1.5 stroke; custom icons go through `AppIcons`. Emoji: `AppEmoji` / `EmojiText` (bundled Fluent 3D PNGs).
- Single-line metadata separators use `MetaLine` (00.19); copy never contains a literal "·". Section headers: title left, info right, no dot.
- The floating tab bar sits in a Stack; give scrolling lists `AppSpace.tabBarClearance` bottom padding.
- Business calculations are pure functions in `lib/domain/` with unit tests in `test/domain/`. `lib/domain/use_cases/` stays empty.

## Data rules

- Every table: UUID text `id`, `createdAt`, `updatedAt`, `deletedAt`. Deletes are soft (undo, future sync); `purgeDeleted` removes rows soft-deleted over a day ago, keeping categories still referenced by transactions.
- Derived amounts (balance, spending, monthly balance) are always computed from `transactions`, never stored. A pocket is a category with a limit (`docs/mvp.md`).
- Money is whole rupiah in an `int`. Format with `rupiah` (`Rp4.530.000`) or `rupiahCompact` (`Rp580K`, `Rp4,53jt`), tabular figures.
- Locale `id-ID`; weeks start Monday, set explicitly in `dates.dart` because locale `id` defaults to Sunday.

## Copy

UI text is lowercase, casual Indonesian, stored in `lib/l10n/app_id.arb` (gen-l10n). Use the exact board copy when a board has it. Write "pengeluaran / pemasukan" (not "keluar / masuk"). Period wording like "bulan ini" lives in the arb; `copy_guard_test` fails if it appears in `lib/ui`.
