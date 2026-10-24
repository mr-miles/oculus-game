# Shared settings. Source, don't run. Run via `mise run ...` (or `mise exec -- ...`) so
# JAVA_HOME/PATH/ANDROID_HOME come from mise.toml.
[ -n "${QUEST_ENV_DONE:-}" ] && return 0   # already sourced by a parent script (XDG dirs changed below)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT
export GAME="$REPO_ROOT/game"
export GODOT_TEMPLATE_DIR=4.7.2.stable
export BUILD_TOOLS_VERSION=35.0.1
: "${ANDROID_HOME:?run through mise: mise run setup / build}"
: "${TOOLCHAIN_DIR:?run through mise}"
# The aqua package ships the editor as Godot_v<version>_linux.x86_64 (no `godot` alias).
GODOT="$(ls "$(mise where godot)"/Godot_v*_linux.x86_64 2>/dev/null | head -1)"; export GODOT
[ -x "$GODOT" ] || { echo "godot not found: run 'mise install'"; return 1 2>/dev/null || exit 1; }
JAVA_HOME="$(mise where java)"; export JAVA_HOME
CMDLINE_TOOLS_DIR="$(mise where http:android-cmdline-tools)"; export CMDLINE_TOOLS_DIR
VENDORS_DIR="$(mise where http:godot-openxr-vendors)"; export VENDORS_DIR
# Godot keeps export templates and editor settings under XDG dirs; keep them in .toolchain.
# Must come after the `mise where` calls (mise follows XDG_DATA_HOME too).
export XDG_DATA_HOME="$TOOLCHAIN_DIR/xdg/data" XDG_CONFIG_HOME="$TOOLCHAIN_DIR/xdg/config"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
export BUILD_TOOLS="$ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION"
export QUEST_ENV_DONE=1
