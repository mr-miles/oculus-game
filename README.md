# Quest Sentinel prototype

A hello-world, Sentinel-inspired VR app for the Meta Quest 2, and the pipeline
that builds its APK headlessly on Linux from a fresh clone.

Stack: Godot 4.7.2 (Compatibility renderer, OpenGL ES 3), Godot OpenXR Vendors
plugin 5.1.0 (Meta flavour), Gradle build, arm64-v8a. Toolchain pinned with
[mise](https://mise.jdx.dev). **Never run on a real headset by the author** — see
`docs/FINDINGS.md`.

## What the app does (what you see and do in the headset)

**Lobby.** The app starts in a calm lobby: a large panel 2.5 metres in front of where you face at start (fixed in the world, never following your head)
with four pages (Story, Rules, How to play with a controller sketch, Ready).
Point the right controller at **Back**, **Next** or **Start** and pull the
trigger. **Start** is on every page and loads level 1.

**World.** A level is a 31 x 31 grid of square stone-green tiles (2 m wide,
altitude 1-11 m) with real slopes, ridges and valleys, under a blue sky. Only
**flat** tiles (darker-brown tiles are sloped) can hold trees, Sentinels,
the player and anything you create. Red **Sentinels** (tall, with a yellow nose
that shows where they look) stand on the highest ground; green **trees** (3 m
tall: a 1.2 m trunk under a 1.8 m leafy canopy) are scattered about. There are ten levels; rules and level generation are
in `docs/SPEC.md` (sections 3-4).

**HUD.** A head-locked panel 2.5 m in front of you, large enough to read, above the centre of
gaze so it never covers the ground you are looking at: **Energy** (number and
bar), **Level n of 10**, **Sentinels: k of N left**, the create mode
(**Create: Synthoid (3)** or **Create: Boulder (2)**), a red border and
countdown while a Sentinel is watching you, and a one-line message that
explains every failed action.

**Controls.**

| Input | Action |
|---|---|
| Right ray | Yellow disc = flat tile you can see, red = flat but hidden, grey = sloped ("Needs flat ground") |
| Right trigger | Create what the mode says on the aimed tile: a synthoid (blue body, 3 energy) or a boulder (grey slab 1.0 m high, 2 energy, up to 6 per tile, also under your own feet to climb); after a loss, try the level again |
| Right grip | Switch the create mode Synthoid <-> Boulder (shown on the HUD; a translucent ghost shows what you will make) |
| Right A | Move into the aimed synthoid (0.2 s fade) |
| Right B | Absorb the top object of the aimed tile: tree (+1), boulder (+2), synthoid (+3) or Sentinel (+4) |
| Left stick left/right | Snap turn 30 degrees |
| Left Y | Pause menu in front of you, fixed in the world: Resume / Restart level / Back to lobby |
| Left X | Hint for the current situation |

Each action plays its own placeholder sound and a short controller pulse.
Absorb every Sentinel to clear a hill; clearing level 10 shows the ending card
and returns to the lobby.

Screenshots (rendered headlessly, see below) are in `docs/screenshots/`.

## Rules, levels and tests

All rules are pure code in `game/scripts/game_logic.gd` (no nodes) and the ten
levels in `game/scripts/levels.gd`; the VR view only calls them.

- **Energy.** Start 10 (carried to the next level, at least 10, at most 63). A
  synthoid costs 3 and a boulder 2; absorbing gives tree 1, synthoid 3, boulder 2,
  Sentinel 4 (only the top object of a tile is absorbed). Boulders (1.0 m, up to
  6 per tile) stack under a synthoid, block sight, and can be made under your
  own feet to raise your eye. Only flat tiles take objects; trees cannot be
  created. At most 64 objects exist at once.
- **Sentinels.** Idle until your first create, absorb or move. Then each turns
  28.125 degrees every 11.94 s (only while it is not watching you) and watches
  a 56.25 degree cone. While you are inside the cone with a clear line of sight
  you lose 1 energy after 7.14 s, then every 1.74 s. Hide behind terrain or a
  tree, or absorb it. Energy 0 is not yet a loss: you lose when a drain
  happens at 0.
- **Win / lose.** Absorb every Sentinel to clear the hill; after level 10 the
  ending card shows. A loss lets you retry with the level's original energy.
- **Levels.** `Levels.build(n)` is deterministic: 31 x 31 tiles on a 32 x 32
  corner grid (altitudes 1-11, neighbouring corners at most 3 apart) grown by
  the original's 40-bit LFSR generator, smoothed twice, scaled, repaired and
  stretched (`Levels.stages(n)` exposes every step). Sentinels use the original's 4 x 4 block rule, trees
  stand below the lowest Sentinel, the start is a low empty tile. Counts per
  level are in `docs/SPEC.md` section 4.

**Tests.** `mise run test` runs every `game/tests/test_ac_*.gd` (one Godot
process each; `PASS`/`FAIL` lines) and the scene smoke test, and exits non-zero
on any failure or script error. `docs/SPEC.md` section 14 maps every AC to its
test. `mise run test-gate` proves the gate itself (AC-37): it plants a failing
and a broken test and checks that `run-tests.sh` fails. `mise run build` runs
tests, lint and the APK checks.

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

## Pinned versions

| Item | Version | Where | Why this one |
|---|---|---|---|
| mise | 2026.10.19 | `min_version` in `mise.toml`, workflow `version:` | latest; local and CI must match |
| Java | Temurin 21.0.13+9 (LTS) | `mise.toml` | newest LTS that the Gradle 8.11.1 required by the Godot 4.7.2 Android template can run on (Java 25 needs Gradle 9) |
| Godot + export templates | 4.7.2-stable | `mise.toml`, `tools/setup-android.sh` | latest stable |
| OpenXR Vendors plugin | 5.1.0-stable | `mise.toml` | latest stable |
| Android command-line tools | 23.0 (16111833) | `mise.toml` | latest |
| Android platform / build-tools | android-36 / 36.1.0 | `tools/setup-android.sh` | what the Godot template asks for |
| Gradle / Android Gradle plugin / Kotlin | 8.11.1 / template / 2.1.21 | Godot's Android template | fixed by Godot 4.7.2; not ours to change |
| CI runner and actions | ubuntu-26.04; checkout v7, mise-action v5, cache v6, upload-artifact v7 | `.github/workflows/build-apk.yml` | latest |

The lock (`mise.lock`) covers linux-x64 only, the platform CI and the build use.

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
RAM, about 6 GB free disk (the repo's own disk must have it: setup fails with a curl write error when full) (mise tools 0.7 GB, SDK 0.8 GB, Gradle cache 1.3 GB,
templates 0.4 GB, build 0.8 GB), and network access to github.com
(+ release-assets.githubusercontent.com), dl.google.com, maven.google.com,
repo.maven.apache.org, services.gradle.org, downloads.gradle.org,
plugins.gradle.org, central.sonatype.com, and mise's own hosts (mise.jdx.dev,
mise-versions.jdx.dev, mise-java.jdx.dev). No NDK, Android Studio or display.

```sh
curl https://mise.run | sh            # or any mise install; needs mise >= 2026.10.19 (CI uses exactly that)
git clone https://git.shop.internal/product.git && cd product
mise trust
mise run setup                         # installs pinned tools, SDK, templates (~3 min)
mise run build                         # tests, export, verify -> game/build/quest-sentinel.apk (~5 min)
mise run test                          # all headless tests (rules ACs, scene tests)
mise run test-gate                     # AC-37: the test task must fail on a failing test
mise run lint                          # parse every script, fail on any error or warning
mise run names                         # AC-38 gate; NAMES_FILE=<list kept outside the repo> (CI sets it)
mise run screenshots                   # re-render docs/screenshots/ (needs xvfb-run and Mesa GL)
mise run verify                        # re-check an existing APK
```

`mise run ci` = setup + build. Everything lands in `~/.local/share/mise` (tools)
and `./.toolchain` (SDK, Gradle cache, Godot templates and settings); delete both
to start clean. The APK is **debug-signed** (a throwaway key made by setup) —
fine for `adb install`, not for any store.

Behind a TLS-inspecting proxy, Java ignores the system CA store, and without the
CA `mise run build` fails at the export step with "PKIX path building failed".
Set `EXTRA_CA_CERT=/path/ca.pem` when running `mise run setup` (re-running setup
is safe); it is added to the
mise-managed JDK's trust store. Without the variable nothing is touched (fine on a network without TLS inspection).

## CI

`.github/workflows/build-apk.yml` installs mise (`jdx/mise-action`), caches
`.toolchain`, runs `mise run ci`, and uploads `game/build/quest-sentinel.apk`.
It has **not been run** (no GitHub Actions here; the firm's git is not GitHub); the YAML was
only parsed locally. Expect to adjust action versions when first run.

## Install and run on a headset

See `docs/DEVICE_GUIDE.md` (needs a human, a developer account and a cable).
