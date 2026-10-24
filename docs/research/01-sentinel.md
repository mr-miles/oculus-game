# Question 1: the Sentinel (Geoff Crammond, 1986)

Strand A of t-7. Facts are kept apart from judgement. Where I could not verify something it says so. Citations [n] refer to references.md. Several sources were seen only as search summaries (marked in references.md); the figures most worth re-checking before design lock are listed in section 9.

**Structure.** Part A is the overview, history, ports and keep/change judgement. Part B (from section "Part B") lists rules read from the documented original BBC Micro source, each with a verification status. **Where Part A and Part B differ, Part B wins**; Part A has been patched on the points below.

**Source-verified now (BBC Micro code, most cross-checked):** Sentry energy 3; start energy 10; cap 63; hyperspace cost 3; skip = landscape + energy; 31x31 grid, altitudes 1-11; landscape algorithm in 11 steps; enemy rotation 28.125° every 11.94 s; drain after 7.14 s then 1 unit per 1.74 s; line of sight by ray stepping with separate head and tile tests; 8-digit codes. **Still open:** behaviour past landscape 9999; enemy maximum sight distance; differences in other ports (Spectrum, C64, Amiga, PC) beyond secret-code digits; Sentinel Returns rules; effective rates when the game loop is busy. Reasons are in Part B section B5.

## 1. Summary

The Sentinel is a 1986 puzzle game by Geoff Crammond, first published by Firebird for the BBC Micro [1][6]. You are a "Synthoid" (a robot) in a chequered 3D landscape of heights. You cannot walk. You gain height by stacking boulders and standing on them, and you must climb high enough to absorb the Sentinel, which sits on the highest point and watches [1]. Its US title was *The Sentry* [1].

## 2. Rules and mechanics

### 2.1 Goal
Absorb the energy on the way up, then absorb the Sentinel from a square at least as high as its platform [1][3]. Doing so lets you hyperspace to the next level [1]. Sentries (later levels) need not be absorbed [1].

### 2.2 Actions
- **Look around** from the current Synthoid [1].
- **Absorb** an object you can see, gaining its energy. **Create** a tree, boulder or Synthoid shell on a square you can see, paying its energy [1][3]. Boulders may be stacked and objects placed on top [3].
- **Transfer** your consciousness to another Synthoid you created, which is how you "move" [1].
- **Hyperspace** costs 3 energy units and takes you to a random square of equal or lower height [1][7]. The Synthoid left behind becomes a tree [3].
- Line of sight rule: you can only absorb or build on squares you can see (sources 3 and 8 say so; the exact geometry, e.g. whether the top of a stack or the base of a square must be visible, I did not verify).

### 2.3 Energy values (units)
| Object | Value | Notes |
|---|---|---|
| Tree | 1 | [3][7][8] |
| Boulder | 2 | [3][7][8] |
| Synthoid (robot) | 3 | [3][7][8] |
| Meanie | 1 | [7][8] |
| Sentry | **3** | BBC Micro code says 3 [27]; fan wiki and Sinclair text say 4 [13][7] (superseded, see Part B) |
| Sentinel | 4 | [3][7][8] |
| Hyperspace | costs 3 | [1][7] |

Creating costs what absorbing yields [3]. You start with 10 energy; hyperspace cost 3; a full energy bar shows 15 as a golden robot icon; energy below zero destroys the robot [13]. Total energy in the world is conserved: when the enemy drains a unit, a tree appears at a random place [1][7].

### 2.4 Enemies
- **Dormant until you act**: the Sentinel wakes when you make noise (absorbing/creating; turning does not count, a 180° turn is reported to) [7][8]. Treat as partly verified.
- **Rotation**: manuals say 30° every 10 s [1][7]; the BBC code is 28.125° every 11.94 s (Part B, section B2.5). Use the code figures.
- **Drain**: if one sees your square, you get a warning and one unit is drained about every 5 seconds per manuals [7]; the BBC code drains after 7.14 s, then every 1.74 s (Part B); if it finds a boulder or Synthoid it stops turning and absorbs it unit by unit (Synthoid becomes a boulder, boulder a tree) [7]. When your energy hits zero the game ends [1].
- **Meanies**: if an enemy sees your head but not your square, it may turn a nearby tree into a Meanie, which forces you to hyperspace at a cost of 3 [1][3][7]. A Meanie reverts to a tree when it loses you or you transfer (Part B, [23]).
- Sentries are lesser Sentinels, appearing from higher levels [1][3].
- You can hide: stay out of sight lines and hold high ground; enemies seeing only parts of you create the Meanie risk.

### 2.5 Scoring
The community scoreboard on the C64 wiki ranks players by the total energy held at the end of a level (top listed: 35) [13]; the game itself has no points. Progress is the energy you hold when you hyperspace after absorbing the Sentinel, which determines the level you jump to [1][9]. The skip formula is now known from the BBC code: next landscape = current landscape + remaining energy, added in BCD, maximum 63 [26][38] (Part B).

## 3. Level structure
- **10,000 landscapes**, numbered 0000–9999 [1][4][6]. The game stores them in BCD [4][9]. Nothing is stored: each landscape is grown from its number using a seeded random generator [4][9].
- **Generator**: a 40-bit linear-feedback shift register, seeded with the BCD landscape number [4]. Building a landscape consumes about 1,212–1,880 values and leaves 10–32 trees [9].
- **Enemy count**: grows by roughly one per 1,000 landscapes, limited in the first 100 [9]. (The fan README's 0–999 = Sentinel only, 1000–1999 = one Sentry is consistent but is a fan source [3].)
- **Landscape 0000** needs no code [4]. After a win the game shows an 8-digit secret code for the landscape you reached [4][9]. The code comes from the same RNG after generation, obfuscated by discarding digits, and differs between ports [4]. Codes can be computed for any landscape [4].
- The game has no ending; Wikipedia says it loops after the last level [1]; the code behaviour past 9999 was not traced (Part B).
- The game cannot be saved; each level shows an eight-digit code, level 0000 is the start, and play restarts after 9999 [13].
- Grid size and heights are now known: 31x31 tiles, altitudes 1-11 (Part B).

## 4. Why the design works (judgement)
- Slow, predictable enemies turn a real-time threat into planning.
- No walking plus line-of-sight forces you to read terrain; every move is a deliberate, visible decision.
- One conserved resource (energy) ties building, climbing, hiding and punishment together.
- Procedural levels give 10,000 puzzles at tiny storage cost, and the seed-based codes allow skipping.

## 5. History
Crammond made earlier Acornsoft BBC Micro titles (*Super Invaders*, *Aviator*) [6]. The Sentinel followed in 1986 from Firebird [1][6]. He said he never expected anyone to finish it [1]. Unknown: development dates and interviews (not found; see suggestions in the cover mail).

## 6. Platforms and ports
BBC Micro (original, Crammond); Commodore 64 (Crammond); Amstrad CPC (Crammond, per Wikipedia); ZX Spectrum (Mike Follin); Atari ST and Amiga (Steve Bak; Amiga with David Whittaker soundtrack); IBM PC (Mark Roll; VGA, distance darkening) [1]. Release years given only as 1986–1987 [1]; per-port dates unverified. A fully documented BBC source exists [5].

## 7. Remakes and successors
- ***Sentinel Returns***, official, Hookstone / Psygnosis, UK 14 Aug 1998, NA 28 Sep 1998, Windows and PlayStation; 651 levels; real-time turning and transfer; networked multiplayer on PC; John Carpenter soundtrack; Crammond was not involved in making it (the Retro Gamer piece says he co-initiated the revival and was too busy to develop it) [2][10]. Darker look than the original [2].
- Unofficial: *Sentry* (1998), *Zenith* (2005, freeware, landscapes up to 120×120), *Augmentinel* (2019), *Pinnacle* (2023); *Annwn: The Otherworld* (2019) is similar in play [1][11]. A 1995 April Fools preview "Monolith" led to a freeware game in 2020 [1].
- *Augmentinel* (2019, Spectrum-style re-skin) supports OpenVR headsets, so a VR precedent exists (Part B, [41]).

## 8. Reception
Zzap!64 Gold Medal; CRASH Smash; Golden Joystick Best Original Game; ranked highly by Your Sinclair (7th in its top 100), Amiga Power (20th), PC Format, Next Generation (53rd) [1]. Sentinel Returns: PC GameRankings 86%, PlayStation 63% [2].

## 9. Open items and caveats
- Superseded: the Part A items on the Sentry value, timings, line-of-sight geometry, grid size and skip formula are closed by Part B. What remains open is listed at the top of this document and in Part B section B5.

## 10. What a faithful VR version must keep, and what it could change (judgement)

**Keep**
- The no-walking, create-and-transfer movement and the height-by-stacking climb.
- The single conserved energy economy and the values (tree 1, boulder 2, Synthoid 3, Sentinel 4, hyperspace 3).
- Slow predictable enemy rotation, line-of-sight detection, the warning before drain, Meanies from partial sightings.
- Seeded landscapes (0000–9999) and the secret-code/energy-based skipping.
- The abstract, clean, chequered look and the eerie stillness.

**Could change**
- Turning and aiming by head tracking (natural fit; the original needs a pointer to look around).
- Teleport-to-created-Synthoid as a first-person transition; comfort options for height and for stacking.
- Presentation of the drain/warning (spatial audio, haptics) and UI for energy.
- Scoring, tutorials, and a campaign wrapper; real-time vs the original's pacing (the Returns remake already went real-time [2]).
- Seated and standing comfort modes. Because motion is by discrete transfer, nausea risk from locomotion is low.

---

# Part B: rules read from the documented BBC Micro source

Question: which exact rules, numbers and algorithms does the original BBC Micro code use, so a VR remake can be faithful? Primary source: the annotated BBC Micro source and deep dives at thesentinel.bbcelite.com [14]-[33] (a commented disassembly of the original binary; the commentary is by a third party, the code is the original). Cross-checks: an independent BBC disassembly [38], an open secret-code generator that supports seven ports [37], Wikipedia [39], the C64 wiki [40].

Status key: **source-verified** = read in the BBC code or its annotated routine; **cross-checked** = source-verified and an independent source agrees; **open** = not established, reason given. Citations [n] refer to `references-source.md`.

### B1. Answer in brief (confidence: high for the figures marked source-verified or cross-checked)

- The Sentry is worth **3** energy, not 4 (BBC table [27]; consistent with the code comment that the Sentinel is 4 and each sentry 3 [31]). Fan sources that say 4 [40] are wrong for the BBC version; whether other ports differ is open.
- Skipping: the next landscape number is the current number plus the player's remaining energy, added in BCD [26][38]. Energy is capped at 63.
- Landscape: 31x31 tiles on 32x32 corners, altitudes 1-11, built from 1024 seeds from a 40-bit LFSR with 11 steps [16][22].
- Enemies are timer-driven. The numbers differ from the manual-style figures (30 degrees every 10 s; one unit every 5 s) used in the earlier document: see section 9.

### 2. Figures

#### 2.1 Energy, skip, secret code (open item 1)

| figure | value | status | reference |
|---|---|---|---|
| Energy per object: robot (Synthoid) / sentry / tree / boulder / meanie / Sentinel / tower | 3 / **3** / 1 / 2 / 1 / 4 / 0 | source-verified | [27] |
| Creating an object costs the same energy as absorbing it yields | yes, same table | source-verified | [29] |
| Start energy | 10 | cross-checked | [31][38] |
| Maximum energy | 63 (6-bit cap `AND #63`) | source-verified | [26] |
| Energy shown by the icons | (display detail: full bar value not read) | open: not read in code | - |
| Hyperspace cost | 3 (it creates a robot, pays 3) | source-verified | [25] |
| Skip formula | next landscape = landscape + remaining energy, BCD addition | cross-checked | [26][38] |
| Energy used for the skip | `playerEnergy` after the winning hyperspace has deducted its 3 | source-read, inferred from call order | [25][26] |
| Maximum skip | 63 levels (energy cap) | derived from the two rows above | [26] |
| Landscape numbers beyond 9999 | no wrap code found in `GetNextLandscape`/`FinishLandscape`; behaviour not established | open: overflow past 9999 not traced (Wikipedia says play loops, unsourced) | [26][39] |
| Landscape number format | 4-digit BCD, high byte first | source-verified | [22][26] |
| Secret code | 8 digits = 4 seed bytes each shown as two BCD digits | cross-checked | [18][37] |
| Code seed position | seed the LFSR with landscape number, generate and discard N values (the count used to build the landscape, 1,211-1,879), then 38 more, then 4 for the code | cross-checked | [18][37] |
| Digit conversion | each byte: high nibble then low nibble; a nibble A-F has 6 subtracted | cross-checked (BBC and C64 use this) | [37] |
| Landscape 0000 code | 06045387 | source-verified (variable `secretCode0000`) | [18] |
| Example | landscape 0002 -> 88534263 | source-verified | [18] |
| Codes differ per port | yes: CPC, Spectrum, ST, PC, Amiga use other digit routines | cross-checked | [37] |
| Why codes cannot be predicted cheaply | the seed count depends on running generation | source-verified | [18] |

#### 2.2 Line of sight (open item 2)

| figure | value | status | reference |
|---|---|---|---|
| Player action keys | R, T, B create robot/tree/boulder; A absorb; Q transfer; H hyperspace; U U-turn (180 degrees) | source-verified (BBC keys) | [29] |
| What the player selects | a tile or boulder side under the crosshair sights, via a ray from the eye through the sights | source-verified | [19][29] |
| Eye height | objects sit 0.875 tile above their tile; the eye is there | source-verified | [19] |
| Ray method | step along the gaze vector in 1/256 increments of the full vector; test each step against tile height, boulder, tower, tree | source-verified | [19] |
| Create | needs the ray to hit a visible **flat tile** or the **side of a boulder** (so the new object goes on the top of that stack), the tile must be empty or hold boulders/tower, an object slot free (max 64 objects), and enough energy (energy never goes below 0) | source-verified | [19][29][33] |
| Absorb | the ray must hit a tile or boulder side; the object absorbed is the **top object on that tile**; the tile must contain an object | source-verified | [29] |
| Transfer | same targeting; the top object must be a robot | source-verified | [29] |
| You cannot target | your own tile; a tile whose surface is above your eye; tiles behind a boulder or tower the ray just misses; the tower's sides (the tower cannot be absorbed) | source-verified | [19][29] |
| After the Sentinel is absorbed | no further absorbing is allowed (error sound) | source-verified | [29] |
| Boulder reach | any part of a boulder side within 50% of the tile centre counts as hit; trees are hit inside a cone that widens downward | source-verified | [19] |
| Stack heights | boulder 0.5 coordinate, tower 1.0, tile cube 1.0; objects stack only on boulders or the tower, not on trees or robots | source-verified | [33] |
| Which tiles hold objects | flat tiles only (shape 0) | source-verified | [21][33] |
| Screen field of view | yaw -10 to +10 units = 28.125 degrees wide (256 units = 360 degrees); highest look-up pitch +53 units (74.5 degrees) | source-verified | [20][36] |
| Enemy viewing arc | 20 yaw units (28.125 degrees) for Sentinel/sentry; 40 units (56.25 degrees) for a meanie. Only yaw is tested in the part read | source-verified | [14][32] |
| Enemy range limit | no distance limit found in `CheckEnemyGaze`; ray reaches the target or hits terrain | open: only yaw arc and ray obstruction read; the full routine was not exhaustively traced | [32] |
| Enemy sees you (full) | its ray reaches your **tile** -> full scanner, drain begins | source-verified | [14][34] |
| Enemy sees you (partial) | ray reaches your robot's head but not your tile -> half scanner, meanie attempt | source-verified | [14][34] |
| Trees block sight | a tree in the way blocks the view of robot or tile | source-verified | [14] |
| Objects and sight for enemies | each robot you create is also a target; enemies drain any robot whose tile they see | source-verified | [14] |
| Hyperspace destination | random flat, empty tile below (player altitude +1); 255 tries per altitude then altitude +1 | source-verified | [25][33] |

#### 2.3 Grid, heights, tiles (open item 3)

| figure | value | status | reference |
|---|---|---|---|
| Grid | 31x31 tiles on 32x32 corners; tile data is 1024 bytes | source-verified | [21] |
| Altitude range | 1 to 11 (4 bits); objects add 0.5 per boulder, 1.0 for tower | source-verified | [21][33] |
| Tile shapes | 0-15 (no shape 8); 0 = flat; shape from corner altitudes; anchor is the front-left corner | source-verified | [21] |
| Axes | x along the front left to right, z into the screen | source-verified | [21] |
| Object number | up to 64; Sentinel always object 0, sentries 1-7 | source-verified | [15][28] |
| Tile with object | high two bits set, object number of the top object in bits 0-5 | source-verified | [16][21] |

#### 2.4 Landscape generation (open item 4)

| figure | value | status | reference |
|---|---|---|---|
| RNG | 40-bit LFSR, 5 bytes; feedback = bit 19 XOR bit 32, into bit 0; 8 shifts per output byte | cross-checked | [22][37] |
| Seeding | landscape number (BCD) in bits 0-15; bit 16 set so 0000 works | cross-checked | [22][37] |
| Step 1 | initialise seeds | source-verified | [16] |
| Step 2 | discard 81 seeds | source-verified | [16] |
| Step 3 | multiplier = 14 + (bits 0-2 + bits 3-6 of next seed) = 14-36; landscape 0000 fixed at 24 | source-verified | [16] |
| Step 4 | next 1024 seeds fill the tile data, back row first, right to left | source-verified | [16] |
| Steps 5-6 | smoothing twice: each corner = average of itself and next three along the strip, rows then columns, wrapping | source-verified | [16] |
| Step 7 | value = multiplier x (data - 128) / 256 + 6, floor 0, add 1, cap 11 -> altitude 1-11 | source-verified | [16] |
| Steps 8-9 | spike/trough smoothing twice | source-verified | [16] |
| Step 10-11 | compute tile shapes; swap nibbles (altitude high, shape low) | source-verified | [16] |
| Enemy count | T = top landscape digit + 2; fetch seeds, take leading zeros of bits 0-6 (0-7), invert if bit 7 set, add T; accept if 0-7, then +1 (1-8); capped by max | source-verified | [17][30] |
| Enemy cap by landscape | landscapes 0000-0009: 1; then 1 + tens digit up to landscape 0070+: 8; at 0100 and above: 8 | source-verified (`InitialiseSeeds`) | [30] |
| Enemy placement | highest 4x4 block (64 blocks) first for the Sentinel, then sentries at the highest free altitude; a placed block and its 8 neighbours are removed; Sentinel stands on a tower | source-verified | [17] |
| Palette | by enemy count, 8 palettes | source-verified | [17] |
| Player start | landscape 0000: tile (8, 17); others: random flat empty tile with altitude <= min(6, lowest enemy altitude), 255 tries per altitude | source-verified | [17][31] |
| Trees | 10 + (0-22) = 10-32, capped at 48 - 3 x enemies; placed below the lowest enemy | source-verified | [31] |
| Tree-count caveat | the prose in [17] says 14-32 once; the code and its comments say 10-32 and the independent source says 10-32 | cross-checked: code wins | [17][31][38] |
| Total landscape energy | at most 49 | source-verified (code comment) | [31] |
| Seeds consumed per landscape | 1,211 (6774) to 1,879 (9915) including the code | source-verified | [18] |
| Seeds before the enemy step | 1,106 always (81 + 1 + 1024) | source-verified | [18] |

#### 2.5 Enemy behaviour (open item 5)

One tick = 0.06 s (three 50 Hz interrupts). A timer set to n lasts (n-1) x 0.06 s [15].

| figure | value | status | reference |
|---|---|---|---|
| Start of enemy activity | enemies stay idle until the player has expended or absorbed energy, hyperspaced, or U-turned (turning the view alone does not) | source-verified | [15] |
| Tactic order | one enemy per gameplay loop, cycling objects 0-7, so every enemy gets equal service whatever the sentry count | source-verified | [14] |
| First tactic delay | random 5-63 ticks (0.24-3.72 s), per enemy, set at placement | source-verified | [17][24] |
| Re-check delay | 4 ticks (0.24 s) by default | source-verified | [14] |
| Rotation step | +20 or -20 yaw units (28.125 degrees), direction fixed per enemy by a seed bit; the source calls it "degrees" but the unit is 1/256 of a turn | source-verified (value), conflict on unit | [24][36] |
| Rotation interval | timer 200 -> 199 x 0.06 = **11.94 s**; independent disassembly has the same value 200 (&C8) though its comment says 168 | cross-checked | [15][38] |
| Rotation only when | the enemy has no target to drain | source-verified | [14] |
| Rotation sound | sound 0 | source-verified | [14][35] |
| Scan | each tactic pass searches objects 63 down to 0 for a robot whose tile or head it can see | source-verified | [14] |
| Drain start delay | when a robot target is first seen: 120 ticks = 7.14 s | source-verified | [14] |
| Drain rate | one unit per 30 ticks = 1.74 s afterwards; independent disassembly also has 30 | cross-checked | [14][38] |
| Drain of the player | energy -1, ping sound 5; if energy is already 0 the next drain ends the game | source-verified | [28] |
| Drain of a robot | robot -> boulder; boulder -> tree; tree deleted | source-verified | [28] |
| Non-robot drain targets | an exposed boulder, or any object stacked on another, on a tile it can see; next pass after 30 ticks = 1.74 s | source-verified | [14] |
| Enemy absorbs | drained energy is stored in the enemy (one counter per enemy) | source-verified | [14][28] |
| Energy return | each tactic pass spends one stored unit by planting a tree on a tile below the lowest enemy; stored energy of an absorbed enemy is still spent | source-verified | [14] |
| Meanie creation | enemy sees your head but not your tile: after the drain delay, it scans trees within 10 tiles (in both x and z) of the target robot, that it can see (view arc doubled to 40 units), and turns one into a meanie; next pass in 2.94 s | source-verified | [14] |
| Meanie behaviour | turns 8 units (11.25 degrees; the source comment says 8.25, an arithmetic slip) towards you every 0.6 s (sound 1); if it sees you or your tile it forces hyperspace | source-verified | [23] |
| Meanie reverts | back to a tree when you transfer or the target is gone, or when it cannot see you | source-verified | [23] |
| Failed meanie | after 2 failed scans for a target the enemy stops trying to drain it | source-verified | [14] |
| Absorbing a meanie | allowed; the owning enemy is reset | source-verified | [29] |
| Sentry vs Sentinel | same code; sentries stand on ordinary tiles; Sentinel on its tower | source-verified | [14][17] |
| Sentinel value | 4 | cross-checked | [27][40] |
| Sentry value | **3** | source-verified; fan wiki says 4 | [27][40] |
| Game over: energy | drain when energy is 0 (game over, Sentinel wins); create that would go below 0 is refused; hyperspace that would go below 0 ends the game | source-verified | [25][28][29] |
| Forced hyperspace failure | if the meanie's forced hyperspace cannot be paid, game over shows a meanie | source-verified | [23] |
| Fixed-time claims in manuals | "30 degrees every 10 s", "one unit every 5 s" | not matching the BBC code; treated as manual/port wording | [40] |

#### 2.6 Winning, hyperspace, scoring, sound (open item 6)

| figure | value | status | reference |
|---|---|---|---|
| Win | absorb the Sentinel (stand high enough to see its tower top), create a robot on the tower, transfer, hyperspace while on the tower tile | source-verified | [25][29] |
| Hyperspace | creates a new robot on a random flat, empty tile no higher than your current altitude, pays 3, plays the hyperspace music | source-verified | [25] |
| Sentry absorption | not needed to win | cross-checked | [25][39] |
| Scoring | no score exists; progress is the energy carried (skip) | source-verified (no score variable found in the routines read) | [26] |
| Scanner | full static box = enemy sees your tile; half box = sees head only | source-verified | [34] |
| Sounds | 0 enemy rotation; 1 meanie rotation; 2 create/absorb; 3 music; 4 scanner; 5 ping (errors, energy drain); 6 game over | source-verified | [35] |
| Music events | hyperspace, transfer, U-turn and landscape completion each play music | source-verified | [25][29][35] |
| Controls | pan, sights, U-turn (instant 180 degrees) | source-verified | [29] |
| Per-port differences | secret-code digits; sentry value, drain timing and rotation figures in manuals | open: only the BBC code was read in full; no Spectrum, C64 or Amiga source read | [37][40] |
| Sentinel Returns | not covered; no source code available | open | - |

### 3. Judgement (mine, labelled)

- Assessment: the earlier document's 30 degrees / 10 s and "5 s per unit" figures should be replaced with the BBC values (28.125 degrees / 11.94 s; 7.14 s then 1.74 s). Confidence medium-high; what would change it: evidence that the gameplay loop is slower than the 0.06 s tick so the effective interval differs.
- Assessment: for VR, the 28.125-degree window is the game's native field of view. A VR headset will see far more, so line-of-sight rules should be tied to the enemy's ray tests (head versus tile), not to what is on screen. Confidence medium.
- Assessment: the head-versus-tile test is the heart of the Meanie mechanic and is easy to implement with two ray casts per enemy per robot. Confidence high.
- Assessment: a faithful remake can reuse landscapes exactly only by porting the LFSR steps above or by using the open generators [37][41]. Confidence high.

### 4. Corrections to the earlier document

1. Sentry energy: 3 (not 4).
2. Rotation: 28.125 degrees (20 of 256 units) every 11.94 s, not 30 degrees every 10 s.
3. Drain: 7.14 s before the first unit, then 1.74 s per unit, not 5 s.
4. Meanie: reverts to a tree if it loses you or you transfer; not after one full turn.
5. Grid size and altitudes are now known (31x31, 1-11).
6. Skip formula is known: landscape + energy.
7. A VR build of the game exists: Augmentinel supports OpenVR headsets [41].

### 5. Unknowns and why

- Overflow past landscape 9999: not traced in code.
- Enemy maximum sight distance: only yaw arc and obstruction read.
- Other ports (Spectrum, C64, Amiga, PC): no source read; only the secret-code differences are documented [37].
- Effective rates when the gameplay loop is busy (panning blocks tactics until the pan ends) [14]: timers keep ticking, but a slow loop could delay actions; not measured.
- Sentinel Returns rules: no primary source.
