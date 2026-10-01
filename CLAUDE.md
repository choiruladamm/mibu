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

Riverpod providers are written by hand (no `riverpod_generator`), declared next to the class they expose. Pin time via `nowProvider`; in tests override `appDatabaseProvider` with `AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true))`.

## MVP scope (see `docs/MVP_PLAN.md`, features in `docs/FEATURES.md`)

- Fully local Drift, no login, no backend. Skip auth (01.2) and deferred features listed in the plan unless asked.
- Every table: UUID text `id`, `createdAt`, `updatedAt`, `deletedAt` (soft delete, powers undo + future sync). No autoincrement ids.
- Never store derived values (saldo, kepake, month balances) — compute from `transactions`. Pocket = category with `monthlyLimit`.
- Business math (aman jajan, stats, CSV) = pure functions in `domain/`, unit-tested. Formulas live in the plan; don't reinvent.

## Structure (`apps/mobile/lib`)

- `domain/models/` — plain models
- `data/database/` — Drift `AppDatabase` (seeds design sample data in debug only, until 01.4 setup exists)
- `data/repositories/` — map Drift rows → domain models, expose streams
- `routing/router.dart` — go_router `routerProvider`, `Routes` paths
- `ui/core/` — `tokens.dart` (design tokens), `theme.dart`, `money.dart` (`rupiah`, `rupiahCompact`), `dashed.dart`, shared `widgets/`
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
