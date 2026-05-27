# Release runbook — remaining hardware & account gates

A sequenced, plain-language walkthrough of every gate the dev machine cannot
clear on its own. Do these in order. Each section says **what you need**,
**what to do**, and **how to know it passed**.

Code-side fixes already landed alongside this doc:
- `ITSAppUsesNonExemptEncryption = false` added to `DrumrotInfo.plist`
  (skips the export-compliance prompt on every TestFlight upload).
- The Xcode project, target, module, folders, Info.plist and test target were
  renamed `SP808Killa` → `Drumrot` (build scheme is now `Drumrot`, project is
  `ios/Drumrot.xcodeproj`); verified `xcodebuild test` green post-rename.
  `CFBundleDisplayName = drumrot` so the home-screen icon reads "drumrot".
  Bundle id stays `com.visaliacrc.drumrot`.
- BpmStepper got accessibility labels on the +/- buttons and a value readout on
  the BPM display.
- User-facing "SP-808 KILLA" strings replaced with "drumrot" in
  `PlaceholderScreen`, `DrumrotCardView` card footer, web `index.html`,
  `js/drumrots.js` card markup, `js/main.js`, `package.json` description, and
  the exported MIDI filename (`drumrot-pattern.mid`).
- `skibidi_tomtomlet` renamed to `trono_tomtomlet` ("Trono Tomtomlet" /
  👑🥁) across `Drumrots.json` (iOS), `js/drumrots.js` (web), and the asset
  files in `Assets.xcassets/drumrots/` and `art/drumrots/`. Parody fields
  pointing to `brainrots/OG/Skibidi_Toilet.png` were dropped from the web
  entry; the orphaned reference image file is still on disk and can be
  deleted manually.

---

## 1. Real iPad latency

**You need:** any iPad you support (oldest one wins; M-series ProMotion is the
ceiling, A14/A15 is the floor), a Lightning or USB-C cable, and headphones.

**Do:**
1. In Xcode: scheme `Drumrot` → set the destination to your iPad.
2. Edit Scheme → Run → Build Configuration: **Release**. (Debug builds add
   overhead that fakes high latency.)
3. Plug in headphones (built-in speaker latency is the iPad's own delay path,
   not the app's).
4. Run on device. Go to Play tab → load any lesson → tap a pad rapidly.
5. Listen for the gap between finger contact and sound. It should feel like a
   real drum, not a button beep.

**How to know it passed:**
- Pad-tap → sound feels tight (no perceptible delay).
- If it feels mushy, open `Drumrot/Audio/AudioSessionManager.swift` and drop
  `setPreferredIOBufferDuration(0.005)` to `0.003`. Rebuild, retest.
- For a numeric measurement: enable the "click" voice and tap on the downbeat;
  a few seconds of recorded audio in Voice Memos will let you see the offset
  in any waveform editor.

---

## 2. USB MIDI

**You need:** an iPad with USB-C **or** a Lightning iPad + Apple Camera
Connection Kit, and any class-compliant MIDI controller (cheapest path:
nanoPAD2, AKAI LPD8, or borrow an SPD-SX).

**Do:**
1. Plug controller into iPad. iOS recognizes class-compliant gear with no
   drivers.
2. Open the app → Settings → MIDI. The device should appear in the source list.
3. Go to Play. Hit pads on the controller. Highway pads should light and play
   their voice.

**How to know it passed:**
- Source name appears within 1–2 seconds of plugging in.
- Each pad strike → on-screen pad pulses + correct voice fires.
- Unplug mid-session → app does not crash; source disappears from the list.
- Plug back in → reappears, still works.

**If a pad triggers the wrong voice:** the controller is sending a non-GM note
number. Open `Drumrot/Domain/GMDrumMapper.swift` — the expected mapping is
kick 36 / snare 38 / hi-hat 42 / crash 49 / tom 45 / ride 51.

---

## 3. Network MIDI

**You need:** a Mac on the same Wi-Fi network as the iPad.

**Do:**
1. On Mac: `Applications → Utilities → Audio MIDI Setup`. Window menu → Show
   MIDI Studio. Double-click "Network".
2. In the "My Sessions" pane, click `+`. Tick the new session.
3. On iPad: open Settings (iOS Settings app, not the app) → General → AirPlay &
   Handoff → **Network MIDI** is what the iPad calls it (or it shows in the
   app's Settings → MIDI directly if Bonjour discovered it).
4. In the app's Settings → MIDI, the Mac's session should appear.
5. From the Mac, send notes (any DAW, or run the repo's
   `scripts/midi-pulse.mjs`) and confirm the highway responds.

**How to know it passed:**
- Mac session shows in the app's source list within ~5 seconds.
- Notes from the Mac drive the highway in near-real-time (Wi-Fi adds a few ms).
- Kill the Mac session → app does not crash.

---

## 4. Bluetooth MIDI

**You need:** any BLE MIDI controller (WIDI Master, mi.1, Yamaha MD-BT01, etc.)
**or** another iPad/Mac advertising itself as a BLE MIDI peripheral.

**Do:**
1. App → Settings → MIDI → "Pair Bluetooth MIDI" button. The system pairing
   sheet appears (`CABTMIDICentralViewController`).
2. Tap your controller in the list. Wait for "Connected".
3. Dismiss the sheet. The controller should now show in the source list.
4. Hit pads. Verify highway responds.
5. Turn the controller off → on. Confirm it reconnects without re-pairing.
6. Force-quit the app, relaunch. Confirm the device reconnects automatically.

**How to know it passed:**
- First pairing completes within ~10 seconds.
- After power-cycle, reconnect is automatic (no need to re-pair).
- After app relaunch, the device is available without re-pairing.

---

## 5. VoiceOver

**You need:** the iPad. No external gear.

**Do:**
1. iOS Settings → Accessibility → VoiceOver → on. Learn the gestures (single
   tap = focus + read; double-tap = activate; swipe right = next element).
2. Open the app. Swipe right through every element on every tab.
3. Listen for any element that reads as just "button" with no name — those need
   `.accessibilityLabel(...)` added.
4. Critical paths to walk:
   - Tab bar: each tab announces its name.
   - Play tab: pads announce ("SNARE pad", "double tap to play"), BPM stepper
     announces value (now: "Tempo, 96 beats per minute"), play/stop/loop/click
     buttons all named.
   - Library tab: lesson cards announce title + difficulty + best score.
   - Progress tab: achievements announce name + locked/unlocked state.
   - Drops tab: cells announce drumrot name or "locked, slot 17 of 31".
   - Settings: every row announces label + current value.
5. Note any gaps → file an issue or fix inline (the pattern is
   `.accessibilityLabel("...")` + optionally `.accessibilityValue("...")`).

**How to know it passed:**
- Every focusable element announces something meaningful (never bare "button").
- Reading order matches visual order (top-to-bottom, left-to-right).
- Reduce Motion (Settings → Accessibility → Motion → Reduce Motion): reveal
  animations cross-fade instead of flying; pad pulses don't scale.

---

## 6. iPad app on Apple silicon Mac

**You need:** an M-series Mac, the same Apple ID as your dev account.

**Do:**
1. After you've uploaded a build to TestFlight (Section 7 below), on the Mac
   open TestFlight → install the iPad app.
2. Launch. Confirm:
   - Window resizes; landscape layout intact.
   - Mouse/trackpad clicks register as taps on pads.
   - Audio plays through the Mac output without `AVAudioSession` asserts in
     Console.app.
   - Keyboard shortcuts (Cmd+1..5, Space, R, L, C) work.
3. In App Store Connect → app → Pricing & Availability → tick **"Make this app
   available on Mac"** before going live (default is off for iPad apps).

**How to know it passed:**
- App runs without crashes on Mac for at least 10 minutes of normal use.
- No `AVAudioSession`, `CoreMIDI`, or `MIDINetworkSession` errors in
  Console.app for the `Drumrot` process.

---

## 7. App Store Connect & TestFlight

**You need:** Apple Developer Program membership ($99/yr), App Store Connect
access, and screenshots.

**Do:**
1. **Create the ASC record** (per `docs/app-store/handoff.md` §#51):
   - Name: `drumrot — SP-808 KILLA` (see §9 below — you may want to rename).
   - Bundle id: `com.visaliacrc.drumrot`.
   - Category: Games > Music. Age: 4+.
   - Privacy nutrition label: **Data Not Collected** (full details in
     `docs/app-store/privacy-label.md`).
   - Encryption: now answered automatically by the plist key — should not be
     prompted.
2. **Screenshots** (required sizes):
   - 12.9" iPad Pro (2nd/3rd gen): 2048 × 2732, 4–6 shots.
   - 13" iPad Pro (M4): 2064 × 2752, 4–6 shots.
   - 6.7" iPhone: only if you support iPhone (you don't — iPad-only).
   - Take them from the iPad-13" simulator running Release builds:
     Play (with highway active), Library, Drops grid, Progress, Build.
3. **Archive & upload:**
   - Xcode → scheme Drumrot → destination "Any iOS Device (arm64)".
   - Product → Archive. Wait ~3 min for the archive.
   - Organizer → Distribute App → App Store Connect → Upload → next next next.
   - 15–20 min later, build appears in ASC under TestFlight.
4. **Internal TestFlight first:** add yourself + 1–2 collaborators. Install,
   smoke (Section 8).
5. **External TestFlight:** create a public link, invite ≥3 testers. First
   external build needs Beta App Review (~24 hours).

**How to know it passed:**
- Build processed without warnings.
- Internal testers can install and launch.
- External testers got an invite email and the app installed.

---

## 8. External tester smoke

**You need:** 3+ testers, ideally drummers with their own MIDI gear.

**Do:**
1. Send each tester the TestFlight link + this 5-task checklist:
   - Install the app and launch it.
   - Complete one lesson on the Play tab.
   - Earn at least one achievement (any).
   - Connect any MIDI controller you own (USB, Network, or BLE) and play a
     lesson with it.
   - Export a MIDI file from the Build tab and share it to yourself.
2. Ask them to report:
   - Anything that crashed.
   - Anything that felt slow or laggy.
   - Anything they didn't understand.
   - Anything that looked broken on their specific iPad model.
3. Aggregate notes in `docs/testing/manual-smoke.md` under "Native iPadOS app".

**How to know it passed:**
- 3 testers, 0 crashes between them.
- Latency rating is "tight" or "fine" from at least 2 of 3.
- No tester got stuck on any onboarding step.

---

## 9. Content & IP review (A4 / A5)

**You need:** 30–60 minutes of focused reading time. Possibly counsel for the
borderline cases.

### A4 — content read-through

Open each JSON file and read every user-facing string aloud:
- `Drumrot/Resources/Content/Lessons.json` — lesson titles, descriptions.
- `Drumrot/Resources/Content/Drumrots.json` — names, flavor text.
- `Drumrot/Resources/Content/Achievements.json` — names, descriptions.

Look for: typos, broken grammar, jokes that don't land, anything that reads
weird out of context.

### A5 — IP scrub

Two prior risks have been resolved in-code (see top of this doc):

1. ~~App name "SP-808 KILLA" trademark collision~~ — **resolved.** Display
   name set to "drumrot" via `CFBundleDisplayName`. User-facing strings
   swapped throughout iOS + web. **Still TODO:** rename the Xcode project /
   target / module from `Drumrot` to `Drumrot` if you want to clear the
   internal name as well. That's a deeper refactor (project rename, target
   rename, `@testable import Drumrot` updates across 8 test files, plus
   the `MIDIClientCreateWithBlock("Drumrot")` identifier). Internal names
   never appear in the App Store listing, so this is optional and can be
   deferred. The bundle id `com.visaliacrc.drumrot` is already aligned.

2. ~~`skibidi_tomtomlet`~~ — **resolved.** Renamed to `trono_tomtomlet`
   ("Trono Tomtomlet", 👑🥁) with toilet/Skibidi references stripped from
   name, flavor text, and emoji. Asset files renamed in both iOS and web.

3. **Italian-brainrot pastiche names** (lower but non-zero risk, still open). These all
   riff on community-generated meme characters that don't have a single owner,
   but some originated with specific TikTok creators who could claim rights:
   - `tung_tung_tamburino` (riffs on "Tung Tung Tung Sahur")
   - `drumbeano_crocodilio`, `bombardino_crashcino`, `bombardino_quattro_tempi`
     (riff on "Bombardiro Crocodilo")
   - `lirili_beatlarila` (riffs on "Lirili Larila")
   - `brrr_brrr_batteria`, `brrr_paradiddlini` (riff on "Brrr Brrr Patapim")
   - `trippelini_boomolini` (riffs on "Trippi Troppi")

   Recommended action: keep them — they're parodies of public-domain-flavored
   meme characters, not direct copies — but be ready to swap any individual
   name if a DMCA notice arrives. Document the parody intent somewhere in the
   App Store description so it's clear they're original characters.

4. **AI-generated portraits** (if any are in the assets). Confirm the model's
   terms allow commercial use, and that your input prompts didn't reference
   trademarked characters.

**How to know it passed:**
- Zero typos in the JSON content.
- ✅ "SP-808 KILLA" name → "drumrot" (done; see top of doc).
- ✅ `skibidi_tomtomlet` → `trono_tomtomlet` (done; see top of doc).
- Decide whether to also rename the Xcode project from `Drumrot` to
  `Drumrot` (optional — internal-only name).
- Delete the now-orphaned `brainrots/OG/Skibidi_Toilet.png` reference image.
- AI-image license documented.

---

## Order of operations (recommended)

If you want to clear these in the fastest sequence:

1. Plug iPad in → Section 1 (latency, 15 min).
2. Plug in any USB controller → Section 2 (5 min).
3. Section 9 IP scrub (60 min — do it before TestFlight so you're not
   uploading a build you'll have to recall).
4. Section 5 VoiceOver (30 min — find gaps now, fix in code, rebuild once).
5. Section 7 ASC + TestFlight upload (90 min first time, mostly waiting).
6. Section 3 + 4 (Network + BLE MIDI) — can be done in parallel with the
   build-processing wait.
7. Section 6 (iPad on Mac) — after the build appears on TestFlight.
8. Section 8 (external testers) — kick off as soon as Beta App Review clears.

Total clock time: roughly one focused weekend, mostly waiting on uploads.
