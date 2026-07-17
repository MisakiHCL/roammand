BUF_BREAKING_AGAINST ?= .git\#branch=main
FLUTTER_APP_DIR := apps/client_flutter
FLUTTER_ARGS ?=
VERBOSE ?= 0
HOST_AGENT_DEBUG := $(abspath target/debug/roammand-host-agent)

.PHONY: help bootstrap bootstrap-steps app-check app-check-steps app-prepare-host-macos app-run-macos app-run-ios app-build-macos app-build-ios-simulator app-build-android package-macos test-product test-product-steps doctor boundary check-libwebrtc fetch-libwebrtc format format-check generate generate-failure-check generate-check schema-lint schema-build schema-breaking test test-conformance test-dart test-host test-m4 test-m4-config test-m4-lifecycle test-m5 test-m5-config test-m5-lifecycle test-m6 test-m6-config test-m6-lifecycle test-m7 test-m7-config test-m7-fuzz test-m7-privacy test-m7-reconnect test-m8 test-m8-config test-m8-privacy test-native-webrtc test-rust test-go test-schema test-schema-contract test-signaling test-signaling-race

define run-product-workflow
	@if [ "$(VERBOSE)" = "1" ]; then \
		$(MAKE) --no-print-directory $(1); \
	else \
		./scripts/run_quiet_workflow.sh "$(2)" $(MAKE) --no-print-directory $(1); \
	fi
endef

help:
	@printf '%s\n' \
		'Roammand product workflow' \
		'' \
		'  make bootstrap                Install workspace dependencies' \
		'  make app-check                Analyze and test the Flutter app' \
		'  make app-run-macos            Build the Debug Host and run the macOS app' \
		'  make app-run-ios              Run an available iOS target' \
		'  make app-build-macos          Build the macOS release app' \
		'  make app-build-ios-simulator  Build the iOS simulator app' \
		'  make app-build-android        Build the Android debug APK' \
		'  make package-macos            Stage and verify the macOS Host package' \
		'  make test-product             Run the complete product gate' \
		'' \
		"Pass Flutter options with FLUTTER_ARGS='--dart-define=KEY=value'." \
		'Set VERBOSE=1 to stream bootstrap, app-check, or test-product output.' \
		'Full repository gate: make test-product'

bootstrap:
	+$(call run-product-workflow,bootstrap-steps,bootstrap)

bootstrap-steps: doctor
	cd $(FLUTTER_APP_DIR) && flutter pub get
	cd gen/dart && dart pub get
	cargo fetch --locked
	cd services/signaling && go mod download

app-check:
	+$(call run-product-workflow,app-check-steps,app-check)

app-check-steps:
	cd $(FLUTTER_APP_DIR) && flutter analyze && flutter test

app-prepare-host-macos: check-libwebrtc
	@LK_CUSTOM_WEBRTC="$$(./scripts/fetch_libwebrtc.sh)"; \
	LK_CUSTOM_WEBRTC="$$LK_CUSTOM_WEBRTC" cargo build \
		-p roammand-host-agent --features native-webrtc
	./scripts/sign_macos_development.sh \
		"$(HOST_AGENT_DEBUG)" dev.roammand.host-agent

app-run-macos: app-prepare-host-macos
	cd $(FLUTTER_APP_DIR) && \
	ROAMMAND_HOST_AGENT_EXECUTABLE="$(HOST_AGENT_DEBUG)" \
	flutter run -d macos --no-pub $(FLUTTER_ARGS)

app-run-ios:
	cd $(FLUTTER_APP_DIR) && flutter run -d ios --no-pub $(FLUTTER_ARGS)

app-build-macos:
	cd $(FLUTTER_APP_DIR) && flutter build macos --release $(FLUTTER_ARGS)

app-build-ios-simulator:
	cd $(FLUTTER_APP_DIR) && flutter build ios --simulator --debug $(FLUTTER_ARGS)

app-build-android:
	cd $(FLUTTER_APP_DIR) && flutter build apk --debug $(FLUTTER_ARGS)

package-macos:
	./scripts/package_m8_macos.sh
	./scripts/check_m8_macos_package.sh dist/m8-macos

test-product:
	+$(call run-product-workflow,test-product-steps,test-product)

test-product-steps: format-check test test-m8

doctor:
	./scripts/doctor.sh

boundary:
	./scripts/check_public_boundary.sh
	./scripts/check_readme_contract.sh
	./scripts/test_app_workflow_contract.sh
	./scripts/test_roammand_brand_asset_contract.sh
	./scripts/test_roammand_product_name_contract.sh

check-libwebrtc:
	./scripts/check_libwebrtc_assets.sh

fetch-libwebrtc: check-libwebrtc
	@./scripts/fetch_libwebrtc.sh

test-native-webrtc: check-libwebrtc
	@LK_CUSTOM_WEBRTC="$$(./scripts/fetch_libwebrtc.sh)"; \
	LK_CUSTOM_WEBRTC="$$LK_CUSTOM_WEBRTC" cargo test -p roammand-host-webrtc --features native-webrtc; \
	LK_CUSTOM_WEBRTC="$$LK_CUSTOM_WEBRTC" cargo clippy -p roammand-host-webrtc --features native-webrtc --all-targets -- -D warnings; \
	LK_CUSTOM_WEBRTC="$$LK_CUSTOM_WEBRTC" cargo test -p roammand-host-agent --features native-webrtc; \
	LK_CUSTOM_WEBRTC="$$LK_CUSTOM_WEBRTC" cargo clippy -p roammand-host-agent --features native-webrtc --all-targets -- -D warnings

format:
	dart format scripts/validate_m4_smoke_config.dart
	cd apps/client_flutter && dart format lib test tool
	cd gen/dart && dart format lib test
	cargo fmt --all
	gofmt -w services/signaling gen/go
	buf format -w

format-check:
	dart format --output=none --set-exit-if-changed scripts/validate_m4_smoke_config.dart
	cd apps/client_flutter && dart format --output=none --set-exit-if-changed lib test tool
	cd gen/dart && dart format --output=none --set-exit-if-changed lib test
	cargo fmt --all --check
	./scripts/check_go_format.sh
	buf format --diff --exit-code

generate:
	./scripts/generate_protocol.sh

generate-failure-check:
	./scripts/check_generation_failure_atomicity.sh

generate-check: generate-failure-check generate
	git diff --exit-code -- gen

schema-lint:
	buf lint

schema-build:
	buf build

schema-breaking:
	buf breaking --against '$(BUF_BREAKING_AGAINST)'

test-conformance:
	cd gen/dart && dart analyze && dart test
	cargo clippy -p roammand-protocol --all-targets -- -D warnings
	cargo test -p roammand-protocol
	cd gen/go && go vet ./... && go test ./...

test-dart:
	cd gen/dart && dart analyze && dart test
	cd apps/client_flutter && flutter analyze && flutter test

test-host:
	cargo clippy -p roammand-host-platform -p roammand-ipc -p roammand-host-agent --all-targets -- -D warnings
	cargo test -p roammand-host-platform -p roammand-ipc -p roammand-host-agent

test-m4-config:
	./scripts/test_m4_smoke_contract.sh

test-m4-lifecycle:
	./scripts/check_m4_lifecycle.sh

test-m4: test-m4-config
	./scripts/run_m4_smoke.sh

test-m5-config:
	./scripts/test_m5_smoke_contract.sh

test-m5-lifecycle:
	./scripts/check_m5_lifecycle.sh

test-m5: test-m5-config
	./scripts/run_m5_smoke.sh

test-m6-config:
	./scripts/test_m6_smoke_contract.sh

test-m6-lifecycle:
	./scripts/check_m6_lifecycle.sh

test-m6: test-m6-config
	./scripts/run_m6_smoke.sh

test-m7-config:
	./scripts/check_m7_self_hosting.sh
	./scripts/test_m7_smoke_contract.sh

test-m7-reconnect:
	./scripts/check_m7_reconnect.sh

test-m7-privacy:
	./scripts/check_m7_privacy.sh

test-m7-fuzz:
	cd services/signaling && go test ./...
	cd services/signaling && go test ./internal/service -run='^$$' -fuzz=FuzzDecodeClientFrame -fuzztime=2s
	cd services/signaling && go test ./internal/transport -run='^$$' -fuzz=FuzzBoundedBinaryCopy -fuzztime=2s
	cargo test -p roammand-ipc --test framing
	cargo test -p roammand-host-webrtc --test input deterministic_arbitrary_data_channel_payloads_fail_closed

test-m7: test-m7-config test-m7-reconnect test-m7-privacy test-m7-fuzz
	./scripts/run_m7_smoke.sh
	./scripts/run_m7_soak.sh --duration-seconds 3 --devices 1 --sample-interval 1

test-m8-config:
	./scripts/test_m8_smoke_contract.sh
	./scripts/check_m8_bridge_contract.sh

test-m8-privacy:
	./scripts/check_m8_privacy.sh

test-m8: test-m8-config test-m8-privacy
	./scripts/run_m8_smoke.sh

test-rust:
	cargo clippy --workspace --all-targets -- -D warnings
	cargo test --workspace

test-go: test-signaling
	cd gen/go && go vet ./... && go test ./...

test-signaling:
	cd services/signaling && go vet ./... && go test ./...

test-signaling-race:
	cd services/signaling && go test -race ./...

test-schema: test-schema-contract schema-lint schema-build schema-breaking generate-check

test-schema-contract:
	./scripts/check_schema_contract.sh

test: boundary test-schema test-conformance test-dart test-rust test-go
