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
| Left trigger | Absorb the top object of the tile the left (orange) ray aims at: tree (+1), boulder (+2), synthoid (+3) or Sentinel (+4). Right hand makes and moves, left hand absorbs |
| Left stick left/right | Snap turn 30 degrees |
| Left Y | Pause menu in front of you, fixed in the world: Resume / Restart level / Back to lobby |
| Left X | Hint for the current situation |

A gentle generated wind loops quietly in the background, in the lobby and in the levels. Each action plays its own placeholder sound and a short controller pulse.
Absorb every Sentinel to clear a hill; clearing level 10 shows the ending card
