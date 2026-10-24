# Findings: code in git to an app on a Quest 2

## Answers

1. **Headless APK build on Linux with Godot 4.7.2 + OpenXR Vendors 5.1.0: yes** (high confidence). `tools/setup-toolchain.sh` then `tools/build-apk.sh` produce a 90 MB arm64 APK, signed (v2), with the Quest manifest entries (`com.oculus.supportedDevices=quest2|quest3|quest3s`, `com.oculus.intent.category.VR`, OpenXR loader and Vendors library packaged). Checked by `tools/verify-apk.sh` (aapt2 + apksigner).
2. **Sentinel-style hello world: rules and scene tested, VR path not run** (high confidence for rules, none for on-device behaviour). 12 logic checks pass; a headless scene smoke test passes on the flat fallback path.
3. **Human guide: written, unverified on a device** (medium-low). adb works as a tool on the build host; nothing was ever connected.

## Not run (no headset)

- The app has never started on an OpenXR runtime. On the build host Godot reports "Failed to find default runtime" and falls back to a flat camera; the `xr_active` branch of `main.gd`, controller tracking, the ray, the button names (`trigger_click`, `ax_button`, `by_button` come from the generated default action map, which binds Touch controller A/B/trigger) and the HUD placement are untested.
- Install via adb or MQDH, Unknown Sources listing, Guardian, framerate (72 Hz target is unmeasured), thermal behaviour, Quest 2 specific rendering (Mobile renderer / Vulkan, foveation settings are the defaults suggested by Godot docs, not tuned).
- Developer account and Developer Mode steps are from memory of Meta's docs, not followed.
- Release-mode signing and `--export-release`.
- The research pack (drive a-1) was never visible to me (`no artifact a-1` for fetch and list), so the build was derived from Godot's and the plugin's own releases; I cannot say where it agrees or disagrees with the pack.

## What went wrong on the way (useful for a dev team)

- GitHub release downloads redirect to `release-assets.githubusercontent.com`, not `objects.githubusercontent.com`; both hosts need allowing.
- Java tools (sdkmanager, Gradle) ignore the system CA store: behind a TLS-inspecting proxy the proxy CA must be imported into the JDK trust store, or they fail with "IO exception while downloading manifest".
- The Vendors 5.x addon has **no `plugin.cfg`**; enabling `res://addons/godotopenxrvendors/plugin.cfg` in `[editor_plugins]` crashes the editor (signal 11, in `--import`). It registers through its GDExtension, and is activated per export preset.
- The preset option names are not what older write-ups say. Needed: `xr_features/xr_mode=1`, `xr_features/enable_meta_plugin=true`, `meta_xr_features/quest_2_support=true` (also `quest_1_support`, `quest_3_support`, `quest_pro_support`). With only `xr_mode=1` the APK builds, but has **no** Meta manifest entries and would not be a proper Quest app. Option names were found by reading the plugin binary's strings; the cleaner way is to open the project once in the editor GUI and let it write the preset.
- Gradle's default 4.5 GB heap gets OOM-killed on a 4 GB machine ("daemon disappeared unexpectedly"); the script caps it at 1.5 GB and disables the daemon.
- A 1 GB scratch partition filled during the Gradle build and showed up as a misleading "strip debug symbols" failure (`No space left on device`). The NDK is not needed for a debug APK.
- A project icon is required for Android export (`No project icon specified`).
- `gradlew` from the template zip is extracted non-executable; the script `chmod`s it.
- Disk: toolchain about 4 GB, build tree about 1 GB.

## For a development team

Keep: the pinned `tools/` pipeline, `verify-apk.sh` as a CI gate, the pure-GDScript rules in `game_logic.gd` with tests.
Rebuild: the view (`main.gd`: build scene in `.tscn`, real art, locomotion comfort such as snap turn, proper Sentinel AI and absorb/energy balancing).
Next, in order: (1) a human runs the device guide and reports; (2) fix whatever the first device run breaks; (3) measure frame time with OVR Metrics Tool on Quest 2; (4) a release keystore held outside git and `--export-release` (+ `gradle_build/export_format` AAB only if going to the store); (5) CI runner image with the toolchain baked in (the setup takes ~10 min); (6) decide the real package id; (7) check the Meta store requirements if distribution is wanted (not covered here).
Risks: unverified on hardware; Meta's developer-mode flow changes often; plugin/engine version coupling (plugin 5.1.0 says Godot >= 4.6; tested only with 4.7.2).
