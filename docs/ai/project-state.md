# Project state

## Current focus
iPadOS native port, Phase 0 ready. The app icon / launch mark asset pass for GitHub #46 is complete locally, and the web favicon gap from #6 is closed locally. The plan comparison remains **resolved**: Codex's iPad-first plan won over Claude's Mac Catalyst plan (matches the locked 2026-05-21 direction) and is now the source of truth in `docs/ai/current-plan.md`. Both planning passes preserved as historical artifacts (`codex-ios-plan.md`, `claudes-ios-plan.md`).

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
- 41 issues filed (#12–#52); awaiting Phase 0 implementation start.
- `docs/ai/decisions.md` records the plan-comparison outcome and issue-filing (2026-05-26 entry).

## Recently completed (2026-05-26)
- **Phase 0 — #12 + #15 (DONE, sim-verified).** Created `ios/SP808Killa.xcodeproj` (objectVersion 77, synchronized-folder group → `ios/SP808Killa/`). Single SwiftUI iPad-only target: bundle id `com.visaliacrc.drumrot`, iPadOS 17, `TARGETED_DEVICE_FAMILY=2`, landscape-locked via `UIRequiresFullScreen=YES` + landscape orientation keys. 5-tab `RootView` (Play/Library/Progress/Build/Drops) + `SPColor` palette + `PlaceholderScreen`. **Verified: `xcodebuild ... build` = BUILD SUCCEEDED; installed + launched on iPad (A16) sim; screenshot shows the 5-tab shell rendering.** Codex's AppIcon catalog compiles into the target. CI workflow `.github/workflows/ios-build.yml` added (#15). `.gitignore` extended for Xcode + signing material. Build commands: see CI yaml.
- **#13 (prototype) folded forward** — rather than a throwaway 1-screen prototype, the real architecture is proven by the building/launching skeleton; the audio-tap + MIDI-enumeration parts of #13 are delivered for real in Phase 3 (#24) and Phase 8 (#41).
- **#46 / #6 local asset pass (Codex)** — `scripts/generate-app-icon.py` creates an original SP-style pad-device mark (no external API / no source image). Generated `AppIcon-1024.png` (1024 RGB, no alpha), `LaunchMark.imageset`, `App/LaunchScreen.swift`, `favicon.ico`, `favicon-32.png`, `apple-touch-icon.png`; `index.html` links the favicon. **Now validated inside the Xcode target** (AppIcon compiles in the build above).

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
- **Debug affordance:** `--demo` seeds sample collection + opens Drops; `--reveal` enqueues an OG reveal (DEBUG only, in `SP808KillaApp`). Used for sim screenshots. Verified: Drops grid (4/31, real portraits, locked cells) + OG reveal (∞/MAX) render on iPad (A16) sim.
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
- **#19 AppStore:** `@MainActor` `ObservableObject` (selectedTab, showSettings, modelContext handle), injected via `.environmentObject` + `.modelContainer` in `SP808KillaApp`.
- **Verified:** BUILD + all 4 test suites pass; app launches on iPad (A16) sim with the gear button rendering. NOTE: benign first-launch CoreData "Application Support missing → recovery successful" log in the sim; self-heals, real devices unaffected.

## Phase 2 — domain parity (DONE, all tests green)
- **Hosted unit-test target `SP808KillaTests`** added to pbxproj + scheme (TEST_HOST = app). 4 parity suites, all passing on iPad (A16) sim: **TEST SUCCEEDED**.
- **#20 drumrots:** `Drumrots.json` (31; tiers 4/4/5/4/4/2/8) via `/tmp/port_drumrots.py`; `DrumrotTier`/`Drumrot`+`DrumrotCatalog`/`DropRoller` (verbatim `rollDrumrot`, injectable RNG, 5% OG, per-difficulty weights)/`DrumrotCollection` (upgrade-only). `DrumrotParityTests` (8).
- **#21 lessons:** `DrumLane` (6-lane), `Lesson`+`LessonFactory` (verbatim `lessonFromPatterns`; beatsPerBar = first-pattern length → Disco Pulse=15 quirk preserved), `Lessons.json` (8). `LessonParityTests` (5).
- **#22 achievements:** `Achievement`+`AchievementCatalog`, `Achievements.json` (18; perf 6 / consistency 6 / tempo 4 / builder 2). `AchievementParityTests` (3). NOTE: the *event-driven* `AchievementEngine` (mutating unlock set on hit/pass/builder events) is deferred to Phase 4 when AppStore/State exist — only the definitions + pure tier/stars/streak math are ported here.
- **#23 scoring:** `ScoringEngine` (HIT_WINDOW 60; dy<20/40 → 300/200/100; score += pts*max(1,combo/4); miss resets combo; Math.round accuracy; stars ≥95/80/50), `PracticeTier` (Steady/Grooving/Locked/Killing It + `forPass` thresholds) + `PracticeStreak.current` (UTC day-keys backward). `ScoringParityTests` (7).
- Test runner: `xcodebuild -project ios/SP808Killa.xcodeproj -scheme SP808Killa -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPad (A16)' test`.

## Project structure note (Xcode)
- `.xcodeproj` lives at `ios/SP808Killa.xcodeproj`; source root is the synchronized folder `ios/SP808Killa/` (App/, DesignSystem/, Features/, Resources/, and later Domain/Audio/MIDI/Playback/Data/). New `.swift`/asset files dropped into that folder are auto-included — no pbxproj edits needed. Target id in pbxproj = `AA0000000000000000000002`.

## Risks / known gaps
- **Pi hardware perf check** — `content-visibility: auto` was removed in PR #8 to fix the blank-portrait regression. The Pi `≥30 fps` gate has not been re-verified after that removal. If perf regresses on the actual Pi, reintroduce `content-visibility: auto` only on the Drops grid cells (not on reveal-popup cards) and re-check.
- **Playwright smoke** still does not assert pixel painting on portraits — only the manual smoke checklist does. Worth adding a Playwright spec that asserts `naturalWidth > 0` and `rect.width > 0` on `.portrait-img` after the reveal animation.

## Next step
Phases 0 and 2 are DONE + verified. Next: **Phase 1 (#16–#19)** — design-system primitives (port `css/cards.css`/`main.css` tokens), Settings tab + SwiftData `ModelContainer`, `AppStore` ObservableObject DI skeleton. Then **#14 asset pipeline** (webp→PNG into the catalog; Pillow available) feeding **Phase 5** (Drops card chrome + reveal), **Phase 4** (SwiftData models persisting the domain), **Phase 6** (SpriteKit highway + Play UI wired to ScoringEngine/PlaybackEngine), **Phase 7** (Library/Progress/Builder), **Phase 8** (MIDI file I/O + CoreMIDI). Carry-forward: build the event-driven `AchievementEngine` in Phase 4 atop AppStore/State. Hard wall (manual/you): on-device latency/BLE/VoiceOver + all Phase 10 ASC/TestFlight (#49–#52). A1 resolved.
