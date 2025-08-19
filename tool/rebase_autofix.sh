#!/usr/bin/env bash
set -euo pipefail

conflicts=$(git diff --name-only --diff-filter=U || true)
if [ -z "$conflicts" ]; then
  echo "Nothing to fix (no conflicts)."
  exit 0
fi

echo "$conflicts" | grep -E '(\.g\.dart$|/generated/|^lib/l10n/|^linux/flutter/|^macos/Flutter/)' | \
xargs -I{} git checkout --theirs "{}" 2>/dev/null || true

git add -A

if [ -f pubspec.yaml ]; then dart pub get || true; fi
dart format --output=none --set-exit-if-changed .
dart analyze

git rebase --continue
