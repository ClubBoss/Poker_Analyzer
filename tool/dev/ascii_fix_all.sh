#!/usr/bin/env bash
set -euo pipefail
paths=(README.md lib test tool docs)
git ls-files "${paths[@]}" | xargs perl -CSAD -pi -e \
's/\x{2013}|\x{2014}/-/g; s/\x{2026}/.../g; s/[\x{2018}\x{2019}]/'"'"'/g; s/[\x{201C}\x{201D}]/"/g; s/\x{00A0}/ /g;'
