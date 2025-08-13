#!/usr/bin/env bash
set -euo pipefail

RED=$'\e[31m'; GRN=$'\e[32m'; NC=$'\e[0m'
fail=0

say_ok(){ echo "${GRN}OK${NC}  $1"; }
say_bad(){ echo "${RED}FAIL${NC} $1"; fail=1; }

# --- Dup checks in CLI --------------------------------------------------------

# 1) single weightsPreset parser
if [[ $(grep -R "addOption('weightsPreset'" tool/l3/pack_run_cli.dart | wc -l) -gt 1 ]]; then
  say_bad "duplicate addOption('weightsPreset') in tool/l3/pack_run_cli.dart"
  grep -n "addOption('weightsPreset'" tool/l3/pack_run_cli.dart || true
else
  say_ok "weightsPreset parser deduped"
fi

# 1b) single addOption('out')
if [[ $(grep -RFn "addOption('out'" tool/l3/pack_run_cli.dart | wc -l) -gt 1 ]]; then
  say_bad "duplicate addOption('out') in tool/l3/pack_run_cli.dart"
  grep -n "addOption('out'" tool/l3/pack_run_cli.dart || true
else
  say_ok "single addOption('out')"
fi

# 1c) single addOption('weights')
if [[ $(grep -RFn "addOption('weights'" tool/l3/pack_run_cli.dart | wc -l) -gt 1 ]]; then
  say_bad "duplicate addOption('weights') in tool/l3/pack_run_cli.dart"
  grep -n "addOption('weights'" tool/l3/pack_run_cli.dart || true
else
  say_ok "single addOption('weights')"
fi

# 1d) single addOption('priors')
if [[ $(grep -RFn "addOption('priors'" tool/l3/pack_run_cli.dart | wc -l) -gt 1 ]]; then
  say_bad "duplicate addOption('priors') in tool/l3/pack_run_cli.dart"
  grep -n "addOption('priors'" tool/l3/pack_run_cli.dart || true
else
  say_ok "single addOption('priors')"
fi

# 2) only one _renderSection in l3_ab_diff.dart (fixed string)
if [[ $(grep -RFn "void _renderSection(" tool/metrics/l3_ab_diff.dart | wc -l) -gt 1 ]]; then
  say_bad "duplicate void _renderSection(...) in tool/metrics/l3_ab_diff.dart"
  grep -n "void _renderSection(" tool/metrics/l3_ab_diff.dart || true
else
  say_ok "_renderSection defined once"
fi

# 3) no stray ternary tails in CLI (?/: 'spr_*' on their own lines)
if grep -nE "^[[:space:]]*[\\?:][[:space:]]*'spr_(low|mid|high)'" tool/l3/pack_run_cli.dart >/dev/null; then
  say_bad "stray ternary tail in tool/l3/pack_run_cli.dart"
  grep -nE "^[[:space:]]*[\\?:][[:space:]]*'spr_(low|mid|high)'" tool/l3/pack_run_cli.dart || true
else
  say_ok "no stray ternary tails in CLI"
fi

# 3b) only one sprBucket declaration (support both styles)
count_eq=$(grep -nE '^[[:space:]]*final[[:space:]]+sprBucket[[:space:]]*=' tool/l3/pack_run_cli.dart | wc -l || true)
count_late=$(grep -nE '^[[:space:]]*late[[:space:]]+final[[:space:]]+String[[:space:]]+sprBucket[[:space:]]*;' tool/l3/pack_run_cli.dart | wc -l || true)
total=$((count_eq + count_late))
if [[ $total -gt 1 ]]; then
  say_bad "multiple sprBucket declarations in CLI (found $total)"
  grep -nE '^[[:space:]]*(final[[:space:]]+sprBucket[[:space:]]*=|late[[:space:]]+final[[:space:]]+String[[:space:]]+sprBucket[[:space:]]*;)' tool/l3/pack_run_cli.dart || true
else
  say_ok "sprBucket declared once or less"
fi

# 4) single default evaluator init
if [[ $(grep -nE '^[[:space:]]*evaluator[[:space:]]*=[[:space:]]*JamFoldEvaluator\(\);' tool/l3/pack_run_cli.dart | wc -l) -gt 1 ]]; then
  say_bad "multiple default evaluator initializations in CLI"
  grep -nE '^[[:space:]]*evaluator[[:space:]]*=[[:space:]]*JamFoldEvaluator\(\);' tool/l3/pack_run_cli.dart || true
else
  say_ok "single default evaluator init"
fi

# --- Formatting / Analyze (scoped) -------------------------------------------

# Scope: if PRECOMMIT_SCOPE=all -> whole repo.
# Else if staged Dart files exist -> format only staged.
# Else -> limit to tool/**, lib/l3/**, test/l3_*.dart (как в CI).
CHANGED_DART=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.dart$' || true)

scope_format_changed() {
  if [[ -n "${CHANGED_DART}" ]]; then
    if dart format --set-exit-if-changed ${CHANGED_DART} >/dev/null 2>&1; then
      say_ok "format clean (changed files)"
    else
      say_bad "formatting needed in changed files (run: dart format ${CHANGED_DART})"
      return 1
    fi
    return 0
  fi
  return 1
}

scope_format_scoped() {
  # собираем список через git ls-files (как в CI); если вдруг git не видит — fallback на find
  FILES="$(git ls-files 'tool/**/*.dart' 'lib/l3/**/*.dart' 'test/l3_*.dart' || true)"
  if [[ -z "${FILES}" ]]; then
    FILES="$( (find tool -type f -name '*.dart' 2>/dev/null; \
               find lib/l3 -type f -name '*.dart' 2>/dev/null; \
               find test -maxdepth 1 -type f -name 'l3_*.dart' 2>/dev/null) | tr '\n' ' ' )"
  fi

  if [[ -z "${FILES// /}" ]]; then
    say_ok "format scope empty (tool/lib/l3/test l3_*)"
    return 0
  fi

  if dart format --set-exit-if-changed ${FILES} >/dev/null 2>&1; then
    say_ok "format clean (tool, lib/l3, test/l3_*)"
  else
    say_bad "formatting needed (run: dart format ${FILES})"
    # покажем, что именно меняет форматтер (не валим шаг дополнительно)
    dart format ${FILES} | sed 's/^/  /' || true
  fi
}

scope_format_all() {
  if dart format --set-exit-if-changed lib tool test >/dev/null 2>&1; then
    say_ok "format clean (all)"
  else
    say_bad "formatting needed (run: dart format lib tool test)"
  fi
}

# 5) Format
if ! command -v dart >/dev/null 2>&1; then
  say_bad "Dart SDK not found in PATH (skip format/analyze)"
else
  if [[ "${PRECOMMIT_SCOPE:-}" == "all" ]]; then
    scope_format_all
  else
    scope_format_changed || scope_format_scoped
  fi
fi

# 6) Analyze (tooling/L3 by default; PRECOMMIT_SCOPE=all -> lib/test целиком)
if command -v dart >/dev/null 2>&1; then
  if [[ "${PRECOMMIT_SCOPE:-}" == "all" ]]; then
    TARGETS=("tool" "lib" "test")
  else
    TARGETS=("tool" "lib/l3")
    if compgen -G "test/l3_*.dart" >/dev/null 2>&1; then
      # раскладываем в массив, чтобы bash не склеил одним аргументом
      while IFS= read -r f; do TARGETS+=("$f"); done < <(ls test/l3_*.dart 2>/dev/null || true)
    fi
  fi

  if dart analyze "${TARGETS[@]}" >/dev/null 2>&1; then
    say_ok "dart analyze (${TARGETS[*]})"
  else
    say_bad "dart analyze has issues in scoped targets (${TARGETS[*]})"
  fi
fi

exit $fail
