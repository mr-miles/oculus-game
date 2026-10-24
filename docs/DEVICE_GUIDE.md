# Putting the APK on a Meta Quest 2 and running it

Steps marked **[HUMAN]** cannot be done by software: they need a person, an
account, or the physical headset. Everything else is a command. This guide was
written without a headset: the `adb` commands were checked only against a
host with no device attached, and the Meta account/app steps come from Meta's
public documentation and may have drifted (Meta renames menus often). Where the
screens differ from this text, trust the screens.

## 0. What you need

- The APK: `game/build/quest-sentinel.apk` (build it with `mise run build`, or get it from whoever built it).
- A Quest 2, charged, set up with a Meta account, and a **USB-C data cable** (the charging cable in the box works).
- A computer (Linux, macOS or Windows) and a smartphone with the Meta Horizon app.

## 1. Developer account and Developer Mode — [HUMAN], once

1. **[HUMAN]** Sign in at <https://developers.meta.com> with the same Meta account that owns the headset.
2. **[HUMAN]** Create a developer organisation when asked (any name; accept the developer terms). Meta may ask you to verify the account with a phone number or payment method.
3. **[HUMAN]** On the phone, open the **Meta Horizon** app → **Menu → Devices** → pick the headset (it must be powered on and connected) → **Headset Settings → Developer Mode** → switch **on**. (Older versions: Settings → Developer Mode.)
4. **[HUMAN]** Reboot the headset (hold power → Restart).

If the toggle is missing, the account is not yet part of a developer organisation: redo steps 1–2.

## 2. Install the APK

Choose **A (adb)** or **B (Meta Quest Developer Hub)**.

### A. adb

1. Install `adb` (Android platform-tools). On the build machine it is at `.toolchain/android-sdk/platform-tools/adb` in the repo after `mise run setup`; otherwise download "SDK Platform-Tools" from developer.android.com.
2. **[HUMAN]** Connect the headset to the computer with the USB-C cable. Put the headset on.
3. **[HUMAN]** In the headset a dialog "Allow USB debugging?" appears: tick **Always allow from this computer**, then **Allow**. (If it doesn't appear: unplug and replug, or toggle Developer Mode off/on.)
3a. On Linux, if `adb devices` shows nothing or `no permissions`: add a udev rule for Meta's vendor id and replug, e.g. `echo 'SUBSYSTEM=="usb", ATTR{idVendor}=="2833", MODE="0666", GROUP="plugdev"' | sudo tee /etc/udev/rules.d/51-quest.rules && sudo udevadm control --reload`. (Id from the research pack; confirm with `lsusb`.) The headset may also show a "USB connected / allow access to data" (MTP) prompt: accept it.
4. On the computer:
   ```sh
   adb devices                 # should list one device as "device" (not "unauthorized" / "no permissions")
   adb install -r quest-sentinel.apk
   ```
   Expected: `Success`. (`-r` reinstalls over an older build. If you get `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, run `adb uninstall org.example.questsentinel` first: the signing key differs.)
5. Optional, wireless afterwards: `adb tcpip 5555`, unplug, then `adb connect <headset-ip>:5555` (headset IP: Settings → Wi-Fi → your network). Both on the same network.

### B. Meta Quest Developer Hub (MQDH)

1. **[HUMAN]** Download MQDH from <https://developers.meta.com> (Windows/macOS; there is no official Linux build — use adb on Linux), install it and sign in with the developer account.
2. **[HUMAN]** Connect the headset by USB, allow USB debugging as above; the headset shows up in MQDH's Device Manager.
3. Drag `quest-sentinel.apk` onto the MQDH window (or **Device Manager → Add Build/APK**) and choose install.

## 3. Run it

1. **[HUMAN]** In the headset: **Library → search/filter → Unknown Sources** (the filter drop-down at the top right of the Library). "Quest Sentinel" is listed there — apps installed outside the store never appear in the main list.
2. **[HUMAN]** Choose a play area with about 2 m × 2 m of free floor; set up the Guardian boundary if the headset asks.
3. Launch it from the list. Or from the computer:
   ```sh
   adb shell am start -n org.example.questsentinel/com.godot.game.GodotApp
   ```
4. Controls (right controller): point at a tile — cursor yellow = you can see it, red = hidden. **Trigger**: create a synthoid (3 energy). **A**: transfer into the synthoid you point at. **B**: absorb a tree/synthoid (+energy). Left wrist shows energy. Reach a tile as tall as the red Sentinel's to win. There is no snap-turn: turn your body.

## 4. If it doesn't work

- Black screen / immediate exit: `adb logcat -s godot:* OpenXR:* AndroidRuntime:*` while launching; send the output.
- App not in Library: check the **Unknown Sources** filter; `adb shell pm list packages | grep questsentinel`.
- Check frame pacing (not part of this prototype's claims): `adb shell dumpsys SurfaceFlinger --latency` is unreliable on Quest; use MQDH's Performance Analyzer or OVR Metrics Tool (**[HUMAN]**) instead.
- Remove it: `adb uninstall org.example.questsentinel`.
- To turn Developer Mode off again, reverse step 1.3.

## 5. Report back (what we still don't know)

Please note, as a **[HUMAN]** observation: did it install; did it launch to a 3D scene in the headset; were the controller ray and the three buttons responsive; was the framerate smooth (no judder); any logcat errors. See `docs/FINDINGS.md`, "Not run".
