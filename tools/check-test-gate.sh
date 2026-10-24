#!/usr/bin/env bash
# AC-37 gate: `mise run test` must exit non-zero when any test fails or a test
# script cannot even load. Plants a failing test and a broken script, expects
# tools/run-tests.sh to fail for each, then removes them.
set -euo pipefail
source "$(dirname "$0")/env.sh"
dir="$GAME/tests"
fail_file="$dir/test_ac_zz_gate_fail.gd"
broken_file="$dir/test_ac_zz_gate_broken.gd"
trap 'rm -f "$fail_file" "$broken_file" "$fail_file.uid" "$broken_file.uid"' EXIT
expect_failure() {
  if "$REPO_ROOT/tools/run-tests.sh" >/dev/null 2>&1; then
    echo "TEST GATE FAIL: run-tests.sh passed with $1"; exit 1
  fi
  echo "TEST GATE OK: run-tests.sh fails on $1"
}
cat > "$fail_file" <<'GD'
extends SceneTree
func _init() -> void:
	print("FAIL planted failure")
	print("FAILURES: 1")
	quit(1)
GD
expect_failure "a failing test"
rm -f "$fail_file"
printf 'extends SceneTree\nfunc _init() -> void:\n\tthis is not valid gdscript\n' > "$broken_file"
expect_failure "a script that does not load"
rm -f "$broken_file"
"$REPO_ROOT/tools/run-tests.sh" >/dev/null || { echo "TEST GATE FAIL: clean run-tests.sh failed"; exit 1; }
echo "TEST GATE OK: run-tests.sh passes on the real suite"
