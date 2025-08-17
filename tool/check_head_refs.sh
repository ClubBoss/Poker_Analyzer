#!/bin/bash
# Check for hidden characters in git HEAD and ref files.

set -e

echo "Checking git HEAD and ref files for hidden characters..."

check_file() {
  local file="$1"
  if [ ! -f "$file" ]; then
    return
  fi
  if LC_ALL=C grep -nP '[\x00-\x08\x0b\x0c\x0e-\x1F\x7F-\x9F]' "$file" >/dev/null; then
    echo "Hidden characters detected in $file:" >&2
    LC_ALL=C grep -nP '[\x00-\x08\x0b\x0c\x0e-\x1F\x7F-\x9F]' -n "$file" >&2
    return 1
  fi
}

error=0
check_file .git/HEAD || error=1
for ref in .git/refs/heads/*; do
  check_file "$ref" || error=1
done

if [ $error -eq 0 ]; then
  echo "No hidden characters found."
else
  echo "Hidden characters were found. Consider rewriting the affected ref file(s)."
fi

