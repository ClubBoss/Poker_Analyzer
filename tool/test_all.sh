#!/bin/bash
set -euo pipefail
# Enable strict mode to exit on errors, unset variables, and pipeline failures.
flutter analyze
flutter test
