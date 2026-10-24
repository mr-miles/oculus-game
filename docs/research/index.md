# Sentinel for Oculus VR (Quest 2 target): research pack

Assignment t-7. Research date 2026-10-24. Plan: drive:a-1@v3.

## Answer in brief
- **Sentinel** (1986, designed by Geoff Crammond, BBC Micro first) is a slow puzzle game of height and line of sight. You cannot walk. You create boulders and robot shells, climb by stacking, and "move" by transferring into a shell, to absorb the watching Sentinel from a higher spot. One conserved energy economy (tree 1, boulder 2, robot 3, Sentinel and Sentry 4, hyperspace costs 3) ties it together. Exact rules are now read from the documented original BBC Micro code (Sentry 3, skip = landscape + energy, 31x31 grid, enemy rotation 28.125° every 11.94 s, drain after 7.14 s then every 1.74 s). It has 10,000 landscapes, each generated from its number. Remakes exist (official: Sentinel Returns 1998); an open-source re-skin, Augmentinel, already supports OpenVR headsets. See `01-sentinel.md`.
- **Linux-first update:** development is by an AI agent on Linux, so the recommended engine is now **Godot 4.7.2 + OpenXR Vendors plugin 5.1.0 with headless Android export on Ubuntu 24.04**; Unity is the fallback (Linux activation and Meta tooling issues). `02-oculus-dev.md` Part 0 gives the engine comparison, package list, install script, headless-testing options and a hello-world spec; humans must do the developer account, developer mode and on-headset checks. Not run on Linux or hardware.
- **Quest 2 development (family use, sideloaded)**: the primary target is a Meta Quest 2; no store release. Recommended: a standalone Android build with Unity 6, OpenXR and URP, sideloaded with Meta's developer tool or adb, iterated with Link play-in-editor or Meta's headset simulator. Developer mode needs a developer team and SMS or payment-method verification. Quest 2 is discontinued but was still a supported dev device and (per search summaries) still updated. Rift and others are optional via OpenXR. Step-by-step guide in `02-oculus-dev.md`; nothing was run on real hardware.
- **Design and roadmap**: Sentinel fits VR unusually well, because its movement is already a teleport and its core is looking. Recommended: a deterministic, headset-independent rules core with a thin Unity/OpenXR presentation layer; about 20 weeks to a family release in 6 phases (no store work), with a prototype review gate after phase 2. See `03-design-architecture-roadmap.md`.

## Recommendation (judgement)
Proceed to phase 0 (hello-world chain on Linux and the Quest 2) and then a prototype, before committing to the full build. Confidence: medium.

## Main caveats
- Derived work: the game is based on Sentinel, not a reproduction of it, and is for a private audience. Rights to the original were not researched.
- Sentinel rules: source-verified for the BBC Micro version; still open: behaviour past landscape 9999, enemy maximum sight distance, other ports' differences, Sentinel Returns rules (no source read). Unverified elsewhere: Meta's lifecycle statement for Rift; Godot and Unreal specifics; Meta's comfort guidelines; Steamworks requirements.
- Neither the Linux path nor the Quest 2 setup has been run on a real Linux machine or hardware; several download URLs, plugin matches and settings are unconfirmed (02 Part 0 lists them); only 6 pages were opened for the Linux research, the rest are search summaries. Quest 2 support status and specs come partly from search summaries. Meta's pages disagree on the minimum Unity 6 version. Unreal, XR Interaction Toolkit, Guardian and wireless adb were not verified. Some sources were seen only as search summaries; references.md marks which.
- The researchers' findings were reviewed for completeness and honesty, but not independently re-fetched.

## Contents
1. `01-sentinel.md`: question 1
2. `02-oculus-dev.md`: question 2
3. `03-design-architecture-roadmap.md`: question 3 (judgement)
4. `references.md`: numbered references (1-13 Sentinel overview, 14-41 Sentinel BBC source, 42-61 Rift briefing, 62-89 Quest 2, 90-110 Linux path)

Version 4: Linux-first, Godot recommendation, hello-world spec. Version 3: reworked around a sideloaded Quest 2 target. Version 2: rights note simplified (derived work, private audience); Sentinel rules revised from the original source. Facts and judgement are tagged in each document; document 03 is entirely judgement.
