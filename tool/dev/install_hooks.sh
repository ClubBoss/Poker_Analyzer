#!/usr/bin/env bash
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel)"
HOOK="$ROOT/.git/hooks/pre-commit"
cat > "$HOOK" <<'H'
#!/usr/bin/env bash
set -e
bash tool/dev/precommit_sanity.sh
H
chmod +x "$HOOK"
echo "pre-commit hook installed -> tool/dev/precommit_sanity.sh"
