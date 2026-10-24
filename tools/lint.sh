#!/usr/bin/env bash
# GDScript lint: Godot parses every script in game/ (and checks its warnings).
# Exit 1 on any parse error or warning. OpenXR start-up noise in headless runs is ignored.
set -euo pipefail
source "$(dirname "$0")/env.sh"
cd "$GAME"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
fail=0
while IFS= read -r f; do
  out=$("$GODOT" --headless --path . --check-only --script "res://${f#./}" 2>&1 || true)
  bad=$(echo "$out" | grep -E "SCRIPT ERROR|Parse Error|^WARNING|^ERROR" | grep -vi openxr | grep -v "ObjectDB" || true)
  if [ -n "$bad" ]; then echo "LINT FAIL $f"; echo "$bad"; fail=1; fi
done < <(find . -name '*.gd' -not -path './addons/*' -not -path './.godot/*' | sort)
[ "$fail" = 0 ] && echo "LINT OK"
exit "$fail"
