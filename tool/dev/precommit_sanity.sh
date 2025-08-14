#!/usr/bin/env bash
set -euo pipefail

FILES=$(git diff --name-only -- '*.dart')
if [[ -n "$FILES" ]]; then
  dart format -o write $FILES
fi

# Guard checks for EV scope hygiene
if grep -R -q -e 'package:flutter/' -e 'dart:ui' lib/ev test/ev bin/ev*; then
  echo 'EV code must not import Flutter.'
  exit 1
fi

if grep -R -q 'package:args' bin/ev_enrich_jam_fold.dart || grep -R -q 'ArgParser' bin/ev_enrich_jam_fold.dart; then
  echo 'bin/ev_enrich_jam_fold.dart must not depend on package:args.'
  exit 1
fi

if grep -R -q 'sdk: flutter' pubspec.yaml; then
  if ! command -v flutter >/dev/null 2>&1; then
    echo 'SKIP analyze/test (no Flutter SDK)'
    exit 0
  fi
  flutter pub get -q
fi

dart analyze lib/ev bin test/ev --fatal-warnings --fatal-infos
dart test test/ev/jam_fold_evaluator_test.dart
