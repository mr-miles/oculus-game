# Quest Sentinel prototype

A hello-world, Sentinel-inspired VR app for the Meta Quest 2, and the pipeline
that builds its APK headlessly on Linux from a fresh clone.

Stack: Godot 4.7.2 (Compatibility renderer, OpenGL ES 3), Godot OpenXR Vendors
plugin 5.1.0 (Meta flavour), Gradle build, arm64-v8a. Toolchain pinned with
[mise](https://mise.jdx.dev). **Never run on a real headset by the author** — see
`docs/FINDINGS.md`.

## What the app does (what you see and do in the headset)

**Lobby.** The app starts in a calm lobby: a panel two metres in front of you
with four pages (Story, Rules, How to play with a controller sketch, Ready).
Point the right controller at **Back**, **Next** or **Start** and pull the
trigger. **Start** is on every page and loads level 1.

**World.** A level is a 31 x 31 grid of square stone-green columns (2 m wide,
altitude 1-11 m) under a blue sky. Red **Sentinels** (tall, with a yellow nose
that shows where they look) stand on the highest ground; green **trees** (3 m
tall) are scattered about. There are ten levels; rules and level generation are
in `docs/SPEC.md` (sections 3-4).

**HUD.** A head-locked panel 1.2 m in front of you, slightly below the centre of
gaze: **Energy** (number and bar), **Level n of 10**, **Sentinels: k of N
left**, a red border and countdown while a Sentinel is watching you, and a
one-line message that explains every failed action.

**Controls.**

| Input | Action |
|---|---|
| Right ray | Yellow disc = you can see that tile, red = hidden |
| Right trigger | Create a synthoid (blue body) on the aimed tile (3 energy); after a loss, try the level again |
| Right A | Move into the aimed synthoid (0.2 s fade) |
| Right B | Absorb the aimed tree (+1), synthoid (+3) or Sentinel (+4) |
| Left stick left/right | Snap turn 30 degrees |
| Left Y | Pause menu: Resume / Restart level / Back to lobby |
| Left X | Hint for the current situation |

Each action plays its own placeholder sound and a short controller pulse.
Absorb every Sentinel to clear a hill; clearing level 10 shows the ending card
and returns to the lobby.

Screenshots (rendered headlessly, see below) are in `docs/screenshots/`.

## Chipset: why an arm64 APK from an x86-64 build machine

The Quest 2 is an ARM64 device (Qualcomm Snapdragon XR2), so the APK must contain
`arm64-v8a` native code, and it does: its only native libraries are in
`lib/arm64-v8a/` (Godot runtime, OpenXR loader, Vendors plugin, libc++), the
manifest targets `quest2|quest3|quest3s`, and `tools/verify-apk.sh` reads each
`.so` ELF header and checks the machine is AArch64. The build host only runs
the build tools; the game's native code is not compiled on it (it comes
prebuilt in Godot's Android export templates), so this is a cross-build in
effect. Host-architecture specific pieces of the pipeline: the Godot editor
binary (`linux.x86_64`; there is a `linux.arm64` build), the Temurin JDK
(`x64`; `aarch64` exists), and the Android build-tools/platform-tools
(`aapt2`, `adb`, `zipalign` are x86-64 Linux binaries; Gradle also fetches an
`aapt2` for the host). On an arm64 Linux host these three would need their arm64
variants in `mise.toml`; nothing else changes. Google's SDK has no official
arm64-Linux build-tools, so that path is untested and likely rough.

## Layout

| Path | What |
|---|---|
| `mise.toml`, `mise.lock` | pinned tools, env and tasks; the lock file carries checksums |
| `game/` | Godot project: `scripts/game_logic.gd`, `levels.gd` (rules, levels); `main.gd`, `lobby.gd`, `hud.gd`, `rig.gd`, `menu3d.gd`, `terrain.gd`, `sfx.gd` (VR view); `tests/` |
| `tools/lint.sh`, `tools/screenshots.sh`, `tools/check-names.sh` | GDScript lint; render `docs/screenshots/` (needs `xvfb-run`) |
| `tools/setup-android.sh` | SDK packages, Godot Android templates (sha512-checked), debug keystore, settings |
| `tools/build-apk.sh`, `run-tests.sh`, `verify-apk.sh` | build, tests, APK checks |
| `.github/workflows/build-apk.yml` | CI: same tasks, APK uploaded as artifact (not run here; see below) |
| `docs/DEVICE_GUIDE.md` | how a human installs and runs the APK on a headset |
| `docs/FINDINGS.md` | what was run, what was not, what a dev team needs |

## Build (from a fresh clone)

Prerequisites: Linux x86-64, bash, curl, python3 (3.8+, for zip extraction), 4 GB
RAM, about 6 GB free disk (mise tools 0.7 GB, SDK 0.8 GB, Gradle cache 1.3 GB,
templates 0.4 GB, build 0.8 GB), and network access to github.com
(+ release-assets.githubusercontent.com), dl.google.com, maven.google.com,
repo.maven.apache.org, services.gradle.org, downloads.gradle.org,
plugins.gradle.org, central.sonatype.com, and mise's own hosts (mise.jdx.dev,
mise-versions.jdx.dev, mise-java.jdx.dev). No NDK, Android Studio or display.

```sh
curl https://mise.run | sh            # or any mise install; tested with v2026.10.18
git clone https://git.shop.internal/product.git && cd product
mise trust
mise run setup                         # installs pinned tools, SDK, templates (~3 min)
mise run build                         # tests, export, verify -> game/build/quest-sentinel.apk (~5 min)
mise run test                          # all headless tests (rules ACs, scene tests)
mise run lint                          # parse every script, fail on any error or warning
mise run names                         # AC-38 gate; NAMES_FILE=<list kept outside the repo> (CI sets it)
mise run screenshots                   # re-render docs/screenshots/ (needs xvfb-run and Mesa GL)
mise run verify                        # re-check an existing APK
```

`mise run ci` = setup + build. Everything lands in `~/.local/share/mise` (tools)
and `./.toolchain` (SDK, Gradle cache, Godot templates and settings); delete both
to start clean. The APK is **debug-signed** (a throwaway key made by setup) —
fine for `adb install`, not for any store.

Behind a TLS-inspecting proxy, Java ignores the system CA store. Optionally set
`EXTRA_CA_CERT=/path/ca.pem` when running `mise run setup`; it is added to the
mise-managed JDK's trust store. Without the variable nothing is touched.

## CI

`.github/workflows/build-apk.yml` installs mise (`jdx/mise-action`), caches
`.toolchain`, runs `mise run ci`, and uploads `game/build/quest-sentinel.apk`.
It has **not been run** (no GitHub Actions here; the firm's git is not GitHub); the YAML was
only parsed locally. Expect to adjust action versions when first run.

## Install and run on a headset

See `docs/DEVICE_GUIDE.md` (needs a human, a developer account and a cable).
