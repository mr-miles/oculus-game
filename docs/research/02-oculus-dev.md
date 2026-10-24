# Question 2: building and running a Sentinel VR game on a Meta Quest 2 (Linux-first, sideloaded, family use)

**Target (set by the product owner):** primary device is a Meta Quest 2 (256 GB, bought February 2022); no store release or review, the game is sideloaded and run locally, a gaming PC may help; Rift and other headsets are optional. Research date 2026-10-24. **Nothing in this document was run on real hardware.** **Reading order.** Part 0 (Linux-first, agent workflow: engine decision, package list, install script, hello-world spec; references 90-110) supersedes the Windows setup steps in Part 1 section 7 and the engine recommendation in Part 1 section 5, because all development is done by an AI agent on Linux and Windows is used only for end-user testing. Part 1 is the Quest 2 guide (references 62-89); its facts on developer mode, sideloading, comfort and hardware still stand. **Nothing in Part 0 was run on a real Linux machine or a real headset.**

---

# Part 0: Linux-first development

Date 2026-10-24. Reuses the earlier Quest 2 guide (a-4@v3; cited [62]-[89]); new sources are [90]-[110] in `references-linux.md`.
**Nothing here was run.** No headset, no Linux build host, no engine installed. Tags: **[Fact-read]** page opened; **[Fact-search]** only a search summary; **[Judgement]**; **[Unverified]**.

## L0. Summary

- **[Judgement] Recommend Godot 4.7.x (Compatibility renderer, OpenGL ES 3) + OpenXR Vendors plugin 5.1.0, built with `godot --headless --export-debug` to a sideloaded APK.** It is the only stack whose whole chain is documented to run on Linux from the command line with a free, scriptable toolchain. Unity 6 builds on Linux but its Personal licence cannot be activated without a browser login and Meta's tooling is Windows/macOS-first. This reverses the earlier recommendation of Unity [A-section 5] only because of the new constraint.
- **[Fact-read]** Godot's Android export needs OpenJDK 17 (higher "also supported"), Build-Tools 35.0.1, Platform 35, NDK r28b, CMake 3.10.2.4988404 [90]; XR needs Gradle build, XR Mode = OpenXR, Compatibility renderer [91].
- **[Fact-read]** Meta XR Simulator documents Windows and macOS only [94]. A Linux download is listed on Meta's Unity downloads page **[Fact-search]** [109], unconfirmed. No headset-free VR run on Linux is documented by Meta.

## L1. Is development tied to Windows? (per engine)

| Engine / stack | Tied to Windows? | Basis |
|---|---|---|
| Unity 6 | **No for building APKs; partly for Meta tooling.** Editor is supported on Ubuntu 22.04/24.04 [97]; Android build works there. Meta XR Simulator and Link play-in-editor are Windows/macOS [94][63]. Meta's docs do not name Linux as an editor OS [110]. | Search + read |
| Godot 4 | **No.** Linux editor, headless export, Android SDK all on Linux [90][92]. | Read |
| Unreal | **Practically yes for Meta features.** Epic's engine supports Android packaging on Linux, but a user report says Meta's XR plugin is Windows-only and Meta's install docs never mention Linux [103][104]. Plain OpenXR without Meta plugin is possible [104]. Overkill here. | Search |
| Native OpenXR + NDK | **No.** Android Studio/NDK run on Linux; a developer reports doing all OpenXR work on Linux [103]. Highest effort (own renderer, input, audio). | Search |

## L2. Unity on Linux

| Item | Finding |
|---|---|
| Editor OS | Ubuntu 22.04 and 24.04 only, 6.0 to 6.6; x64, Vulkan or OpenGL 3.2+, GNOME on X11/Wayland [97] **[Fact-search]**. Other distros unsupported. |
| Versions | 6000.3 LTS (6000.3.26f1 seen in a 2026-10-09 report); 6000.6 mainline [100] **[Fact-search]**. Meta needs 6000.0.66f2+ [64][110]. |
| Licence | Command-line `-serial` activation does not apply to Personal; Hub is the only route [99] **[Fact-search]**. GameCI: generate `.ulf` via Hub, store in `UNITY_LICENSE` with `UNITY_EMAIL`/`UNITY_PASSWORD`; the `.alf` manual flow no longer works for Personal [98]. One report: `unity auth login` (browser OAuth, 5-min wait) then `unity license activate --personal --accept-eula`; the licence did not survive 24 h [100] (single community source). |
| Install | Hub CLI `--headless install-modules -m android android-sdk-ndk-tools android-open-jdk`, or the standalone `unity` CLI `unity install-modules` [101]. |
| Batch build | `Unity -batchmode -nographics -quit -projectPath . -buildTarget Android -executeMethod Build.Run -logFile -` with a static C# method calling `BuildPipeline.BuildPlayer` [L12 example is macOS]. **[Judgement]** standard practice. |
| Meta SDK / OpenXR | Packages are plain UPM and build on Linux **[Judgement]**; Project Setup Tool "Fix All" is an editor GUI action, so scripting it is **[Unverified]**. Community shims exist for editor play mode on Linux [102]. |
| Headless practicality | **[Judgement]** Weak: an interactive browser login is needed at least once and may recur daily; cost is a human in the loop. |

## L3. Godot 4 headless and other stacks

| Item | Value |
|---|---|
| Godot | 4.7 stable (2026-06-18); latest seen 4.7.2 (2026-08-18) **[Fact-search]** [96]. Linux editor zip ~76 MB; export templates `.tpz` ~1.3 GB [96]. |
| Android prerequisites | OpenJDK 17 (higher supported); platform-tools ≥35.0.0, build-tools **35.0.1**, platform **android-35**, cmdline-tools latest, CMake **3.10.2.4988404**, NDK **28.1.13356709** (r28b) **[Fact-read]** [90]. Docs warn not to use the distro's Android SDK on Linux [90]. |
| CLI export | `godot --headless --export-debug "<preset>" out.apk`; `--export-release` likewise; `--export-debug` implies `--import`; the binary must be the editor, templates must be installed; relative output resolves from `project.godot`'s directory [92] **[Fact-read]**. |
| XR settings | Add Android preset, enable **Use Gradle Build**, **XR Mode = OpenXR**, Runnable; one preset per device; Compatibility renderer (Mobile/Vulkan "still being worked out") [91] **[Fact-read]**. |
| OpenXR Vendors | Plugin is optional but recommended from Godot 4.6 [91]. **5.1.0-stable (2026-05-19) requires 4.6+**; 5.2.0-rc1 is pre-release; 4.3.1 is for Godot 4.4+ [93]. So for Godot 4.7.x use **5.1.0**. |
| Keystore | Env vars `GODOT_ANDROID_KEYSTORE_DEBUG_PATH/_USER/_PASSWORD` (and `_RELEASE_`) override export values [90]. Release key: `keytool -v -genkey -keystore mygame.keystore -alias mygame -keyalg RSA -validity 10000`; keystore and key passwords must match [90]. Debug keystore is auto-generated in the editor; headless it must be created by hand **[Judgement]** (see §6). |
| godot-xr-tools | 4.5.2 stable (2026-10-08), fixes Godot 4.7 script errors; README says Godot 4.4+; 4.6.0-dev2 is a risky pre-release [105] **[Fact-search]**. **[Judgement]** Not needed for a look-and-teleport game; skip to cut dependencies. |
| Other stacks | **[Unverified, own knowledge]** Native OpenXR + NDK gives full control but you write rendering, input, audio. Bevy has experimental OpenXR/Android support; I did not research it. Not recommended. |

## L4. Recommendation

**Godot 4.7.2 + OpenXR Vendors 5.1.0 + Compatibility renderer + OpenJDK 17 + Android SDK per [90], Ubuntu 24.04 x86_64.**
Reasons: [Fact] fully CLI-driven; free; no account or licence step; small download. [Judgement] the game is lightly rendered, so Godot's weaker XR tooling matters little; the rules core can be pure GDScript or a plain-language library with unit tests.
Risks:
1. **[Unverified]** headless Gradle export of an XR project needs the Android build template extracted by hand (the editor menu does this normally); steps in §6 are my reconstruction.
2. **[Judgement]** Godot's Quest 2 path is less used than Unity's; first-run failures plausible, so keep the known-good-APK fallback (§7).
3. Plugin/engine matching moves quickly (5.x needs 4.6+ [93]); pin versions.
4. Quest 2 is discontinued but still updated [78]-[80]; sideloading unchanged.
Fallback stack: Unity 6000.3 LTS on Ubuntu 24.04 if Godot fails, accepting an interactive licence step [99][100].

## L5. Testing without a headset

| Need | Linux answer |
|---|---|
| Meta XR Simulator | Not documented for Linux [94]; a Linux download exists on Meta's Unity downloads page **[Fact-search]** [109]. Treat as unavailable. |
| Android emulator | **[Unverified, own knowledge]** Emulator has no OpenXR runtime or Quest system; useless for VR rendering. Not recommended. |
| Desktop OpenXR on Linux | Monado is a Linux OpenXR runtime; Debian/Ubuntu `xr-hardware` gives udev rules [106] **[Fact-search]**. Godot on desktop can use an OpenXR runtime or run with XR disabled. Monado's simulated/no-hardware mode: **[Unverified]**. |
| Rules core | **[Judgement]** Keep game rules (landscape generation, energy, absorb/transfer, enemy tactics) in engine-independent code; unit-test with seed replays (`godot --headless --script tests/run.gd`). Fully agent-verifiable. |
| Screenshots | `godot --headless` has no GPU renderer (dummy driver); for images use `xvfb-run godot --rendering-driver opengl3 ...` with Mesa llvmpipe and `get_viewport().get_texture().get_image().save_png()` **[Judgement, unverified]**. |
| adb from Linux | Install `adb`/platform-tools; udev rule for Meta's vendor ID 2833 (**[Fact-search]** from Monado/Oculus lists; confirm with `lsusb`) [106][107]: `SUBSYSTEM=="usb", ATTR{idVendor}=="2833", MODE="0666", GROUP="plugdev"`; reload with `udevadm control --reload-rules && udevadm trigger`; replug [107]. Meta's own page has no Linux text [95]. |
| Wireless adb | `adb tcpip 5555`, `adb connect <ip>:5555` [66]. |

**Human must:** create Meta developer account and organization, verify via SMS/payment [62]; enable Developer Mode in the phone app [62]; put the headset on, enable MTP Notification and accept "Always allow" USB debugging [95][62]; wear the headset and judge the acceptance criteria; plug in the cable.

## L6. Exact package and download list (recommended path)

Assumptions: Ubuntu 24.04 LTS x86_64, user in `plugdev`. Versions from [90][93][96][108]; items marked ? are unconfirmed.

| Component | Version | Source |
|---|---|---|
| OS packages | `openjdk-17-jdk-headless unzip wget adb xvfb libgl1-mesa-dri libasound2t64 libfontconfig1 libxcursor1 libxinerama1 libxi6 libxrandr2 libxkbcommon0 git` | archive.ubuntu.com |
| Android cmdline-tools | build 15859902 (candidate [108]) | dl.google.com/android/repository/commandlinetools-linux-15859902_latest.zip |
| SDK packages | platform-tools, build-tools;35.0.1, platforms;android-35, cmake;3.10.2.4988404, ndk;28.1.13356709 [90] | sdkmanager |
| Godot editor | 4.7.2-stable linux.x86_64 zip ? | godotengine.org download or github.com/godotengine/godot-builds releases |
| Export templates | `Godot_v4.7.2-stable_export_templates.tpz` (~1.3 GB) | same |
| OpenXR Vendors | 5.1.0-stable zip, copy `assets/addons/godotopenxrvendors` into `addons/` [91][93] | github.com/GodotVR/godot_openxr_vendors/releases |
| Keystore / signing | `keytool` (from JDK), `apksigner` from build-tools | local |

Env vars: `JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64`, `ANDROID_HOME=$HOME/android-sdk`, `ANDROID_SDK_ROOT=$ANDROID_HOME`, `PATH` + `$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/35.0.1`, and the `GODOT_ANDROID_KEYSTORE_DEBUG_*` trio.

```bash
#!/usr/bin/env bash
# install.sh -- run once; scripts live outside any download directory
set -euo pipefail
GV=4.7.2-stable; GT=4.7.2.stable
sudo apt-get update
sudo apt-get install -y openjdk-17-jdk-headless unzip wget adb xvfb git \
  libgl1-mesa-dri libfontconfig1 libxcursor1 libxinerama1 libxi6 libxrandr2 libxkbcommon0
sudo usermod -aG plugdev "$USER"
echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="2833", MODE="0666", GROUP="plugdev"' | \
  sudo tee /etc/udev/rules.d/51-quest.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
export ANDROID_HOME=$HOME/android-sdk
mkdir -p "$ANDROID_HOME/cmdline-tools" "$HOME/dl-sdk" "$HOME/dl-godot"
wget -P "$HOME/dl-sdk" https://dl.google.com/android/repository/commandlinetools-linux-15859902_latest.zip
unzip -q "$HOME/dl-sdk"/commandlinetools-linux-*_latest.zip -d "$HOME/dl-sdk/x"
mv "$HOME/dl-sdk/x/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$PATH
yes | sdkmanager --sdk_root="$ANDROID_HOME" --licenses
sdkmanager --sdk_root="$ANDROID_HOME" "platform-tools" "build-tools;35.0.1" \
  "platforms;android-35" "cmdline-tools;latest" "cmake;3.10.2.4988404" "ndk;28.1.13356709"
B=https://github.com/godotengine/godot-builds/releases/download/$GV   # ? confirm URL
wget -P "$HOME/dl-godot" $B/Godot_v${GV}_linux.x86_64.zip $B/Godot_v${GV}_export_templates.tpz
mkdir -p "$HOME/godot" "$HOME/.local/share/godot/export_templates/$GT"
unzip -q "$HOME/dl-godot/Godot_v${GV}_linux.x86_64.zip" -d "$HOME/godot"
unzip -q "$HOME/dl-godot/Godot_v${GV}_export_templates.tpz" -d "$HOME/dl-godot/tpl"
cp -r "$HOME/dl-godot/tpl/templates/." "$HOME/.local/share/godot/export_templates/$GT/"
# debug keystore (headless editor does not create one)
keytool -genkeypair -v -keystore "$HOME/debug.keystore" -alias androiddebugkey \
  -keyalg RSA -validity 9999 -storepass android -keypass android \
  -dname "CN=Android Debug,O=Android,C=US"
```
Log out/in for the group. Then run `godot --headless --editor --quit` once to create `~/.config/godot/editor_settings-4.7.tres` and set `export/android/java_sdk_path` and `export/android/android_sdk_path` in it (key names from memory **[Unverified]**).

**First-run checklist:** `java -version` = 17; `sdkmanager --list_installed` shows the five packages; `godot --version` prints 4.7.2; `ls ~/.local/share/godot/export_templates/4.7.2.stable/android_*`; `lsusb | grep 2833`; `adb devices` lists `device` (not `unauthorized` or `no permissions`).

## L7. Hello-world spec (chequered floor, cube, head-tracked)

**Project** `hello/`: `project.godot` with `renderer/rendering_method="gl_compatibility"`, `xr/openxr/enabled=true`, main scene with `XROrigin3D` > `XRCamera3D`, `MeshInstance3D` plane (checker shader or generated `ImageTexture`), `MeshInstance3D` BoxMesh 0.3 m at (0, 1.2, -1). `main.gd`: `var xr = XRServer.find_interface("OpenXR"); if xr and xr.initialize(): get_viewport().use_xr = true; print("HELLO_XR_OK")`. Package `org.example.hellosentinel`, arm64-v8a only, `addons/godotopenxrvendors` enabled, Meta XR option set to Quest 2 entry.

**Stages and commands** (agent-verifiable = A, human = H)

| # | Stage | Command | Check | Who |
|---|---|---|---|---|
| 1 | Import | `godot --headless --path hello --import` | exit 0, no errors | A |
| 2 | Gradle template | extract `android_source.zip` from templates into `hello/android/build` (**[Unverified]** headless equivalent of the menu item) | dir exists | A |
| 3 | Build | `godot --headless --path hello --export-debug "Meta Quest" /work/out/hello.apk` | exit 0, APK exists | A |
| 4 | Inspect | `aapt2 dump badging hello.apk` | package name, `arm64-v8a`, `com.oculus.intent.category.VR` / OpenXR features **[Unverified]** | A |
| 5 | Sign check | `apksigner verify --verbose hello.apk` | "Verifies" | A |
| 6 | Deploy | `adb devices`; `adb install -r hello.apk` | `Success` | A (needs H prerequisites) |
| 7 | Run | `adb shell monkey -p org.example.hellosentinel 1`; `adb logcat -d \| grep -E "HELLO_XR_OK\|godot"` | line `HELLO_XR_OK`; no crash | A |
| 8 | Look | wear headset: app in Library > Unknown Sources [69] | below | H |

**Acceptance (human):** (a) app launches without returning to Home; (b) chequered floor visible and stationary as you turn and walk; (c) a cube about 1.2 m up, 1 m ahead, stays fixed in space; (d) head rotation and a step both move the view without lag; (e) text, if any, readable; frame rate steady (`adb shell dumpsys` or OVR metrics not specified).

**Self-verified limits:** steps 1-7 prove the chain reaches the app starting and initialising OpenXR; they cannot prove the picture or tracking feel, which stay human.

**Fallback if on-device fails:** (1) install a known-good sample APK (e.g. the Godot XR tools/OpenXR demo APK, or Meta's sample) with `adb install` to separate toolchain fault from project fault; (2) check `adb logcat` for OpenXR loader errors, mismatched plugin/engine versions [93], or wrong XR Mode [91]; (3) switch to the Unity fallback; (4) a PC-streamed desktop test needs Windows Link [63], so is a human-run option, not Linux.

---

# Part 1: Quest 2 guide (Windows-centred steps superseded by Part 0)
 Appendix A is the earlier Rift/PC VR briefing (references 42-61); its store-distribution content (A8) is not needed for this project and its numbering is prefixed with A.

Conventions: **[Fact]** = from a page I read; number in brackets points to `references-quest2.md`. **[Search]** = seen only in a web-search summary, page not opened. **[Judgement]** = my recommendation. **[Unverified]** = could not confirm. 

**Nothing in this document was run on real hardware.** No headset, no Windows machine, no Unity install. Every step is taken from documentation.

The earlier Rift and PC VR briefing is kept as Appendix A at the end; its Link PC requirements and Meta XR Simulator facts are reused here [138].

## 0. Summary

- **[Judgement]** Recommended path: **Unity 6 + URP + Unity OpenXR Plugin 1.15.1 + Meta XR All-in-One SDK, standalone Android build, sideloaded with MQDH or adb.** Iterate with Link play-in-editor or Meta XR Simulator; do a real build-and-run for performance and comfort checks. Reasons in sections 4 and 5.
- **[Fact]** Developer mode needs a developer team on the Meta dashboard, a verified account (SMS number or payment method; PayPal not accepted), age 18+ [62][64].
- **[Fact]** Quest 2 is discontinued ("no longer available") but is still a supported dev device for Link and Build and Run in Meta's current Unity docs [63][68]. **[Search]** It was still receiving Horizon OS updates in October 2026 and has a security-update commitment to December 2027 [78][79][80].
- **[Fact]** A sideloaded APK needs no store review. It appears under **Unknown Sources** in the Library [69].

## 1. Developer mode on a Quest 2

**Requirements [Fact][62][64]**
- A Meta developer account that is a member of, or creator of, a developer team (the "organization") on the Meta Horizon Developer Dashboard. The organization step is **still required** [62].
- The account must be verified once: confirm a mobile number by SMS, or add a payment method (PayPal not accepted) [62]. A paid account is not required if SMS verification is used. This follows from the page's "either/or"; no charge is mentioned.
- Age 18 or older; no device-level restrictions blocking developer mode [62][64].
- Meta's setup list also asks for a Unity ID and for MQDH signed in with the same developer credentials as the headset [64].

**Phone app steps [Fact][62]**
1. Open the Meta Horizon app, tap the headset icon in the toolbar.
2. Tap your paired headset at the top.
3. Tap **Headset Settings**, then **Developer Mode**.
4. Toggle **Developer Mode** on.

**USB debugging [Fact][62][64]**
1. Connect the headset to the PC with a USB-C **data** cable.
2. In the headset: Quick Control > Settings (gear) > **Developer** tab > turn on **MTP Notification**.
3. Accept the USB debugging prompt, choosing "Always allow from this computer".
4. In MQDH Device Manager the device should show a green Active status; `adb devices` should list it as `device` [64].

**Quest 2 versus newer headsets.** The setup page lists Quest 2 as supported and gives no Quest 2-specific steps [62]. Meta's device list for Link and Build and Run: Quest 2, 3, 3S, Pro and Meta VR Glasses [63]. **[Unverified]** I found no documented difference in the developer-mode procedure between Quest 2 and Quest 3.

Terms [Fact][62]: developer mode is for running, debugging and testing apps; other use can lead to account limits. Running your own sideloaded game falls under testing, but **[Judgement]** it is a family game, so keep it to your own devices.

## 2. Quest 2 status and hardware

**Software and support status**
- **[Fact]** Meta's consumer page says "Meta Quest 2 is no longer available" [68]. **[Search]** Discontinued September 2024 [78].
- **[Search]** Meta's security-update policy lists Quest 2 at December 2027 (at least five years of security updates from first US sale) [79]. A secondary source says feature updates end earlier (December 2026); I could not confirm it from Meta [79].
- **[Search]** Horizon OS 2.9 was rolling out in the week of 2026-10-19 to Quest 3, 3S, Pro and Quest 2; releases 2.5 to 2.7 named Quest 2 [80]. Meta dropped the v-number scheme in early 2026 (v86 became 2.1) [80].
- **[Search]** I found no official statement of end of support for developers and no deprecation of sideloading or developer mode [78]. One third-party site calls Quest 2 "legacy deployments only"; that is commentary, not Meta [78].
- **[Fact]** Meta's Unity docs still list Quest 2 for Link and Build and Run [63].
- **[Judgement]** Risk to sideloading is low: nothing found says it is going away, and a sideloaded local game does not depend on the store. **[Unverified]** I did not read Meta's release notes page or developer blog.

**Hardware (consumer specs; not from developer docs)**
- **[Fact]** Display: fast-switch LCD, 1832 x 1920 per eye. Refresh rates 60, 72, 80, 90, 120 Hz. Storage 128 or 256 GB [68].
- **[Search]** Snapdragon XR2, Adreno 650 GPU, 6 GB RAM [87]. Field of view about 97 x 93 degrees. Battery not found in any source I read. **[Unverified]**.
- **[Search]** Meta's performance guidance: default refresh 72 Hz; frame budget about 13.8 ms at 72 Hz; for Quest 2, fewer than 100 draw calls and fewer than 750K triangles per frame [81][82]. Thermal throttling may drop a high-refresh app to 72 Hz [81].
- **[Judgement]** A low-poly 31x31 terrain with few objects is far inside these limits. Use URP, few lights, baked or simple lighting, no post-processing.

## 3. Sideloading

**Install location [Fact][69].** Sideloaded apps appear in the headset Library under **Unknown Sources** in the left navigation.

**adb [Fact][66][72]**
- adb comes with Android SDK Platform Tools [72]; the Unity Android module also ships it under `PlaybackEngines/AndroidPlayer/SDK/platform-tools` [64].
- On Windows install the Oculus ADB driver if the headset is not listed [64][66].
- `adb devices` (state should be `device`); `adb install <apk>`; `adb install -r <apk>` to overwrite [66]. Sideloaded apps are not covered by Cloud Backup [66].
- Wireless (legacy method, used by Meta): with USB attached, `adb shell ip route` to find the IP, then `adb tcpip 5555` and `adb connect <ip>:5555`; unplug USB [66]. Android's own wireless pairing flow is for Android 11+ phones [72]; **[Unverified]** whether Quest supports it.
- Launch: from Library > Unknown Sources [69]. **[Unverified]** `adb shell monkey -p <package> 1` is common practice; I did not find it in a page I read.
- Logcat: Meta's page links to "Collect Logs with Logcat" [66], which I did not open. **[Judgement]** `adb logcat -s Unity` is the usual filter. The Android page points to logcat without detail [72].
- If two entries show up (USB and Wi-Fi), target one with `adb -s <id>` [66].

**MQDH [Fact][69].** Open Device Manager, drag the APK under Apps or click **Add Build**; it overwrites an APK with the same app ID. A matching OBB file in the same folder installs automatically. **[Search]** "ADB over Wi-Fi" toggle under Device Actions [89]. MQDH is Windows/macOS [89].

**SideQuest [Fact][74][75].** The open-source desktop app (MIT-licensed, active repository) installs on PC [74]. Its setup page I fetched only had a header, no steps [75]. **[Judgement]** MQDH or plain adb covers everything needed; SideQuest is optional.

**APK signing [Search][85]**
- Android requires every APK to be signed, but does not check the certificate against a trusted root, so a debug keystore works for sideloading. Unity signs with a temporary debug key by default.
- Use the **same key** for every version, or installs fail as a different publisher and you must uninstall first (losing app data).
- The store rejects debug-signed builds, which does not matter here. Meta requires signing scheme v1 or v2 for the store [85]. **[Judgement]** For a family game, create one keystore (Player > Publishing Settings) and keep it.
- **[Unverified]** The MQDH deploy page does not mention signing [69]; I could not confirm a Quest-specific signing check on sideload.

## 4. Standalone Android versus PC-streamed

| | Standalone (Android APK) | PC-streamed |
|---|---|---|
| What runs | Game on the Quest 2 | Game on the PC; headset shows video |
| Needs PC at play time | No | Yes |
| Iteration | Build and Run: slowest [77] | Link play-in-editor: press Play, no APK [83] |
| Look and performance | Final | May differ from on-device [83] |
| Family use | Pick up and play | Needs PC on, Wi-Fi or cable |

**Link [Fact][63][77][83]:** Windows only; USB-C data cable (5 Gbps or better, about 3 m per Meta's help page) or Air Link over Wi-Fi (5 GHz preferred). PC minimum i5-4590 / Ryzen 5 1500X, 8 GB RAM, supported GPU; recommended i7/Ryzen 7, RTX 20 or RX 6000 series, 16 GB [77]. Workflow: Link app on PC, headset Settings > Quest Link on, Launch Quest Link, press Play in Unity [83]. **Meta XR Simulator** needs no headset, runs on Windows or Apple-silicon macOS [63][77].

**Virtual Desktop and Steam Link [Search][86]:** Steam Link wants 5 GHz Wi-Fi, a wired PC, GTX 970 or better; Air Link about 150 Mbps at High; Virtual Desktop is paid with the most tuning. No source gave a reliable latency ranking (one old test: Air Link 55 ms, Virtual Desktop 47 ms) [86]. **[Judgement]** Streaming suits big PC games; it adds nothing for a light game.

**Recommendation [Judgement]:** standalone. A 31x31 low-poly game fits Quest 2 easily; the family needs no PC at play time and there is no streaming latency or Wi-Fi tuning. During development use Link play-in-editor or the Simulator for fast iteration, and do a Build and Run before judging comfort or frame rate. The PC is useful for the editor only.

## 5. Engines for Quest 2 standalone

**Unity 6 [Fact]**
- Editor: Meta's setup page says **6000.0.66f2 or higher** [64]; the manual-setup page says **6.1 or later**, because earlier ones may lack the Meta Quest build profile (otherwise choose Android) [65]. **[Judgement]** Install the newest 6.x LTS-style release that Hub offers at 6.1 or above; the two pages disagree and I could not resolve it.
- Modules: Android Build Support, OpenJDK, Android SDK and NDK Tools [64].
- Project: **Universal 3D** (URP) template [65].
- XR: **Unity OpenXR Plugin 1.15.1** (recommended; needs Unity 6 and Meta XR SDK v74+). Oculus XR Plugin 4.5.1 is deprecated [65]. The plugin targets Android arm64 and Vulkan on Quest [71].
- Enable OpenXR in XR Plug-in Management for both Standalone and Android; check Meta XR Feature (on), Meta XR Foveation (on by default) [65].
- Package: `com.meta.xr.sdk.all` (Meta XR All-in-One SDK: Core, Platform, Interaction) [65]. Run **Window > Meta > Tools > Project Setup Tool**, Fix All for both targets [65].
- **[Unverified]** XR Interaction Toolkit: I did not read its page; the Meta path uses the Interaction SDK instead. For a puzzle game with look-and-teleport, either works.

**Godot 4 [Fact][70][73]**
- Needs OpenJDK 17, Android Studio SDK, an Android build template (Project > Install Android Build Template), Gradle build on, XR Mode = OpenXR [70].
- Use the **Compatibility (OpenGL)** renderer on Android XR "for now" [70].
- OpenXR Vendors plugin (GDExtension) from the Asset Library or GitHub; optional but recommended from Godot 4.6 [70][73]. **[Unverified]** exact plugin version and which Godot 4.x releases it matches.
- One-click deploy with developer mode on and the ADB driver [70].

**Unreal [Unverified]** The Epic page I fetched held only a table of contents [76]. Not researched further. **[Judgement]** Overkill for this game.

**Recommendation [Judgement]: Unity 6.** Meta's current docs, Simulator, Link, MQDH and Project Setup Tool all target it, and I have read the setup exactly. Godot is a fine open-source alternative and has a short Android path [70]; its main risk is the less certain vendor-plugin matching. The earlier Rift briefing also recommended Unity [77].

## 6. Comfort and locomotion

- **[Fact]** Teleport and snap turn can disorient, but snap turn cuts vection. Spatial sound, blinks and warps help reorientation. Fixed snap angles 15, 30, 45, 90, 180 degrees. Vignettes darken screen edges during movement [67].
- **[Fact]** A consistent frame rate is crucial; ATW does not replace it [67].
- **[Fact]** Seated mode "is important for accessibility and should be supported". Let players pick seated or standing early; base seated height on the system-reported player height; offer artificial turning since chairs may not swivel [67].
- **[Search]** Meta recommends teleport and snap turn as comfort defaults and wants user choice of teleport/slide and snap/smooth [84].
- **[Search]** Refresh: 72 Hz is the default; other rates are opt-in and must be sustained [81]. **[Judgement]** Choose 72 Hz: a slow puzzle game needs nothing more, it leaves headroom and battery. 90 Hz is an easy later test.
- **[Search]** Fixed foveated rendering: no level guidance found [81]. Meta XR Foveation is enabled by default in the Unity OpenXR setup [65]. **[Judgement]** Leave at default; this game should not need it, and chequered terrain edges can shimmer if set high.
- **[Unverified]** Guardian/boundary documentation: not retrieved. **[Judgement]** Design for seated or small standing areas; teleport (look and select) means the player never has to walk. Do not rely on room-scale.

## 7. Step by step: empty Windows machine to the app on the headset (standalone)

Windows 10 or 11, 64-bit. ⚠ = I could not verify the exact click path.

1. **Accounts.** Create a Meta account, then a developer account at the Meta developer site and a developer team (organization); verify with SMS or payment method [62]. Create a Unity ID [64].
2. **Phone.** Install the Meta Horizon app, pair the Quest 2, turn on Developer Mode (section 1) [62].
3. **Unity.** Install Unity Hub, then Unity 6.1 or newer (not older than 6000.0.66f2) with Android Build Support, OpenJDK, Android SDK and NDK Tools [64][65].
4. **MQDH.** Install Meta Quest Developer Hub ⚠ (download page not opened); sign in with the same developer account [64].
5. **Cable.** Connect USB-C data cable; on the headset enable MTP Notification, allow USB debugging "Always" [62][64]. On Windows install the Oculus ADB driver ⚠ [64][66].
6. **Check.** MQDH Device Manager shows green Active; add Unity's `platform-tools` to PATH; `adb devices` shows `device` [64].
7. **Project.** Hub > New project > Universal 3D [65]. File > Build Profiles > Meta Quest > Enable/Switch Platform [65].
8. **XR.** Package Manager: install `com.meta.xr.sdk.all`; ensure Unity OpenXR Plugin 1.15.1 [65]. Project Settings > XR Plug-in Management: OpenXR on for Standalone and Android; Meta XR Feature on [65].
9. **Fix.** Window > Meta > Tools > Project Setup Tool > Fix All for Android [65].
10. **Signing.** Optional: create a keystore in Player > Publishing Settings and keep it; otherwise Unity's debug key is used [85].
11. **Scene.** Add an XR rig and a simple look-and-teleport interaction ⚠ (Meta Interaction SDK sample or XR Interaction Toolkit; not read).
12. **Build.** Build Profiles > Meta Quest > Build (APK), or Build And Run with the headset attached [77].
13. **Install.** Drag the APK into MQDH Device Manager > Apps (or `adb install -r app.apk`) [66][69].
14. **Run.** In the headset: Library > Unknown Sources > your app [69].
15. **Logs.** `adb logcat` while the app runs ⚠ [66][72].

**PC-streamed alternative [Fact][83]:** install the Meta Horizon Link app on the PC and sign in; in the headset turn on Quest Link and Launch Quest Link (USB or Air Link); in Unity set OpenXR runtime to Meta ⚠ and press Play. No APK needed. **[Judgement]** Use it for iteration only.

**Not verified:** every step of the above; current MQDH download page; Quest 2 Guardian settings; wireless pairing on Quest; exact Unity 6 build to use; XR Interaction Toolkit versions; Unreal.

## Rift and other headsets (optional)

- **[Fact]** OpenXR is the portable layer. Unity OpenXR Plugin 1.15.1 is linked against OpenXR SDK 1.1.45 and works with interaction profiles chosen per device [71]. Rift S and Quest via Link use the Meta runtime on Windows (D3D11) [77].
- **[Judgement]** Keep the game logic engine-neutral about input: gaze/select plus teleport, via OpenXR actions, so Rift S, Quest 3 and SteamVR headsets work with a build target change. Quest 3 and 3S share the same Android pipeline [63].
- **[Unverified]** Rift S end-of-support dates (see earlier briefing [77]).

---

# Appendix A: Rift and PC VR briefing (earlier version; store content not needed)

Conventions: **[Fact]** = taken from a cited source. **[Judgement]** = my recommendation or inference. **[Unverified]** = I could not confirm it. Numbers in brackets point to `references.md`. Research date: 2026-10-24.

## AA0. Summary (for people who know nothing about VR)

- **[Fact]** "Oculus Rift" is a family of PC-tethered headsets (DK1, DK2, CV1, Rift S). Meta has since replaced the "Oculus PC app" with the **Meta Quest Link / Meta Horizon Link** PC app, which also runs Rift S content [42][43].
- **[Fact]** The modern way to build for the Rift is **OpenXR**, the Khronos open standard. Oculus has accepted OpenXR apps in the store since runtime v19, and Unreal treats OpenXR as the only supported VR API [44][45][46].
- **[Fact]** Today's Meta headsets (Quest family) can run PC VR through Link / Air Link, so a PC VR game written once in OpenXR reaches Rift S owners and Quest-on-PC owners [47][48].
- **[Judgement]** Recommended path: **Unity 6 + OpenXR Plugin + XR Interaction Toolkit, target PC (Windows, DX11), test with Meta XR Simulator when no headset is at hand, ship on Steam first and Meta's Link PC VR store second.** Reasons in section 4.
- **[Judgement]** Do not design around DK1, DK2 or CV1 hardware. They are legacy. Design for "OpenXR PC VR with 6DoF controllers", which covers Rift S, Quest via Link, and SteamVR headsets.

## A1. Hardware and versions

| Headset | Year | Tracking | Connection | Status today |
|---|---|---|---|---|
| DK1 / DK2 | 2013 / 2014 | DK1 rotation only; DK2 external IR camera | HDMI+USB | **[Unverified]** No official current support found; treat as historical. No controllers, so unsuitable for the project. |
| CV1 | 2016 | External IR sensors, Touch controllers | HDMI + USB 3 | **[Fact]** Still works on the Link PC app per community setup guides [49]; **[Fact]** Linux works via SteamVR/Monado [50]. **[Unverified]** No official lifecycle statement found. |
| Rift S | 2019 | Inside-out, 5 cameras, Touch controllers | DisplayPort + USB 3 | **[Fact]** Meta's Rift page still lists it with docs and SDKs and states "the same SDKs and documentation as the original Rift"; 2560x1440 at 80 Hz [51]. **[Fact]** Meta's Link PC requirements page still lists Rift S [43]. **[Fact]** No end-of-support date found in official sources [43][51]. It was discontinued as a product (**[Unverified]**: I did not retrieve the primary announcement). |
| Quest 2 / 3 / 3S / Pro via Link or Air Link | 2020+ | Inside-out | USB-C cable (Link) or Wi-Fi (Air Link) | **[Fact]** Supported by Meta for PC VR development; Link runs only on Windows 10+ [52]. Quest 1 reached end of support on 2024-08-31 [53]. |

- **[Fact]** Oculus accounts ended in January 2023; a Meta account is required [43].
- **[Judgement]** The practical market is Quest-via-PC plus Steam headsets plus a shrinking Rift S base. Official statements on Rift support are silent rather than reassuring, so plan on it working but not on it being a growth platform.

## A2. SDKs and runtimes

- **Legacy Oculus PC SDK / LibOVR / Oculus Integration (Unity):** **[Fact]** Still accepted: VRC.PC.SDK.2 allows Oculus PC SDK 1.8+ or OpenXR 1.0+ [44]. **[Fact]** The Unity learning course for Oculus is marked deprecated [51]. **[Fact]** In Unreal, Epic deprecated the Oculus VR plugin in 5.1 and Meta says not to use it in UE5 [45][46]. **[Judgement]** Do not start new work on it.
- **OpenXR:** **[Fact]** Khronos standard [54]; the Rift gained basic OpenXR support in 2019 [55]; store submissions accept OpenXR since runtime v19 [44]. **[Fact]** The Meta PC software can be set as the active OpenXR runtime; SteamVR can too, and the choice can affect smoothness [47].
- **Meta XR SDKs (Core SDK etc.):** **[Fact]** Packages for Unity and Unreal; they add Meta-specific features. Unity OpenXR Plugin 1.15.1 is recommended with Meta XR SDK v74+ and Unity 6 [56]. **[Fact]** The generic Unity OpenXR plugin supports "Oculus PC + Link (Windows 64-bit, DX11): HMD and controllers only" [57].
- **Platform SDK:** **[Fact]** Entitlement check (ownership) is expected on store builds; v207 updated 2026-09-22; some features (device integrity, abuse report, user age category) are not supported on PC VR [44][58].
- **[Judgement]** Use plain OpenXR plus the Touch interaction profile for the base game; add Meta XR Core SDK only if you need Meta-only features.

## A3. Engines

| Engine | VR status | Notes |
|---|---|---|
| Unity | **[Fact]** OpenXR Plugin 1.14 needs Unity 2021.3+; Meta's current docs require Unity 6 (6000.0.66f2+) for Meta SDK work, 6.1+ recommended [56][57][59]. | Largest tutorial base; Meta XR Simulator integrates. |
| Unreal | **[Fact]** Meta XR plugin; "Epic Native OpenXR" is the default and recommended backend, OVRPlugin is legacy [46]. | High visual fidelity; heavier, C++/Blueprint. |
| Godot | **[Fact]** OpenXR built in since 4.0; OpenXR Vendors plugin adds Meta extensions; godot-xr-tools has locomotion, grabbing, pointing; Godot 4.6 has an XR Project Setup Wizard [60]. | **[Unverified]** The Godot XR docs index lists "Basic XR Locomotion" under XR Tools, but I did not read it; teleport specifics are not verified. |
| Others | **[Unverified]** Native C++ with OpenXR directly, or Unity-less frameworks (e.g. Babylon/WebXR): not researched. | |

**[Judgement] Recommendation: Unity 6.** Reasons: Meta documents it most thoroughly, includes the Simulator and Link workflows, the OpenXR plugin is mature, and a small team can find ready-made teleport/locomotion in XR Interaction Toolkit. Godot is the credible open-source alternative if licensing or engine size matters; Unreal if high-end visuals matter more than iteration speed.

## A4. PC requirements

- **[Fact]** Windows 10 or later; Windows 7 and 8.1 support ended 2020-01-14 [43]. Link only works on Windows 10+ [52].
- **[Fact]** Rift S room-scale: 9x9 ft space with at least 6.5x6.5 ft clear [51].
- **[Fact]** Per Meta's requirements page [43] (read on 2026-10-24):
  - **Rift S minimum:** i3-6100 / Ryzen 3 1200, GTX 1050 Ti / RX 470, 8 GB+ RAM, 1 USB 3.0, Mini DisplayPort. Recommended: i5-4590 / Ryzen 5 1500X, GTX 1060 / RX 480.
  - **Rift CV1 minimum:** same CPU/GPU, 1 USB 3.0 + 2 USB 2.0, HDMI 1.3. Recommended: 3 USB 3.0 + 1 USB 2.0.
  - **Quest via Link, minimum:** i5-4590 / Ryzen 5 1500X, 8 GB+ RAM, 1 USB port. Recommended: i7 / Ryzen 7, RTX 20-series or RX 6000-series, 16 GB, USB-C.
  - **Link GPU caveats:** Intel Arc and workstation cards are unsupported; RTX 2050 is unsupported; RTX 3050 laptop and 3050 Ti are not recommended for Link.
- **[Judgement]** Test on the recommended spec, not the minimum.
- **[Judgement]** For development, plan on a current mid-range GPU with a DisplayPort output (Rift S) or USB 3 / Wi-Fi 6 (Quest via Link).

## A5. Input

- **[Fact]** Rift S and CV1 use Oculus Touch controllers; in OpenXR enable the "Oculus Touch Controller" interaction profile [57]. In Unreal, the old Oculus controller pose is deprecated; use OpenXR grip or aim [46].
- **[Fact]** Gamepad: **[Unverified]** whether store VRCs require or allow gamepad-only play; not researched. **[Judgement]** Support Touch first; add a gamepad fallback only if cheap.
- **[Judgement]** Map teleport to thumbstick push-and-release (aim, then release to teleport), snap-turn on the other stick.

## A6. Comfort and locomotion

All of this section is **[Judgement]** informed by general VR practice; I did not retrieve a primary Meta comfort source, so it is **[Unverified]** against official guidelines (Meta's Rift VRC page [44] and comfort guidance should be read before design lock).

- Teleport (blink or short fade) is the least nauseating locomotion and suits a teleport-based game. Avoid smooth artificial movement unless optional.
- Add vignette on any smooth turn or movement; offer snap-turn by default.
- Support both seated and standing play: expose a height/offset recenter. Rift S and Quest track both.
- Keep frame rate at the headset's native rate (Rift S is 80 Hz [51]); dropped frames cause more discomfort than anything else.
- Teleport design points: show an arc with a valid/invalid target marker, confirm the destination visually, keep targets within the guardian/play area where possible.

## A7. Testing without a headset

- **[Fact]** **Meta XR Simulator**: standalone app, Windows 10+ or Apple-silicon macOS; works with Vulkan, D3D11, D3D12; the app must request OpenXR 1.0 to 1.1; no extra Unity package for OpenXR projects; hand tracking is simulated with keyboard and mouse [56].
- **[Fact]** Link needs a headset; Build-and-Run is slowest [56]. Meta XR Operator is experimental (Core SDK v207+, OpenXR plugin 1.17+) [56].
- **[Fact]** Unity's XR Interaction Toolkit has its own device simulator. **[Unverified]**: I did not open its page; confirm it in Unity docs.
- **[Judgement]** Use Simulator for logic and UI iteration, a real headset for comfort and teleport feel. Comfort cannot be tested headset-less.

## A8. Packaging and distribution

- **[Fact]** **Meta**: PC VR apps go to the "Link PC VR Store" after review via the Developer Dashboard; upload with the Oculus Platform Tool (Unity: Meta > Tools), the command-line tool for packages over 200 MB, or MQDH; package under 1 GB per Unity tool docs; no SDK copies or debug symbols; entitlement check recommended within 10 seconds of launch [44][58].
- **[Fact]** **Steam**: OpenXR PC games listed on Steam support Rift S and Quest over PC connection; SteamVR 2.18 lets Quest owners stream PC VR over USB with Steam Link [47][61].
- **[Fact]** **SideQuest** sideloads APKs onto Quest, so it is a standalone-Quest channel, not a PC VR one [47].
- **[Fact]** **itch.io**: PC builds are possible but a developer report shows a build opening in desktop mode over Air Link when the runtime was not selected [47]. **[Judgement]** Use itch for demos; document "set OpenXR runtime" for users.
- **[Judgement]** Ship to Steam first (broadest PC VR reach), then Meta's store.

## A9. Step-by-step: empty Windows machine to a running build

Assumes Windows 10/11 64-bit with a suitable GPU. Items marked ⚠ I could not verify the exact click-path or version; version numbers are from the cited docs.

1. Update Windows and GPU drivers (vendor site). ⚠ minimum driver versions not verified.
2. Create a **Meta account** and a **Unity ID** [56][43].
3. Install the **Meta Quest Link / Horizon Link PC app** from Meta's site. Sign in, run device setup for your headset (Rift S: DisplayPort + USB 3; CV1: HDMI + USB 3; Quest: USB-C cable or Air Link) [49]. In the app's settings, set it as the **active OpenXR runtime** ⚠ (menu naming varies by release) [49][47].
4. Install **Unity Hub**, then **Unity 6000.0.66f2 or newer** (6.1+ recommended) with **Windows Build Support (IL2CPP)** [59][56]. Android modules are only needed if you also target Quest standalone.
5. Create a project from the **3D (URP)** template ⚠ template name varies.
6. **Edit > Project Settings > XR Plug-in Management**: on the **PC** tab tick **OpenXR**; under OpenXR add the **Oculus Touch Controller Profile** and set Play Mode OpenXR Runtime to **Meta/Oculus** [57].
7. **Window > Package Manager**: install **XR Interaction Toolkit** and its Starter Assets (sample with teleport) ⚠ exact package version not verified. Optionally install Meta XR Core SDK (v74+) with OpenXR Plugin 1.15.1 [56].
8. Set **Graphics API to Direct3D11** (Player Settings > Other Settings), matching the documented Oculus PC + Link support [57].
9. Open the sample scene, add an XR Origin (XR Rig), add a Teleportation Area/Anchor and Teleportation Provider, press **Play** with the headset on (Link app running) [57].
10. No headset: install **Meta XR Simulator** (standalone), activate it in Unity, press Play [56].
11. **Build**: File > Build Profiles > Windows, Build; launch the .exe with the Link app running and runtime set.
12. For release: create the app in the Meta Developer Dashboard, upload via the Oculus Platform Tool [58]; for Steam, use Steamworks (⚠ not researched).

### AWhat I could not verify
- (Resolved in v2: PC CPU/GPU/RAM minimums, section 4. The page's GPU tables were garbled in extraction, so individual supported cards are not listed.)
- Any official end-of-support date or statement for Rift CV1 and Rift S, and the discontinuation announcement itself.
- Godot docs: access arrived late. The XR index page only listed topics (Setting up XR, OpenXR Settings, Basic XR Locomotion, Room scale), and I did not read those pages. Godot teleport setup remains unverified.
- Unity XR Interaction Toolkit and Epic docs for current UE 5.x PC-VR setup (the Epic page I fetched was empty).
- Meta's official comfort guidance and gamepad policy; Steamworks requirements; exact Link app menu names.
- I have not run any of the steps on a real machine.
