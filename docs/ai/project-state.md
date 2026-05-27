# Project state

## Current focus
iPadOS native port (now **Drumrot**), Phases 0–10-prep done + sim-verified. Manual play-through (2026-05-26) caught and **fixed** three gameplay-feel bugs that static verification missed — see "Playback feel fix" below + `.agent-stack/postmortems/2026-05-26-playback-feel-smoke-fail.json`. Remaining release gates are hardware/account-bound: real iPad audio latency, USB/Network/BLE MIDI, VoiceOver, iPad app on Apple silicon Mac, App Store Connect record, TestFlight, external testers, A4/A5 content review.

**Play UI redesign — DONE for the Play tab (2026-05-26).** Rebuilt the Play surface to match the web SP-808 chassis from `css/main.css`: full hardware palette in `SPColor` (chassis/metal/plastic/LCD/LED/sticker), `Chassis.swift` (Scanlines, Screw, `.lcdPanel()`, `.chassisModule()`), and a two-column face+rail `PlayView` — green **LCD readout** (PRG chip + glowing lesson name + Score/Combo/Acc), colored **lane tags**, LCD **highway** recolored (green screen + red glowing hit-line, `HighwayScene`), **rubber pads** (`PlayPad`: rim/LED/label/keycap, `DrumLane.padName`/`keyHint`), and **rail modules** (Pattern mini-notation, Coach Note, Transport, I/O·Sync). All playback/scoring/MIDI wiring preserved; tests green; sim screenshot confirms fidelity. **Other tabs (Library/Progress/Build/Drops/Settings) still use the older flat chrome** — they pick up the new palette via aliases but not the chassis/LCD treatment; applying it to them is the next visual pass.
- Sim-capture note: the app is landscape-locked, so `simctl` screenshots come out rotated 90° on the portrait sim device (correct behavior, not a bug). Rotate the Simulator window (Device → Rotate / Cmd+→) for an upright view; osascript keystroke rotation is blocked by accessibility perms.

## Playback feel fix (2026-05-26, DONE, tests green)
- `PlaybackEngine` reworked to mirror `js/highway.js animate`: **metronome** ticks every quarter through count-in AND groove (was count-in only), accent on downbeat, gated by Click toggle; **BPM** drives note timing live via `beat*halfBeatMs` (`@Published bpm`, readout reactive) so +/- actually moves notes (was baked at load); **loop** is one continuous timeline (loopIteration offset, flags-only reset) + shadow notes for a seamless reel. Play/restart keep the chosen BPM. Count-in number shown on highway. 3 regression tests added; all suites pass. Commit `d033333`.
- Lesson for verification-gate: unit tests + one screenshot do NOT smoke an interactive time-based app — a rhythm game needs a dynamic play-through (clock driven, audio/motion asserted) before "done".

Confirmed direction: Swift/SwiftUI, iPad-first, Apple silicon Mac via iPad app availability, hardware MIDI as the main v1 requirement, App Store/TestFlight distribution, exact SP-808 web UI parity, low-latency rhythm response. Audio = AVAudioEngine + synth buffers; highway = SpriteKit; persistence = SwiftData; MIDI transport order USB → Network → BLE.

## Branch
`workflow/run-2026-05-26` (this run: plan promotion + 41 issues filed). Off `main`. Last merges: PR #5 (v0.3 card system, `f0927d31`), PR #8 (portrait-rendering fix, `5fff600`), PR #10 (virtual MIDI test source, `ac00810`).

## iOS port issues (filed 2026-05-26)
All 41 port issues are on GitHub as **#12–#52**. Plan IDs in the docs are #20–#60; **GitHub# = plan ID − 8**. Crosswalk table is at the top of `current-plan.md`. Dependencies in the filed issue bodies use live GitHub numbers. Local issue files: `docs/ai/generated-issues/*.md`. Phase 0 = #12–#15 (bootstrap, prototype, asset pipeline, CI).

## Recently completed (2026-05-20 → 2026-05-21)
- **PR #5** — Issues #1–#4, v0.3 card system:
  - #1 DRUMROTS migrated to v0.3 schema (`drumrot_god` → `god`, `art` → `emoji`, v0.3 wording, numeric stats with 99 sentinel).
  - #2 `css/cards.css` ports v0.3 card chrome; `index.html` head adds IBM Plex Mono + `cards.css`.
  - #3 `renderDrumrotCard` rewritten for v0.3 markup, OG `∞/MAX` rules, locked variant, grapheme emoji fallback.
  - #4 Dead `.dc-*` CSS removed, reveal entry animation, OG holofoil hover sweep, `prefers-reduced-motion` guards, README docs.
- **PR #8** — Post-merge regression: revealed portraits were blank. Cause: `loading="lazy"` + `content-visibility: auto` interaction inside the opacity-0 reveal overlay. Fix: drop both, plus always emit emoji creature behind the image as defensive fallback. Smoke contract tightened to require pixel painting (not just HTTP 200). Postmortem `.agent-stack/postmortems/2026-05-21-portrait-blank-after-pr5.json`.
- **PR #10** — Virtual MIDI test source. `scripts/midi-pulse.mjs` opens a system-visible CoreMIDI port (`Drumrot Test Source`) and pulses GM drum notes; Chrome's Web MIDI API enumerates it like a hardware controller, exercising the real receive path in `js/midi-device.js`. Confirmed working — app catches the notes.

## In progress
- `docs/ai/current-plan.md` is the canonical iPadOS port plan (promoted from Codex's pass 2026-05-26, with a tightened iPad-only entitlements section grafted from Claude's pass).
- 41 issues filed (#12–#52); #12–#46 implemented locally across Phases 0–9. #49–#50 local checklist/privacy docs are complete. #47–#48 are explicitly deferred; #51–#52 require App Store Connect/TestFlight access and real testers.
- `docs/ai/decisions.md` records the plan-comparison outcome and issue-filing (2026-05-26 entry).

## Recently completed (2026-05-26)
- **Phase 10 local readiness — #49 + #50 (DONE locally; ASC/TestFlight = human/account gate).** Extended `docs/testing/manual-smoke.md` with native iPadOS + iPad-app-on-Mac coverage, including MIDI transports, keyboard shortcuts, Drops/reveal, accessibility, and hardware-only gates. Added `docs/app-store/privacy-label.md` with "Data Not Collected" guidance and `docs/app-store/handoff.md` for hardware/ASC/TestFlight next steps. Replaced generated Info.plist settings with explicit `ios/DrumrotInfo.plist` so Bluetooth, Local Network, and `NSBonjourServices = ["_apple-midi._udp"]` are emitted in the built app. Verified processed simulator Info.plist contains the Bonjour array.
- **Phase 0 — #12 + #15 (DONE, sim-verified).** Created `ios/Drumrot.xcodeproj` (objectVersion 77, synchronized-folder group → `ios/Drumrot/`). Single SwiftUI iPad-only target: bundle id `com.visaliacrc.drumrot`, iPadOS 17, `TARGETED_DEVICE_FAMILY=2`, landscape-locked via `UIRequiresFullScreen=YES` + landscape orientation keys. 5-tab `RootView` (Play/Library/Progress/Build/Drops) + `SPColor` palette + `PlaceholderScreen`. **Verified: `xcodebuild ... build` = BUILD SUCCEEDED; installed + launched on iPad (A16) sim; screenshot shows the 5-tab shell rendering.** Codex's AppIcon catalog compiles into the target. CI workflow `.github/workflows/ios-build.yml` added (#15). `.gitignore` extended for Xcode + signing material. Build commands: see CI yaml.
- **#13 (prototype) folded forward** — rather than a throwaway 1-screen prototype, the real architecture is proven by the building/launching skeleton; the audio-tap + MIDI-enumeration parts of #13 are delivered for real in Phase 3 (#24) and Phase 8 (#41).
- **#46 / #6 local asset pass (Codex)** — `scripts/generate-app-icon.py` creates an original SP-style pad-device mark (no external API / no source image). Generated `AppIcon-1024.png` (1024 RGB, no alpha), `LaunchMark.imageset`, `App/LaunchScreen.swift`, `favicon.ico`, `favicon-32.png`, `apple-touch-icon.png`; `index.html` links the favicon. **Now validated inside the Xcode target** (AppIcon compiles in the build above).

## Phase 9 — accessibility + iPad-on-Mac + icon (DONE; on-device VoiceOver = gate)
- **#43 a11y:** cards/pads/settings have `accessibilityLabel`s; decorative LEDs hidden. Real VoiceOver navigation pass is a manual/device gate.
- **#44 reduce-motion + dynamic type:** RevealOverlay + PadButton honor `accessibilityReduceMotion`; all text uses `.system(textStyle)` so it scales with Dynamic Type.
- **#45 keyboard shortcuts:** RootView Cmd+1…5 (tabs) + Cmd+, (settings); PlayView Space/Cmd+R (restart), L (loop), C (click) — for iPad hardware keyboard + iPad-app-on-Mac.
- **#46 icon/launch:** Codex's AppIcon + LaunchScreen compiled into the target (Phase 0/5).

## Phase 8 — MIDI file I/O + CoreMIDI input (DONE; live hardware = gate)
- **#39 parser:** `Domain/MIDIFile.swift` `MIDIFileParser` (SMF header/track, VLQ, running status, note-on, meta/sysex skip, SMPTE rejection) + `lesson(name:events:ppq:)` import (quantize ppq/2). `Domain/GMDrumMapper.swift`.
- **#40 exporter:** `MIDIFileExporter` (Type-0, ch10, PPQ96, tempo meta, GM notes [49,42,38,36,45,51]) — byte-compatible w/ web. `MIDIFileTests` (6): round-trip, SMF header, SMPTE/non-MIDI rejection, GM map, import quantize. TEST SUCCEEDED.
- **#41 CoreMIDI input:** `MIDI/MIDIInputManager.swift` (client + input port w/ UMP receive block, source enumeration, Network MIDI enabled, note-on → MainActor → `onNote`). Wired into Play (drives highway) + MIDI activity LED. Live device input is a real-device gate.
- **#42 BLE + picker:** `MIDI/BluetoothMIDIView.swift` (CABTMIDICentralViewController) + Settings MIDI section (source list + "Pair Bluetooth MIDI"). Import (Library `.fileImporter` → ExtraLesson) + export (Builder ShareSheet `sp808-pattern.mid`). Info.plist Bluetooth + Local Network usage descriptions added to target.

## Phase 7 — Library + Progress + Builder + achievement wiring (DONE, sim-verified)
- **#35 Library:** `LessonCardView` (number, New/Played, BPM·genre·difficulty, dot mini-notation, stars, high) + `LibraryView` grid (`@Query LessonScore`); tap → set `currentLesson` + autostart + Play. PlayView reloads on `currentLesson` change.
- **#36 Progress:** `ProgressTabView` — streak/sessions/best/top-accuracy stat cards, 14-day calendar, 18-achievement grid (unlocked highlighted) from PracticeDay/LessonScore/AchievementUnlock queries.
- **#37 Builder:** `BuilderLessonFactory` (grid→Lesson) + `BuildView` (6×16/32 toggle grid, BPM, coach, Clear, Load-into-Play; persists BuilderState + ExtraLesson; empty→disabled).
- **#38 achievement engine:** `Domain/AchievementEngine.swift` ports `checkAchievements` (hit-combo, pass acc/stars/tier/streak/aggregate, creator/coach) → unlock via persistence → toast (`AchievementToast` + AppStore queue) → drop roll + collect + reveal. Added `LessonScore.practiceTier`. Wired from PlayView (hit/pass) + BuildView (creator/coach).
- Debug `--demo` seeds collection+score+playday+unlocks; `--library/--progress/--build/--drops` select a tab. Verified all three tabs render with seeded data + the toast/reveal pipeline compiles.

## Phase 6 — playback + highway + Play tab (DONE, sim-verified playable)
- **#31:** `Playback/Clock.swift` (Host/Test) + `Playback/PlaybackEngine.swift` (count-in, 1800ms travel, per-note progress, nearest-in-window dy hit judging, auto-miss, loop rollover/finish). `PlaybackEngineTests` (5) green.
- **#32:** `Features/Play/HighwayScene.swift` (SKScene drives engine from its own update loop; 6 colored lanes, strike line, note nodes by progress, hit/miss styling) + `HighwayView` (SpriteView host).
- **#33:** `Features/Play/PlayView.swift` — readout (name/score/combo/acc), progress strip, highway, 6 lane-colored `PadButton`s, transport (Play/Stop/Loop/Click/BpmStepper/MIDI LED).
- **#34 wiring:** pad tap → `audio.play(lane)` + `engine.registerHit`; count-in beat → metronome click; `.finished` → `persistence.recordPass` + `recordPlayDay`. Audio activated on Play appear (`AppStore.audio`/`activateAudio`).
- Debug `--play` auto-loads lesson 0 + starts. Verified on iPad (A16) sim: notes scroll the highway, readout/pads/transport render and run.

## Phase 3 — audio / AVAudioEngine (DONE, synthesis tested; real latency = hardware gate)
- **#24:** `Audio/VoiceSynth.swift` ports `js/audio.js` drumSound (kick sine sweep 120→40, snare highpass-1500 shaped noise, tom bandpass-350, crash/hihat/ride highpass white noise w/ web durations 0.6/0.08/0.35) via an RBJ `Biquad`; preloaded PCM buffers. `Audio/DrumAudioEngine.swift` (AVAudioEngine + 8-node pool, `play(lane:velocity:)`).
- **#25:** `Audio/ClickSynth.swift` (square 1800/1100 accent/normal) + `Audio/AudioSessionManager.swift` (.playback + .mixWithOthers, 5ms IO buffer, interruption + route-change handlers → engine stop/restart).
- **Tests:** `VoiceSynthTests` (3) — per-lane buffer durations, non-silent + in-range PCM, accent louder than normal. TEST SUCCEEDED. NOTE: audible output + ≤10ms latency must be confirmed on real iPad (hardware gate, not sim-verifiable).

## Phase 5 — Drops + card chrome + reveal (DONE, sim-verified)
- **#14 asset pipeline:** `scripts/export-drumrots-png.py` (Pillow) → 31 `<id>.imageset` under `Assets.xcassets/drumrots/`. `Image(drumrot.imageName)` (== id) resolves portraits.
- **#28 card:** `DesignSystem/Cards/DrumrotCardView.swift` — tier banner (★ LABEL + #NNN, OG → #NNN/OG), portrait (image over emoji fallback), name plate, flavor, stats (OG → ∞/∞/MAX; power 99 → MAX), footer, locked `???` variant, a11y label.
- **#29 grid:** `Features/Drops/DropsView.swift` — adaptive LazyVGrid over all 31, `@Query` on `DrumrotCollectionEntry` for collected tier, "N / 31 collected" header.
- **#30 reveal:** `Features/Drops/RevealOverlay.swift` + AppStore reveal queue (`enqueueReveal`/`dismissCurrentReveal`); fullScreenCover from RootView; NEW!/UPGRADED/FIRST OG! badge, auto-dismiss 6s (9s OG), tap-to-dismiss, Reduce-Motion aware.
- **Debug affordance:** `--demo` seeds sample collection + opens Drops; `--reveal` enqueues an OG reveal (DEBUG only, in `DrumrotApp`). Used for sim screenshots. Verified: Drops grid (4/31, real portraits, locked cells) + OG reveal (∞/MAX) render on iPad (A16) sim.
- Snapshot tests for cards deferred to Phase 10 (#55, needs swift-snapshot-testing SPM dep).

## Phase 4 — persistence + AppStore wiring (DONE, round-trip tests green)
- **#26 models:** `Data/Models/PersistenceModels.swift` — `LessonScore`, `AchievementUnlock`, `PracticeDay`, `ExtraLesson`, `DrumrotCollectionEntry`, `BuilderState`, each with `@Attribute(.unique)` keys + `schemaVersion`. All added to `AppModelContainer.schema`.
- **#27 wiring:** `Data/PersistenceService.swift` (upsert layer: recordPass = max score + best stars + plays++, unlock once, recordPlayDay once, collect upgrade-only + count++). `AppStore.persistence` exposes it over the live context.
- **Tests:** `PersistenceRoundTripTests` (5) — upsert keeps best + counts plays, unlock/playday idempotent, collection upgrade-only, and survives across two contexts in one in-memory container. TEST SUCCEEDED.
- Carry-forward: event-driven `AchievementEngine` (fire rules → unlock → drop roll) still to build atop this in Phase 6/7 wiring.

## Phase 1 — chassis, design system, Settings, AppStore (DONE, sim-verified)
- **#16** root TabView (5 tabs) shipped in Phase 0; now bound to `AppStore.selectedTab`.
- **#17 design system:** `DesignSystem/Theme/ColorHex.swift` (`Color(hex:)` + `DrumrotTier.color`/`PracticeTier.color`), `Typography.swift` (`SPFont` mono/display), controls `LED`, `PadButton`, `BpmStepper` (40–200 clamp). `SPColor` palette from Phase 0.
- **#18 Settings + SwiftData:** `Data/AppSettings.swift` (`@Model` singleton: midiDeviceUID, audioLatencyOffsetMs, haptics, reduceMotionOverride, lastTab, schemaVersion), `Data/AppModelContainer.swift` (schema + factory, `inMemory` for tests/previews), `Features/Settings/SettingsView.swift` (Form bound to the settings row; gear button in `RootView` opens it as a sheet).
- **#19 AppStore:** `@MainActor` `ObservableObject` (selectedTab, showSettings, modelContext handle), injected via `.environmentObject` + `.modelContainer` in `DrumrotApp`.
- **Verified:** BUILD + all 4 test suites pass; app launches on iPad (A16) sim with the gear button rendering. NOTE: benign first-launch CoreData "Application Support missing → recovery successful" log in the sim; self-heals, real devices unaffected.

## Phase 2 — domain parity (DONE, all tests green)
- **Hosted unit-test target `DrumrotTests`** added to pbxproj + scheme (TEST_HOST = app). 4 parity suites, all passing on iPad (A16) sim: **TEST SUCCEEDED**.
- **#20 drumrots:** `Drumrots.json` (31; tiers 4/4/5/4/4/2/8) via `/tmp/port_drumrots.py`; `DrumrotTier`/`Drumrot`+`DrumrotCatalog`/`DropRoller` (verbatim `rollDrumrot`, injectable RNG, 5% OG, per-difficulty weights)/`DrumrotCollection` (upgrade-only). `DrumrotParityTests` (8).
- **#21 lessons:** `DrumLane` (6-lane), `Lesson`+`LessonFactory` (verbatim `lessonFromPatterns`; beatsPerBar = first-pattern length → Disco Pulse=15 quirk preserved), `Lessons.json` (8). `LessonParityTests` (5).
- **#22 achievements:** `Achievement`+`AchievementCatalog`, `Achievements.json` (18; perf 6 / consistency 6 / tempo 4 / builder 2). `AchievementParityTests` (3). NOTE: the *event-driven* `AchievementEngine` (mutating unlock set on hit/pass/builder events) is deferred to Phase 4 when AppStore/State exist — only the definitions + pure tier/stars/streak math are ported here.
- **#23 scoring:** `ScoringEngine` (HIT_WINDOW 60; dy<20/40 → 300/200/100; score += pts*max(1,combo/4); miss resets combo; Math.round accuracy; stars ≥95/80/50), `PracticeTier` (Steady/Grooving/Locked/Killing It + `forPass` thresholds) + `PracticeStreak.current` (UTC day-keys backward). `ScoringParityTests` (7).
- Test runner: `xcodebuild -project ios/Drumrot.xcodeproj -scheme Drumrot -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPad (A16)' test`.

## Project structure note (Xcode)
- `.xcodeproj` lives at `ios/Drumrot.xcodeproj`; source root is the synchronized folder `ios/Drumrot/` (App/, DesignSystem/, Features/, Resources/, Domain/Audio/MIDI/Playback/Data/). New `.swift`/asset files dropped into that folder are auto-included — no pbxproj edits needed. Target id in pbxproj = `AA0000000000000000000002`. The app target uses explicit `ios/DrumrotInfo.plist` outside the synchronized source folder so App Store privacy/network keys can include array values.

## Recent coding-agent runs

### 2026-05-26 — Phase 10 local readiness #49–#50
- Files modified: `docs/testing/manual-smoke.md` native checklist; `docs/app-store/privacy-label.md` ASC privacy label draft; `docs/app-store/handoff.md` hardware/account handoff; `ios/DrumrotInfo.plist` explicit app plist; `ios/Drumrot.xcodeproj/project.pbxproj` target plist wiring; `docs/ai/project-state.md` memory update.
- Checks run: PASS `xcodebuild -project ios/Drumrot.xcodeproj -scheme Drumrot -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPad (A16)' build`; PASS processed Info.plist inspection confirmed `NSBonjourServices` array; PASS `xcodebuild ... test` (42 tests, 0 failures); PASS `node --input-type=module -e "import('./js/drumrots.js').then(m => console.log('count=', m.DRUMROTS.length))"` (`count= 31`); PASS `git diff --check`.
- Decisions made: explicit plist chosen because `INFOPLIST_KEY_NSBonjourServices` did not emit into the processed app plist as a build setting.
- Deviations from spec: #47 snapshot tests and #48 XCUITest remain deferred per handoff; #51–#52 cannot be completed without App Store Connect/TestFlight/hardware.
- Verification recovery: first post-edit `xcodebuild ... test` rerun hit a simulator `FBSOpenApplicationServiceErrorDomain` / preflight `Busy` launch failure, with duplicate `iPad (A16)` simulator runtimes and simulator cleanup still active. No source change was needed; rerunning the same command after cleanup passed 42 tests. First pushed CI run then failed because `.gitignore`'s unanchored `build/` rule ignored `ios/Drumrot/Features/Build/BuildView.swift`; fix is to anchor `/build/` and track `BuildView.swift`.
- Remote verification: PR #53 CI run `26489231572` passed on commit `c89259d` (`iOS build` build-test: Build + Test on iPad simulator).
- Concerns: real iPad MIDI/audio/VoiceOver and App Store Connect acceptance remain manual gates.

## Risks / known gaps
- **Pi hardware perf check** — `content-visibility: auto` was removed in PR #8 to fix the blank-portrait regression. The Pi `≥30 fps` gate has not been re-verified after that removal. If perf regresses on the actual Pi, reintroduce `content-visibility: auto` only on the Drops grid cells (not on reveal-popup cards) and re-check.
- **Playwright smoke** still does not assert pixel painting on portraits — only the manual smoke checklist does. Worth adding a Playwright spec that asserts `naturalWidth > 0` and `rect.width > 0` on `.portrait-img` after the reveal animation.

## Next step
Next: commit/push the remaining Phase 10 local readiness changes, update/open the workflow PR, then complete the human gates: real iPad latency + USB/Network/BLE MIDI, VoiceOver, iPad app on Apple silicon Mac, App Store Connect record/screenshots/preview (#51), TestFlight upload + external tester smoke (#52), and A4/A5 content/IP review before submission.
