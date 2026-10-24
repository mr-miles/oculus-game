# Shared settings. Source, don't run.
export TC="${TOOLCHAIN:-$HOME/.quest-toolchain}"
export GODOT_VERSION=4.7.2-stable
export GODOT_TEMPLATE_DIR=4.7.2.stable
export VENDORS_VERSION=5.1.0-stable
export JDK_DIR="$TC/jdk-17.0.21+9"
export JAVA_HOME="$JDK_DIR"
export ANDROID_HOME="$TC/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export GRADLE_USER_HOME="$TC/gradle"
export GODOT="$TC/godot/Godot_v${GODOT_VERSION}_linux.x86_64"
export BUILD_TOOLS="$ANDROID_HOME/build-tools/35.0.1"
export PATH="$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export REPO_ROOT
export GAME="$REPO_ROOT/game"
