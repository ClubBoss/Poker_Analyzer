#!/usr/bin/env bash
set -euo pipefail
set -x

# format L3 scope (не fail-on-diff)
dart format -o write tool/l3 lib/l3 test/l3_cli_runner_weights_parse_test.dart test/fixtures/l3/weights

# deps
if grep -q 'sdk: flutter' pubspec.yaml; then flutter pub get; else dart pub get; fi

# analyze L3 only (warnings fatal)
dart analyze tool/l3 lib/l3 test/l3_cli_runner_weights_parse_test.dart --fatal-warnings
