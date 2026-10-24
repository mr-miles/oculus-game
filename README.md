# Quest Sentinel prototype

A hello-world, Sentinel-inspired VR app for the Meta Quest 2, and the pipeline
that builds its APK headlessly on Linux from a fresh clone.

You stand on a tile of a rolling landscape. Point the right controller at a
tile: **trigger** creates a synthoid (costs 3 energy), **A** transfers
(teleports) you into a synthoid you can see, **B** absorbs a tree or synthoid
(returns energy). Reach a tile as high as the red Sentinel's to win. A tile is
selectable only if the line of sight from your eye to it is not blocked by
terrain (cursor yellow = visible, red = hidden). The left-hand label shows
energy.

Stack: Godot 4.7.2 (Compatibility renderer, OpenGL ES 3, as the research pack recommends), Godot OpenXR Vendors plugin 5.1.0
(Meta flavour), Gradle build, arm64-v8a, Quest 2 / 3 / 3S in the manifest.

## Layout

| Path | What |
|---|---|
| `game/` | Godot project (`scripts/game_logic.gd` rules, `scripts/main.gd` VR view, `tests/`) |
| `tools/setup-toolchain.sh` | one-time download of Godot, JDK 17, Android SDK, plugin (pinned, checksummed) |
| `tools/build-apk.sh` | plugin copy, tests, Android export, APK checks |
| `tools/verify-apk.sh` | checks package, ABI, OpenXR libs, Quest manifest entries, signature |
| `docs/DEVICE_GUIDE.md` | how a human installs and runs the APK on a headset |
| `docs/FINDINGS.md` | what was run, what was not, what a dev team needs |

## Prerequisites (build machine)

Linux x86_64, bash, curl, python3, tar, coreutils; **4 GB RAM** minimum (the script
caps Gradle at 1.5 GB), **~5 GB free disk** outside any small partition (the
toolchain is ~4 GB, the Gradle build ~1 GB more), network access to
`github.com`, `release-assets.githubusercontent.com`, `dl.google.com`,
`repo.maven.apache.org`, `services.gradle.org`, `plugins.gradle.org`,
`maven.google.com`. No NDK is needed. No Android Studio, no display.

## Build

```sh
git clone https://git.lab.internal/prototypes.git && cd prototypes
git checkout rosa/quest-sentinel
export TOOLCHAIN=$HOME/.quest-toolchain      # optional; this is the default
tools/setup-toolchain.sh                      # once, ~10 min
tools/build-apk.sh                            # ~2-5 min -> game/build/quest-sentinel.apk
```

`build-apk.sh` runs the logic tests and a headless scene smoke test, exports a
**debug-signed** APK and runs `verify-apk.sh`. Expected end of output: eight
`OK` lines. If the machine sits behind a TLS-inspecting proxy, its CA is imported
into the downloaded JDK's trust store (`EXTRA_CA_CERT=/path/ca.crt`).

Run the tests alone:

```sh
source tools/env.sh
$GODOT --headless --path game --script res://tests/test_logic.gd
$GODOT --headless --path game --script res://tests/test_scene.gd
```

## Install and run on a headset

See `docs/DEVICE_GUIDE.md` (needs a human, a developer account and a cable).

## Hard-coded or stubbed

Debug keystore only (no release signing); no sound, no real art; fixed terrain;
no enemy behaviour (the Sentinel only rotates); no snap-turn (turn physically);
package id `org.example.questsentinel` is a placeholder. **Never run on a real
headset by the author** — see `docs/FINDINGS.md`.
