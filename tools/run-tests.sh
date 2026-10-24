#!/usr/bin/env bash
# Headless tests. Exit 1 on any failure.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$GAME"
rm -rf addons; mkdir -p addons; cp -r "$VENDORS_DIR/addons/godotopenxrvendors" addons/ 2>/dev/null \
  || cp -r "$(find "$VENDORS_DIR" -type d -name godotopenxrvendors | head -1)" addons/
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
out=$("$GODOT" --headless --path . --script res://tests/test_ac_logic.gd 2>&1 || true)
echo "$out" | grep -E "^(PASS|FAIL|FAILURES)"
echo "$out" | grep -q "^FAILURES: 0" || { echo "logic tests failed"; exit 1; }
out=$("$GODOT" --headless --path . --script res://tests/test_scene.gd 2>&1 || true)
echo "$out" | grep -E "SCENE|scene smoke"
echo "$out" | grep -q "SCENE PASS" || { echo "scene smoke test failed"; exit 1; }
