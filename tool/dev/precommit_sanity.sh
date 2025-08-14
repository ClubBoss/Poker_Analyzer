#!/usr/bin/env bash
set -euo pipefail

FILES=$(git diff --name-only -- '*.dart')
if [[ -n "$FILES" ]]; then
  dart format -o write $FILES
fi

dart analyze lib/ev bin test/ev --fatal-warnings --fatal-infos
dart test test/ev/jam_fold_evaluator_test.dart
