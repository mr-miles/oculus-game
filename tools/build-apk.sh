#!/usr/bin/env bash
# Headless build of the Quest APK: plugin -> tests -> Android template -> export -> verify.
# Usage: tools/build-apk.sh [debug|release]   (default debug; debug is signed
# with the debug keystore and installable with adb). Output: game/build/quest-sentinel.apk
set -euo pipefail
source "$(dirname "$0")/env.sh"
MODE="${1:-debug}"
[ -x "$GODOT" ] || { echo "Run tools/setup-toolchain.sh first"; exit 1; }
cd "$GAME"

echo "== plugin"
rm -rf addons; mkdir -p addons; cp -r "$TC/vendors/addons/godotopenxrvendors" addons/

echo "== import + tests"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
"$GODOT" --headless --path . --script res://tests/test_logic.gd 2>&1 | grep -E "^(PASS|FAIL|FAILURES)"
"$GODOT" --headless --path . --script res://tests/test_scene.gd 2>&1 | grep -E "SCENE|scene smoke"

echo "== android build template"
if [ ! -f android/.build_version ] || [ "$(cat android/.build_version)" != "$GODOT_TEMPLATE_DIR" ]; then
  rm -rf android; mkdir -p android/build
  python3 -I -c "import zipfile,sys;zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" \
    "$HOME/.local/share/godot/export_templates/$GODOT_TEMPLATE_DIR/android_source.zip" android/build
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
