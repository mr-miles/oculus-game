#!/usr/bin/env bash
# One-time setup of everything the headless Quest build needs, under $TOOLCHAIN
# (default ~/.quest-toolchain, ~4.5 GB). Idempotent: finished steps are skipped.
# Needs: bash, curl, python3, tar, sha256sum, sha512sum, and network access to
# github.com (+ release-assets.githubusercontent.com), dl.google.com.
set -euo pipefail
source "$(dirname "$0")/env.sh"
mkdir -p "$TC" "$TC/dl" "$TC/tmp"
export JAVA_TOOL_OPTIONS="-Djava.io.tmpdir=$TC/tmp"
dl() { curl -fsSL --retry 3 -o "$2" "$1"; }

echo "== Godot ${GODOT_VERSION} editor"
if [ ! -x "$GODOT" ]; then
  B=https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}
  dl $B/SHA512-SUMS.txt "$TC/dl/SHA512-SUMS.txt"
  dl $B/Godot_v${GODOT_VERSION}_linux.x86_64.zip "$TC/dl/godot.zip"
  dl $B/Godot_v${GODOT_VERSION}_export_templates.tpz "$TC/dl/templates.tpz"
  for f in "godot.zip:Godot_v${GODOT_VERSION}_linux.x86_64.zip" "templates.tpz:Godot_v${GODOT_VERSION}_export_templates.tpz"; do
    want=$(grep " ${f#*:}\$" "$TC/dl/SHA512-SUMS.txt" | cut -d' ' -f1)
    got=$(sha512sum "$TC/dl/${f%%:*}" | cut -d' ' -f1)
    [ "$want" = "$got" ] || { echo "checksum mismatch for ${f%%:*}"; exit 1; }
  done
  python3 -I - "$TC" "$GODOT_TEMPLATE_DIR" <<'PY'
import sys, zipfile, os
tc, tdir = sys.argv[1:3]
zipfile.ZipFile(f"{tc}/dl/godot.zip").extractall(f"{tc}/godot")
out = os.path.expanduser(f"~/.local/share/godot/export_templates/{tdir}")
os.makedirs(out, exist_ok=True)
z = zipfile.ZipFile(f"{tc}/dl/templates.tpz")
for n in z.namelist():  # only the Android templates are needed
    if n.startswith("templates/") and ("android" in n or n.endswith("version.txt")):
        open(f"{out}/{os.path.basename(n)}", "wb").write(z.read(n))
PY
  chmod +x "$GODOT"; rm -f "$TC/dl/godot.zip" "$TC/dl/templates.tpz"
fi

echo "== JDK 17 (Temurin)"
if [ ! -d "$JDK_DIR" ]; then
  U="https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.21%2B9/OpenJDK17U-jdk_x64_linux_hotspot_17.0.21_9.tar.gz"
  dl "$U" "$TC/dl/jdk.tgz"; dl "$U.sha256.txt" "$TC/dl/jdk.sha"
  [ "$(cut -d' ' -f1 "$TC/dl/jdk.sha")" = "$(sha256sum "$TC/dl/jdk.tgz" | cut -d' ' -f1)" ] || { echo "jdk checksum mismatch"; exit 1; }
  tar xzf "$TC/dl/jdk.tgz" -C "$TC"; rm -f "$TC/dl/jdk.tgz"
fi
# If outbound TLS is inspected by a firm CA (NODE_EXTRA_CA_CERTS / system CA),
# Java needs to trust it too, or sdkmanager and Gradle fail with IO exceptions.
CA="${EXTRA_CA_CERT:-/usr/local/share/ca-certificates/zapper.crt}"
if [ -f "$CA" ] && ! keytool -list -keystore "$JAVA_HOME/lib/security/cacerts" -storepass changeit -alias firm-proxy >/dev/null 2>&1; then
  keytool -importcert -noprompt -trustcacerts -alias firm-proxy -file "$CA" \
    -keystore "$JAVA_HOME/lib/security/cacerts" -storepass changeit
fi

echo "== Android SDK"
if [ ! -d "$ANDROID_HOME/build-tools/35.0.1" ]; then
  # Pinned revision; sha1 from https://dl.google.com/android/repository/repository2-3.xml
  dl https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip "$TC/dl/cmdline.zip"
  python3 -I -c "import zipfile,sys;zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$TC/dl/cmdline.zip" "$TC/dl/ct"
  mkdir -p "$ANDROID_HOME/cmdline-tools"; rm -rf "$ANDROID_HOME/cmdline-tools/latest"
  mv "$TC/dl/ct/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
  chmod +x "$ANDROID_HOME"/cmdline-tools/latest/bin/*; rm -rf "$TC/dl/cmdline.zip" "$TC/dl/ct"
  SM="$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager --sdk_root=$ANDROID_HOME"
  yes | $SM --licenses >/dev/null || true
  $SM "platform-tools" "build-tools;35.0.1" "platforms;android-35"
fi

echo "== OpenXR Vendors plugin ${VENDORS_VERSION}"
V="$TC/dl/vendors.zip"
if [ ! -d "$TC/vendors/addons/godotopenxrvendors" ]; then
  dl https://github.com/GodotVR/godot_openxr_vendors/releases/download/${VENDORS_VERSION}/godotopenxrvendorsaddon.zip "$V"
  echo "6a838dbdf4115549e4511ebee0da9a5dcc8f9f6258d4cc2f2ee57a907a3e2911  $V" | sha256sum -c -
  python3 -I -c "import zipfile,sys;zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])" "$V" "$TC/vendors.tmp"
  mkdir -p "$TC/vendors"; mv "$TC/vendors.tmp/asset/addons" "$TC/vendors/addons"; rm -rf "$TC/vendors.tmp" "$V"
fi

echo "== Debug keystore + Godot editor settings"
mkdir -p "$TC/ks"
[ -f "$TC/ks/debug.keystore" ] || keytool -genkeypair -keystore "$TC/ks/debug.keystore" -storepass android -keypass android \
  -alias androiddebugkey -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Android Debug,O=Android,C=US" >/dev/null 2>&1
mkdir -p "$HOME/.config/godot"
cat > "$HOME/.config/godot/editor_settings-4.7.tres" <<EOF
[gd_resource type="EditorSettings" format=3]

[resource]
export/android/android_sdk_path = "$ANDROID_HOME"
export/android/java_sdk_path = "$JAVA_HOME"
export/android/debug_keystore = "$TC/ks/debug.keystore"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
EOF

echo "== Gradle memory limits (a 4 GB machine OOM-kills the default 4.5 GB daemon)"
mkdir -p "$GRADLE_USER_HOME"
[ -f "$GRADLE_USER_HOME/gradle.properties" ] || cat > "$GRADLE_USER_HOME/gradle.properties" <<EOF
org.gradle.jvmargs=-Xmx${GRADLE_XMX:-1536m} -XX:MaxMetaspaceSize=512m
kotlin.daemon.jvm.options=-Xmx768m
org.gradle.daemon=false
org.gradle.workers.max=1
EOF
echo "Toolchain ready in $TC"
