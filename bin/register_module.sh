#!/usr/bin/env bash
set -euo pipefail
id="${1:?usage: register_module.sh <module_id>}"
short="${2:-"TBD short_scope"}"

# 1) dispatcher block (если нет)
if ! grep -q "^module_id: $id$" prompts/dispatcher/_ALL.txt; then
  cat >> prompts/dispatcher/_ALL.txt <<EOF
module_id: $id
short_scope: $short
spotkind_allowlist:
none
target_tokens_allowlist:
none
EOF
fi

# 2) research block (если нет)
grep -q "^GO MODULE: $id$" prompts/research/_ALL.prompts.txt || \
  printf 'GO MODULE: %s\n' "$id" >> prompts/research/_ALL.prompts.txt

# 3) curriculum_ids.dart (если нет — добавить в конец списка)
if ! grep -q "\"$id\"" tooling/curriculum_ids.dart; then
  perl -0777 -pe 's/(\]\s*;)/  "'$id'",\n$1/s' -i tooling/curriculum_ids.dart
fi

dart run tooling/validate_research_outputs.dart --only "$id"
echo "Registered: $id"
