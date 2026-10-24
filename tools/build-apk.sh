#!/usr/bin/env bash
# Headless build of the Quest APK: plugin -> tests -> Android template -> export -> verify.
# Usage: tools/build-apk.sh [debug|release]   (default debug; debug is signed
# with the debug keystore and installable with adb). Output: game/build/quest-sentinel.apk
set -euo pipefail
source "$(dirname "$0")/env.sh"
MODE="${1:-debug}"
cd "$GAME"

echo "== plugin + tests"
"$REPO_ROOT/tools/run-tests.sh"
echo "== lint"
"$REPO_ROOT/tools/lint.sh"

echo "== android build template"
if [ ! -f android/.build_version ] || [ "$(cat android/.build_version)" != "$GODOT_TEMPLATE_DIR" ]; then
  rm -rf android; mkdir -p android/build
  python3 -I -c "import zipfile,sys;zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" \
    "$XDG_DATA_HOME/godot/export_templates/$GODOT_TEMPLATE_DIR/android_source.zip" android/build
  chmod +x android/build/gradlew
  touch android/build/.gdignore
  echo -n "$GODOT_TEMPLATE_DIR" > android/.build_version
fi

echo "== export ($MODE)"
mkdir -p build; rm -f build/quest-sentinel.apk
"$GODOT" --headless --path . --export-$MODE Quest build/quest-sentinel.apk 2>&1 | grep -v -E "^\s*$|\[ *[0-9]+%|DONE" | tail -40 || true
[ -f build/quest-sentinel.apk ] || { echo "BUILD FAILED: no APK produced"; exit 1; }

echo "== verify"
"$REPO_ROOT/tools/verify-apk.sh" build/quest-sentinel.apk
