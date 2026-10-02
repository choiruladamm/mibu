APP := apps/mobile
FLUTTER := cd $(APP) && fvm flutter
DART := cd $(APP) && fvm dart

.PHONY: help get gen watch l10n run profile test analyze format check clean

help: ## list commands
	@grep -E '^[a-z0-9-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  %-8s %s\n", $$1, $$2}'

get: ## pub get
	$(FLUTTER) pub get

gen: ## drift codegen (build_runner)
	$(DART) run build_runner build

watch: ## drift codegen in watch mode
	$(DART) run build_runner watch

l10n: ## regenerate AppLocalizations from app_id.arb
	$(FLUTTER) gen-l10n

run: ## run app (pass device: make run d=<id>)
	$(FLUTTER) run $(if $(d),-d $(d))

profile: ## run app in profile mode, real perf (pass device: make profile d=<id>)
	$(FLUTTER) run --profile $(if $(d),-d $(d))

test: ## run tests (one file: make test t=test/data)
	$(FLUTTER) test $(t)

analyze: ## static analysis
	$(FLUTTER) analyze

format: ## dart format lib + test
	$(DART) format lib test

check: format analyze test ## format, analyze, test

clean: ## flutter clean + pub get
	$(FLUTTER) clean && fvm flutter pub get
