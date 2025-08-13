#!/usr/bin/env bash
set -euo pipefail

RED=$'\e[31m'; GRN=$'\e[32m'; NC=$'\e[0m'
fail=0

say_ok(){ echo "${GRN}OK${NC}  $1"; }
say_bad(){ echo "${RED}FAIL${NC} $1"; fail=1; }

# 1) Не должно быть дублей weightsPreset в парсере CLI
if [[ $(grep -R "addOption('weightsPreset'" tool/l3/pack_run_cli.dart | wc -l) -gt 1 ]]; then
  say_bad "duplicate addOption('weightsPreset') in tool/l3/pack_run_cli.dart"
  grep -n "addOption('weightsPreset'" tool/l3/pack_run_cli.dart || true
else
  say_ok "weightsPreset parser deduped"
fi

# 2) Не более одного определения _renderSection в A/B диффе
if [[ $(grep -R "void _renderSection\\(" tool/metrics/l3_ab_diff.dart | wc -l) -gt 1 ]]; then
  say_bad "duplicate void _renderSection(...) in tool/metrics/l3_ab_diff.dart"
  grep -n "void _renderSection\\(" tool/metrics/l3_ab_diff.dart || true
else
  say_ok "_renderSection defined once"
fi

# 3) Не должно быть «голых» строк тернарника (мусор '? spr_*' или ': spr_*')
if grep -nE "^[[:space:]]*[?:].*'spr_(low|mid|high)'" tool/l3/pack_run_cli.dart >/dev/null; then
  say_bad "stray ternary tail in tool/l3/pack_run_cli.dart"
  grep -nE "^[[:space:]]*[?:].*'spr_(low|mid|high)'" tool/l3/pack_run_cli.dart || true
else
  say_ok "no stray ternary tails in CLI"
fi

# 4) Инициализация evaluator не должна повторяться «по дефолту»
# (больше одного 'evaluator = JamFoldEvaluator();' подозрительно)
if [[ $(grep -n "evaluator[[:space:]]*=[[:space:]]*JamFoldEvaluator\\(\\);" tool/l3/pack_run_cli.dart | wc -l) -gt 1 ]]; then
  say_bad "multiple default evaluator initializations in CLI"
  grep -n "evaluator[[:space:]]*=[[:space:]]*JamFoldEvaluator\\(\\);" tool/l3/pack_run_cli.dart || true
else
  say_ok "single default evaluator init"
fi

# 5) Быстрый формат-чек (не правит, только валит при расхождении)
if dart format --set-exit-if-changed lib tool test >/dev/null 2>&1; then
  say_ok "format clean"
else
  say_bad "formatting needed: run 'dart format lib tool test'"
fi

# 6) Быстрый анализ (если SDK на месте)
if command -v dart >/dev/null 2>&1; then
  if dart analyze >/dev/null 2>&1; then
    say_ok "dart analyze"
  else
    say_bad "dart analyze has issues"
  fi
fi

exit $fail
