#!/usr/bin/env bash
set -euo pipefail

MODE="${MODE:-}"
if [[ -z "${MODE}" && "${1:-}" == "--mode" ]]; then
  MODE="${2:-}"
fi

REPORT_DIR="${REPORT_DIR:-build/theory_report}"

if [[ ! -d "$REPORT_DIR" ]] || [[ -z "$(ls -A "$REPORT_DIR" 2>/dev/null || true)" ]]; then
  echo "no report (no theory changes) — skipping verification"
  exit 0
fi

dart run bin/ci_report.dart --mode "$MODE"
