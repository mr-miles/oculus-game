#!/usr/bin/env bash
# AC-38 gate: no person names in the repository (game text, assets, docs).
# Usage: tools/check-names.sh <names-file> [dir]
#   names-file: one name per line, kept OUTSIDE the repo (CI supplies it).
#   dir: tree to scan (default: the repo root). Exit 1 if any name appears
#   as a whole word in any file (case-insensitive), in file contents or paths.
set -euo pipefail
names="${1:?usage: check-names.sh <names-file> [dir]}"
root="${2:-$(cd "$(dirname "$0")/.." && pwd)}"
[ -s "$names" ] || { echo "names file is empty or missing: $names"; exit 2; }
fail=0
while IFS= read -r name; do
  [ -n "$name" ] || continue
  if grep -r -I -i -w -n --exclude-dir=.git --exclude-dir=.toolchain --exclude-dir=.godot -e "$name" "$root" \
      || find "$root" -path '*/.git' -prune -o -iname "*$name*" -print | grep -q .; then
    echo "NAME GATE FAIL: '$name' found"; fail=1
  fi
done < "$names"
[ "$fail" = 0 ] && echo "NAME GATE OK"
exit "$fail"
