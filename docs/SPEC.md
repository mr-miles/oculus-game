# Quest Sentinel: family game specification

Status: v1 (draft for build). Extends the Godot 4.7 / OpenXR prototype in this
repo (`game/`) into a complete family game for Meta Quest 2. Toolchain is the
repo's existing one: `mise run test`, `mise run build` (`tools/*.sh`); no npm.
Scope fits two engineers: **A** = rules, levels, sentinels, tests
(`game_logic.gd`, new `levels.gd`); **B** = VR view, lobby, HUD, input
(`main.gd`, new `lobby.gd`, `hud.gd`).

Source basis: the prototype and `docs/FINDINGS.md`. The board's research pack
(drive a-1) was not readable when this was written; section 13 lists what to
reconcile once it is.

## 1. Product in one paragraph

A calm, puzzle-like, non-violent VR game for ages 8+. You are a small "spark"
that lives in robot bodies called synthoids. On a landscape of stone columns,
watchful Sentinels guard the high ground. You climb by creating synthoids on
tiles you can see and moving into them, absorbing trees and synthoids for
energy, until you have absorbed every Sentinel on the level. Nothing is hurt;
losing just means your energy drains away and you try again.

## 2. Storyline

The Quiet Valley once hummed with light. Long ago the Sentinels, tall
lighthouse-keepers of the hills, grew fearful and began to hoard the light
for themselves, and the valley dimmed. You are a Spark, the last small light
that slipped past them. You cannot walk, but you can grow bodies and slip from
one into another. Climb above each Sentinel, gather its light gently (absorb
it) and the hill glows again. After ten hills the valley is bright and the
trees sing. Epilogue: the Sentinels, freed of their fear, are returned to the
light as friendly beacons.

Tone: gentle and encouraging. No blood, no enemies that hit you, no jump
scares. Text is short, large, and readable by an 8-year-old.

## 3. Rules

Grid of square tiles (edge 2 m), each a column with whole-metre height. Terms:

- **Visible**: no terrain column blocks the straight line from your eye
  (tile top + 1.6 m) to the tile's top centre (prototype `can_see`). Trees and
  synthoids do not block sight. Your own tile is never targetable.
- **Occupied**: holds a tree, synthoid, Sentinel, or you.

Constants (single source: `GameLogic` constants):

| Name | Value |
|---|---|
| SYNTHOID_COST | 3 energy |
| TREE_ENERGY | 1 |
| SYNTHOID_ENERGY (absorbing one) | 3 |
| SENTINEL_ENERGY (absorbing one) | 4 |
| START_ENERGY (level 1) | 6 |
| SENTINEL_TURN_RATE | 0.5 rad/s |
| SENTINEL_FOV | 90 degrees total (45 each side of facing) |
| DRAIN_INTERVAL | 2.0 s |
| DRAIN_AMOUNT | 1 energy |
| MAX_ENERGY | 20 (excess is lost) |

Rules:

1. Create: needs a visible, unoccupied tile and energy >= 3; costs 3.
2. Transfer (move): needs a visible synthoid; you now stand on that tile, the
   synthoid is consumed (no energy change), view height is the new tile top +
   1.6 m.
3. Absorb: needs a visible tree (+1), synthoid (+3) or Sentinel (+4); the
   object is removed. You may not absorb the tile you stand on.
4. Watched: you are watched when a Sentinel's facing is within its FOV of the
   direction to you AND the Sentinel has line of sight to your eye (same
   terrain rule, from the Sentinel's eye at tile top + 2.2 m). While watched,
   you lose DRAIN_AMOUNT every DRAIN_INTERVAL (the timer restarts when
   watched begins and resets when it ends).
5. Win a level: sentinel counter reaches 0. Lose a level: energy reaches 0.
6. Win the game: finish level 10.

## 4. Levels and progression

Ten levels, each a deterministic function of its number (`Levels.build(n)`
returns the same level every time; a fixed seed per level). Terrain is
layered sine/hash heights clamped to 0..9 (Sentinel tiles are raised to be
local peaks, at least 2 m above all tiles within 2 tiles).

| Level | Grid | Sentinels | Trees | Starting energy |
|---|---|---|---|---|
| 1 | 12x12 | 1 | 4 | 6 |
| 2 | 12x12 | 1 | 5 | carried, min 6 |
| 3 | 14x14 | 2 | 6 | carried, min 6 |
| 4 | 14x14 | 2 | 7 | carried, min 6 |
| 5 | 16x16 | 3 | 8 | carried, min 6 |
| 6 | 16x16 | 3 | 9 | carried, min 6 |
| 7 | 18x18 | 4 | 10 | carried, min 6 |
| 8 | 18x18 | 4 | 11 | carried, min 6 |
| 9 | 20x20 | 5 | 12 | carried, min 6 |
| 10 | 20x20 | 6 | 14 | carried, min 6 |

Generation constraints every level must satisfy (all checked by tests):
Sentinel tiles are distinct, at least 4 tiles apart (Chebyshev) and the highest
local tiles; trees sit on distinct non-Sentinel tiles; the player start is a
low tile (height <= 1) at least 6 tiles from every Sentinel, and is **not
watched at start** for the first 5 seconds (grace: drain timer is paused for
5 s after a level starts); and the level is solvable: from the start there is
always at least one visible free tile or tree, and the sum of reachable
energy never makes the level impossible (design test: a scripted greedy solver
bot clears levels 1-10 in logic only).

Energy carries over between levels (capped at MAX_ENERGY, minimum 6 so a
level never begins on a dead end). Progress persists only for the session; the
lobby always starts at level 1 (no save game in v1).

## 5. User actions and controls

Right Touch controller points a yellow ray; a disc marks the aimed tile
(yellow = visible, red = hidden, as the prototype). Aimed object is whatever
stands on the aimed tile.

| Input | Action |
|---|---|
| Right trigger | Create synthoid on aimed tile |
| Right A | **Move**: transfer into the aimed synthoid |
| Right B | Absorb aimed tree/synthoid/Sentinel |
| Left thumbstick left/right | Snap turn 30 degrees (rotates the XR origin around the player) |
| Left Y | Pause menu: Resume / Restart level / Back to lobby |
| Left X | Hint line: shows the one-line suggestion for the current state |

Move rules: pressing A with a visible synthoid under the ray moves you there
(this fixes the prototype bug where the move button did not change location;
see AC-12..AC-14). A move takes a 0.2 s fade (dark vignette) then the
XR origin is at the new tile top; the camera then sits at height tile + 1.6 m
(room-scale offset kept). Pressing A with no valid target does nothing but
shows the HUD message "Aim at a blue synthoid you can see" and a short
low-pitch beep. Every failed action shows a one-line reason on the HUD.

Feedback: each action plays a distinct sound and a short controller haptic
pulse (success 0.2 s / failure 0.05 s).

## 6. Win, lose, flow

- Level won: the last Sentinel is absorbed -> HUD "Hill cleared!" for 3 s,
  next level loads (level 10 -> ending card, then lobby).
- Level lost: energy 0 -> "You ran out of energy. Pull the trigger to try
  again." Trigger reloads the same level with its original start energy
  (not carried); Y offers "Back to lobby".
- No lives, no timer other than the drain; restart is always available from
  the pause menu.

## 7. Lobby

A separate scene `lobby.tscn` shown on app launch, before any level. A calm
sky, one low hill, a world-space panel 2 m in front of the player at eye
height, interacted with by the same ray + trigger. Pages, with **Back** and
**Next** buttons, and a **Start** button visible on every page (also the
final page's primary button):

1. **Story** (section 2, condensed to <= 60 words).
2. **Rules** (what to do; energy; Sentinels watching; win and lose).
3. **How to play**: a walkthrough in 5 numbered steps with a controller
   diagram: 1 point and see yellow; 2 trigger = make a body; 3 A = move into
   it; 4 B = absorb trees; 5 absorb the Sentinels. Each step names the
   button.
4. **Ready**: Start.

Start loads level 1 with 6 energy. Returning from the pause menu or ending
brings the user back here.

## 8. HUD (viewport-anchored)

The HUD is a child of the XR camera (head-locked), never of a controller. It
sits 1.2 m in front of the eyes, 0.3 m below the centre of gaze, unshaded and
drawn on top. Contents, always visible: Energy (number and bar), Level
("Level 3 of 10"), **Sentinels left** counter ("Sentinels: 2 of 3 left"),
watched warning (red text and red border when watched, with the next-drain
countdown), and the one-line message. The prototype's left-hand label is
removed.

## 9. Visual changes

- **Bigger trees**: tree height 3.0 m (prototype was a 1.2 m capsule), trunk
  radius 0.25 m, canopy radius 0.9 m, clearly taller than a synthoid (1.6 m)
  and than the player's eye (1.6 m). Absorb/aim hit area covers the whole
  tile top.
- Sentinels (red tall figures, yellow nose) face the direction they look; the
  nose shows facing. A counter ring above each Sentinel is optional.
- Synthoids blue, as in the prototype.

## 10. Technical constraints

- Godot 4.7.2, OpenXR Vendors 5.1.0, Compatibility renderer, 72 Hz target,
  arm64 APK from `mise run build`; nothing new that needs another toolchain.
- Pure rules stay in `GameLogic` / `Levels` (no nodes) and are headless
  testable; the view only calls them.
- **Test seams (required so every AC is automatable)**: `Main` exposes
  `press(button: String)` (calls the same handler as the controller signal,
  names `trigger_click`, `ax_button`, `by_button`, `by_left_button`...),
  `aim_at(tile: Vector2i)` (override for the ray), `advance(seconds: float)`
  (steps sentinels, drain and timers deterministically), and nodes named
  `Hud`, `HudEnergy`, `HudLevel`, `HudSentinels`, `HudMessage`,
  `HudWatched`, `XRCamera3D`, `XROrigin3D`, `LeftController`,
  `RightController`. `Lobby` exposes `press_start()`, `next()`, `back()` and
  nodes `LobbyPanel`, `LobbyPage`, `StartButton`.
- Tests: GDScript headless scripts under `game/tests/`, run by
  `tools/run-tests.sh` (add them; print `PASS`/`FAIL` lines like the existing
  ones). One test per acceptance criterion, named `ac_N_...`.
- Not verifiable headless (manual device checklist in `docs/DEVICE_GUIDE.md`):
  comfort, frame rate, real controller button mapping. The first
  device run must confirm AC-12 on hardware.

## 11. Known prototype bugs to cover

1. **Move button did not change the user's location.** Possible causes to
   check: (a) `ax_button` not delivered because the signal is connected to
   the right controller only while the action map names differ; (b) the
   transfer succeeding in logic but the XR origin not following the camera
   offset; (c) the aimed tile resolving to the tile below the synthoid, so
   transfer returns false silently. Fix, then prove with AC-12..AC-14, which
   assert on `XROrigin3D` / `XRCamera3D` world positions, not on logic state.
2. Sentinel never saw, drained or attacked (now covered by section 3 rule 4).
3. Win condition was a label only (now: counter 0, level load).

## 12. Acceptance criteria

Each is binary and testable; one test each. "Logic" = `GameLogic`/`Levels`
headless; "Scene" = instantiate scene headless with `Main.advance`.

**Rules and energy**

- AC-1 (Logic) New game: energy 6, 1 Sentinel, player on tile with height <= 1.
- AC-2 (Logic) Create on a visible free tile costs exactly 3 energy and adds a
  synthoid there.
- AC-3 (Logic) Create fails (no state change, reason string returned) when
  energy < 3, tile hidden, tile occupied, or tile is the player's.
- AC-4 (Logic) Absorbing a tree gives +1, a synthoid +3, a Sentinel +4; each
  removes the object; energy is capped at 20.
- AC-5 (Logic) Absorb fails on a hidden target, an empty tile, or one's own tile.
- AC-6 (Logic) A tall column on the line of sight makes a tile not visible;
  trees and synthoids do not block sight.
- AC-7 (Logic) Transfer onto a visible synthoid sets the player tile, consumes
  the synthoid and leaves energy unchanged; transfer onto a hidden or
  nonexistent synthoid fails.

**Sentinels, win and lose**

- AC-8 (Logic) A Sentinel turns at 0.5 rad/s: after `advance(2*PI/0.5)` it is
  back at the original facing.
- AC-9 (Logic) Watched is true only when the player is inside the 90 degree
  cone AND has terrain line of sight; false if either fails.
- AC-10 (Logic) While watched, energy drops 1 per 2.0 s (not before 2.0 s);
  when watching stops the timer resets.
- AC-11 (Logic) Energy 0 sets state `lost`; absorbing the last Sentinel sets
  state `won` and counter 0; neither fires early.

**Move button (the prototype bug)**

- AC-12 (Scene) With a visible synthoid at tile T, `aim_at(T)`, `press("ax_button")`,
  then `advance(0.3)`: `XROrigin3D` global position equals `top_position(T)`
  within 1 cm.
- AC-13 (Scene) Same case: the `XRCamera3D` world y is `height(T) + 1.6` (+ the
  room offset, zero in the test) within 1 cm, and the HUD still shows.
- AC-14 (Scene) `press("ax_button")` with no valid target leaves origin
  unchanged and sets `HudMessage` to a non-empty reason.
- AC-15 (Scene) Snap turn: left stick right changes origin yaw by 30 degrees
  (+-0.5), and the player's tile does not change.

**Levels**

- AC-16 (Logic) `Levels.build(n)` for n=1..10 matches the table (grid size,
  Sentinel count, tree count, start energy) and is identical on two calls.
- AC-17 (Logic) For all levels: Sentinels distinct, >= 4 apart, highest local
  peaks (>= 2 m above tiles within 2); trees on distinct non-Sentinel tiles;
  start height <= 1 and >= 6 tiles from each Sentinel.
- AC-18 (Logic) For all levels the player is not watched at start and no drain
  happens in the first 5 s.
- AC-19 (Logic) A greedy solver bot clears all 10 levels (headless, bounded
  steps).
- AC-20 (Logic) Energy carries to the next level, capped 20, min 6; after a
  loss the retry starts at the level's original start energy.
- AC-21 (Scene) Clearing level n<10 loads level n+1 (HUD level text updates);
  clearing 10 shows the ending card then the lobby.

**Lobby**

- AC-22 (Scene) App launch scene is the lobby; no level is loaded.
- AC-23 (Scene) Lobby has pages Story, Rules, How to play, Ready; `next()`/`back()`
  move between them and page text is non-empty.
- AC-24 (Scene) Story page text contains the words "Spark" and "Sentinel"; Rules
  page mentions energy (the number 3 and 4 appear); How to play lists 5
  numbered steps naming trigger, A and B.
- AC-25 (Scene) `StartButton` is visible on every page; `press_start()` loads
  level 1 with energy 6 and HUD showing "Level 1 of 10".
- AC-26 (Scene) Pause menu "Back to lobby" returns to the lobby.

**HUD**

- AC-27 (Scene) `Hud` is a descendant of `XRCamera3D` and not of either controller;
  its local transform is constant while the camera moves.
- AC-28 (Scene) `Hud` local position is (0, -0.3 +- 0.05, -1.2 +- 0.1).
- AC-29 (Scene) HUD text shows energy as a number that updates after create
  and absorb.
- AC-30 (Scene) `HudSentinels` reads "Sentinels: k of N left" and decrements
  after each Sentinel absorb; it shows 0 left when the level is won.
- AC-31 (Scene) `HudWatched` is visible with a countdown only while watched.
- AC-32 (Scene) `LeftController` has no Label3D child (HUD removed from hand).

**Trees and visuals**

- AC-33 (Scene) Each tree's visual AABB height is >= 3.0 m and its width <=
  1.9 m and > 0.5 m; taller than a synthoid.
- AC-34 (Scene) Aiming at any point over a tree's tile selects that tile
  (tree absorbable when visible).
- AC-35 (Scene) Each Sentinel node's facing (nose) matches its logic facing
  after `advance`.

**Feedback and build**

- AC-36 (Scene) Every failed action (create, move, absorb) sets a non-empty
  `HudMessage`; every successful action plays its named audio bus stream (a
  stub counter in tests).
- AC-37 (Build) `mise run test` runs all tests above and exits non-zero on
  any failure; `mise run build` still produces the verified arm64 APK.
- AC-38 (Build) No colleague or board names appear anywhere in the repo
  (grep gate in `tools/run-tests.sh`).

## 13. Open items

- Reconcile with the research pack (a-1) when readable; adjust constants, not
  structure.
- Audio assets and art are placeholders in v1 (generated tones, primitives).
- Real-device confirmation of button mapping and comfort is a manual
  post-release check.
