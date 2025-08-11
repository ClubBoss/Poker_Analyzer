#!/usr/bin/env bash
# Ensure android/local.properties has flutter.sdk path for Gradle builds.
# Detects Flutter SDK via FLUTTER_SDK, FLUTTER_HOME or `which flutter`.
# Idempotent and exits 0 even if SDK not found.

set -u
set -o pipefail

# Determine SDK path
sdk="${FLUTTER_SDK:-${FLUTTER_HOME:-}}"
if [ -z "$sdk" ]; then
  if command -v flutter >/dev/null 2>&1; then
    # flutter binary path -> remove /bin/flutter
    binpath="$(command -v flutter)"
    sdk="$(dirname "$(dirname "$binpath")")"
  fi
fi

if [ -n "$sdk" ]; then
  propfile="android/local.properties"
  mkdir -p "$(dirname "$propfile")"
  if [ -f "$propfile" ] && grep -q '^flutter\.sdk=' "$propfile"; then
    # replace existing value if different
    current="$(grep '^flutter\.sdk=' "$propfile" | head -n1 | cut -d'=' -f2-)"
    if [ "$current" != "$sdk" ]; then
      sed -i.bak "s|^flutter\.sdk=.*|flutter.sdk=$sdk|" "$propfile" && rm -f "$propfile.bak"
    fi
  else
    echo "flutter.sdk=$sdk" >> "$propfile"
  fi
fi

exit 0
