#!/usr/bin/env bash
# Screenshots of all screens for one tenant -> screenshots/<id>/*.png
set -euo pipefail; cd "$(dirname "$0")/.."
ID="${1:?usage: tools/screenshots.sh <tenant-id>}"
[ -n "$ANDROID_ENV" ] && . "$ANDROID_ENV"; [ -n "$FLUTTER_HOME" ] && export PATH="$FLUTTER_HOME/bin:$PATH"
python3 tools/apply_tenant.py "$ID"
rm -rf "screenshots/$ID"; flutter test --update-goldens test/screenshot_test.dart
ls "screenshots/$ID"
