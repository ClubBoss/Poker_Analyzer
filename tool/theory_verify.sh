#!/usr/bin/env bash
set -euo pipefail

MODE=${MODE:-}
if [[ $# -gt 0 ]]; then
  case "$1" in
    --mode)
      MODE="$2"
      shift 2
      ;;
    *)
      MODE="$1"
      shift
      ;;
  esac
fi

REPORT_DIR=${REPORT_DIR:-"build/theory_report"}

if [ ! -d "$REPORT_DIR" ] || [ -z "$(ls -A "$REPORT_DIR" 2>/dev/null || true)" ]; then
  echo "no report (no theory changes) – skipping verification"
  exit 0
fi

dart run bin/ci_report.dart --mode "$MODE"
