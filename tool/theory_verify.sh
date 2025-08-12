#!/usr/bin/env bash
set -euo pipefail

# Resolve report dir (defaults to build/theory_report); can be overridden by REPORT_DIR env
REPORT_DIR_DEFAULT="build/theory_report"
REPORT_DIR="${REPORT_DIR:-$REPORT_DIR_DEFAULT}"

echo "Theory verifier: MODE=${MODE:-strict}"
echo "REPORT_DIR=${REPORT_DIR}"

# --- Early success when no report to check ---
if [[ ! -d "$REPORT_DIR" ]] || [[ -z "$(ls -A "$REPORT_DIR" 2>/dev/null || true)" ]]; then
  echo "no report (no theory changes) — skipping verification"
  echo "::notice title=Theory Integrity::No theory changes detected; verifier skipped."
  exit 0
fi

# --- Existing strict verification logic below ---
if ! dart run bin/ci_report.dart --mode "${MODE:-strict}"; then
  echo "::error title=Theory Integrity::Violations found"
  exit 1
fi

echo "Theory verification passed."
