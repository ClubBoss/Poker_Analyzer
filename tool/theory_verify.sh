#!/usr/bin/env bash
set -euo pipefail

MODE="${MODE:-}"
if [[ -z "${MODE}" && "${1:-}" == "--mode" ]]; then
  MODE="${2:-}"
  shift 2 || true
fi

REPORT_DIR_DEFAULT="build/theory_report"
REPORT_DIR="${REPORT_DIR:-$REPORT_DIR_DEFAULT}"
if [[ "${1:-}" == "--report-dir" ]]; then
  REPORT_DIR="${2:-$REPORT_DIR_DEFAULT}"
  shift 2 || true
fi

if [[ ! -d "$REPORT_DIR" ]] || [[ -z "$(ls -A "$REPORT_DIR" 2>/dev/null || true)" ]]; then
  echo "no report (no theory changes) — skipping verification"
  echo "::notice title=Theory Integrity::No theory changes detected; verifier skipped."
  exit 0
fi

dart run bin/ci_report.dart --mode "$MODE"
