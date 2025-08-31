#!/usr/bin/env bash
set -euo pipefail
id="$1"
dart run tooling/compose_prompt_for_id.dart --id "$id" \
| awk '1; /^GO MODULE:/{print ""; system("cat tooling/images_contract.txt")}'
