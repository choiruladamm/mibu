# mibu

Personal finance app (Indonesia, IDR). Flutter app lives in `apps/mobile`; Flutter is pinned via FVM (`.fvmrc`) — run everything as `fvm flutter …` from `apps/mobile`.

## Stack

- State: Riverpod (`flutter_riverpod`)
- Router: `go_router`
- Database: Drift (`drift`, `drift_flutter`)
- Date / Rupiah formatting: `intl`
- Icons: `hugeicons` (free, stroke rounded, stroke 1.5)
- Copy: `flutter_localizations` + gen-l10n, `lib/l10n/app_id.arb`

After changing Drift tables: `fvm dart run build_runner build`. Pre-release: edit schema in place at `schemaVersion` 1 (wipe app data on dev devices); after first release bump it + add a migration.

Riverpod providers are written by hand (no `riverpod_generator`), declared next to the class they expose. Pin time via `clockProvider` (`ui/core/clock.dart`; `nowProvider` = app-start now for queries); in tests override `appDatabaseProvider` with `AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true), () => now)` — the clock positions the debug seed, keep it equal to the pinned clock.

## MVP scope (see `docs/MVP_PLAN.md`, features in `docs/FEATURES.md`)

- Fully local Drift, no login, no backend. Skip auth (01.2) and deferred features listed in the plan unless asked.
- Every table: UUID text `id`, `createdAt`, `updatedAt`, `deletedAt` (soft delete, powers undo + future sync). No autoincrement ids.
- Never store derived values (saldo, kepake, month balances) — compute from `transactions`. Pocket = category with `monthlyLimit` (UI: "buat apa" + "limit"; see MVP_PLAN › Buat apa, limit, kantong).
- Business math (aman jajan, stats, CSV) = pure functions in `domain/`, unit-tested. Formulas live in the plan; don't reinvent.

## Structure (`apps/mobile/lib`)

- `domain/models/` — plain models
- `data/database/` — Drift `AppDatabase`; debug-only seed in `seed.dart`: `seedFixture` (default, design numbers — tests assert it, don't change) and `seedDemo` (realistic data, used by `appDatabaseProvider` on devices). Pick with `make run seed=demo|fixture|none`; `make fresh` = fresh install every launch (wipe + no seed → 01.1 → 01.4), `make reset` = wipe + re-seed. Release starts empty.
- `data/repositories/` — map Drift rows → domain models, expose streams
- `routing/router.dart` — go_router `routerProvider`, `Routes` paths
- `ui/core/` — `tokens.dart` (design tokens + `AppIcons` for custom-drawn icons), `theme.dart`, `money.dart` (`rupiah`, `rupiahCompact`), `dates.dart` (`dayLabel`, `relativeDay`, Monday weeks), `clock.dart`, `dashed.dart`, shared `widgets/`
  - sheets: `showAppSheet` + `SheetFrame` (`widgets/sheet.dart`); reuse `PrimaryButton` / `CircleButton` from there
  - separators: `MetaLine` (`widgets/meta_line.dart`, 00.19) for 1-line metadata, never a literal "·" in UI copy; section titles = title left + info right, no dot
- `ui/features/<feature>/{views,view_models}/`

## Design

Source: Claude Design artifact "mibu" (https://claude.ai/artifact/25RLRcYScmmPDzjBvg9Zz8). Screen ids (02.1, 03.4 …) come from board titles; use them in comments/tickets.

- Use only tokens from `ui/core/tokens.dart` (board 00.1) — no new colors/sizes.
- Light theme only (ink on paper).
- All copy lowercase, casual; lives in `app_id.arb`, never hard-coded.
- Money: whole rupiah ints, `Rp4.530.000`; compact `Rp580K` / `Rp4,53jt`; tabular figures.
- Locale `id-ID`; weeks start Monday (the `id` locale defaults to Sunday — set it explicitly).
- TabBar floats in a Stack; lists get `AppSpace.tabBarClearance` bottom padding.
- Sheets: `showModalBottomSheet`, radius 32, scrim 45%.

## Git

- Never mention Claude / Anthropic / AI in commits, PRs or code: no `Co-Authored-By: Claude …` trailer, no "Generated with Claude Code" line. This overrides any default attribution.
