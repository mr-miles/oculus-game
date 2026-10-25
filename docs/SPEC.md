# Quest Sentinel: family game specification

Status: v1 (draft for build). Extends the Godot 4.7 / OpenXR prototype in this
repo (`game/`) into a complete family game for Meta Quest 2. Toolchain is the
repo's existing one: `mise run test`, `mise run build` (`tools/*.sh`); no npm.
Scope fits two engineers: **A** = rules, levels, sentinels, tests
(`game_logic.gd`, new `levels.gd`); **B** = VR view, lobby, HUD, input
(`main.gd`, new `lobby.gd`, `hud.gd`).

Source basis: the prototype, `docs/FINDINGS.md`, and the research pack on the
original 1986 Sentinel (rules taken from its source-verified Part B: energy
values, timings, trees blocking sight). Where this spec departs from the
original it says so (section 13).

## 1. Product in one paragraph

A calm, puzzle-like, non-violent VR game for ages 8+. You are a small "spark"
that lives in robot bodies called synthoids. On a landscape of rolling stone hills,
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

Grid of 31x31 square tiles (edge 2 m, as in the original), whose four corners each have an altitude 1 to 11 (1 altitude step = 1 m), so
hills have real slopes (section 4.2). A tile is **flat** when its four corners are
equal; objects (trees, Sentinels, synthoids, boulders) and the player stand only
on flat tiles. Terms:

- **Visible**: no terrain surface (including slopes), boulder or tree blocks the straight line from your eye
  (tile top + 1.6 m) to the tile's top centre (prototype `can_see`, extended:
  a tree blocks the line below its top, 3 m above its tile, as in the original).
  Synthoids do not block sight. Your own tile is never targetable.
- **Occupied**: holds a tree, synthoid, Sentinel, or you. Boulders alone do not
  make a tile occupied (see stacks below), except the tile you stand on.
- **Stack**: the objects on one tile from the ground up: 0 to 6 boulders, then
  at most one top object (synthoid, tree or Sentinel). Only boulders can have
  something on top of them; nothing can be created on a tree, synthoid or
  Sentinel. **Surface height** of a tile = altitude + 1.0 m per boulder
  (BOULDER_HEIGHT, one altitude step). Your eye is the surface height of your tile + 1.6 m.
  Boulders block sight like terrain; synthoids do not.

Constants (single source: `GameLogic` constants):

| Name | Value |
|---|---|
| SYNTHOID_COST | 3 energy |
| BOULDER_COST | 2 energy |
| BOULDER_ENERGY (absorbing one) | 2 |
| BOULDER_HEIGHT | 1.0 m (one altitude step; board request, was 0.5 m) |
| MAX_BOULDERS_PER_TILE | 6 |
| MAX_OBJECTS | 64 (trees, boulders, synthoids and Sentinels all count) |
| TREE_ENERGY | 1 |
| SYNTHOID_ENERGY (absorbing one) | 3 |
| SENTINEL_ENERGY (absorbing one) | 4 |
| START_ENERGY (level 1) | 10 |
| SENTINEL_TURN_STEP | 28.125 degrees, every 11.94 s (direction fixed per Sentinel; rotates only while it has nothing to drain) |
| SENTINEL_FOV | 56.25 degrees total (28.125 each side of facing) |
| DRAIN_DELAY | 7.14 s of continuous watching before the first drain |
| DRAIN_INTERVAL | 1.74 s between drains after that |
| DRAIN_AMOUNT | 1 energy |
| MAX_ENERGY | 63 (excess is lost) |

Rules:

1. Create, two kinds only: a **synthoid** (cost 3) or a **boulder** (cost 2),
   on a visible tile whose stack can take it (top is not a tree, synthoid or
   Sentinel; fewer than 6 boulders for a boulder). Needs the energy; fewer than
   MAX_OBJECTS objects exist. A synthoid or boulder created on a tile with
   boulders goes on top of them. **Trees cannot be created by the player** (they
   exist only from level generation). A synthoid cannot be created on your own
   tile; a **boulder can**: it is added under you, the tile stays yours, and
   your eye rises by 1.0 m. This is how you climb without a second body; it
   costs 2 energy per metre, and you cannot take that energy back while
   you stand there (you may not absorb your own tile).
2. Transfer (move): needs a visible tile whose top object is a synthoid; you
   now stand on that tile, the synthoid is consumed (no energy change), view
   height is that tile's surface height (altitude + boulders under the
   synthoid) + 1.6 m.
3. Absorb: takes the **top object** of the aimed visible tile only: tree (+1),
   synthoid (+3), Sentinel (+4) or boulder (+2). A synthoid standing on boulders
   is absorbed first, then each boulder one at a time. You may not absorb
   the tile you stand on. Create cost equals absorb yield, so create then
   absorb returns exactly the energy spent.
4. Watched: you are watched when a Sentinel's facing is within its FOV of the
   direction to you AND the Sentinel has line of sight to your eye (same
   terrain rule, from the Sentinel's eye at tile top + 2.2 m). While watched
   continuously, the HUD warns at once; after DRAIN_DELAY you lose
   DRAIN_AMOUNT, then again every DRAIN_INTERVAL. The timer resets when
   watching stops. Turn and drain values are from the original game, which
   gives the player time to hide; they are constants so play-testing can
   change them.
5. Win a level: sentinel counter reaches 0. Lose a level: a drain happens while energy is already 0 (energy 0 alone is not a loss; as in the original). Create is refused if it would take energy below 0, or if MAX_OBJECTS objects already exist.
   Sentinels are idle (no turning, no drain) until the player's first create, absorb or transfer (as in the original; turning your head does not wake them).
6. Win the game: finish level 10.

## 4. Levels and progression

Ten levels, each a deterministic function of its number (`Levels.build(n)`
returns the same level every time). All levels use the original's world:
**31x31 tiles on a 32x32 grid of corner altitudes, altitudes 1-11**. Level n
uses landscape number L(n) = n - 1 (so level 1 is landscape 0). Engineers may
change L(n) per level, recorded in a table in `levels.gd`, only to make
every generation AC below pass.

### 4.1 Terrain generator (mountains and valleys, not random noise)

The generator follows the structure of the original's 11 steps (research
Part B 2.4) so ridges and valleys come from smoothing a seeded field. Every step
is deterministic and exposed for tests as `Levels.stages(n)` (AC-54).

1. **Seed** a 40-bit LFSR (5 bytes; feedback = bit 19 XOR bit 32 shifted into
   bit 0; 8 shifts per output byte). Seed bits 0-15 = L(n) in BCD, bit 16 set.
2. **Discard** 81 outputs.
3. **Multiplier** M = 14 + (bits 0-2 + bits 3-6 of the next output), i.e.
   14..36; for L = 0, M = 24.
4. **Fill** a 32x32 grid of corner values with the next 1024 outputs (row by
   row).
5. **Smooth** (pass 1): each corner = average of itself and the next three
   along its row (wrapping); then the same along columns.
6. **Smooth** (pass 2): repeat step 5.
7. **Scale**: value = floor(M x (data - 128) / 256) + 6, floor 0, +1, cap 11.
8. **Spike/trough repair** (pass 1): a corner at least 2 above all four of its
   neighbours is set to the highest neighbour; a corner at least 2 below
   all four is set to the lowest neighbour. Edge corners compare with the
   neighbours they have.
9. **Spike/trough repair** (pass 2): repeat step 8.
10. **Stretch and limit**: linearly stretch so the lowest corner is 1 and the
    highest is 11 (integer: 1 + floor((a - min) x 10 / (max - min))); then
    repeat until stable: lower any corner that is more than 3 above a
    neighbour to neighbour + 3 (so no neighbouring corners differ by more
    than 3).
11. **Tiles**: a tile is **flat** when its four corners are equal (only flat
    tiles can hold trees, Sentinels, the player and any created object, as in
    the original). Tile altitude = round-half-up of the mean of its four
    corners (used for naming and statistics; the visible ground is the
    sloped surface of section 4.2). Then place
    Sentinels, trees and the player start (below).

Differences from the original: the exact tile-shape numbering is ours (section
4.2); step 10's stretch/limit is ours; the spike repair details are ours (the
research only says "spike/trough smoothing twice").

### 4.2 Tile shapes and slopes

The generator's corner grid `corner(x, z)` (32x32 ints, 1-11) is the ground
truth; `GameLogic` keeps it and every query below reads it. For tile (x, z)
name its corners a = (x, z), b = (x+1, z), c = (x, z+1), d = (x+1, z+1)
(z grows away from the viewer; a is the front-left corner, as in the
original). `tile_shape(t)` returns one of four classes:

| Class | Corner rule | Looks like |
|---|---|---|
| `flat` | a = b = c = d | level ground; the only class that can hold objects |
| `slope` | not flat, and a + d = b + c | one tilted plane (a ramp, up to 3 m rise over a tile edge) |
| `ridge` | a + d > b + c | a roof: the fold runs along the a-d diagonal and is the highest line |
| `valley` | a + d < b + c | a trough: the fold runs along the a-d diagonal and is the lowest line |

The original has 16 numbered shape codes (research: 0-15, no 8, 0 = flat).
The research does not give the encoding, so this spec keeps its idea (a tile
shape follows from the four corner altitudes, 0 = flat, only flat tiles hold
objects) with the four classes above instead of the numbered codes.
`height(t)` stays the spec 3 value: the common altitude for a flat tile, the
round-half-up mean of the corners otherwise (used only for statistics and
the grey aim disc).

**Surface height** at a point inside tile (x, z), with u and v in [0, 1] the
fraction across the tile along x and z. The tile is split into two triangles
along the a-d diagonal:

- if u >= v: h = a + u (b - a) + v (d - b)
- otherwise: h = a + v (c - a) + u (d - c)

So the fold of a ridge or valley is always on the a-d diagonal, a flat tile
has h = its altitude everywhere, and a tile corner's surface height is the
corner altitude. Boulders add 1.0 m each on flat tiles only.

**Eye height.** The player stands only on flat tiles, so the eye is always
flat altitude + 1.0 m per boulder + 1.6 m (spec 3); slopes never change it
and there is no walking onto a slope. A transfer into a synthoid never lands on
a slope because synthoids are only created on flat tiles.

**Line of sight.** The ray from the eye to the target tile's top centre
(flat target tiles only) is sampled every 0.25 m (or finer) horizontally; it is
blocked wherever the ray is below the surface height there (or below a tree
top, boulder stack or any terrain of other tiles). The cells of the
player's own tile and the target tile are skipped, as before. Slopes therefore
hide what is behind a ridge, and a valley lets you see across it.

**Aim and what can be targeted.** The aimed tile is the first tile where the
aim ray goes at or below the surface height (not a column top). Any tile can
be aimed at, flat or not. Flat and visible: yellow disc; flat and hidden: red
disc; not flat: **grey** disc at the tile centre's surface height, and every
action on it fails with the message "Needs flat ground". Create, transfer and
absorb apply to flat tiles only (a sloped tile never has an object).

**Placement.** Trees, Sentinels, the player start and any object the player
creates are on flat tiles only (spec 3 already says this for the generator;
this adds the rule for the player's actions and for the final check in AC-63).

**Rendering.** One merged heightfield mesh (so AC-39 still holds, <= 16 mesh
instances): per tile two triangles split along a-d (the triangles above),
flat-shaded normals, vertex colours: flat tiles the two stone-green checker
colours of the prototype, non-flat tiles a distinct darker brown-green (so
players see where objects can go), and a vertical skirt down to y = 0 around
the 31x31 border so the edge has no see-through gaps. Aim disc, Sentinels,
trees and boulders are unchanged. No physics colliders are needed.

| Level | Sentinels | Trees | Starting energy |
|---|---|---|---|
| 1 | 1 | 10 | 10 |
| 2 | 1 | 12 | carried, min 10 |
| 3 | 2 | 14 | carried, min 10 |
| 4 | 2 | 16 | carried, min 10 |
| 5 | 3 | 18 | carried, min 10 |
| 6 | 3 | 20 | carried, min 10 |
| 7 | 4 | 22 | carried, min 10 |
| 8 | 4 | 24 | carried, min 10 |
| 9 | 5 | 26 | carried, min 10 |
| 10 | 6 | 28 | carried, min 10 |

Trees per level are always within the original's 10-32 and at most
48 - 3 x Sentinels.

Generation rules every level must satisfy (all checked by tests):

- **Sentinel placement** (original): the 31x31 grid is cut into 4x4-tile
  blocks; the first Sentinel stands on the highest flat tile of the highest block;
  each next Sentinel on the highest flat tile of the highest block not yet
  excluded; a used block and its 8 neighbouring blocks are excluded. Sentinel
  tiles are flat and never share a tile.
- **Trees**: distinct, flat, empty tiles, each at an altitude below the
  lowest Sentinel's.
- **Player start**: a random (seeded) flat, empty tile with altitude <=
  min(6, lowest Sentinel altitude).
- **Shape checks** (AC-55 to AC-58): no pit or spike tiles; altitudes use the
  full 1-11 range; neighbouring altitude steps at most 3; between 20% and 80% of
  tiles are flat; the first Sentinel is on the highest flat tile with
  altitude >= 9, and every Sentinel has altitude >= 5.
- **Solvable**: from the start at least one tree or free tile is visible, and
  a scripted greedy solver bot clears levels 1-10 in logic only.
- Total world energy stays within the original's budget: trees + 3 x Sentinels
  <= 48 (the research's "at most 49" total is not separately tested, see
  section 13).

Energy carries over between levels (capped at MAX_ENERGY, minimum 10 so a
level never begins on a dead end). Progress persists only for the session; the
lobby always starts at level 1 (no save game in v1).

## 5. User actions and controls

Right Touch controller points a yellow ray; a disc marks the aimed tile
(yellow = visible, red = hidden, as the prototype). Aimed object is whatever
stands on the aimed tile.

| Input | Action |
|---|---|
| Right trigger | Create the selected object (synthoid or boulder) on the aimed tile |
| Right grip (`grip_click`) | Toggle what the trigger creates: Synthoid (3) <-> Boulder (2). Default Synthoid at level start and after a retry |
| Right A | **Move**: transfer into the aimed synthoid |
| Left trigger (`trigger_left_click`) | **Absorb** the top object of the tile the left (orange) ray aims at (tree, synthoid, boulder or Sentinel). The right hand makes and moves, the left hand absorbs; the right B button does nothing |
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

Creating: why a mode toggle on the grip. Trigger-create is the most frequent
action and stays one press. A separate button for boulders would use A/B/stick
click, which are Move, Absorb and (reserved) recentre; the grip is the only
free button the right index/middle fingers reach without moving the hand. The
current mode is always shown on the HUD ("Create: Synthoid (3)" or "Create:
Boulder (2)") and the aim disc shows a ghost of the object (blue capsule or
grey slab), so the mode cannot be mistaken. A mode change plays a short tone.
Boulders can be aimed at on any visible tile, including the tile you stand on
(boulder mode only), and the aimed boulder or stack is whatever the ray hits
over that tile.

Feedback: each action plays a distinct sound and a short controller haptic
pulse (success 0.2 s / failure 0.05 s).

## 6. Win, lose, flow

- Level won: the last Sentinel is absorbed -> HUD "Hill cleared!" for 3 s,
  next level loads (level 10 -> ending card, then lobby).
- Level lost: a drain at energy 0 -> "You ran out of energy. Pull the trigger to try
  again." Trigger reloads the same level with its original start energy
  (not carried); Y offers "Back to lobby".
- No lives, no timer other than the drain; restart is always available from
  the pause menu.

## 7. Lobby

A separate scene `lobby.tscn` shown on app launch, before any level. A calm
sky, one low hill, a world-space panel placed once, 2.5 m in front of where the
player is facing when the lobby loads (taken from the camera's own yaw, after
head tracking has settled, so it is right whatever yaw the headset starts
with), at eye height, turned to face the player, scaled 1.4x (2.8 x 2.1 m, about
58 x 45 degrees of view, so every line reads without turning the head), and
then fixed in the world: it never follows head movement. It is interacted with
by the same ray + trigger. Pages, with **Back** and
**Next** buttons, and a **Start** button visible on every page (also the
final page's primary button):

1. **Story** (section 2, condensed to <= 60 words).
2. **Rules** (what to do; energy; Sentinels watching; win and lose).
3. **How to play**: a walkthrough in 5 numbered steps with a controller
   diagram, 6 numbered steps: 1 point and see yellow; 2 trigger = make a body
   (a synthoid); 3 A = move into it; 4 squeeze grip to switch to boulders,
   trigger to stack them and climb (also under your feet); 5 left controller
   (orange ray) + its trigger = absorb trees, boulders and bodies for energy; 6 absorb
   the Sentinels. Each step names the
   button.
4. **Ready**: Start.

Start loads level 1 with 10 energy. Returning from the pause menu or ending
brings the user back here.

## 8. HUD (viewport-anchored, at the top)

The HUD is a child of the XR camera (head-locked), never of a controller. It is
a strip at the **top** of the view: centred 2.5 m in front of the eyes and 0.9 m
above the centre of gaze (about 20 degrees up), scaled so it looks about 1.3x larger than
the first version (which sat 1.2 m away and was too close to read), unshaded and drawn on top, so the
middle of the view stays clear. Contents, always visible: Energy (number and
bar), Level ("Level 3 of 10"), **Sentinels left** counter ("Sentinels: 2 of 3
left"), the create mode ("Create: Synthoid (3)" / "Create: Boulder (2)"), the
watched warning (red text and red border when watched, with a countdown to the
next drain), and the one-line message and hint (also in the top strip, on a
second row). Every HUD element is above the gaze centre line and inside the
view. The prototype's left-hand label is removed.

## 9. Visual changes

- **Bigger trees, mostly leaves**: tree height 3.0 m (prototype was a 1.2 m
  capsule), clearly taller than a synthoid (1.6 m) and than the player's eye
  (1.6 m). The tree is a short brown trunk (nodes `Trunk`: 1.2 m high, radius
  0.2 m) under a large green leaf mass (node `Canopy`: 1.8 m high, i.e. 60% of
  the tree, radius 0.9 m, starting 1.0 m above the tile). Absorb/aim hit area
  covers the whole tile top.
- Boulders: grey, 1.0 m high, covering most of the tile (radius 0.8 m), stacked
  with no gaps; the ghost preview is a translucent boulder or synthoid.
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
  names `trigger_click`, `grip_click`, `ax_button`, `trigger_left_click`, `by_left_button`...),
  `GameLogic.create(tile, kind)` with kind `"synthoid"` or `"boulder"` (any
  other kind, including `"tree"`, is refused with a reason),
  `Levels.stages(n)` (the generator's intermediate grids, AC-54),
  `aim_at(tile: Vector2i)` (override for the ray), `advance(seconds: float)`
  (steps sentinels, drain and timers deterministically), and nodes named
  `Hud`, `HudEnergy`, `HudLevel`, `HudSentinels`, `HudMessage`,
  `HudWatched`, `HudMode`, `XRCamera3D`, `XROrigin3D`, `LeftController`,
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

- AC-1 (Logic) New game: energy 10, 1 Sentinel, 31x31 grid, player on a flat empty tile with altitude <= min(6, Sentinel altitude).
- AC-2 (Logic) Create on a visible free tile costs exactly 3 energy and adds a
  synthoid there.
- AC-3 (Logic) Create fails (no state change, reason string returned) when
  energy is below the kind's cost (synthoid 3, boulder 2), tile hidden or not flat, the
  tile's top is a tree, synthoid or Sentinel, the kind is a synthoid and the
  tile is the player's, or MAX_OBJECTS (64, boulders included) already exist.
- AC-4 (Logic) Absorbing a tree gives +1, a synthoid +3, a boulder +2, a
  Sentinel +4; each removes the object; energy is capped at 63.
- AC-5 (Logic) Absorb fails on a hidden target, an empty tile, or one's own tile.
- AC-6 (Logic) Terrain on the line of sight (flat or sloped, by surface height,
  section 4.2) makes a tile not visible; so does a tree (3 m) in the way; a synthoid does not.
- AC-7 (Logic) Transfer onto a visible synthoid sets the player tile, consumes
  the synthoid and leaves energy unchanged; transfer onto a hidden or
  nonexistent synthoid fails.

**Sentinels, win and lose**

- AC-8 (Logic) A Sentinel with nothing to drain turns 28.125 degrees every
  11.94 s: after `advance(11.9)` facing is unchanged, after `advance(0.1)` more
  it has turned exactly one step; after 12 steps the total is 337.5 degrees.
- AC-9 (Logic) Watched is true only when the player is inside the 56.25 degree
  cone AND has terrain line of sight; false if either fails.
- AC-10 (Logic) While watched, no energy is lost before 7.14 s, 1 is lost at
  7.14 s, then 1 every 1.74 s; when watching stops the timer resets and the
  next watch again waits 7.14 s.
- AC-11 (Logic) A drain at energy 0 sets state `lost`; energy reaching 0 by
  itself does not; absorbing the last Sentinel sets state `won` and counter 0;
  neither fires early.

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

- AC-16 (Logic) `Levels.build(n)` for n=1..10 matches the table (Sentinel
  count, tree count, start energy), has a 31x31 grid with every altitude in
  1..11, and is identical on two calls.
- AC-17 (Logic) For all levels: Sentinels follow the block-placement rule
  (first on the highest block's highest tile; used block and 8 neighbours
  excluded); trees are on distinct flat empty tiles below the lowest Sentinel;
  trees <= 48 - 3 x Sentinels and within 10..32; start tile flat, empty,
  altitude <= min(6, lowest Sentinel altitude); no neighbouring corner
  altitudes differ by more than 3.
- AC-18 (Logic) Sentinels are idle until the first create, absorb or
  transfer: after `advance(60)` with no action no Sentinel has turned and
  energy is unchanged; after the first action they turn and watch normally.
- AC-19 (Logic) A greedy solver bot clears all 10 levels (headless, bounded
  steps).
- AC-20 (Logic) Energy carries to the next level, capped 63, min 10; after a
  loss the retry starts at the level's original start energy.
- AC-21 (Scene) Clearing level n<10 loads level n+1 (HUD level text updates);
  clearing 10 shows the ending card then the lobby.

**Lobby**

- AC-22 (Scene) App launch scene is the lobby; no level is loaded.
- AC-23 (Scene) Lobby has pages Story, Rules, How to play, Ready; `next()`/`back()`
  move between them and page text is non-empty.
- AC-24 (Scene) Story page text contains the words "Spark" and "Sentinel"; Rules
  page mentions energy (the numbers 2, 3 and 4 appear); How to play lists 6
  numbered steps naming trigger, grip, A and the left controller and the words "boulder" and
  "Sentinel".
- AC-25 (Scene) `StartButton` is visible on every page; `press_start()` loads
  level 1 with energy 10 and HUD showing "Level 1 of 10".
- AC-26 (Scene) Pause menu "Back to lobby" returns to the lobby.

**HUD**

- AC-27 (Scene) `Hud` is a descendant of `XRCamera3D` and not of either controller;
  its local transform is constant while the camera moves.
- AC-28 (Scene) `Hud` local position is (0, +0.9 +- 0.05, -2.5 +- 0.1), i.e. above
  the gaze centre, not below or at it, and its on-screen size (scale / distance) is
  at least 1.25 / 1.2 (board finding: larger and further).
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
- AC-39 (Scene) The 31x31 terrain (a merged heightfield mesh, section 4.2) is built
  from at most 16 mesh instances (not one node per tile), so the scene stays Quest-friendly;
  the existing scene smoke test still passes.
- AC-38 (Build) No person names appear in game text, assets or docs (grep gate
  against a names list kept outside the repo, run in CI).

**Board changes (v3): trees, HUD, boulders, terrain**

*Trees*

- AC-40 (Scene) Each tree has `Trunk` and `Canopy` mesh nodes; the canopy's
  AABB height divided by the whole tree's AABB height is >= 0.5 (spec: 0.6), and
  the canopy bottom is >= 0.9 m above the tile top.
- AC-41 (Scene) Canopy AABB width is between 1.4 and 1.9 m, the trunk's width
  is <= 0.5 m and less than a third of the canopy's, the canopy's material is
  green-dominant and the trunk's is not (red >= green > blue).

*HUD*

- AC-42 (Scene) `HudEnergy`, `HudLevel`, `HudSentinels`, `HudMode`, `HudWatched`
  and `HudMessage` each have camera-local y between +0.5 and +1.5 m (at
  z = -2.5), |x| <= 1.6 m, and between 5 and 35 degrees up and under 35 degrees
  to the side: all above the gaze line and inside the view.
- AC-52 (Scene) `HudMode` reads "Create: Synthoid (3)" at level start and after
  a retry, and "Create: Boulder (2)" after one `press("grip_click")`.

*Boulders*

- AC-43 (Scene) `press("grip_click")` toggles the create mode synthoid <->
  boulder and nothing else; pressing it any number of times never yields a
  third mode (no tree).
- AC-44 (Logic) Create a boulder on a visible empty flat tile: energy -2, one
  boulder on the tile, the tile's surface height rises by 1.0 m, the tile is
  still free for another boulder or a synthoid on top.
- AC-45 (Scene) Boulder mode, `aim_at` the player's own tile, trigger: energy -2,
  the player's tile is unchanged, boulders under the player = 1, and after
  `advance(0.3)` `XROrigin3D` y is higher by 1.0 m (+-1 cm) with x and z
  unchanged, and `XRCamera3D` y = altitude + 1.0 + 1.6 (room offset zero).
  The same press in synthoid mode on the own tile fails with a reason.
- AC-46 (Logic) `create(tile, "tree")` is refused with a reason and changes
  nothing (energy, objects), on any tile including the player's; there is no
  other code path that adds a tree after level generation.
- AC-47 (Logic) Stacks: up to 6 boulders on a tile; the 7th is refused; a
  synthoid can be created on top of boulders; nothing can be created on a tile
  whose top is a tree, a synthoid or a Sentinel.
- AC-53 (Scene) With a synthoid on top of 2 boulders at tile T: `aim_at(T)`,
  `press("ax_button")`, `advance(0.3)`: `XRCamera3D` y = altitude(T) + 2.0 + 1.6
  (+-1 cm) and the boulders stay on T.
- AC-48 (Logic) Absorb takes the top object only: synthoid on 2 boulders gives +3
  then +2, +2 in three absorbs; absorbing your own tile fails (boulders under you
  stay); creating then absorbing a boulder or synthoid returns exactly the
  energy spent (conservation).
- AC-49 (Logic) A stack of 6 boulders (6 m) on a tile between the eye and a
  tile behind it makes that tile not visible; removing the boulders makes it
  visible again.
- AC-50 (Logic) Energy math: with energy 2 a boulder can be created and a
  synthoid cannot; with energy 1 neither; after the create the energy is
  exactly start - cost; with 63 objects one more create works, with 64 it
  fails (boulders count).
- AC-51 (Scene) The lobby's How-to-play page has 6 numbered steps; step 4 contains
  "grip" and "boulder".

*Terrain*

- AC-54 (Logic) `Levels.stages(n)` returns, for n=1..10: the LFSR outputs used
  (1024 corner values after the 81 discarded), the corner grids after smoothing
  pass 2, after scale (all in 1..11), after repair pass 2, and after
  stretch/limit; the smoothed grid has lower variance than the raw one, and
  the final grid's min is 1 and max is 11.
- AC-55 (Logic) For all 10 levels, no tile is a pit or a spike: no tile (Sentinel
  tiles exempt from the spike test) has altitude >= 2 above all of its
  4-neighbours, and none has altitude >= 2 below all of them.
- AC-56 (Logic) For all 10 levels: neighbouring corner altitudes differ by at
  most 3; the mean absolute difference between neighbouring tiles is between
  0.3 and 1.2 (smooth, not noise, but not flat).
- AC-57 (Logic) For all 10 levels, between 20% and 80% of tiles are flat.
- AC-58 (Logic) For all 10 levels: the first Sentinel is on the highest flat
  tile of the grid and its altitude >= 9; every Sentinel has altitude >= 5 and
  is the highest flat tile in its 4x4 block.
- AC-59 (Logic) The LFSR and `Levels.build` are deterministic: two builds are
  identical, and levels 1..10 have pairwise different altitude grids.

*Tile slopes (spec 4)*

Spec 3 ACs changed by this section: **AC-6** (wording: terrain surface, not
column), **AC-39** (mesh is a heightfield). Unchanged and still valid: AC-12,
AC-13, AC-17, AC-45, AC-53, AC-55 to AC-58 (they use flat altitudes and corner
steps). AC-57 now also guarantees that sloped tiles exist.

- AC-60 (Logic) `tile_shape(t)` on hand-built corner grids (a, b, c, d as in
  section 4.2) returns `flat` for 3,3,3,3; `slope` for 3,3,5,5 (a + d = b + c);
  `ridge` for 3,3,3,5 (a + d = 8 > b + c = 6); `valley` for 3,4,4,3
  (a + d = 6 < 8). `height(t)` is the common altitude for flat tiles and the
  round-half-up mean of the corners otherwise.
- AC-61 (Logic) `surface_height(x_m, z_m)` returns the corner altitude at every
  corner. With a, b, c, d = 1, 3, 3, 5 (slope) the tile centre is 3.0; with
  1, 1, 1, 5 (ridge) the centre is 3.0 and (u, v) = (0.75, 0.25) gives 2.0; with
  3, 5, 5, 3 (valley) the centre is 3.0 and (0.75, 0.25) gives 4.0; a flat tile
  returns its altitude everywhere.
- AC-62 (Logic) Every level n = 1..10 contains at least one `slope` tile, and
  over the 10 levels `slope`, `ridge` and `valley` each occur at least once;
  in every level the share of non-flat tiles is between 20% and 80%.
- AC-63 (Logic) For all 10 levels every tree, every Sentinel and the player
  start are on `flat` tiles; and attempting `create` (synthoid and boulder, with
  ample energy) on every non-flat visible tile is refused with a reason
  containing "flat" and changes nothing; at the end no object stands on a non-flat tile.
- AC-64 (Logic) Sight over slopes. One row of four tiles along x (each 2 m): A and
  B flat at altitude 3, two middle tiles between them whose only varying
  corner column is the one at x = 4 m (altitude `apex`; the others are 3), eye on
  A at 3 + 1.6, target B. The sight line is 3.8 m high at x = 4 m. B is not
  visible for apex = 5 and for apex = 4; B is visible for apex = 3.5 and for
  apex = 1 (a valley).
- AC-65 (Scene) Aim on a slope with a real controller pose (no `aim_at`): a
  right-hand ray pointing at the centre of a sloped tile makes it the aimed
  tile; the disc is grey; `press("trigger_click")`, `press("ax_button")` and
  `press("trigger_left_click")` change nothing and set `HudMessage` containing "Needs
  flat ground". A ray at a flat visible tile shows a yellow disc, at a hidden
  one a red disc.
- AC-66 (Scene) Terrain mesh geometry: for every tile the four mesh vertices at
  its corners have x, z = corner index x 2 m and y = the corner altitude (1 mm),
  the two triangles are split along the a-d diagonal, and the border has a
  vertical skirt down to y = 0 (no boundary edge without a wall).
- AC-67 (Scene) Terrain vertex colours: all vertices of a flat tile use one of
  the two flat colours; all vertices of a non-flat tile use the slope colour;
  the three colours are mutually different.
- AC-68 (Scene) After a transfer onto a flat tile next to sloped tiles,
  `XROrigin3D` y equals the flat altitude (+ 1.0 per boulder) exactly (1 cm),
  never an interpolated slope value, and `XRCamera3D` y is that + 1.6.
- AC-69 (Build) `README.md` World paragraph mentions "slopes" or "sloping" and
  "flat" (grep gate in `tools/check-test-gate.sh`), and no longer says "columns".

*Boulder height (board finding)*

- AC-71 (Logic) One boulder lets you see over a 2 m step. Flat grid, player on
  tile A at altitude h, tile B next to it at h + 2, target tile C behind B at
  h + 2 (a plateau). With no boulder under A the eye is at h + 1.6 and C is not
  visible; with one boulder under A (eye h + 2.6) C is visible. With B at h + 3
  one boulder is not enough (eye h + 2.6) and two are (eye h + 3.6).
- AC-72 (Logic) A synthoid on one boulder, once moved into, gives the same eye:
  create a boulder and a synthoid on tile T at altitude h, `move(T)`:
  `eye_position().y` = h + 1.0 + 1.6, the boulder stays on T, and a plateau of
  height h + 2 two tiles away is visible from there but not from the tile T
  without the boulder.
*Ambient wind (board finding)*

- AC-77 (Scene) The lobby and every level play a gentle wind: a generated 8 s
  loop of low-pass filtered noise with slow gusts (no audio files), started
  automatically, looping seamlessly (end and start samples match), audible but
  quiet (-22 dB player volume). It is separate from the action sounds.

*Lobby placement (board finding)*

- AC-70 (Scene) At load the lobby panel is within 5 degrees of the camera's
  horizontal forward direction, 2.0 to 3.5 m away, at eye height and facing the
  player; it does not move when the camera or the rig yaws afterwards; and
  placing it again from any rig yaw (90, 180, -137 degrees) puts it in front of
  the camera.

*Pause menu placement (board finding)*

- AC-73 (Scene) When Y opens the pause menu it appears within 5 degrees of the
  camera's horizontal forward direction, 1.0 to 2.5 m away, at eye height and
  facing the player, at any rig yaw; it is fixed in the world (turning the head
  or rig afterwards does not move it) and is placed again each time it opens.

Known simplification (kept from the prototype): visibility tests only whether
terrain or a tree blocks the line to a tile's top centre; the target tile's
own surface never blocks. A Sentinel standing higher than the player is
therefore visible and absorbable from a lower tile if nothing is in the way.
The original needs the tile's top face in view, which forces more climbing.

## 13. Audit against the research and open items

Research = `docs/research/01-sentinel.md` Part B (BBC Micro source). "Align" =
spec follows the research. "Departure" = deliberate, with reason.

| # | Item | Research | Spec | Verdict |
|---|---|---|---|---|
| 1 | Grid | 31x31 tiles (32x32 corners) | 31x31 | Align (earlier draft was wrong) |
| 2 | Altitudes | 1-11 | 1-11, 1 step = 1 m (original: step = tile width) | Align range; departure on scale: 11 m peaks keep eye-height comfortable, prototype scale |
| 3 | Tile shapes / slopes | 16 shape codes (0-15, no 8), 0 = flat, from the 4 corner altitudes; objects on flat tiles only | tiles are triangulated from the 4 corners; classes flat, slope, ridge, valley; objects, player, Sentinels and trees on flat only (section 4.2) | Align on idea and on flat-only placement; departure: four classes instead of the original's numeric codes, because the research does not give the encoding |
| 4 | Terrain generator | 40-bit LFSR, 11 steps, 10,000 landscapes | same LFSR and step structure (section 4.1), 10 levels | Align on structure; departures: the spike repair and the stretch/limit step are ours (research gives no detail), only 10 landscapes; earlier "simplified noise" departure removed |
| 5 | Trees | 10-32, cap 48 - 3 x enemies, below lowest enemy | 10..28 by level, same cap and placement | Align |
| 6 | Enemy count | 1 for landscapes 0-9, then 1 + tens digit, max 8 | 1,1,2,2,3,3,4,4,5,6 | Departure: gentler ramp for a family game and 10 levels |
| 7 | Enemy kinds | one Sentinel (4), up to 7 optional sentries (3) | all enemies are Sentinels worth 4, all must be absorbed | Departure: one counter and one goal; sentries/Meanies are v2 |
| 8 | Enemy placement | highest 4x4 block, used block + 8 neighbours removed | same | Align |
| 9 | Sentinel on a tower | yes | tile only | Departure: no towers in v1 |
| 10 | Player start | flat empty, altitude <= min(6, lowest enemy) | same | Align (replaces earlier "height <= 1, 6 tiles away") |
| 11 | Energy values | robot 3, tree 1, boulder 2, Sentinel 4, sentry 3 | synthoid 3, tree 1, boulder 2, Sentinel 4 | Align; sentries not in v1 |
| 12 | Start / max energy | 10 / 63 | 10 / 63 | Align |
| 13 | Total landscape energy | at most 49 | trees + 3 x enemies <= 48 tested; 49 not separately tested | Align by construction; meaning of 49 not fully established in the research |
| 14 | Create cost = absorb yield | yes | yes | Align |
| 15 | Object limit | 64 | 64, boulders included | Align |
| 16 | Next level | landscape + remaining energy (cap 63) | level n+1; energy carried, min 10 | Departure: fixed 10-level progression; minimum 10 avoids dead ends |
| 17 | Win | absorb the Sentinel, then hyperspace | absorb all Sentinels | Departure: no hyperspace in v1 |
| 18 | Hyperspace (cost 3) | yes | none | Departure: v2 candidate |
| 19 | Meanies | trees become Meanies when only your head is seen | none | Departure: v2 candidate; head-vs-tile sighting not implemented |
| 20 | Turn step / interval | 28.125 deg every 11.94 s, direction fixed per enemy | same | Align |
| 21 | Enemy view arc | 28.125 deg (yaw 20 units); sources unclear whether total or half | 56.25 deg total (28.125 each side) | Departure on interpretation: VR needs a readable cone; constant, tunable |
| 22 | Drain delay / rate | 7.14 s then 1 per 1.74 s | same | Align |
| 23 | Lose | drain while energy 0 | same | Align (earlier draft lost at 0) |
| 24 | Enemy wake-up | idle until you spend/absorb energy | same | Align (new AC-18) |
| 25 | First tactic delay | random 0.24-3.72 s per enemy | none | Departure: simplicity |
| 26 | Enemy sight range | no limit found (open in research) | unlimited | Align with the open item |
| 27 | Trees block sight | yes | yes, 3 m | Align |
| 28 | Eye height | 0.875 tile (1.75 m at 2 m) | 1.6 m | Departure: prototype value |
| 29 | Targetable | not own tile, not above eye, objects hit by ray | not own tile; visible tiles only | Align in effect; "above eye" is covered by line of sight |
| 30 | Scoring, secret codes | none / 8-digit codes | none | Departure: no codes in v1 |
| 31 | Locomotion | not in original | A moves into synthoid, snap turn | Departure: VR |
| 32 | HUD | not in original (research suggests wrist gauge) | head-locked HUD (product requirement) | Departure |

Other open items: audio and art are placeholders in v1; real-device
confirmation of button mapping and comfort is a manual post-release check;
terrain must be a merged mesh (AC-39) because 961 separate tile nodes would
exceed the Quest draw-call budget.

| 33 | Boulders | create 2, absorb 2, stack 0.5, objects sit on boulders | same, 6 per tile max, 1.0 m per boulder | Align on energy; departure on height (board: 0.5 m was too short to see over the next altitude step) and the cap of 6 is ours (comfort and draw cost) |
| 34 | Create on own tile | own tile not targetable | boulder allowed on own tile, raises the eye | Departure (board request): gives a way to climb without a second body; energy cost stops abuse |
| 35 | Creating trees | player can create trees (T) | cannot | Departure (board request) |
| 36 | Create keys | R, T, B | trigger + grip mode toggle | Departure: VR controls |
| 37 | Sentinels drain robots to boulders | yes | Sentinels drain only the player | Departure: v1 simplicity |
| 38 | Boulder side targeting | must hit a boulder side to stack | aim at any tile; goes on top | Departure: simpler VR aim |

## 14. Traceability (engineers fill in)

Every AC is checkable headlessly (`mise run test`, or `mise run build` for
AC-37); the device checks in section 10 are extra, not ACs. One row per AC;
fill the test file and test function when the test is written. Existing tests for AC-3, AC-4, AC-17, AC-24 and AC-28 change with the v3 text above.

| AC | Test file (under `game/tests/`) | Test name |
|---|---|---|
| AC-1 | `test_ac_logic.gd` | `ac_1_new_game` |
| AC-2 | `test_ac_logic.gd` | `ac_2_create_costs_three` |
| AC-3 | `test_ac_logic.gd` | `ac_3_create_fails` |
| AC-4 | `test_ac_logic.gd` | `ac_4_absorb_energy` |
| AC-5 | `test_ac_logic.gd` | `ac_5_absorb_fails` |
| AC-6 | `test_ac_logic.gd` | `ac_6_line_of_sight` |
| AC-7 | `test_ac_logic.gd` | `ac_7_transfer` |
| AC-8 | `test_ac_logic.gd` | `ac_8_sentinel_turns` |
| AC-9 | `test_ac_logic.gd` | `ac_9_watched` |
| AC-10 | `test_ac_logic.gd` | `ac_10_drain_timing` |
| AC-11 | `test_ac_logic.gd` | `ac_11_win_lose` |
| AC-12 | `test_ac_12_move_origin.gd` | `ac_12 ...` PASS lines |
| AC-13 | `test_ac_13_move_camera.gd` | `ac_13 ...` PASS lines |
| AC-14 | `test_ac_14_move_fails.gd` | `ac_14 ...` PASS lines |
| AC-15 | `test_ac_15_snap_turn.gd` | `ac_15 ...` PASS lines |
| AC-16 | `test_ac_logic.gd` | `ac_16_levels_match_table` |
| AC-17 | `test_ac_logic.gd` | `ac_17_level_constraints` |
| AC-18 | `test_ac_logic.gd` | `ac_18_sentinels_idle_until_first_action` |
| AC-19 | `test_ac_logic.gd` | `ac_19_solver_bot_clears_all` |
| AC-20 | `test_ac_logic.gd` | `ac_20_energy_carry_and_retry` |
| AC-21 | `test_ac_21_level_flow.gd` | `ac_21 ...` PASS lines |
| AC-22 | `test_ac_22_launch_is_lobby.gd` | `ac_22 ...` PASS lines |
| AC-23 | `test_ac_23_lobby_pages.gd` | `ac_23 ...` PASS lines |
| AC-24 | `test_ac_24_lobby_text.gd` | `ac_24 ...` PASS lines |
| AC-25 | `test_ac_25_start.gd` | `ac_25 ...` PASS lines |
| AC-26 | `test_ac_26_pause_to_lobby.gd` | `ac_26 ...` PASS lines |
| AC-27 | `test_ac_27_hud_headlocked.gd` | `ac_27 ...` PASS lines |
| AC-28 | `test_ac_28_hud_position.gd` | `ac_28 ...` PASS lines |
| AC-29 | `test_ac_29_hud_energy.gd` | `ac_29 ...` PASS lines |
| AC-30 | `test_ac_30_hud_sentinels.gd` | `ac_30 ...` PASS lines |
| AC-31 | `test_ac_31_hud_watched.gd` | `ac_31 ...` PASS lines |
| AC-32 | `test_ac_32_no_hand_label.gd` | `ac_32 ...` PASS lines |
| AC-33 | `test_ac_33_big_trees.gd` | `ac_33 ...` PASS lines |
| AC-34 | `test_ac_34_aim_tree_tile.gd` | `ac_34 ...` PASS lines |
| AC-35 | `test_ac_35_sentinel_facing.gd` | `ac_35 ...` PASS lines |
| AC-36 | `test_ac_36_feedback.gd` | `ac_36 ...` PASS lines |
| AC-37 | `tools/check-test-gate.sh` (`mise run test-gate`); APK: `mise run build` runs `verify-apk.sh` | `TEST GATE OK` lines; `verify` OK lines |
| AC-38 | `test_ac_38_names_gate.gd`, `tools/check-names.sh` | `ac_38 ...` PASS lines |
| AC-39 | `test_ac_39_terrain_meshes.gd` | `ac_39 ...` PASS lines |
| AC-40 | `test_ac_40_tree_canopy.gd` | `ac_40 ...` PASS lines |
| AC-41 | `test_ac_41_tree_shape.gd` | `ac_41 ...` PASS lines |
| AC-42 | `test_ac_42_hud_top.gd` | `ac_42 ...` PASS lines |
| AC-43 | `test_ac_43_grip_toggle.gd` | `ac_43 ...` PASS lines |
| AC-44 | `test_ac_logic.gd` | `ac_44_create_boulder` |
| AC-45 | `test_ac_45_boulder_under_you.gd` | `ac_45 ...` PASS lines |
| AC-46 | `test_ac_logic.gd` | `ac_46_trees_not_creatable` |
| AC-47 | `test_ac_logic.gd` | `ac_47_stacks` |
| AC-48 | `test_ac_logic.gd` | `ac_48_absorb_top_only` |
| AC-49 | `test_ac_logic.gd` | `ac_49_boulders_block_sight` |
| AC-50 | `test_ac_logic.gd` | `ac_50_energy_math` |
| AC-51 | `test_ac_51_lobby_six_steps.gd` | `ac_51 ...` PASS lines |
| AC-52 | `test_ac_52_hud_mode.gd` | `ac_52 ...` PASS lines |
| AC-53 | `test_ac_53_climb_stack.gd` | `ac_53 ...` PASS lines |
| AC-54 | `test_ac_logic.gd` | `ac_54_generator_stages` |
| AC-55 | `test_ac_logic.gd` | `ac_55_no_pits_or_spikes` |
| AC-56 | `test_ac_logic.gd` | `ac_56_smooth_not_noise` |
| AC-57 | `test_ac_logic.gd` | `ac_57_flat_share` |
| AC-58 | `test_ac_logic.gd` | `ac_58_sentinels_on_peaks` |
| AC-59 | `test_ac_logic.gd` | `ac_59_deterministic` |
| AC-60 | `test_ac_logic.gd` | `ac_60_tile_shapes` |
| AC-61 | `test_ac_logic.gd` | `ac_61_surface_height` |
| AC-62 | `test_ac_logic.gd` | `ac_62_slopes_in_levels` |
| AC-63 | `test_ac_logic.gd` | `ac_63_objects_only_on_flat` |
| AC-64 | `test_ac_logic.gd` | `ac_64_sight_over_slopes` |
| AC-65 | `test_ac_65_aim_slope.gd` | `ac_65 ...` PASS lines |
| AC-66 | `test_ac_66_terrain_geometry.gd` | `ac_66 ...` PASS lines |
| AC-67 | `test_ac_67_terrain_colours.gd` | `ac_67 ...` PASS lines |
| AC-68 | `test_ac_68_move_flat_height.gd` | `ac_68 ...` PASS lines |
| AC-69 | `tools/check-test-gate.sh` (`mise run test-gate`) | `README GATE OK` line |
| AC-70 | `test_ac_70_lobby_panel_placement.gd` | `ac_70 ...` PASS lines |
| AC-71 | `test_ac_logic.gd` | `ac_71_boulder_sees_over_step` |
| AC-72 | `test_ac_logic.gd` | `ac_72_synthoid_on_boulder_eye` |
| AC-77 | `test_ac_77_wind.gd` | `ac_77 ...` PASS lines |
| AC-73 | `test_ac_73_pause_menu_placement.gd` | `ac_73 ...` PASS lines |
