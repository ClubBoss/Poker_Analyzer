#!/usr/bin/env bash
set -euo pipefail

SEED="${SEED:-111}"
PRESET="${PRESET:-paired}"   # paired|unpaired|ace-high|all

echo "[L3 sanity] flutter pub get"
flutter pub get >/dev/null

out_dir="build/tmp/l3/${SEED}"
rep_dir="build/reports"
mkdir -p "$out_dir" "$rep_dir"

echo "[L3 sanity] generate boards seed=${SEED} preset=${PRESET}"
dart run tool/autogen/l3_board_generator.dart \
  --preset "${PRESET}" \
  --seed "${SEED}" \
  --out "${out_dir}" \
  --maxAttemptsPerSpot 5000 \
  --timeoutSec 90

echo "[L3 sanity] pack_run default"
dart run tool/l3/pack_run_cli.dart \
  --dir "${out_dir}" \
  --out "${rep_dir}/l3_packrun_${SEED}.json" \
  --weightsPreset default

echo "[L3 sanity] pack_run aggro"
dart run tool/l3/pack_run_cli.dart \
  --dir "${out_dir}" \
  --out "${rep_dir}/l3_packrun_aggro.json" \
  --weightsPreset aggro

echo "[L3 sanity] A/B diff"
dart run tool/metrics/l3_ab_diff.dart \
  --base "${rep_dir}/l3_packrun_${SEED}.json" \
  --challenger "${rep_dir}/l3_packrun_aggro.json" \
  --out "${rep_dir}/l3_ab_${SEED}.md"

echo "[L3 sanity] metrics report"
dart run tool/metrics/l3_packrun_report.dart \
  --reports "${rep_dir}/l3_packrun_${SEED}.json,${rep_dir}/l3_packrun_aggro.json" \
  --out "${rep_dir}/l3_report_${SEED}.md"

echo
echo "Done:"
echo "  - ${rep_dir}/l3_packrun_${SEED}.json"
echo "  - ${rep_dir}/l3_packrun_aggro.json"
echo "  - ${rep_dir}/l3_ab_${SEED}.md"
echo "  - ${rep_dir}/l3_report_${SEED}.md"
