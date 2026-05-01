.PHONY: get build_runner watch clean test lint format fix run_dev run_prod build_ios build_android setup-hooks sentry-upload-symbols release_ios release_android

# Dependencies
get:
	flutter pub get

# Code generation
build_runner:
	dart run build_runner build --delete-conflicting-outputs

watch:
	dart run build_runner watch --delete-conflicting-outputs

# Cleaning
clean:
	flutter clean && rm -rf .dart_tool build

# Testing
test:
	flutter test --coverage

# Code quality
lint:
	flutter analyze

format:
	dart format lib test --set-exit-if-changed

fix:
	dart fix --apply

# Running
run_dev:
	flutter run --dart-define=ENV=dev

run_prod:
	flutter run --dart-define=ENV=prod

# Git hooks (run once per clone)
setup-hooks:
	git config core.hooksPath .githooks
	@echo "✓ git hooksPath set to .githooks"
	@echo "  pre-commit will run 'dart format --set-exit-if-changed' on staged .dart files"

# Building
build_ios:
	flutter build ios --release --obfuscate --split-debug-info=build/debug-info \
		--extra-gen-snapshot-options=--save-obfuscation-map=build/debug-info/obfuscation.map.json

build_android:
	flutter build appbundle --release --obfuscate --split-debug-info=build/debug-info \
		--extra-gen-snapshot-options=--save-obfuscation-map=build/debug-info/obfuscation.map.json

# Upload Dart .symbols + Android mapping.txt to Sentry for de-obfuscation.
# Requires SENTRY_AUTH_TOKEN — typically: `set -a && . .env.sentry && set +a`.
sentry-upload-symbols:
	@if [ -z "$$SENTRY_AUTH_TOKEN" ]; then \
		echo "ERROR: SENTRY_AUTH_TOKEN is not set."; \
		echo "       Source .env.sentry first: 'set -a && . .env.sentry && set +a'"; \
		exit 1; \
	fi
	dart run sentry_dart_plugin

# One-shot release: build + upload symbols.
release_ios: build_ios sentry-upload-symbols

release_android: build_android sentry-upload-symbols
