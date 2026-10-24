# References

Numbers 1-13: Sentinel Part A. 14-41: Sentinel Part B (BBC Micro source pack). 42-61: Rift briefing (Appendix A of 02). 62-89: Quest 2 guide (02 Part 1). 90-110: Linux-first path (02 Part 0). Access date 2026-10-24. 'Search' = seen only as a web-search summary; 'fetched'/'read' = page read. Document 03 is judgement and cites 01 and 02 by section.

## Sentinel (Part A)

Access dates: 2026-10-24. "Fetched" = page read via fetch tool (the tool returns an extract, not the raw page). "Search" = only seen as a web-search result summary, not opened.

1. Wikipedia, "The Sentinel (video game)", https://en.wikipedia.org/wiki/The_Sentinel_(video_game). Fetched. Gameplay overview, ports, programmers, reception and awards, remakes.
2. Wikipedia, "Sentinel Returns", https://en.wikipedia.org/wiki/Sentinel_Returns. Fetched. Release dates, 651 levels, reception.
3. GitHub, heikog/sentinel (fan reimplementation README), https://github.com/heikog/sentinel. Fetched. Fan clone: its numbers are NOT authoritative for the original (see 7, 8).
4. GitHub, simonowen/sentcode, https://github.com/simonowen/sentcode. Fetched. Landscape number range, 40-bit RNG, secret code derivation.
5. GitHub, markmoxon/the-sentinel-source-code-bbc-micro, https://github.com/markmoxon/the-sentinel-source-code-bbc-micro. Fetched. Confirms fully documented BBC Micro source exists; contains no rules text itself. Companion site: https://thesentinel.bbcelite.com (not fetched; host not approved).
6. Wikipedia, "Geoff Crammond", https://en.wikipedia.org/wiki/Geoff_Crammond. Fetched. 1986 Firebird release, "ten thousand levels", earlier Acornsoft work.
7. Sinclair-era instruction text, https://rk.nvg.ntnu.no/sinclair/instructions/sentinel.html. Search summary only (fetch failed). Energy table, 10 s per 30° rotation, 1 unit per 5 s drain.
8. Search summaries of retrogames.biz/games/amiga/sentinel, primidi.com/sentinel_returns/game_mechanics, c64-wiki.com/wiki/The_Sentinel. Not opened; used only to cross-check energy values.
9. Search summary of level7.org.uk, "The Sentinel disassembly", https://level7.org.uk/miscellany/the-sentinel-disassembly.txt, and thesentinel.bbcelite.com. Not opened. Source of landscape-generation facts (1,212–1,880 RNG numbers, 10–32 trees, sentry count rising by one per 1000 landscapes), repeated in 4.
10. Search summary of Retro Gamer #245, "The Making of Sentinel Returns" (magzter / pocketmags). Not opened. Development of Sentinel Returns.
11. Search summaries of John Valentine's Zenith page (https://johnvalentine.co.uk/zenith.php) and MobyGames "Zenith". Not opened. Remake details.
12. Search summary of Wikipedia "Sentinel (iOS game)" — title only seen; unrelated tower-defence game per summary; not used.
13. C64-Wiki, "The Sentinel", https://www.c64-wiki.com/wiki/The_Sentinel. Fetched (second pass). Energy table, start 10, hyperspace 3, 30° per 10 s, drain 1 per 5 s, 8-digit codes, score table. Confirms the figures attributed to [7].

## Sentinel Part B: BBC Micro source pack (items 14-41; items 14-36 are the annotated disassembly site)

14. Enemy tactics, deep dive, thesentinel.bbcelite.com, 2026. https://thesentinel.bbcelite.com/deep_dives/enemy_tactics.html. Tactics loop, drain timings, meanie rules, scan order. Primary (commentary on source).
15. Enemy timers and state variables, deep dive, same site. https://thesentinel.bbcelite.com/deep_dives/enemy_timers_and_state_variables.html. 0.06 s tick, three timers, start condition, enemy slots.
16. Generating the landscape, deep dive, same site. https://thesentinel.bbcelite.com/deep_dives/generating_the_landscape.html. The 11 generation steps, multiplier, smoothing, 31x31 grid.
17. Adding enemies and trees to the landscape, deep dive, same site. https://thesentinel.bbcelite.com/deep_dives/adding_enemies_and_trees_to_the_landscape.html. Enemy count, placement, palette, player start, trees (note the 14-32 slip, see ref 18).
18. The landscape secret code, deep dive, same site. https://thesentinel.bbcelite.com/deep_dives/the_landscape_secret_code.html. Code derivation, seed counts, 0000 and 0002 examples.
19. Following the gaze vector, deep dive, same site. https://thesentinel.bbcelite.com/deep_dives/following_the_gaze_vector.html. Ray stepping, what the player and enemies can see.
20. The projection system, deep dive, same site. https://thesentinel.bbcelite.com/deep_dives/the_projection_system.html. Field of view +-10 units, pitch limit +53.
21. Tile data and Tile shapes, deep dives, same site. https://thesentinel.bbcelite.com/deep_dives/tile_data.html and https://thesentinel.bbcelite.com/deep_dives/tile_shapes.html. Byte layout, altitude 1-11, shapes 0-15.
22. Seed number generation, deep dive, same site. https://thesentinel.bbcelite.com/deep_dives/seed_number_generation.html. LFSR taps, seeding.
23. Source of ApplyTactics (Part 2 of 10), same site. https://thesentinel.bbcelite.com/source/main/subroutine/applytactics_part_2_of_10.html. Meanie behaviour; 8-unit step (comment says 8.25 degrees; 360 x 8 / 256 = 11.25).
24. Source of AddEnemiesToTiles, same site. https://thesentinel.bbcelite.com/source/main/subroutine/addenemiestotiles.html. Timer 5-63, yaw step +-20.
25. Source of PerformHyperspace, same site. https://thesentinel.bbcelite.com/source/main/subroutine/performhyperspace.html. Hyperspace cost, win test (on the tower tile).
26. Source of GetNextLandscape, UpdatePlayerEnergy, GetPlayerEnergyBCD, same site. https://thesentinel.bbcelite.com/source/main/subroutine/getnextlandscape.html (and updateplayerenergy.html, getplayerenergybcd.html). Skip = landscape + energy in BCD; energy cap 63.
27. Source of objectTypeEnergy, same site. https://thesentinel.bbcelite.com/source/main/variable/objecttypeenergy.html. Energy table: robot 3, sentry 3, tree 1, boulder 2, meanie 1, Sentinel 4, tower 0.
28. Source of DrainObjectEnergy, same site. https://thesentinel.bbcelite.com/source/main/subroutine/drainobjectenergy.html. Drain effects, energy 0 game over.
29. Source of ProcessActionKeys (Parts 1 and 2), same site. https://thesentinel.bbcelite.com/source/main/subroutine/processactionkeys_part_1_of_2.html (and part_2_of_2). Keys, absorb/create/transfer conditions, no absorbing after the Sentinel.
30. Source of GetEnemyCount and InitialiseSeeds, same site. https://thesentinel.bbcelite.com/source/main/subroutine/getenemycount.html and .../initialiseseeds.html. Enemy count formula and cap.
31. Source of SpawnTrees and SpawnPlayer, same site. https://thesentinel.bbcelite.com/source/main/subroutine/spawntrees.html and .../spawnplayer.html. Tree count 10-32, start energy 10, start tile (8, 17).
32. Source of CheckEnemyGaze (Parts 1 and 2), same site. https://thesentinel.bbcelite.com/source/main/subroutine/checkenemygaze_part_2_of_2.html. Viewing arc 20 / 40.
33. Source of SpawnObjectBelow and SpawnObjectOnTile, same site. https://thesentinel.bbcelite.com/source/main/subroutine/spawnobjectbelow.html and .../spawnobjectontile.html. Placement rules, boulder 0.5 and tower 1.0 heights.
34. The scanner, deep dive, same site. https://thesentinel.bbcelite.com/deep_dives/the_scanner.html. Full versus half scanner.
35. Sound effects, deep dive, same site. https://thesentinel.bbcelite.com/deep_dives/sound_effects.html. Sound numbers 0-6.
36. Pitch and yaw angles, deep dive, same site. https://thesentinel.bbcelite.com/deep_dives/pitch_and_yaw_angles.html. 256 units per full circle.
37. sentcode, S. Owen, GitHub README. https://github.com/simonowen/sentcode. Independent open generator of secret codes for BBC, C64, CPC, Spectrum, ST, PC, Amiga; LFSR confirmed. Secondary but independent.
38. The Sentinel (Firebird, 1986) disassembly and analysis, level7.org.uk. https://level7.org.uk/miscellany/the-sentinel-disassembly.txt. Independent BBC disassembly; confirms start energy 10, tree cap 48 - 3n, yaw 20, drain timer 30, skip by energy. Comment errors noted (rotation 168 vs byte 200).
39. The Sentinel (video game), Wikipedia. https://en.wikipedia.org/wiki/The_Sentinel_(video_game). Secondary summary of rules; agrees with source on win, hyperspace, skip by energy.
40. The Sentinel, C64-Wiki. https://www.c64-wiki.com/wiki/The_Sentinel. Fan wiki, C64 version; says sentry 4, 30 degrees / 10 s, 5 s drain: differs from the BBC code.
41. Augmentinel, S. Owen, GitHub README. https://github.com/simonowen/augmentinel. Spectrum-based re-skin with OpenVR support (a precedent for VR).

## Oculus Rift development (items 42-61)



Some were obtained through WebSearch result summaries rather than a full page read; those are marked (search).

42. Meta, "Windows PC requirements for Meta Horizon Link" — https://www.meta.com/help/quest/459034058728993/ (read in v2)
   Godot XR docs index — https://docs.godotengine.org/en/stable/tutorials/xr/index.html (read; index only)
43. Same page as [1] plus "Oculus accounts after January 1, 2023" — https://www.meta.com/help/quest/757887065115653/ (search)
44. Meta, "Rift Virtual Reality Check (VRC) Guidelines" — https://developers.meta.com/vr/resources/publish-rift-app-submission/ (search)
45. Epic, "Developing for Oculus in Unreal Engine" — https://dev.epicgames.com/documentation/unreal-engine/developing-for-oculus-in-unreal-engine (search)
46. Meta, "Choosing an OpenXR Backend" (Unreal) — https://developers.meta.com/vr/documentation/unreal/unreal-openxr/ ; "Setting up the Meta XR plugin" — https://developers.meta.com/vr/documentation/unreal/unreal-setting-up-metaxr-plugin/ (search)
47. Web search on OpenXR runtimes, SteamVR/Steam Link, SideQuest, itch.io (aggregated; includes https://deep-matrix.com/blog/openxr-runtime-explained/ and https://mixed-news.com/en/steamvr-quest-usb-steam-link-stable-release/ — low-to-medium authority)
48. Meta, "Improvements to Meta Quest Link" — https://developers.meta.com/vr/blog/meta-quest-link-improvements/ (search)
49. Community setup guide, flyawaysimulation — https://flyawaysimulation.com/ask/answers/oculus-rift-rift-s-pc-flight-simulation-setup/ (low authority)
50. ArchWiki, "Virtual reality" — https://wiki.archlinux.org/title/Virtual_reality
51. Meta, "Rift (PC VR) overview" — https://developers.meta.com/vr/resources/rift/ (read)
52. Meta, "Hardware and software requirements" (Unity) — https://developers.meta.com/vr/documentation/unity/unity-development-requirements/ (read)
53. Wikipedia, "Meta Quest" — https://en.wikipedia.org/wiki/Meta_Quest (secondary)
54. Khronos, OpenXR — https://www.khronos.org/openxr/ (not fetched; cited as the standard's home)
55. UploadVR, "Oculus Rift Has Hidden Preliminary Support For OpenXR" — https://www.uploadvr.com/oculus-rift-basic-openxr-support/
56. Meta, Unity docs: Meta XR Simulator — https://developers.meta.com/vr/documentation/unity/xrsim-getting-started/ ; XR Plugin Management — https://developers.meta.com/vr/documentation/unity/unity-xr-plugin/ ; Deploy and Test — https://developers.meta.com/vr/documentation/unity/unity-deploy-and-test/ (search)
57. Unity, OpenXR Plugin 1.14 manual — https://docs.unity3d.com/Packages/com.unity.xr.openxr@1.14/manual/index.html (read)
58. Meta, "Upload apps to the Meta Horizon Store" — https://developers.meta.com/horizon/documentation/unity/unity-platform-tool/ ; "Uploading your Link PC-VR apps" — https://developers.meta.com/horizon/resources/publish-upload-rift/ ; Platform SDK — https://developers.meta.com/vr/downloads/package/oculus-platform-sdk/ (search)
59. Same as [11] for Unity version.
60. Godot articles: https://godotengine.org/article/godot-openxr-vendors-plugin-400/ ; https://github.com/GodotVR/godot_openxr_vendors/releases (search); secondary: vr.org Godot 4.6 article
61. Steam community, "Introducing SteamVR 2.17" — https://steamcommunity.com/games/250820/announcements/detail/679635225181946199 (search)

## Suggested further sources (for the manager, not requested from security)
- store.steampowered.com / partner.steamgames.com (Steamworks VR requirements)
- github.com (GodotVR/godot-xr-tools docs, Unity XR Interaction Toolkit samples)
- www.meta.com/help (Rift S lifecycle, requirements)
- docs.godotengine.org (still pending)

## Quest 2 guide (items 62-89; item 77 points to the Rift briefing, item 88 is unused)

### Read

62. Meta, "Set up your device for development" (developer mode, account, phone app, USB). https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/ . Read.
63. Meta, "Hardware Setup" (Unity). https://developers.meta.com/horizon/documentation/unity/unity-env-device-setup/ . Read. Supported devices, Simulator/Link/Build and Run table.
64. Meta, "Software Setup" (Unity). https://developers.meta.com/horizon/documentation/unity/unity-software-setup/ . Read. Unity 6000.0.66f2+, modules, MQDH, adb PATH.
65. Meta, "Manual project setup" (Unity Hello World). https://developers.meta.com/horizon/documentation/unity/unity-tutorial-hello-world-manual-steps/ . Read. Unity 6.1+, OpenXR plugin 1.15.1, com.meta.xr.sdk.all, Project Setup Tool.
66. Meta, "ADB on Meta Quest". https://developers.meta.com/horizon/documentation/native/android/ts-adb/ . Read.
67. Meta, "Locomotion comfort and usability". https://developers.meta.com/vr/design/locomotion-comfort-usability/ . Read.
68. Meta, Quest 2 tech specs. https://www.meta.com/quest/products/quest-2/tech-specs/ . Read. Display, refresh rates, "no longer available"; no CPU/RAM/battery.
69. Meta, "Deploy a build to your device" (MQDH). https://developers.meta.com/vr/documentation/unity/ts-mqdh-deploy-build/ . Read. Unknown Sources.
70. Godot docs, "Deploying to Android" (XR). https://docs.godotengine.org/en/stable/tutorials/xr/deploying_to_android.html . Read.
71. Unity, OpenXR Plugin 1.15 manual. https://docs.unity3d.com/Packages/com.unity.xr.openxr@1.15/manual/index.html . Read.
72. Android Developers, "Android Debug Bridge". https://developer.android.com/tools/adb . Read.
73. GitHub, GodotVR/godot_openxr_vendors README. https://github.com/GodotVR/godot_openxr_vendors . Read; no versions shown.
74. GitHub, SideQuestVR/SideQuest README. https://github.com/SideQuestVR/SideQuest . Read; developer build notes only.
75. SideQuest setup page. https://sidequestvr.com/setup-howto . Read; header only, no steps.
76. Epic, "Developing for Meta Quest in Unreal Engine". https://dev.epicgames.com/documentation/en-us/unreal-engine/developing-for-meta-quest-in-unreal-engine . Read; table of contents only.
77. Internal: Oculus Rift development briefing, drive a-4@v2, 02-oculus-dev.md and references.md (items 43, 47, 52, 56-59 there). Link PC requirements and Meta XR Simulator facts reused.

### Search only

78. UploadVR, "Meta Is Discontinuing Quest 2 & Quest Pro". https://www.uploadvr.com/meta-discontinuing-quest-2-and-quest-pro/ . Search summary (fetch failed). Also a commentary site calling Quest 2 "legacy".
79. Meta, "Security updates on Meta devices". https://www.meta.com/help/policies/1268845083754899/ . Search summary: Quest 2 December 2027. Feature-update date from a secondary source, unconfirmed.
80. Meta Quest release notes https://www.meta.com/help/quest/172903867975450/ and Mixed News on Horizon OS 2.9 https://mixed-news.com/en/horizon-os-2-9-quest-window-anchor-removed-wall-snapping-rollout/ . Search summaries only.
81. Meta, VRC.Quest.Performance.1. https://developers.meta.com/vr/resources/vrc-quest-performance-1/ . Search summary (refresh rates, 60 fps).
82. Meta, "Device-specific optimization (Quest 3 vs Quest 2)". https://developers.meta.com/vr/resources/device-optimization-comparison/ . Search summary (frame budget, draw calls, triangles).
83. Meta, "Use Link for App Development". https://developers.meta.com/vr/documentation/unity/unity-link/ . Search summary.
84. Meta, "Comfort" https://developers.meta.com/vr/design/comfort/ and "Locomotion user preferences" https://developers.meta.com/vr/design/locomotion-user-preferences/ . Search summaries.
85. Meta, "Android Application Signing" https://developers.meta.com/horizon/resources/publish-mobile-app-signing/ and "Meta Quest Application Signing"; dev.to "Automating Unity Builds for Meta Quest". Search summaries.
86. Streaming comparisons: https://blog.rottenwifi.com/airlink-vs-steam-link-vs-virtual-desktop-which-should-you-choose-for-meta-quest-pcvr/ , https://vrlowdown.com/air-link-vs-virtual-desktop/ , https://pcvrcentral.com/guides/quest-pcvr-setup . Search summaries; third-party, not authoritative.
87. VR & AR Wiki "Meta Quest 2" https://vrarwiki.com/wiki/Meta_Quest_2 ; Qualcomm device finder https://www.qualcomm.com/xr-vr-ar/device-finder/meta-quest-2 . Search summaries (XR2, Adreno 650, 6 GB).
88. (unused)
89. Meta, "Get Started with Meta Quest Developer Hub". https://developers.meta.com/vr/documentation/unity/ts-mqdh-getting-started/ . Search summary (ADB over Wi-Fi toggle).

Not reachable or not opened: www.khronos.org, Meta release notes, Meta Guardian docs, Unity XR Interaction Toolkit docs, Unreal setup pages.

## Linux-first path (items 90-110; 'search' marks pages not opened)

| # | Source | Status | Used for |
|---|---|---|---|
| L1 | Godot docs (stable = 4.7), "Exporting for Android", https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html | Read | JDK, SDK/NDK versions, sdkmanager line, keystore env vars, keytool |
| L2 | Godot docs (4.7), "Deploying to Android" (XR), https://docs.godotengine.org/en/stable/tutorials/xr/deploying_to_android.html | Read | Gradle build, XR Mode, Compatibility renderer, vendors plugin optional from 4.6 |
| L3 | Godot docs, "Command line tutorial", https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html | Read | `--headless`, `--export-debug/-release`, preset naming |
| L4 | GodotVR/godot_openxr_vendors releases, https://github.com/GodotVR/godot_openxr_vendors/releases | Read | v5.1.0 (4.6+), v4.3.1 (4.4+), 5.2.0-rc1 |
| L5 | Meta, "Get Started with Meta XR Simulator", https://developers.meta.com/vr/documentation/unity/xrsim-getting-started/ | Read | Windows and macOS only listed |
| L6 | Meta, mobile device setup, https://developers.meta.com/horizon/documentation/native/android/mobile-device-setup/ | Read | USB-C data cable, MTP notification, "Always allow"; no Linux/udev text |
| L7 | Godot download archive 4.7-stable and SourceForge mirror, https://godotengine.org/download/archive/4.7-stable/ | Search | 4.7 released 2026-06-18; 4.7.2 on 2026-08-18; file names |
| L8 | Unity manual, "System requirements for Unity 6.x", https://docs.unity3d.com/6000.1/Documentation/Manual/system-requirements.html | Search | Ubuntu 22.04 and 24.04 only |
| L9 | GameCI, activation / builder / common issues, https://game.ci/docs/github/activation/ | Search | `.ulf` secret, `UNITY_LICENSE/EMAIL/PASSWORD`, manual `.alf` flow no longer works for Personal |
| L10 | Unity manual 6000.3, "Manage your license through the command line", https://docs.unity3d.com/6000.3/Documentation/Manual/ManagingYourUnityLicense.html | Search | `-serial` activation not for Personal; Hub only |
| L11 | DEV Community, "Running Unity 6000.x Headless Builds in a Linux Container: A Field Report", https://dev.to/nydjustin/running-unity-6000x-headless-builds-in-a-linux-container-a-field-report-including-licensing-519b | Search | `unity auth login`, licence expiry within 24 h (single community report) |
| L12 | Unity CLI docs, https://docs.unity.com/en-us/unity-cli/use-unity-cli ; Hub CLI, https://docs.unity.cn/hub/manual/HubCLI.html | Search | `install-modules`, module IDs |
| L13 | Stridemann/Unity-XR-on-Linux-for-Meta-Quest, https://github.com/Stridemann/Unity-XR-on-Linux-for-Meta-Quest | Search | Community shims for Unity editor play mode on Linux (Quest 3; not Meta-supported) |
| L14 | Meta community forums, tag "linux", https://communityforums.atmeta.com/tag/linux | Search | User report: UE5 Meta XR plugin Windows-only |
| L15 | Meta, "Installing Unreal Engine", https://developers.meta.com/vr/documentation/unreal/unreal-quick-start-install-unreal-engine/ | Search | Three install options; no Linux mention |
| L16 | GodotVR/godot-xr-tools releases, https://github.com/GodotVR/godot-xr-tools/releases | Search | 4.5.2 stable (2026-10-08); 4.6.0-dev2 pre-release |
| L17 | Monado getting started, https://monado.freedesktop.org/getting-started.html | Search | Linux OpenXR runtime; `xr-hardware` udev package |
| L18 | adb udev guides (e.g. https://gist.github.com/1242035/4f73c093fd786a41d249397c2eb9e47c) | Search | `51-android.rules` pattern, plugdev, reload commands |
| L19 | CodePath, Installing Android SDK Tools, https://guides.codepath.org/android/Installing-Android-SDK-Tools | Search | `commandlinetools-linux-15859902_latest.zip` candidate |
| L20 | Meta Unity downloads page, https://developers.meta.com/vr/downloads/unity/ | Search | Lists a "Meta XR Simulator (Linux)" download; not confirmed |
| L21 | Meta, "Hardware and software requirements" (Unity), https://developers.meta.com/vr/documentation/unity/unity-development-requirements/ | Search | Unity 6000.0.66f2+; Linux not named |

Not researched: Bevy/other engines (own knowledge only); Android emulator limits (own knowledge); Monado on a Quest (no source read).
