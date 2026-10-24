#!/usr/bin/env bash
# Checks that an APK carries what a Quest 2 needs. Exit 1 on any miss.
set -euo pipefail
source "$(dirname "$0")/env.sh"
APK="${1:-$GAME/build/quest-sentinel.apk}"
BAD=0
chk() { if eval "$2"; then echo "OK   $1"; else echo "MISS $1"; BAD=1; fi; }
BADGING=$("$BUILD_TOOLS/aapt2" dump badging "$APK")
MAN=$("$BUILD_TOOLS/aapt2" dump xmltree --file AndroidManifest.xml "$APK")
LIBS=$(python3 -I -c "import zipfile,sys;print('\n'.join(zipfile.ZipFile(sys.argv[1]).namelist()))" "$APK")
chk "package name"                      'grep -q "^package: name=.org.example.questsentinel" <<<"$BADGING"'
chk "arm64-v8a only"                    '[ "$(grep -o "native-code: .*" <<<"$BADGING")" = "native-code: '"'"'arm64-v8a'"'"'" ]'
chk "OpenXR loader packaged"            'grep -q "lib/arm64-v8a/libopenxr_loader.so" <<<"$LIBS"'
chk "OpenXR Vendors lib packaged"       'grep -q "lib/arm64-v8a/libgodotopenxrvendors.so" <<<"$LIBS"'
chk "Quest 2 in supportedDevices"       'grep -q "quest2|" <<<"$MAN"'
chk "Oculus VR intent category"         'grep -q "com.oculus.intent.category.VR" <<<"$MAN"'
chk "OpenXR immersive HMD category"     'grep -q "org.khronos.openxr.intent.category.IMMERSIVE_HMD" <<<"$MAN"'
chk "APK signature (v2) valid"          '"$BUILD_TOOLS/apksigner" verify "$APK" >/dev/null 2>&1'
ls -l "$APK" | awk '{print "size:", $5, "bytes"}'
exit $BAD
