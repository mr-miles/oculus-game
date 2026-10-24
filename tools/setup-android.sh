#!/usr/bin/env bash
# Everything mise doesn't install itself: SDK packages, Godot Android export
# templates, debug keystore, Godot editor settings, Gradle memory limits.
# Idempotent. Run via `mise run setup`.
set -euo pipefail
source "$(dirname "$0")/env.sh"
TC="$TOOLCHAIN_DIR"; mkdir -p "$TC/dl" "$TC/tmp"
export JAVA_TOOL_OPTIONS="-Djava.io.tmpdir=$TC/tmp"
TEMPLATES_SHA512="ca4d71c4d7b81dfc15d1a98baa07534aa95b03fdda78a0075b06672e1648d2e5f40980c9adc28d23e1b92e732ee7bf3461997aa804af74ec2fcd7a93ccb84079"

echo "== Optional: trust a TLS-inspecting proxy CA in the (mise-managed) JDK"
# Only if EXTRA_CA_CERT is set to a PEM file. Java ignores the system CA store.
if [ -n "${EXTRA_CA_CERT:-}" ] && [ -f "$EXTRA_CA_CERT" ] \
   && ! keytool -list -keystore "$JAVA_HOME/lib/security/cacerts" -storepass changeit -alias firm-proxy >/dev/null 2>&1; then
  keytool -importcert -noprompt -trustcacerts -alias firm-proxy -file "$EXTRA_CA_CERT" \
    -keystore "$JAVA_HOME/lib/security/cacerts" -storepass changeit
fi

echo "== Android SDK packages"
if [ ! -d "$ANDROID_HOME/build-tools/$BUILD_TOOLS_VERSION" ]; then
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  rm -rf "$ANDROID_HOME/cmdline-tools/latest"
  CT="$CMDLINE_TOOLS_DIR"
  SRC="$(find "$CT" -type d -name cmdline-tools | head -1)"; [ -n "$SRC" ] || SRC="$CT"
  cp -r "$SRC" "$ANDROID_HOME/cmdline-tools/latest"; chmod +x "$ANDROID_HOME"/cmdline-tools/latest/bin/*
  SM="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --sdk_root=$ANDROID_HOME"
  yes | $SM --licenses >/dev/null || true
  # sdkmanager redraws a progress bar with carriage returns; keep only the lines that matter.
  $SM "platform-tools" "build-tools;$BUILD_TOOLS_VERSION" "platforms;android-35" 2>&1 \
    | tr '\r' '\n' | grep -E "Installing|Warning|Error|error" | sort -u || true
fi

echo "== Godot Android export templates (checksummed)"
TD="$XDG_DATA_HOME/godot/export_templates/$GODOT_TEMPLATE_DIR"
if [ ! -f "$TD/android_source.zip" ]; then
  U=https://github.com/godotengine/godot/releases/download/4.7.2-stable
  curl -fsSL --retry 3 -o "$TC/dl/templates.tpz" "$U/Godot_v4.7.2-stable_export_templates.tpz"
  echo "$TEMPLATES_SHA512  $TC/dl/templates.tpz" | sha512sum -c -
  mkdir -p "$TD"
  python3 -I - "$TC/dl/templates.tpz" "$TD" <<'PY'
import sys, zipfile, os
z = zipfile.ZipFile(sys.argv[1])
for n in z.namelist():  # only the Android templates are needed
    if n.startswith("templates/") and ("android" in n or n.endswith("version.txt")):
        open(os.path.join(sys.argv[2], os.path.basename(n)), "wb").write(z.read(n))
PY
  rm -f "$TC/dl/templates.tpz"
fi

echo "== Debug keystore + Godot editor settings"
mkdir -p "$TC/ks" "$XDG_CONFIG_HOME/godot"
[ -f "$TC/ks/debug.keystore" ] || keytool -genkeypair -keystore "$TC/ks/debug.keystore" -storepass android -keypass android \
  -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US" >/dev/null 2>&1
cat > "$XDG_CONFIG_HOME/godot/editor_settings-4.7.tres" <<EOF
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "$ANDROID_HOME"
export/android/java_sdk_path = "$JAVA_HOME"
export/android/debug_keystore = "$TC/ks/debug.keystore"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
EOF

echo "== Gradle memory limits (a 4 GB machine OOM-kills the default 4.5 GB heap)"
mkdir -p "$GRADLE_USER_HOME"
cat > "$GRADLE_USER_HOME/gradle.properties" <<EOF
org.gradle.jvmargs=-Xmx${GRADLE_XMX:-1536m} -XX:MaxMetaspaceSize=512m
kotlin.daemon.jvm.options=-Xmx768m
org.gradle.daemon=false
org.gradle.workers.max=1
EOF
echo "Setup done."
