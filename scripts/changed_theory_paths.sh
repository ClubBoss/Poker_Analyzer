#!/usr/bin/env bash
set -euo pipefail

BASE=${1:-main}
THEORY_DIRS=${THEORY_DIRS:-"theory,yaml_out"}
IFS=',' read -ra WATCH <<< "$THEORY_DIRS"

git fetch origin "$BASE" >/dev/null 2>&1 || true
FILES=$(git diff --name-only "origin/${BASE}"...HEAD -- "${WATCH[@]}" | grep '\.yaml$' || true)
if [ -z "$FILES" ]; then
  exit 0
fi

echo "$FILES" | xargs -r dirname | sort -u
