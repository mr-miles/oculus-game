#!/usr/bin/env bash
# Render docs/screenshots/*.png from the real scenes (lobby, HUD, trees, a move).
# Needs a display: runs Godot under Xvfb (xvfb-run) with the OpenGL renderer
# (Mesa software GL is enough). Not part of `mise run build`.
set -euo pipefail
source "$(dirname "$0")/env.sh"
command -v xvfb-run >/dev/null || { echo "xvfb-run not found (install xvfb)"; exit 1; }
cd "$GAME"
"$GODOT" --headless --path . --import >/dev/null 2>&1 || true
xvfb-run -a -s "-screen 0 1280x720x24" "$GODOT" --path . --rendering-driver opengl3 \
  --audio-driver Dummy --script res://tests/capture_screenshots.gd -- "$REPO_ROOT/docs/screenshots"
