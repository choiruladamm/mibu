APP := apps/mobile
FLUTTER := cd $(APP) && fvm flutter
DART := cd $(APP) && fvm dart

.PHONY: help get gen watch l10n run run-android fresh reset dev release dev-android release-android apk profile test analyze format check clean

help: ## list commands
	@grep -E '^[a-z0-9-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-16s %s\n", $$1, $$2}'

get: ## pub get
	$(FLUTTER) pub get

gen: ## drift codegen (build_runner)
	$(DART) run build_runner build

watch: ## drift codegen in watch mode
	$(DART) run build_runner watch

l10n: ## regenerate AppLocalizations from app_id.arb
	$(FLUTTER) gen-l10n

run: ## run on iOS in debug (d=<id>, f=dev for mibu dev, seed=demo|fixture|none)
	$(FLUTTER) run $(if $(f),--flavor $(f)) $(if $(d),-d $(d)) $(if $(seed),--dart-define=MIBU_SEED=$(seed))

run-android: ## run on Android in debug (d=<id>, f=dev for mibu dev, default prod)
	$(FLUTTER) run --flavor $(or $(f),prod) $(if $(d),-d $(d)) $(if $(seed),--dart-define=MIBU_SEED=$(seed))

release: ## install release build of mibu on iPhone (real data, own signing), main only (d=<id>)
	@test "$$(git rev-parse --abbrev-ref HEAD)" = main || { echo "make release cuma dari main (app mibu, data asli). Fitur: make dev"; exit 1; }
	$(FLUTTER) run --release $(if $(d),-d $(d))

dev: ## install release build of mibu dev on iPhone (own data), any branch (d=<id>)
	$(FLUTTER) run --release --flavor dev $(if $(d),-d $(d))

release-android: ## install release build of mibu on Android, main only (d=<id>)
	@test "$$(git rev-parse --abbrev-ref HEAD)" = main || { echo "make release-android cuma dari main (app mibu, data asli). Fitur: make dev-android"; exit 1; }
	$(FLUTTER) run --release --flavor prod $(if $(d),-d $(d))

dev-android: ## install release build of mibu dev on Android (own data), any branch (d=<id>)
	$(FLUTTER) run --release --flavor dev $(if $(d),-d $(d))

apk: ## build release APK of mibu (prod) for sideload, main only
	@test "$$(git rev-parse --abbrev-ref HEAD)" = main || { echo "make apk cuma dari main (app mibu, data asli)"; exit 1; }
	$(FLUTTER) build apk --release --flavor prod
	@echo "APK: $(APP)/build/app/outputs/flutter-apk/app-prod-release.apk"

fresh: ## run as a brand-new install: wipes data each launch → onboarding → 01.4 atur awal
	$(FLUTTER) run $(if $(f),--flavor $(f)) $(if $(d),-d $(d)) --dart-define=MIBU_SEED=none --dart-define=MIBU_RESET=true

reset: ## run with data wiped + re-seeded each launch (seed=demo|fixture, default demo)
	$(FLUTTER) run $(if $(f),--flavor $(f)) $(if $(d),-d $(d)) --dart-define=MIBU_SEED=$(or $(seed),demo) --dart-define=MIBU_RESET=true

profile: ## run app in profile mode, real perf (pass device: make profile d=<id>)
	$(FLUTTER) run --profile $(if $(d),-d $(d))

test: ## run tests, 30s cap per test so a hang fails fast (one file: make test t=test/data)
	$(FLUTTER) test --timeout 30s $(t)

analyze: ## static analysis
	$(FLUTTER) analyze

format: ## dart format lib + test
	$(DART) format lib test

check: format analyze test ## format, analyze, test

clean: ## flutter clean + pub get
	$(FLUTTER) clean && fvm flutter pub get
