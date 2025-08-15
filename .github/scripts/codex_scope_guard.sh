#!/usr/bin/env bash
set -euo pipefail
ALLOW_RE='^(bin/|test/ev/|tool/l3/|lib/l3/|\.github/|README\.md|docs/)'
BASE_REF="${GITHUB_BASE_REF:-main}"
git fetch --no-tags --depth=50 origin "${BASE_REF}" >/dev/null 2>&1 || true
if git rev-parse -q --verify "origin/${BASE_REF}" >/dev/null; then
  RANGE="origin/${BASE_REF}...HEAD"
else
  RANGE="HEAD~1...HEAD"
fi
CHANGED="$(git diff --name-only $RANGE || true)"
if echo "$CHANGED" | grep -E -v "$ALLOW_RE" | grep -q '.'; then
  echo "::notice title=Codex scope guard::Out-of-scope changes detected; skipping auto-actions."
  exit 78
fi
echo "Scope OK — only allowed paths changed."
