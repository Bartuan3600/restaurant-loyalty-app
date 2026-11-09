#!/usr/bin/env bash
# Signed release APK for one tenant -> dist/<id>-<version>.apk  (keystore auto-created on first build)
set -euo pipefail; cd "$(dirname "$0")/.."
ID="${1:?usage: tools/build_apk.sh <tenant-id>}"
[ -n "$ANDROID_ENV" ] && . "$ANDROID_ENV"
[ -n "$FLUTTER_HOME" ] && export PATH="$FLUTTER_HOME/bin:$PATH"
KP="keystores/$ID.properties"
if [ ! -f "$KP" ]; then
  mkdir -p keystores; PW=$(python3 -c 'import secrets;print(secrets.token_urlsafe(24))')
  keytool -genkeypair -keystore "keystores/$ID.jks" -alias "$ID" -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass "$PW" -keypass "$PW" -dname "CN=$ID, O=Loyalty Demo, C=DE" >/dev/null 2>&1
  printf 'storeFile=%s\nstorePassword=%s\nkeyAlias=%s\nkeyPassword=%s\n' "$PWD/keystores/$ID.jks" "$PW" "$ID" "$PW" > "$KP"
  chmod 600 "$KP" "keystores/$ID.jks"; echo "Neuer Keystore: keystores/$ID.jks (SICHERN! Ohne ihn keine Updates.)"
fi
python3 tools/apply_tenant.py "$ID"
flutter build apk --release --target-platform android-arm,android-arm64
VN=$(python3 -c "import json;print(json.load(open('tenants/$ID/tenant.json'))['versionName'])")
mkdir -p dist; OUT="dist/$ID-$VN.apk"; cp build/app/outputs/flutter-apk/app-release.apk "$OUT"
BT=$(for d in $(ls -d "${ANDROID_HOME:?set ANDROID_HOME}"/build-tools/* | sort -V); do [ -x "$d/apksigner" ] && echo "$d"; done | tail -1)
"$BT/aapt2" dump badging "$OUT" | head -1 || true
"$BT/apksigner" verify --print-certs "$OUT" | grep -E "SHA-256|DN"
sha256sum "$OUT"
echo "APK: $PWD/$OUT"
