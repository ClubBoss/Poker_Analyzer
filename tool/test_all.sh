#!/bin/bash
set -e

ensure_flutter() {
  if ! command -v flutter >/dev/null 2>&1; then
    echo "Flutter is not installed or not in PATH. Please install Flutter and try again." >&2
    exit 1
  fi
}

ensure_flutter
flutter analyze
flutter test
