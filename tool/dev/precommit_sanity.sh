#!/usr/bin/env bash
set -euo pipefail
set -x

# 1) format check (fail if бы изменил)
dart format --output=none --set-exit-if-changed tool/l3 lib/l3 test/l3_cli_runner_weights_parse_test.dart test/fixtures/l3/weights
  lib/services lib/l3 tool/l3 \
  test/l3_cli_runner_weights_parse_test.dart test/fixtures/l3/weights

# 2) EV scope hygiene (только если каталоги/файлы существуют)
if [ -d lib/ev ] && grep -R -q -e 'package:flutter/' -e 'dart:ui' lib/ev; then
  echo 'EV code must not import Flutter.'
  exit 1
fi
if [ -d test/ev ] && grep -R -q -e 'package:flutter/' -e 'dart:ui' test/ev; then
  echo 'EV tests must not import Flutter.'
  exit 1
fi
if ls bin/ev_* >/dev/null 2>&1 && grep -R -q -e 'package:flutter/' -e 'dart:ui' bin/ev_*; then
  echo 'EV CLI must not import Flutter.'
  exit 1
fi

# 3) EV CLI deps guard (файлы могут отсутствовать — пропускаем)
for file in bin/ev_enrich_jam_fold.dart bin/ev_report_jam_fold.dart bin/ev_summary_jam_fold.dart bin/ev_rank_jam_fold_deltas.dart; do
  [ -f "$file" ] || continue
  if grep -q -e 'package:args' -e 'ArgParser' "$file"; then
    echo "$file must not depend on package:args."
    exit 1
  fi
  if grep -q 'package:path/' "$file"; then
    echo "$file must not depend on package:path."
    exit 1
  fi
done

# 4) flutter deps (если это flutter-проект)
if grep -q 'sdk: flutter' pubspec.yaml; then
  flutter pub get
else
  dart pub get
fi

# 5) analyzer строго по L3-скоупу
dart analyze tool/l3 lib/l3 test/l3_cli_runner_weights_parse_test.dart --fatal-warnings

# Тесты контракта запускаются отдельным шагом workflow
