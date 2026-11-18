---
paths:
  - "apps/mobile/test/**"
---

# Widget tests

Full working patterns: `test/ui/features/home/home_test.dart` and `settings_test.dart`. Screen tests live at `test/ui/features/<feature>/<screen>_test.dart`; shared widget tests in `test/ui/core/`.

- **Drift needs the real event loop.** `testWidgets` runs on a fake clock. After `pumpWidget` and after each DB action, run `await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50))); await tester.pumpAndSettle();`. Each file wraps this in a local `settle()`. Read the DB with `tester.runAsync(() => db.select(...).get())`.
- **Hangs** usually mean a missing `runAsync` or a missing `appDatabaseProvider` override. `make test` uses `--timeout 30s`; `flutter_test_config.dart` sets `dontWarnAboutMultipleDatabases`.
- **Screen size.** Tests use the Ahem font (1em per glyph, wider than the real font). Use 390 × 844 for home, `Size(900, 1400)` for dense screens like settings, `devicePixelRatio = 1`, and `addTearDown(tester.view.reset)`. Overflow in a test is a test layout issue unless the test checks for it (`expect(tester.takeException(), isNull)`, as in `tx_row_test.dart`).
- **Teardown order.** Stop streams before closing the DB: `addTearDown(() async { await tester.pumpWidget(const SizedBox()); await db.close(); })`.
- **App shell.** Test `MaterialApp` needs `AppTheme.light`, `locale: Locale('id')`, and `AppLocalizations.localizationsDelegates`. Open the view directly (`home: const HomeView()`) unless the test covers navigation.
- **Plugins.** Mock platform plugins, e.g. `PackageInfo.setMockInitialValues(...)` for settings.
- **Finders.** `MetaLine` / `EmojiText` content: `findMeta` / `findEmojiText` from `test/meta.dart`. Tap below-the-fold items after `tester.ensureVisible(finder)`.
- Integration tests are outside the default scope.
