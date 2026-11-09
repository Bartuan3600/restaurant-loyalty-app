#!/usr/bin/env bash
# iOS-Projekt für einen Tenant als ZIP -> dist/<id>-ios-<version>.zip (auf dem Mac entpacken, siehe MAC_ANLEITUNG.md)
set -euo pipefail; cd "$(dirname "$0")/.."
ID="${1:?usage: tools/export_ios.sh <tenant-id>}"
python3 tools/apply_tenant.py "$ID"
VN=$(python3 -c "import json;print(json.load(open('tenants/$ID/tenant.json'))['versionName'])")
mkdir -p dist; OUT="$PWD/dist/$ID-ios-$VN.zip"; rm -f "$OUT"
NAME="$ID-ios"; TMP=$(mktemp -d); mkdir "$TMP/$NAME"
# nur was der Mac braucht – keine Keystores, keine Builds, keine anderen Tenants
cp -r lib assets ios test pubspec.yaml pubspec.lock analysis_options.yaml MAC_ANLEITUNG.md "$TMP/$NAME/"
mkdir -p "$TMP/$NAME/tenants"; cp -r "tenants/$ID" "$TMP/$NAME/tenants/"
rm -rf "$TMP/$NAME/ios/Pods" "$TMP/$NAME/ios/.symlinks" "$TMP/$NAME/ios/Flutter/ephemeral"
(cd "$TMP" && python3 -c "import shutil,sys;shutil.make_archive(sys.argv[1][:-4],'zip','.',sys.argv[2])" "$OUT" "$NAME"); rm -rf "$TMP"
echo "ZIP: $OUT ($(du -h "$OUT" | cut -f1))"
