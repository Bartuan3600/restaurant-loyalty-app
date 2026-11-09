#!/usr/bin/env bash
# App Studio starten -> http://localhost:8787
cd "$(dirname "$0")"
[ -n "$ANDROID_ENV" ] && . "$ANDROID_ENV"
[ -n "$FLUTTER_HOME" ] && export PATH="$FLUTTER_HOME/bin:$PATH"
exec python3 studio/server.py
