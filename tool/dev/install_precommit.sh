#!/usr/bin/env bash
set -e

mkdir -p .git/hooks
cat > .git/hooks/pre-commit <<'H'
#!/usr/bin/env bash
exec bash tool/dev/precommit_sanity.sh
H
chmod +x .git/hooks/pre-commit tool/dev/precommit_sanity.sh
echo "pre-commit hook installed"
