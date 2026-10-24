#!/usr/bin/env bash
# Headless tests. Runs every game/tests/test_ac_*.gd (one Godot process each) and
# the scene smoke test. Exit 1 on any failure, script error or missing result.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$GAME"
rm -rf addons; mkdir -p addons; cp -r "$VENDORS_DIR/addons/godotopenxrvendors" addons/ 2>/dev/null \
  || cp -r "$(find "$VENDORS_DIR" -type d -name godotopenxrvendors | head -1)" addons/
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
failed=0
for f in tests/test_ac_*.gd; do
  out=$("$GODOT" --headless --path . --script "res://$f" 2>&1 || true)
  echo "$out" | grep -E "^(PASS|FAIL|FAILURES)" || true
  if echo "$out" | grep -qE "^SCRIPT ERROR|^FAIL "; then failed=1; fi
  echo "$out" | grep -q "^FAILURES: 0" || { echo "$f failed"; failed=1; }
done
out=$("$GODOT" --headless --path . --script res://tests/test_scene.gd 2>&1 || true)
echo "$out" | grep -E "SCENE|scene smoke"
echo "$out" | grep -q "SCENE PASS" || { echo "scene smoke test failed"; failed=1; }
exit $failed
