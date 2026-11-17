# mibu documentation

mibu is a local-first personal finance app for Indonesia, using IDR. The [design artifact](https://claude.ai/artifact/25RLRcYScmmPDzjBvg9Zz8) uses screen numbers (such as 02.1 and 07.2) as board IDs.

These documents are the source of truth for product decisions, calculations, and flows. Read the relevant topic before changing a feature. Product ideas are tracked in [GitHub issues](https://github.com/choiruladamm/mibu/issues) and should only be implemented when requested. The app's interface and quoted UI copy remain in Indonesian.

| Document | Contents |
| --- | --- |
| [MVP](mvp.md) | Scope, architecture, data model, and calculations |
| [Features](features.md) | Screens, shared components, and entities |
| [Payday cycle](payday-cycle.md) | Payday periods and date resolution |
| [Changing payday](payday-change.md) | Period boundaries when payday changes |
| [Weekend payday](payday-weekend.md) | Friday adjustment for weekend paydays |
| [Period ledger](period-ledger.md) | Period income and expenses without carryover |
| [Hide income](hide-income.md) | Amount privacy modes |
| [CSV import](import.md) | Importing mibu and Excel CSV files |
| [App lock](app-lock.md) | PIN, biometrics, lockout, and storage |

Keep one file per topic, using lowercase hyphenated names. Screen IDs follow the design boards reorganized on 2026-10-10.
