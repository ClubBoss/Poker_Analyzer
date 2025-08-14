#!/usr/bin/env bash
set -euo pipefail

# --- args/env ---
MODE="${MODE:-strict}"

# allow CLI overrides: --mode <v>, --report-dir <dir>
REPORT_DIR_DEFAULT="build/theory_report"
REPORT_DIR="${REPORT_DIR:-$REPORT_DIR_DEFAULT}"
while [[ "${1:-}" =~ ^-- ]]; do
  case "$1" in
    --mode)        MODE="${2:-$MODE}";        shift 2 || true ;;
    --report-dir)  REPORT_DIR="${2:-$REPORT_DIR}"; shift 2 || true ;;
    *) shift ;;
  esac
done

echo "Theory verifier:"
echo "  MODE=${MODE}"
echo "  REPORT_DIR=${REPORT_DIR}"

# --- Early success when there is nothing to verify ---
if [[ ! -d "$REPORT_DIR" ]] || [[ -z "$(ls -A "$REPORT_DIR" 2>/dev/null || true)" ]]; then
  echo "no report (no theory changes) - skipping verification"
  echo "::notice title=Theory Integrity::No theory changes detected; verifier skipped."
  exit 0
fi

# --- Strict verification (single call) ---
if ! dart run bin/ci_report.dart --mode "${MODE}"; then
  echo "::error title=Theory Integrity::Violations found"
  exit 1
fi

echo "Theory verification passed."
