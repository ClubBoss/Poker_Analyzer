#!/usr/bin/env bash
set -e

THEORY_DIRS=${THEORY_DIRS:-"theory,yaml_out"}
IFS=',' read -ra WATCH <<< "$THEORY_DIRS"

STAGED=$(git diff --cached --name-only --diff-filter=ACM -- "${WATCH[@]}" | grep '\.yaml$' || true)
if [ -z "$STAGED" ]; then
  exit 0
fi

DIRS=$(echo "$STAGED" | xargs -r dirname | sort -u)
ARGS=""
for d in $DIRS; do
  ARGS+=" --dir $d"
done

echo "Running poker_analyzer verify on: $DIRS"
if ! dart run bin/poker_analyzer.dart verify $ARGS --manifest theory_manifest.json --ci; then
  echo
  echo "Theory verification failed. Run:" 
  echo "  dart run bin/poker_analyzer.dart sweep $ARGS --fix --manifest theory_manifest.json"
  echo "  dart run bin/poker_analyzer.dart manifest update $ARGS"
  echo "to fix and update the manifest."
  exit 1
fi
