# Findings: code in git to an app on a Quest 2

## Answers

1. **Headless APK build on Linux with Godot 4.7.2 + OpenXR Vendors 5.1.0: yes** (high confidence). `mise run setup` then `mise run build` produce a 90 MB arm64 APK, signed (v2), with the Quest manifest entries (`com.oculus.supportedDevices=quest2|quest3|quest3s`, `com.oculus.intent.category.VR`, OpenXR loader and Vendors library packaged). Checked by `tools/verify-apk.sh` (aapt2 + apksigner).
2. **Sentinel-style hello world: rules and scene tested, VR path not run** (high confidence for rules, none for on-device behaviour). 12 logic checks pass; a headless scene smoke test passes on the flat fallback path.
3. **Human guide: written, unverified on a device** (medium-low). adb works as a tool on the build host; nothing was ever connected.

## Not run (no headset)

- The app has never started on an OpenXR runtime. On the build host Godot reports "Failed to find default runtime" and falls back to a flat camera; the `xr_active` branch of `main.gd`, controller tracking, the ray, the button names (`trigger_click`, `ax_button`, `by_button` come from the generated default action map, which binds Touch controller A/B/trigger) and the HUD placement are untested.
- Install via adb or MQDH, Unknown Sources listing, Guardian, framerate (72 Hz target is unmeasured), thermal behaviour, Quest 2 specific rendering (Compatibility renderer, no foveation or tuning).
- Developer account and Developer Mode steps are from memory of Meta's docs, not followed.
- Release-mode signing and `--export-release`.
- The pack was first invisible to me (a-1), then republished as a-2; I compared it after the first build. Differences: (1) my first build used the Mobile renderer; switched to the pack's Compatibility (OpenGL ES 3) before final, so what was built and verified is Compatibility. (2) The pack lists NDK 28.1 and CMake 3.10.2 as prerequisites; the debug Gradle build succeeded without either (NDK would not fit on the 8 GB build disk; it may matter for release builds or native plugins, untested). (3) I used the plugin zip's `addons/` layout under `asset/`, not `assets/`. (4) The pack suggests `adb shell monkey -p <package> 1` to launch (unverified there); the guide uses `am start` with the component name read from the manifest. (5) The pack's Linux adb notes (udev rule for Meta vendor id 2833, MTP notification prompt) are added to the guide.

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

## Reproducible toolchain with mise (follow-up)

- `mise.toml` pins Java (Temurin 17.0.21+9), Godot 4.7.2 (aqua registry) and, through the `http:` backend with sha256, the Android command-line tools and the OpenXR Vendors plugin. `mise.lock` holds checksums for the registry tools. SDK packages and Godot templates are fetched by `tools/setup-android.sh` (templates sha512-checked). Gradle itself comes from the project's wrapper.
- Clean-state proof: fresh clone, no mise data or cache dirs, empty Android SDK dir, Godot settings and templates redirected into `.toolchain`, earlier toolchain deleted (not just hidden: the disk is too small for two); `mise run ci` took 6m46s after tools were installed and passed the tests and all 9 verify checks. The resulting APK has the same size as before (85,924,415 bytes), an identical manifest, and identical content for 135 of 137 entries; the 2 differing entries are the serialized main scene and the asset index (same size), not native code.
- Pitfalls hit: (1) setting XDG_DATA_HOME in mise's env makes mise reinstall all tools there (doubling 0.7 GB); the redirect now happens only in `tools/env.sh`, after `mise where`. (2) The aqua Godot package has no `godot` binary name, only `Godot_v4.7.2-stable_linux.x86_64`. (3) `mise run` computes PATH before installing, so scripts locate tools with `mise where`. (4) Installing registry tools with attestations (e.g. actionlint) needs tuf-repo-cdn.sigstore.dev; Godot and Java did not.
- CI workflow `.github/workflows/build-apk.yml`: not run (no GitHub Actions here). Only parsed with PyYAML (structure fine); actionlint could not be used.
