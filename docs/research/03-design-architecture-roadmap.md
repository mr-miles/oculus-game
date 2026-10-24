# Question 3: design, architecture and roadmap for a VR Sentinel

Everything in this document is **judgement** built on the facts in `01-sentinel.md` and `02-oculus-dev.md` (section references point there). Confidence is stated per item. It has not been prototyped.

## 1. Why Sentinel suits VR (confidence: high)
- Movement is by discrete transfer to a created Synthoid, not continuous walking (01 §2.2). That is a teleport, the least nauseating locomotion in VR (02 §6 of Part 1). The core loop needs no locomotion workaround.
- The game is about looking: line of sight decides what you can absorb or build and what the enemy sees (01 §2.2, §2.4). Head tracking makes "can I see that square?" literal, which the original needed a pointer for.
- The look is abstract and light (a chequered landscape, few objects), so the Quest 2 at 72 Hz is realistic (02 §6 of Part 1: dropped frames are the main comfort risk).
- Height is the central resource. In VR, standing atop a tall boulder stack and looking down on the Sentinel is a physical sensation of height. This is the main thing VR adds.

## 2. Mapping the mechanics

| Original (01) | VR design | Notes |
|---|---|---|
| Look around | Head orientation, with snap-turn on stick as a seated aid | Keep Sentinel/Sentry rotation rates in real seconds (30° per 10 s) |
| Pointer picks a square or object | Controller ray (hand aim pose), highlight on the targeted square or object, trigger to confirm | Show whether the target is visible and what action is possible |
| Absorb / create | Hold trigger to absorb (energy drains to a gauge); radial or wrist menu to choose tree, boulder or Synthoid, then place | A wrist-attached energy gauge avoids a screen-space HUD |
| Transfer | Aim at a created Synthoid, press; short fade/blink into its viewpoint | Keep the fade to a fraction of a second; the original is also a cut |
| Hyperspace | Button with a hold-to-confirm; cost 3; the old Synthoid becomes a tree | Distinct audio and a short fade |
| Sentinel drain warning | Spatialised audio from the Sentinel's direction, a visible gaze cone or beam, controller haptics | Replaces the original's on-screen alert; better than the original in VR |
| Meanies | Same rules; visible transformation of a tree plus audio | |
| Level code entry | Landscape selector plus code entry on a virtual keypad | |

Decisions the team must make, each with my recommendation:
1. **Scale**: table-top "god view" vs first-person scale. Recommend first-person scale as the main mode (it is the game), plus an optional hand-held miniature map of the landscape as a planning aid. Confidence: medium; test early.
2. **Real-time vs paced**: keep the original's rotation timing for the faithful mode; consider an untimed "study" mode. Confidence: medium.
3. **Seated and standing**: both supported through recenter and a height offset (02 §6 of Part 1). Because eye height comes from the Synthoid, not the player, standing physical height matters little. Confidence: medium.
4. **Faithful mode vs enhanced mode**: ship "Classic" (original values and rules per 01 §10 "Keep") first. Add enhancements (hints, new levels) afterwards.

## 3. Rules that must be settled before design lock
Closed by reading the original BBC Micro source (01 Part B): Sentry energy 3, skip formula (landscape plus remaining energy), line-of-sight geometry (ray from the eye through the sights; separate head and tile tests for enemies), grid 31x31 with altitudes 1-11, enemy timings (rotation 28.125° every 11.94 s; drain after 7.14 s, then every 1.74 s), landscape generation in 11 steps.

Still open (01 section B5): behaviour past landscape 9999, enemy maximum sight distance, differences in the Spectrum/C64/Amiga/PC ports, and Sentinel Returns rules. None blocks phase 1. Keep every value in data, not code, and decide on an "original BBC rules" default.

## 3a. Target and standalone versus PC-streamed
Target: Meta Quest 2, sideloaded, for family use; no store submission (02 Part 1). Recommendation: **standalone Android build** (02 §4), with the editor on a PC used only for iteration (Link play-in-editor or Meta XR Simulator). Reasons: the game is very light (31x31 low-poly grid, few objects; Quest 2 guidance of under 100 draw calls and 750K triangles is far above its needs, 02 §2), the family needs no PC at play time, and streaming adds latency and Wi-Fi tuning for no gain. Streaming (Link, Air Link) is kept as a development aid and a fallback. Confidence: medium-high; nothing was run on hardware. Optional Rift S, Quest 3 and SteamVR support comes from the same OpenXR code with a build target change (02 Appendix A).

## 3b. Engine for an AI agent on Linux (judgement; supersedes the Unity default)
All development is done by an AI agent on Linux, headless, with Windows only for end-user testing. The research (02 Part 0) recommends **Godot 4.7.2 with the OpenXR Vendors plugin 5.1.0, Compatibility renderer, headless Android export from the command line**, on Ubuntu 24.04. Unity runs on Linux (Ubuntu 22.04/24.04) but Personal-licence activation needs a browser login and one report says the licence lapsed within 24 h, and Meta's simulator and Link are Windows/macOS only, so Unity is the fallback. Unreal's Meta plugin is reported Windows-only. Confidence: medium; nothing was run on a Linux machine or headset, and several URLs and settings are unconfirmed (02 Part 0 caveats). The rules core (below) is written engine-neutral, so the engine can change at low cost; in Godot, write it in GDScript or C# (verify the C# Android export separately) instead of the Unity C# assumed in the sketch below.

## 4. Suggested architecture (engine: Godot 4 + OpenXR per 02 Part 0; Unity as fallback)

Separate the game rules from the presentation so that the rules are testable without a headset.

```
Game.Core (pure C#, no Unity types)
  Landscape      grid of tile heights, objects, seeded generator (landscape number -> world)
  Energy         ledger: conservation of energy, absorb/create costs
  Visibility     line-of-sight queries: can viewer V see tile T (or object O)?
  Enemy          Sentinel/Sentry state: rotation, scanning, absorption, Meanie spawning
  Rules          actions: Absorb, Create, Transfer, Hyperspace -> validated, deterministic
  Codes          level code generation and check
Game.Engine (presentation; Godot scenes, or Unity if used)
  WorldView      meshes for terrain/objects built from Core state
  XRInput        OpenXR input (Touch Plus/Touch profile on Quest 2), ray picking, UI
  Locomotion     transfer fade, hyperspace, recenter
  Audio/Haptics  spatial audio for enemy, feedback
  UI             wrist gauge, menus, level select
Tests
  Core unit tests; deterministic replay tests against known landscapes
  Headset-less play tests with the Meta XR Simulator (02 §4); keep the render budget in mind (URP, few lights, 72 Hz)
```

Key points:
- Keep Core deterministic and integer-based so the same landscape number always gives the same level, and tests can replay full solutions.
- Implement the landscape generator from the documented algorithm (01 Part B §B2.4: seeded 40-bit shift register, 11 steps) and the open secret-code generator (01 ref 17) and verify against known levels from the references; this is the highest-value early test.
- Visibility is the most important computation. Do it in Core by porting the original ray-stepping test (eye 0.875 tile up, 1/256 steps; 01 B2.2), with separate head and tile tests for enemies, not with engine physics raycasts, so the rule is exact and testable. The original's 28.125° view window is a screen limit; in VR, tie player targeting to the controller ray and enemy detection to the original ray tests. Display uses the same function for highlights.
- Use plain OpenXR with the Touch profile; add Meta SDK packages only when a feature needs them (02 §5).

## 5. Risks

| Risk | Likelihood / impact | Mitigation |
|---|---|---|
| **Derived work.** The game is based on Sentinel, not a reproduction, and is for a private audience; rights to the original were not researched. | Accepted | Build an original implementation of the mechanics with new assets. |
| **Quest 2 is discontinued.** Meta says it is no longer available; search summaries (not Meta pages read) say updates continue with security updates committed to December 2027 (02 §2). Sideloading and developer mode were not found deprecated. | Medium / medium | Keep the build portable via OpenXR; keep the signing keystore and the APK; a second device (Quest 3 class) is a fallback. |
| **Developer account friction.** Developer mode needs a developer team and SMS or payment-method verification, age 18+ (02 §1). | Medium / low | Do this in phase 0; use SMS verification. |
| **Sideload and signing.** Updates fail if the signing key changes (02 §3). | Medium / low | Create one keystore at the start and back it up. |
| **Platform churn.** Meta SDK and plugin names change often (02 §5). | High / low | Pin versions; use plain OpenXR. |
| **Rule uncertainty** (remaining items in 01 B5; port differences). | Low / low | Default to BBC Micro rules; keep values in data. |
| **Comfort / usability**: stacking boulders at height, precise picking at a distance. | Medium / high | Early prototype tests on the Quest 2 with several people; add assisted aiming and a map. Comfort cannot be tested without headsets (02 §7). |
| **Linux/headless path unproven: nothing run on Linux or hardware; some URLs, plugin matching and settings unconfirmed (02 Part 0).** | Medium / medium | Phase 0 is the hello-world chain; Unity is the fallback engine. |
| **Nothing run on real hardware; Unity version guidance in Meta's pages conflicts** (02 Part 1 §5, §7). | Medium / medium | First engineer follows the guide on the real Quest 2 in phase 0 and corrects it. |

## 5a. Precedent
An open-source re-skin of Sentinel, *Augmentinel*, already supports OpenVR headsets (01 ref 41, README only; not played). Study it for comfort lessons before the prototype. Confidence: low, as it was not examined.

## 6. Phased roadmap (effort in team-weeks is a rough estimate by judgement; a team of 3–4 assumed)

| Phase | Weeks | Content | Exit criterion |
|---|---|---|---|
| 0. Hello-world chain | 2 | Human: Meta developer team and verified account, developer mode, USB debugging (humans only). Agent: Linux box with packages from 02 Part 0, headless build, sign, adb install, run, logcat checks of a chequered floor + cube + head-tracked view | Hello-world acceptance criteria met on the Quest 2; fallback (02 Part 0 §L7) documented if not; guide corrected |
| 1. Core (can start in parallel with phase 0; no headset needed) | 4 | Game.Core: landscape generator, energy, visibility, enemy, codes; unit and replay tests | Known landscapes reproduce; full-solution replays pass |
| 2. VR prototype | 4 | Unity + OpenXR standalone, one landscape, look/absorb/create/transfer with controller ray, enemy audio; Link or Simulator for iteration, Build and Run each week | Playable on the Quest 2 at 72 Hz; family testers finish level 1 |
| 3. Vertical slice | 6 | 20 landscapes, tutorial, hyperspace, Meanies, Sentries, level codes, comfort options (teleport, snap turn, vignette, seated) | Comfort and usability checked on the Quest 2 |
| 4. Content and family release | 4 | All 10,000 landscapes (generated), settings, saves, accessibility; an install guide for the family: how to sideload an update (MQDH or adb), where it appears (Library > Unknown Sources), backup of keystore and APK | Release APK installed on the family headset |
| 5. Support | ongoing | Fixes, optional extras: Rift S/Quest 3/SteamVR build targets | Feedback triaged |

Total to the family release: about 20 weeks (no store submission, review or listings). Confidence in the estimate: low to medium; replace it after phase 2.

## 7. What the product manager should ask for first
1. A one-page rule sheet taken from 01 Part B (the values are now source-verified); decide the port-difference defaults.
2. The Quest 2, a USB-C data cable, a Windows PC meeting Meta's Link requirements (02 §4), and an adult with a phone to create the developer account.
3. A phase 2 prototype review with family testers before committing to phases 3 to 5.
