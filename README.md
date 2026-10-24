# Quest Sentinel prototype

A hello-world, Sentinel-inspired VR app for the Meta Quest 2, and the pipeline
that builds its APK headlessly on Linux from a fresh clone.

Stack: Godot 4.7.2 (Compatibility renderer, OpenGL ES 3), Godot OpenXR Vendors
plugin 5.1.0 (Meta flavour), Gradle build, arm64-v8a. Toolchain pinned with
[mise](https://mise.jdx.dev). **Never run on a real headset by the author** — see
`docs/FINDINGS.md`.

## What the app does (what you see and do in the headset)

**World.** You stand on one tile of a 12 × 12 grid of square stone-green
columns of different heights, a rolling landscape, under a blue sky. A tall red
figure with a yellow "nose", the **Sentinel**, stands on the highest tile and
slowly turns on the spot. Three green capsules are **trees**. The label on your
left controller shows your **energy** (start: 6) and a hint line.

**Looking.** Turn your head and body freely. There is no walking or stick
turning: you move only by transferring (below). Point your right controller: a
thin yellow ray comes out of it and a flat disc marks the tile you aim at.
**Yellow disc = you can see that tile** (no terrain blocks the line from your
eyes to it); **red disc = hidden behind terrain**, so you cannot act on it.

**Controls (right Touch controller).**

| Button | Action | Rule |
|---|---|---|
| Trigger | Create a **synthoid** (blue capsule, a stand-in body) on the aimed tile | needs a visible, empty tile and 3 energy |
| A | **Transfer**: teleport into the synthoid on the aimed tile | needs a visible synthoid; the synthoid is consumed and you now stand on that tile, looking from its height |
| B | **Absorb** the aimed tree (+1 energy) or synthoid (+3 energy) | the target must be visible |

**Goal.** Create synthoids on higher and higher visible tiles and transfer
into them until you stand on a tile **at least as high as the Sentinel's**. The
label then reads **YOU WIN**.

**Placeholders / not built.** The Sentinel only rotates: it never sees, drains
or attacks you. No sound, no real art, no menu or restart, fixed terrain, no
snap-turn or comfort options, win is just a label. Controls and rules are
tested logic (`game/tests`), but the VR view has not been run on a headset.

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
| `game/` | Godot project (`scripts/game_logic.gd` rules, `scripts/main.gd` VR view, `tests/`) |
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
git clone https://git.lab.internal/prototypes.git && cd prototypes
git checkout rosa/quest-sentinel-mise
mise trust
mise run setup                         # installs pinned tools, SDK, templates (~3 min)
mise run build                         # tests, export, verify -> game/build/quest-sentinel.apk (~5 min)
mise run test                          # all headless tests (rules ACs, scene tests)
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
