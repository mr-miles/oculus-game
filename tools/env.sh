# Shared settings. Source, don't run. Run via `mise run ...` (or `mise exec -- ...`) so
# JAVA_HOME/PATH/ANDROID_HOME come from mise.toml.
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT
export GAME="$REPO_ROOT/game"
export GODOT_TEMPLATE_DIR=4.7.2.stable
export BUILD_TOOLS_VERSION=35.0.1
: "${ANDROID_HOME:?run through mise: mise run setup / build}"
: "${TOOLCHAIN_DIR:?run through mise}"
GODOT="$(command -v godot || true)"; export GODOT
[ -n "$GODOT" ] || { echo "godot not on PATH: run 'mise install'"; return 1 2>/dev/null || exit 1; }
JAVA_HOME="$(mise where java)"; export JAVA_HOME
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
export BUILD_TOOLS="$ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION"
VENDORS_DIR="$(mise where http:godot-openxr-vendors)"; export VENDORS_DIR
