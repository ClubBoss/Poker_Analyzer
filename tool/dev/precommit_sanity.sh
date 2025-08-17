#!/usr/bin/env bash
set -euo pipefail

dart format --set-exit-if-changed .
dart analyze
echo "ok"

