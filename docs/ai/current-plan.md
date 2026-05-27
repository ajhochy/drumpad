# Current plan — SP-808 KILLA native iPadOS port (v1)

> **Source of truth.** Promoted 2026-05-26 from [docs/ai/codex-ios-plan.md](codex-ios-plan.md) (the iPad-first planning pass that matches the locked 2026-05-21 direction), with a tightened entitlements/usage-description section grafted from [docs/ai/claudes-ios-plan.md](claudes-ios-plan.md). Both prior planning passes are preserved alongside this file for historical comparison; this file is the authoritative current plan and supersedes the v0.3 card-system plan (shipped via PR #5 / #8 / #10).
>
> For implementation agents: create a feature branch named `workflow/run-YYYY-MM-DD` before editing. This plan is planning-only; do not commit generated images outside the iOS app asset catalog, `art/drumrots/`, or `brainrots/`. Do not commit `.DS_Store`.

## Status

Active. The web app at `index.html` is **frozen at v0.3** and remains the reference implementation. The native app is a **clean SwiftUI + AVAudioEngine + CoreMIDI rewrite**, not a wrapped WebView. The two surfaces are intentionally independent — no progress migration in either direction.

## Goal

Ship drumrot / SP-808 KILLA as a native Swift/SwiftUI iPadOS app — **one iPad-first App Store/TestFlight app**, available on Apple silicon Macs as the iPad app where compatible — with real **CoreMIDI** input from a hardware drum controller, low-latency rhythm-game-quality response, and a visual experience that matches the existing SP-808 web UI exactly: v0.3 card chrome, 6-lane highway, 5-tab information architecture, chassis/readout styling, and all current functionality.

## Plan ID ↔ GitHub issue crosswalk

The issue table below uses **plan IDs #20–#60** (numbering leaves room for open web-side follow-ups like favicon #6). When filed on GitHub on 2026-05-26 the repo's shared issue/PR sequence was already at #11, so the live GitHub numbers are offset by **−8**:

| Plan ID | GitHub # | Plan ID | GitHub # | Plan ID | GitHub # |
|---|---|---|---|---|---|
| 20 | #12 | 34 | #26 | 48 | #40 |
| 21 | #13 | 35 | #27 | 49 | #41 |
| 22 | #14 | 36 | #28 | 50 | #42 |
| 23 | #15 | 37 | #29 | 51 | #43 |
| 24 | #16 | 38 | #30 | 52 | #44 |
| 25 | #17 | 39 | #31 | 53 | #45 |
| 26 | #18 | 40 | #32 | 54 | #46 |
| 27 | #19 | 41 | #33 | 55 | #47 |
| 28 | #20 | 42 | #34 | 56 | #48 |
| 29 | #21 | 43 | #35 | 57 | #49 |
| 30 | #22 | 44 | #36 | 58 | #50 |
| 31 | #23 | 45 | #37 | 59 | #51 |
| 32 | #24 | 46 | #38 | 60 | #52 |
| 33 | #25 | 47 | #39 | | |

**Rule:** `GitHub# = plan ID − 8`. Dependencies in the filed GitHub issues are expressed in live GitHub numbers; the issue table below keeps plan IDs for readability.

## Locked decisions (from upfront orchestrator alignment, 2026-05-21)

| Decision | Choice | Reason on record |
|---|---|---|
| Architecture | **Fully native Swift/SwiftUI** | User chose Swift. WKWebView wrapper is not acceptable for the shipping app. |
| Platform | **iPad first; available as iPad app on Apple silicon Mac where compatible** | User chose iPad main + macOS running the iPad install, not a separate Mac app. |
| MIDI on iPad | **Hard requirement in v1** | User said hardware MIDI is the main requirement; CoreMIDI bridge ships day one. |
| Distribution | **App Store + TestFlight** | Public/beta Apple distribution is the target. |
| UX bar | **Exact same UI** — preserve current IA, SP-808 chassis, and v0.3 card chrome | User explicitly requested exact visual parity. |
| Timing bar | **Low-latency is vital** | Treat touch/MIDI/audio timing as rhythm-game quality and verify on real hardware. |

## In scope (v1)

- Native iPadOS app, **landscape-locked**, iPad 6th-gen and newer (anything running iPadOS 17).
- Apple silicon Mac availability through the iPad app on Mac, with compatibility verified in App Store Connect. No separate macOS target in v1.
- All five existing tabs: **Play**, **Library**, **Progress**, **Build**, **Drops**.
- All 31 existing drumrots across all 7 tiers, with the existing voxel art, v0.3 card chrome, OG holofoil, tier system, and drop-roll math (5% OG flat bonus + existing tier weights — math identical to web).
- All 8 existing built-in lessons + custom builder lessons + MIDI-file-import lessons.
- All 18 existing achievements with the existing toast → drop-roll sequencing.
- Hardware MIDI input via USB-C / Lightning-camera-kit / Bluetooth MIDI / Network MIDI (CoreMIDI). This is the main v1 feature and blocks release.
- Drum trainer (6-lane highway + scoring + count-in + metronome + loop) running at 60 Hz everywhere and 120 Hz on ProMotion iPads, with real-device latency measurement.
- AVAudioEngine-synthesized drums and click (same character as the Web Audio synthesis in `js/audio.js`).
- MIDI file import (`.mid` / `.midi`) and export (`sp808-pattern.mid`).
- 16/32-step beat builder.
- SwiftData persistence for scores, achievements, tiers (Steady/Grooving/Locked/Killing It), play days, extra lessons, collection, builder pattern, and settings.
- VoiceOver complete, Reduced Motion honored, Dynamic Type supported.
- App Store distribution: free, no IAP, "Data Not Collected" privacy label.

## Out of scope (v1) — see v1.1 backlog at the bottom

- **iPhone** build. The v1 UI is iPad-landscape-shaped; iPhone portrait deserves its own design pass.
- Stage Manager / Split View / Slide Over.
- Apple Pencil interactions on the Build tab.
- iPad-native UI rethink (sidebar nav, larger pads, sheet-based reveal).
- Separate native macOS or Mac Catalyst build (menu bar items, AppKit-flavored controls, Mac-typical preferences window).
- iCloud / CloudKit sync of drops, scores, or progress across devices.
- Progress migration from the web app's `localStorage`.
- Localizations beyond English.
- In-app purchase, ads, telemetry, crash reporting service.
- New drumrots, new lessons, or any content additions.
- Touch-only mode as the primary product path. On-screen pads remain for visual parity, local testing, and fallback interaction, but hardware MIDI is the v1 main path.
- watchOS / visionOS / tvOS.
- A WebView wrapper as the shipping architecture (temporary harnesses during development are fine; shipping is native).

## Hard constraints

- **No background audio.** App does **not** request the `audio` `UIBackgroundModes` entitlement — drum trainer is foreground-only. Simplifies App Review.
- **MIDI threading discipline.** CoreMIDI callbacks run on a high-priority real-time thread; UI updates must marshal to MainActor. (Swarm: #1 cause of dropped notes / hangs in indie MIDI apps.)
- **Low latency is a release gate.** Touch/MIDI input to sound and judgement must be measured on real iPad hardware; poor-feeling latency blocks TestFlight/App Store readiness.
- **No new runtime dependencies in v1.** AVFoundation, CoreMIDI, SpriteKit, SwiftData are all first-party. Only test-side SPM addition: `swift-snapshot-testing`.
- **No data collection.** Privacy nutrition label must remain "Data Not Collected" — no analytics SDK, no telemetry, no crash reporter. Anything changing this is a separate architecture decision.
- **AGENTS.md data safety preserved.** `.DS_Store`, generated images outside `art/drumrots/`, user data — none of it committed.
- **Manual merge only.** Workflow rules unchanged. Branch per workflow run, draft PR, human merges.
- **Don't break the web app.** All Swift code lives in a new top-level `ios/` directory. `index.html`, `js/`, `css/`, `art/` stay untouched. The web app is the reference implementation for behavior parity.

## Design tensions

| Tension | A | B | Resolution |
|---|---|---|---|
| Speed to ship vs polish | Wrap web in WKWebView | Native rewrite | Native rewrite (user chose). Accept ~2-3mo timeline. |
| Code reuse vs native feel | JavaScriptCore-embed the JS engine | Reimplement in Swift | Reimplement. JS bridge adds latency to the scoring path. |
| iPad-native UI vs visual continuity | Sidebar + sheets | TabView mirroring web tabs | TabView + landscape lock; exact web UI parity wins. |
| Mac support mode | Native macOS / Catalyst | iPad app on Apple silicon Mac | iPad app on Mac v1; separate Mac optimization deferred. |
| Audio fidelity vs simplicity | AudioUnit graph | AVAudioEngine | AVAudioEngine — sufficient for sample / synth playback, far less code. |
| Highway fidelity vs build cost | Metal | SpriteKit | SpriteKit. 60-120 Hz with ~20 active sprites is well within budget. |
| Preserve JS field names in storage vs cleaner typed model | Mirror JS keys | Idiomatic Swift naming | Idiomatic Swift; document the mapping in `Persistence/SchemaMapping.md`. |

## Cheapest version that proves the idea

Before the full plan runs, **issues #20–#21 build a 1-screen prototype**:

1. New Xcode project, single SwiftUI iPadOS target.
2. SwiftUI `ContentView` shows one hard-coded TIER_GOD/OG drumrot card.
3. AVAudioEngine plays a single drum sample on tap.
4. CoreMIDI enumerates connected sources and logs them to the debug console.

If this builds on iPad simulator, runs as the iPad app on Apple silicon Mac where available, plays a sample, and lists a real/virtual MIDI source, the architecture is proven. Everything after is volume, not risk.

## Decisions made by the planner (redirect any of these before issue creation)

| # | Decision | Rationale | Cost to flip later |
|---|---|---|---|
| D1 | **Minimum: iPadOS 17.0**; Apple silicon Mac availability through App Store Connect compatibility where the iPad app functions correctly | Unlocks SwiftData, Swift Charts, `.scrollPosition`, native ProMotion 120 Hz APIs. Cuts iPad 5, iPad mini 4, 2016 iPad Pro. Mac support is the iPad app running on Apple silicon, not a separate macOS binary. | Low for iPadOS minimum; medium if a separate Mac target is later required. |
| D2 | **Free app, no IAP, no ads** | Mirrors current web posture. Simplest App Review path. | Medium (adds StoreKit + receipts). |
| D3 | **Accessibility complete in v1** | VoiceOver labels, Reduced Motion, Dynamic Type. Cheaper to bake in than retrofit. | High (retrofitting doubles the work). |
| D4 | **English only in v1; `Localizable.xcstrings` scaffolded** | Faster ship. No translation pipeline cost. | Low. |
| D5 | **Zero telemetry / analytics / crash reporting** | "Data Not Collected" privacy label = simplest App Review. | Low. |
| D6 | **Audio: AVAudioEngine + synthesized buffers** (matches web's Web Audio synthesis) | First-party, well-documented, sub-10 ms output latency on iPad. AudioUnits is overkill for the existing sound palette. | Medium (engine swap is a contained rewrite of `Core/Audio/`). |
| D7 | **Highway render: SpriteKit via SwiftUI `SpriteView`** | Hits 120 Hz without Metal-level code volume. Easy to mix with SwiftUI overlays. | Medium (re-host in Metal or Canvas later if perf demands). |
| D8 | **Persistence: SwiftData** (one model per concern; JSON snapshot for debug import/export) | iOS 17+ default. Less boilerplate than Core Data. | High (data migration). |
| D9 | **Bundle id `com.visaliacrc.drumrot`** (placeholder) | Matches user's `visaliacrc.com` domain. Rename pre-submit. | Trivial pre-submit; high post-submit. |
| D10 | **Single iPadOS Xcode target, no Catalyst target in v1** | User asked for macOS running the iPad install. Apple silicon Mac availability is managed in App Store Connect for the iPad app. | Medium (project split / Catalyst target later). |
| D11 | **No localStorage migration from web** | Different surface; different progress. iPad install = fresh save. Documented in store description. | Medium (would need a web export → iPad import flow). |
| D12 | **App name on store: "drumrot — SP-808 KILLA"** (placeholder) | Matches existing branding. Confirm pre-submit. | Low pre-submit; medium post-submit. |
| D13 | **Repository layout: new top-level `ios/` directory holding the Xcode project, sibling to existing `js/` and `art/`** | Keeps web app untouched; one git repo. | Trivial. |
| D14 | **Mac mode: iPad app on Apple silicon Mac, not Optimized for Mac** | Single iPad layout pass; matches exact UI port decision. v1.1 considers native Mac/Catalyst if needed. | Medium (Mac optimization is a separate pass). |
| D15 | **iPhone target left disabled in v1** | Landscape-locked iPad UI doesn't compose to iPhone portrait without redesign. iPhone is v1.1. | Low (toggle in target settings + new layout work). |

## Known ambiguities (resolve before Phase 7 — App Store submission)

- **A1. RESOLVED (2026-05-26).** User is already enrolled in the Apple Developer Program. Signing assets exist (App Store Connect API key + Developer ID Application certificates), stored in a local folder **outside this repo** on the user's machine. These must never be committed — load them into CI/TestFlight automation as secrets, not files in the tree.
- **A2.** Whether the existing **drum sounds** (synthesized at runtime by `js/audio.js` from Web Audio oscillators / noise buffers) translate 1:1 to AVAudioEngine synthesis, OR whether v1 ships pre-rendered sample WAVs. If WAVs: source/license must be confirmed before submission.
- **A3.** Final **app icon**. Current web favicon is a 404 (open issue [#6](https://github.com/ajhochy/drumpad/issues/6)). App Store requires a 1024×1024 PNG plus a full Asset Catalog set.
- **A4.** Voxel-art licensing — whether the 31 portraits in `art/drumrots/` are original, commissioned, or sourced, and whether they are commercially redistributable on the App Store.
- **A5.** Whether any drumrot names / portraits read as direct parody of trademarked characters (review pre-submission).

A1 is resolved (see above); the remaining four (A2 drum-sound translation, A3 app icon, A4 voxel-art licensing, A5 parody-name review) surface before Phase 7. None block any earlier phase.

## Prior Art (Tier 3 swarm synthesis, 2026-05-20)

### CoreMIDI low-latency on iPadOS
- **`MIDIServices` framework, `MIDIEventList` / `MIDIPortCreate` (iOS 14.5+)** — sub-5 ms jitter on USB. WWDC 2024 *"What's new in Core Audio"* covers Audio Workgroup setup to prevent thread preemption on the MIDI callback.
- **iOS 17+ adds native `MIDINetworkSession` pairing** — removes the need for custom rtpMIDI discovery code.
- **Latency tiers** (measured ranges in the wild):
  - USB MIDI: 0.5–5 ms
  - Network MIDI: 10–50 ms (LAN-dependent)
  - BLE MIDI: 7.5 ms nominal, spikes to 20 ms under CPU contention
- **Threading rule (non-negotiable):** receive callbacks are on a high-priority real-time thread. SwiftUI updates must marshal to MainActor. Calling SwiftUI updates from the callback is the #1 cause of dropped notes and frame hitches.
- **Sysex** is reliable on USB only; BLE / Network MIDI truncate. Not relevant for drum input (no sysex needed).
- **Pattern adopted:** layered transport detection — USB preferred → Network MIDI → BLE fallback. Pre-allocate `MIDIEventPacket` buffers to avoid allocation jitter.

### iPad apps on Apple silicon Mac + App Store availability
- Apple states that iPhone/iPad apps can run on Apple silicon Macs with no porting process, using the same frameworks, resources, and runtime environment as iOS/iPadOS. Availability is managed in App Store Connect.
- App Store Connect allows selecting whether an iPhone/iPad app is available on Apple silicon Macs and verifying compatibility after a build exists.
- **AVAudioSession `.playback + .duckOthers`** works on iPadOS; behavior when the iPad app runs on macOS must be smoke-tested because unavailable iPad features can differ on Mac.
- **No background audio entitlement needed for v1** — drum trainer is foreground-only.
- **No native Mac optimization in v1** — v1 ships the iPad-shaped UI on Mac. v1.1 can evaluate Catalyst/native Mac only if the iPad app on Mac cannot satisfy MIDI/audio needs.
- **Privacy nutrition label "Data Not Collected"** qualifies for the simplest and fastest review.

### Apple platform anti-patterns surfaced (rejected)
- **JavaScriptCore-embedding the existing JS engine.** Tempting but kills latency in the scoring path and bypasses the whole point of going native.
- **`AVAudioPlayer` (one player per voice).** Works but allocates per-play, can stutter under load. Use pre-loaded `AVAudioPCMBuffer` + `AVAudioPlayerNode` instead.
- **SwiftUI `Canvas` for the highway at 120 Hz with 20+ sprites + camera shake.** Frames drop. Use SpriteKit.

### Reference docs
- [CoreMIDI](https://developer.apple.com/documentation/coremidi)
- [`MIDIInputPortCreateWithProtocol`](https://developer.apple.com/documentation/coremidi/3566488-midiinputportcreatewithprotocol)
- [AVAudioEngine](https://developer.apple.com/documentation/AVFAudio/audio-engine)
- [UniformTypeIdentifiers — `UTType.midi`](https://developer.apple.com/documentation/uniformtypeidentifiers/uttype/3551522-midi)
- [SwiftData](https://developer.apple.com/documentation/SwiftData)
- [Running your iOS apps in macOS](https://developer.apple.com/documentation/apple-silicon/running-your-ios-apps-in-macos)
- [Manage availability of iPhone and iPad apps on Macs with Apple silicon](https://developer.apple.com/help/app-store-connect/manage-your-apps-availability/manage-availability-of-iphone-and-ipad-apps-on-macs-with-apple-silicon/)

## Existing web feature inventory

### App shell
- `index.html` defines a single app shell with tabs: Play, Library, Progress, Build, Drops.
- `js/main.js` owns tab switching, app bootstrap, lesson loading, keyboard/pad transport, BPM sync, loop/metronome toggles, MIDI selection, and event wiring.
- Native equivalent: `RootView` with TabView and shared `AppStore`.

### Play
- Header/readout: lesson id/name, score, combo, accuracy.
- Progress strip: notes complete out of total, fill width, 10-dot streak bar.
- Highway: 6 lanes (crash / hihat / snare / kick / tom / ride), hit line, judge text, count-in display, note travel animation, shadow notes for seamless loop rollover.
- Pads: crash, hi-hat, snare, kick, tom, ride.
- Rail: notation, coach note, transport, click toggle, tempo input, loop toggle, MIDI input selector / activity.
- Runtime behavior:
  - `HIT_WINDOW = 60` ms (in the JS implementation).
  - Count-in is 8 eighth-notes.
  - Note travel time is 1800 ms.
  - Metronome ticks every quarter note through count-in and groove.
  - Loop mode saves a pass at each loop rollover and resets pass hit/miss state.
  - Non-loop mode finishes after final note passes.
  - Hit scoring: perfect 300 when `dy < 20`, great 200 when `dy < 40`, good 100 otherwise within window.
  - Combo multiplier: points multiplied by `max(1, floor(combo / 4))`.

### Lessons and library
- 6 lanes (LANES order: `crash, hihat, snare, kick, tom, ride`; labels `CR, HH, SN, KK, TM, RD`).
- **8 built-in lessons**: Rock Beat 101, Disco Pulse, Half-Time Slap, Tom Fill, Crash & Ride, Shuffle, Punk Bash, Funk Pocket.
- Each lesson carries name, BPM, coach tip, pattern strings, notes, bars, beatsPerBar, difficulty, genre.
- Library cards: lesson number, New/Played stamp, metadata, mini-notation, stars, high score, tier pips.

### Progress and achievements
- Progress shows day streak, last 14 play days, total notes, sessions, best score, top accuracy, achievements, recent sessions.
- **18 achievements** across performance, consistency, tempo, and builder categories.
- Achievement unlock triggers toast + delayed Drumrot roll/reveal.
- **Tempo tiers**: Steady, Grooving, Locked, Killing It (`TIER_NAMES` in `js/achievements.js`; colors `['#5cf07d', '#ff8a1e', '#ff3a5a', '#ff2a7a']`).
- Pass stars: 3 at ≥95%, 2 at ≥80%, 1 at ≥50%.

### Build
- Step sequencer: 16/32 steps × 6 lanes, BPM, coach note, MIDI export, load into player, clear.
- Builder "load into player" creates/replaces one persisted builder lesson, unlocks Creator, unlocks Coach if coach note non-empty, switches to Play.

### MIDI file import/export
- Parser supports standard MIDI header/track chunks, PPQ timing, running status, note-on, meta/sysex skips, common MIDI event skips.
- SMPTE time division is rejected.
- Import maps GM drum notes into the 6 lanes, quantizes to eighth-note indexes (`ppq / 2`), creates custom lessons, persists them.
- Export writes Type 0 MIDI, PPQ 96, tempo meta event, channel 10 note-on/off, GM notes `[49, 42, 38, 36, 45, 51]`.

### MIDI hardware input
- Web MIDI maps GM drum notes to the 6 lanes.
- Input devices listed, all inputs currently receive callbacks, MIDI activity LED pulses on note-on velocity > 0.
- No-MIDI and denied states visible.

### Audio
- Web Audio synthesizes:
  - Kick: oscillator 120 Hz → 40 Hz with gain envelope.
  - Snare / tom: noise buffer through highpass / bandpass filter.
  - Cymbals (crash / ride / hihat): noise buffer through highpass filter with lane-specific duration.
  - Click: square oscillator, accent / non-accent variants.
- Native equivalent: AVAudioEngine source / player nodes with short generated buffers (matches character).

### Drumrot collection (verified against `js/drumrots.js`, 2026-05-20)
- **31 Drumrots**; 31 `.webp` portraits under `art/drumrots/`.
- **7 tier keys**: `common` (4), `rare` (4), `epic` (5), `legendary` (4), `mythic` (4), `god` (2), `og` (8).
- `TIERS_ORDER = ['common','rare','epic','legendary','mythic','god','og']`.
- Weighted roll based on achievement difficulty, plus separate 5% flat OG upgrade chance.
- Collection stores highest tier per drumrot id; duplicate lower/equal pulls do not downgrade.
- Drops tab shows locked / unlocked card grid and count (N / 31).
- Reveal overlay queues drops, auto-dismisses after 6 s (9 s for OG), supports manual dismissal, refreshes Drops when open.
- Card renderer has tier-specific chrome, locked variant, image portrait with emoji fallback, stat display rules, OG number/stat rules (`#NNN/OG`, `∞` for bpm/groove, `MAX` for power).

## Target native architecture

### Project
- New Xcode project under `ios/SP808Killa/`.
- **Single SwiftUI iPadOS target**. Do not add a Mac Catalyst target for v1.
- Deployment: **iPadOS 17.0** (primary). Apple silicon Mac availability is managed in App Store Connect for the iPad app.
- iPhone target box: **unchecked** in v1 (v1.1 backlog).
- `UISupportedInterfaceOrientations~ipad = LandscapeLeft, LandscapeRight` (landscape-locked iPad).
- On Apple silicon Mac, verify the iPad app preserves the 1366 × 1024-ish landscape proportions and does not expose broken resizing/full-screen states.
- Swift 5.10+; Xcode 15+.
- SPM packages: `swift-snapshot-testing` (tests only). No other v1 dependencies.

### Module layout

```
ios/SP808Killa/
├── SP808Killa.xcodeproj
└── SP808Killa/
    ├── App/                      # @main, scene, RootView, AppStore
    │   ├── SP808KillaApp.swift
    │   ├── Info.plist
    │   └── SP808Killa.entitlements
    ├── Domain/                   # pure types + stateless services
    │   ├── DrumLane.swift, NoteEvent.swift, PatternLine.swift
    │   ├── Lesson.swift, LessonFactory.swift, LessonMeta.swift
    │   ├── ScoringEngine.swift, Streak.swift
    │   ├── DrumrotTier.swift, Drumrot.swift, TierWeights.swift, DropRoller.swift
    │   ├── Achievement.swift, AchievementEngine.swift
    │   ├── PracticeTier.swift, DateStreakCalculator.swift
    │   ├── MIDIFileParser.swift, MIDIFileExporter.swift, GMDrumMapper.swift
    │   └── BuilderLessonFactory.swift
    ├── Audio/                    # AVAudioEngine
    │   ├── DrumAudioEngine.swift, VoiceSynth.swift, ClickSynth.swift
    │   └── AudioSessionManager.swift
    ├── MIDI/                     # CoreMIDI
    │   ├── MIDIInputManager.swift, MIDITransport.swift
    │   ├── NetworkMIDISession+Setup.swift, BluetoothMIDIPairing.swift
    │   └── MIDIDeviceID.swift
    ├── Playback/                 # gameplay clock
    │   ├── PlaybackEngine.swift, NoteTravel.swift
    │   └── TestClock.swift
    ├── Data/                     # SwiftData persistence
    │   ├── ModelContainer+App.swift, SchemaMapping.md
    │   └── Models/
    │       ├── DrumrotCollectionEntry.swift, LessonScore.swift
    │       ├── AchievementUnlock.swift, PracticeDay.swift
    │       ├── ExtraLesson.swift, BuilderState.swift, AppSettings.swift
    ├── Features/
    │   ├── Play/                 # highway + scoring + readout + pads + rail
    │   ├── Library/              # lesson grid + cards + mini-notation
    │   ├── Progress/             # streak + calendar + achievements + recents
    │   ├── Builder/              # 16/32-step grid + coach + MIDI export
    │   ├── Drops/                # collection grid + reveal overlay + queue
    │   └── Settings/             # MIDI device picker + audio offset + toggles
    ├── DesignSystem/             # palette, typography, tier tokens, cards, pads
    │   ├── Cards/DrumrotCardView.swift, LockedDrumrotCardView.swift, TierBadge.swift, PortraitView.swift
    │   ├── Theme/Palette.swift, Typography.swift, Tiers.swift, Motion.swift
    │   ├── Controls/Pad.swift, BpmStepper.swift, LED.swift
    │   └── Modifiers/HolofoilSweep.swift
    ├── Resources/
    │   ├── Assets.xcassets/
    │   │   ├── drumrots/         # 31 image sets (PNG @1x/@2x/@3x)
    │   │   ├── icons/, AppIcon.appiconset
    │   ├── Fonts/                # IBM Plex Mono, Space Grotesk, Inter, etc.
    │   ├── Sounds/               # optional pre-rendered WAVs (depends on A2)
    │   └── Content/
    │       ├── Drumrots.json     # mirror of js/drumrots.js DRUMROTS
    │       ├── Lessons.json      # mirror of js/lessons.js LESSONS
    │       └── Achievements.json # mirror of js/achievements.js ACHIEVEMENTS
    └── SP808KillaTests/, SP808KillaUITests/
```

### State model
- `@MainActor final class AppStore: ObservableObject` — replaces JS mutable state.
- Pure stateless domain services: `LessonFactory`, `ScoringEngine`, `AchievementEngine`, `DropRoller`, `MIDIFileParser`, `MIDIFileExporter`, `GMDrumMapper`, `DateStreakCalculator`, `BuilderLessonFactory`.
- `PlaybackEngine` owns the gameplay clock; publishes snapshots to UI via `@Published`.
- SwiftData `ModelContainer` injected at the root.

### Rendering approach
- **SwiftUI** for shell, tabs, cards, library, progress, builder, drops, settings.
- **SpriteKit** (via `SpriteView`) for the note highway — handles 60/120 Hz scrolling with note sprites + camera shake + count-in overlay.
- Bundled images through Asset Catalog (PNG @1x/@2x/@3x re-exported from `art/drumrots/*.webp`).
- Bundled fonts via `Resources/Fonts/` and Info.plist `UIAppFonts`. No CDN.
- Tabler Icons → SF Symbols where mapped; otherwise Asset-Catalog vectors.

### Native APIs
- **AVFoundation / AVAudioEngine** for drum + click synthesis (Phase 3).
- **CoreMIDI** for device enumeration and note input (Phase 8).
- **UniformTypeIdentifiers** (`UTType.midi`) + document picker / exporter for MIDI file I/O (Phase 8).
- **SwiftData** for persistence (Phase 4).
- **XCTest** + **XCUITest** + **swift-snapshot-testing** for tests.

### Audio engine details
- `AVAudioEngine` → `AVAudioMixerNode` (main) → output.
- Voices: one `AVAudioPlayerNode` per drum + one for the click.
- Each voice loads a synthesized PCM buffer at engine start (kick: oscillator 120 Hz → 40 Hz; snare/tom: filtered noise; cymbals: filtered noise; click: square accent / non-accent). Matches the character of `js/audio.js` 1:1.
- `AVAudioSession` category `.playback`, mode `.default`, options `.mixWithOthers`. `setPreferredIOBufferDuration(0.005)` where the device allows it.
- Interruption handler (iOS): on `.began` → pause + mute. On `.ended` with `.shouldResume` → restart.
- Route change handler: restart on `.oldDeviceUnavailable`.
- Apple silicon Mac iPad-app mode: smoke-test AVAudioEngine startup, interruptions, output routing, and MIDI behavior separately from iPad hardware.

### CoreMIDI bridge details

```
AppLaunch
   ↓
MIDIInputManager.start()
   ├─ MIDIClientCreateWithBlock("SP808Killa", &client, notifyBlock)
   ├─ MIDIInputPortCreateWithProtocol(client, "in", ._1_0, &port, receiveBlock)
   ├─ For each MIDIGetSource(): MIDIPortConnectSource(port, source, nil)
   ├─ MIDINetworkSession.default().isEnabled = true
   │     .connectionPolicy = .anyone (dev) / .hostInitiated (release)
   └─ BLE MIDI: present CABTMIDICentralViewController on user tap (Settings)

receiveBlock (RT thread):
   Decode MIDIEventList → packets → (status, data1, data2)
   For Note On (0x90-0x9F, vel > 0):
      if let lane = GMDrumMapper.lane(forNote: data1) {
        let hit = MIDIHit(lane: lane, velocity: data2, hostTime: timestamp)
        Task { @MainActor in PlaybackEngine.shared.recordHit(hit) }
      }
   For Note Off (0x80) or Note On vel == 0:
      (unused in v1; reserved for sustained-roll detection in v1.1)

notifyBlock (object added/removed):
   marshal to MainActor; update Devices picker

Settings → MIDI Devices:
   - List USB + Network sources by name + UID
   - "Pair Bluetooth MIDI device" → CABTMIDICentralViewController
   - Persist selected device UID to AppSettings (SwiftData)
   - Auto-reconnect to last selected on launch if present
   - "All Sources" toggle to receive from every connected device
```

GM drum mapping is ported verbatim from `js/midi-device.js` — same MIDI note numbers → same internal lane ids.

### Persistence migration (web localStorage → SwiftData)
- No automated migration. iPad app starts fresh.
- Documented in App Store description ("per-device progress, no cross-platform sync in v1").
- SwiftData models map to web `localStorage` keys per `SchemaMapping.md` (not for migration — for documentation and future export tooling):

| Web key (`js/state.js`) | SwiftData model | Notes |
|---|---|---|
| `drum.scores` | `LessonScore` (1 row per lesson) | high, stars, plays, lastAcc, when |
| `drum.achievements` | `AchievementUnlock` (1 row per unlock) | id + unlockedAt |
| `drum.tiers` | `PracticeTierSnapshot` (rolling) | enum case |
| `drum.playDays` | `PracticeDay` (1 row per day) | date |
| `drum.extraLessons` | `ExtraLesson` (1 row per custom lesson) | full lesson blob as JSON |
| `drum.collection` | `DrumrotCollectionEntry` (1 row per collected id) | highest tier + count + firstAt |
| `drum.builder` | `BuilderState` (singleton) | steps × lanes + bpm + coach |
| `drum.settings` | `AppSettings` (singleton) | MIDI UID, audio offset, haptics, motion, last tab |

Top-level `schemaVersion: Int` on every model; corrupt-row recovery logs an error and falls back to defaults.

Debug-only Settings entry: "Export progress (JSON)" / "Import progress (JSON)" — useful for tester transcripts and for the v1.1 web → iPad migration tool.

### Navigation rewrite
- `TabView` with 5 tabs: Play / Library / Progress / Build / Drops.
- Tab icons: SF Symbols (e.g., `music.note.list`, `books.vertical`, `chart.bar`, `slider.horizontal.3`, `square.grid.3x3.fill`).
- iPad: landscape-locked. Apple silicon Mac: verify the iPad app keeps a usable landscape presentation.
- Reveal overlay: `.fullScreenCover`, matching the web reveal overlay as closely as native iPad allows.
- Settings: gear in top-right.
- Hardware keyboard shortcuts on iPad/Mac-running-iPad-app: Cmd+1..5 switch tabs; Cmd+R restart current lesson; Spacebar play/pause; L toggle loop; C toggle click.

### Accessibility
- **VoiceOver:** every card emits `accessibilityLabel("\(name), tier \(tier), number \(num). Stats: bpm \(bpm), groove \(groove), power \(power). \(state.description)")`. Pads emit `accessibilityLabel("\(lane) pad")` + `accessibilityHint("Double-tap to play")`. Drops grid combines child elements per cell.
- **Reduced Motion** (`@Environment(\.accessibilityReduceMotion)`): disables holofoil sweep, drop-roll spin, highway camera shake, reveal slide-in. Replaced with cross-fades.
- **Dynamic Type:** every text view uses `.font(.system(... style:))` not fixed pt. AX3 verified.
- **Switch Control:** every interactive element reachable.
- **Increased Contrast:** alternate tier badge colors meet AA contrast.
- **Audio latency offset** (`AppSettings.audioLatencyOffsetMs`): user-tunable -50…+50 ms for BLE headphones / hearing aids.

### App Store compliance
- Apple Developer Program: **enrolled** (A1 resolved). Signing assets (App Store Connect API key + Developer ID certificates) live outside the repo on the user's machine; load into CI/TestFlight as secrets, never commit.
- App Store Connect record: name, subtitle, bundle id, age rating 4+, category Games > Music, screenshots (4-6 per device class), 30 s app preview video.
- **Privacy nutrition label: "Data Not Collected."**
- Required device capabilities: `audio-output`.
- Capabilities (target Signing & Capabilities — iPad-only target):
  - **Bluetooth** — required for BLE MIDI pairing.
  - **Local network** — required for Network MIDI.
  - **User-selected file access** via the iOS document picker / exporter for MIDI import/export (no persistent file-access entitlement needed).
  - **No macOS App Sandbox entitlements.** This is an iPad-only target; it runs on Apple silicon Mac as the iPad app and inherits the iOS capability model. If a separate Mac/Catalyst target is ever added in v1.1, it will need its own sandbox entitlements (`com.apple.security.app-sandbox`, `device.bluetooth`, `device.usb`, `network.client`, `files.user-selected.read-only`).
- Info.plist usage descriptions (required):
  - `NSBluetoothAlwaysUsageDescription` = "drumrot uses Bluetooth to connect to wireless MIDI drum controllers."
  - `NSLocalNetworkUsageDescription` = "drumrot uses your local network to receive MIDI from network MIDI sources."
  - `NSBonjourServices` = `["_apple-midi._udp"]` (required for iOS 14+ Network MIDI discovery).
- No background modes declared.
- No tracking, no IDFA, no SKAdNetwork.
- **No audio-input usage description and no recording entitlement** — the app does not record audio.

## Implementation phases

Phase numbering aligns with the Issue Table below.

| Phase | Theme | Issues (plan IDs) | Exit criteria |
|---|---|---|---|
| 0 | Project setup, asset pipeline, CI | #20–#23 | Xcode project builds + runs blank tab UI on iPad simulator and, where available, the iPad app on Apple silicon Mac; CI green; 31 voxel PNGs in Asset Catalog. |
| 1 | Visual chassis & navigation | #24–#27 | All 5 tabs present, blank content, design system primitives exist, settings + SwiftData container working. |
| 2 | Domain parity (data + math) | #28–#31 | Lessons / achievements / drumrots / roll math match web byte-for-byte (parity tests). |
| 3 | Audio + AVAudioEngine | #32–#33 | Tap a pad → synthesized drum plays with low latency; metronome accents distinguishable; interruption/output behavior works on iPad and iPad-app-on-Mac mode. |
| 4 | Persistence + AppStore | #34–#35 | Scores / achievements / collection / settings persist across relaunch; corrupt-row recovery logs error and defaults. |
| 5 | Drops + card chrome + reveal | #36–#38 | Drops grid renders 31 cells; locked + collected + OG variants pixel-correct; reveal overlay queues + auto-dismisses. |
| 6 | Playback + scoring + Play tab UI | #39–#42 | SpriteKit highway scrolls; full lesson plays end-to-end; score / combo / accuracy match web rules. |
| 7 | Library + Progress + Builder | #43–#46 | All 3 tabs functional; builder loads into player; achievement triggers reach drop-roll. |
| 8 | MIDI file I/O + CoreMIDI hardware input | #47–#50 | Import `.mid` → custom lesson; export `sp808-pattern.mid`; USB / Network / BLE MIDI input drives the highway. |
| 9 | Accessibility + iPad-on-Mac polish + responsive | #51–#54 | VoiceOver-complete; Reduced Motion honored; hardware keyboard shortcuts work; iPad app presentation on Mac is verified. |
| 10 | Tests + App Store prep + TestFlight | #55–#60 | Snapshot suite green; manual smoke checklist captured; ASC record populated; TestFlight build accepted; submission queued. |

## Issue table

(Plan IDs `#20`–`#60`. GitHub numbers are plan ID − 8; see the crosswalk above.)

| Order | # | Title | Goal | Likely files | Tests / evaluation | Deps |
|---|---|---|---|---|---|---|
| 1 | 20 | Bootstrap `ios/` Xcode project | Create `ios/SP808Killa.xcodeproj`, single SwiftUI iPadOS target, deployment iPadOS 17, landscape-lock iPad, App Store/TestFlight-ready signing placeholders, Apple silicon Mac availability documented for App Store Connect | `ios/SP808Killa/App/SP808KillaApp.swift`, `Info.plist`, `.entitlements`, `.gitignore` | App builds for iPad sim and, where available, "My Mac (Designed for iPad)"; both launch a blank view | — |
| 2 | 21 | Hello-world prototype: card + sample + MIDI enumeration | One screen: hard-coded TIER_GOD/OG card, plays a synthesized snare on tap (AVAudioEngine), prints connected MIDI sources to debug console | `Features/Drops/PrototypeCard.swift`, `Audio/DrumAudioEngine.swift` (stub), `MIDI/MIDIInputManager.swift` (stub) | Runs on iPad sim + iPad-app-on-Mac mode where available; MIDI sources visible when a real/virtual MIDI source is running | 20 |
| 3 | 22 | Asset pipeline — voxel PNGs + fonts | Add `scripts/export-drumrots-png.mjs` that emits PNG @1x/@2x/@3x from `art/drumrots/*.webp`; populate Asset Catalog; bundle TTFs + declare `UIAppFonts` | `scripts/export-drumrots-png.mjs`, `Resources/Assets.xcassets/drumrots/`, `Resources/Fonts/` | Asset catalog contains 31 image sets; SwiftUI preview shows correct font | 20 |
| 4 | 23 | CI on GitHub Actions — xcodebuild test | `.github/workflows/ios-build.yml` runs `xcodebuild test` on macOS runner | `.github/workflows/ios-build.yml` | Action passes on a PR | 20 |
| 5 | 24 | Root TabView + 5 placeholder tabs | App shell with Play / Library / Progress / Build / Drops, SF Symbol icons, landscape lock | `App/SP808KillaApp.swift`, `App/RootView.swift`, `Features/*/EmptyView.swift` | Manual: tap each tab on iPad sim and iPad-app-on-Mac mode where available; landscape stays | 20 |
| 6 | 25 | Design system primitives — exact web UI parity | Centralize colors, fonts, tier gradients; mirror `css/main.css` and `css/cards.css` tokens; LED, Pad, BpmStepper primitives | `DesignSystem/Theme/Palette.swift`, `Typography.swift`, `Tiers.swift`, `Controls/*.swift` | `#Preview` shows each component; controls and tier badges match web reference screenshots | 22 |
| 7 | 26 | Settings tab + SwiftData container + AppSettings | Gear icon → sheet with MIDI device picker placeholder, audio offset slider, haptics toggle, reduced-motion toggle, debug import/export buttons | `Features/Settings/SettingsView.swift`, `Data/ModelContainer+App.swift`, `Data/Models/AppSettings.swift` | Toggle a setting → kill app → reopen → setting persists | 20 |
| 8 | 27 | AppStore (ObservableObject) + dependency injection skeleton | `@MainActor` AppStore, env-injected, owns SwiftData context + AudioEngine + MIDIInputManager handles | `App/AppStore.swift` | Unit test: AppStore initializes with default state; injection compiles | 26 |
| 9 | 28 | Port domain models + Drumrots.json + parity tests | `Drumrot`, `DrumrotTier` (7 cases), `TierWeights`, `DropRoller`; load `Drumrots.json` (mirror of `js/drumrots.js`) | `Domain/Drumrot.swift`, `DrumrotTier.swift`, `TierWeights.swift`, `DropRoller.swift`, `Resources/Content/Drumrots.json` | XCTest: 31 entries, 7 tiers, ids match web; injected-RNG roll distribution within ±2σ; OG bonus = 5% | 26 |
| 10 | 29 | Port lessons + Lessons.json + parity tests | 8 built-in lessons + LANES + LANE_LABEL + LANE_COLORS + `LessonFactory` + `LessonMeta` | `Domain/Lesson.swift`, `LessonFactory.swift`, `DrumLane.swift`, `Resources/Content/Lessons.json` | XCTest: lesson note counts/order match web; tier pips ordering preserved | 28 |
| 11 | 30 | Port achievements + Achievements.json + AchievementEngine | 18 achievements with category metadata + `AchievementEngine` that triggers from hit/pass/builder/MIDI events | `Domain/Achievement.swift`, `AchievementEngine.swift`, `Resources/Content/Achievements.json` | XCTest: 18 ids match web; each rule fires under the right synthetic event sequence | 28 |
| 12 | 31 | Port scoring + streak + tempo tier + stars | `ScoringEngine`, `Streak`, `PracticeTier` (Steady / Grooving / Locked / Killing It), star thresholds (≥95/80/50%) | `Domain/ScoringEngine.swift`, `Streak.swift`, `PracticeTier.swift` | XCTest: perfect/great/good/miss boundary tests; combo multiplier; star calc | 28 |
| 13 | 32 | AVAudioEngine drum synth — kick/snare/tom/crash/hihat/ride | Synthesize matching the web Web Audio character; one `AVAudioPlayerNode` per voice; preloaded buffers; `play(lane:velocity:)` | `Audio/DrumAudioEngine.swift`, `VoiceSynth.swift`, `Resources/Sounds/` (if buffers cached to disk) | Manual: pad tap → distinct sound per lane; input-to-sound latency target ≤ 10 ms measured on real iPad | 27 |
| 14 | 33 | Audio session category + interruption + route change handling | `.playback + .mixWithOthers`; interruption (iPadOS) + route change handlers; click synth (accent + non-accent square) | `Audio/AudioSessionManager.swift`, `ClickSynth.swift` | Manual: interruption resumes correctly; headphones unplug pauses; Apple silicon Mac audio route smoke passes | 32 |
| 15 | 34 | Persistence — all SwiftData models + schema versioning | `LessonScore`, `AchievementUnlock`, `PracticeDay`, `ExtraLesson`, `DrumrotCollectionEntry`, `BuilderState` + `schemaVersion` on each | `Data/Models/*.swift`, `Data/ModelContainer+App.swift`, `Data/SchemaMapping.md` | XCTest: save → kill container → reload round-trips; corrupt-row recovery logs error, defaults | 26 |
| 16 | 35 | AppStore wired to persistence | AppStore reads / writes all SwiftData models; save points after pass / achievement / collection / builder save | `App/AppStore.swift`, glue in each Feature ViewModel | XCTest: AppStore mutation → SwiftData query reflects | 27, 34 |
| 17 | 36 | DrumrotCardView (port of v0.3 card chrome) | SwiftUI card: screws, banner with tier + #NNN, portrait image, stats footer, OG `∞/MAX`, locked variant, emoji fallback | `DesignSystem/Cards/DrumrotCardView.swift`, `LockedDrumrotCardView.swift`, `TierBadge.swift`, `PortraitView.swift` | Snapshot tests for all 7 tiers × {locked, collected} + OG variant | 22, 25, 28 |
| 18 | 37 | DropsGrid — full 31-cell collection | LazyVGrid of cards; locked variants for un-collected; data backed by SwiftData query; N/31 header | `Features/Drops/DropsGrid.swift`, `DropsViewModel.swift` | Snapshot of full grid; manual: collect one → cell unlocks | 28, 34, 36 |
| 19 | 38 | Reveal overlay + queue + auto-dismiss | `.fullScreenCover` shows new card; queue handles multiple rolls; auto-dismiss 6 s (9 s OG); honors Reduced Motion | `Features/Drops/RevealOverlay.swift`, `RevealQueue.swift` | UI test: trigger fake achievement → overlay → dismiss; queue handles N rolls | 30, 36 |
| 20 | 39 | PlaybackEngine + NoteTravel + test clock | Monotonic gameplay clock; count-in; note travel (1800 ms); loop rollover (save pass + reset); non-loop completion; test-clock for determinism | `Playback/PlaybackEngine.swift`, `NoteTravel.swift`, `TestClock.swift` | XCTest: count-in timing; loop rollover saves exactly one pass; non-loop terminates after last note | 31 |
| 21 | 40 | SpriteKit Highway scene + note sprites + count-in overlay | `SKScene` hosted via `SpriteView`; 6 lanes; strike line; note sprites scroll; count-in text; 120 Hz on ProMotion | `Features/Play/HighwayScene.swift`, `HighwayView.swift`, `NoteNode.swift` | Visual: lane scrolls at 60 Hz iPad sim, 120 Hz ProMotion device; count-in displays 1..8 | 25 |
| 22 | 41 | Play tab UI — readout + pads + rail + judge text | All Play surface: lesson header, score/combo/accuracy readout, progress strip, 6 pads (touch + visual pulse), notation, coach note, transport (play/pause/restart/next), tempo input (clamp 40-200), loop toggle, click toggle, MIDI selector slot | `Features/Play/PlayView.swift`, `Readout.swift`, `Pads.swift`, `Rail.swift`, `JudgeText.swift` | Manual: every control responds; pads pulse on tap; tempo clamp works | 32, 39, 40 |
| 23 | 42 | Wire scoring → highway → readout + lesson completion | Hit at strike line → judgment → score / combo / accuracy update; loop rollover saves pass; pass completion writes `LessonScore` | `Features/Play/PlayViewModel.swift` (glue) | Manual: play through a lesson; score writes to SwiftData; loop saves multiple passes | 35, 39, 40, 41 |
| 24 | 43 | LibraryView | Lesson cards with number / New-Played stamp / metadata / mini-notation / stars / high score / tier pips; tap → loads into Play and starts | `Features/Library/LibraryView.swift`, `LessonCardView.swift`, `MiniNotationView.swift`, `TierPipsView.swift` | UI test: card tap → Play tab open with lesson loaded | 29, 42 |
| 25 | 44 | ProgressView | Day streak; 14-day calendar; total notes / sessions; best score; top accuracy; achievement grid; recent sessions | `Features/Progress/ProgressView.swift`, `AchievementGrid.swift`, `RecentSessions.swift` | Unit: aggregate calcs match web; UI: empty / partial / full preview | 30, 34, 35 |
| 26 | 45 | BuilderView — 16/32-step grid + load into Play | 6 lane rows × 16/32 steps; BPM (40-200); coach note; clear; load into player (creates/replaces builder lesson, unlocks Creator + Coach if non-empty); persists | `Features/Builder/BuilderView.swift`, `BuilderEngine.swift`, `Domain/BuilderLessonFactory.swift` | Unit: empty pattern → error; load-into-player triggers correct achievements; persistence round-trips | 29, 30, 34 |
| 27 | 46 | Achievement → toast → reveal queue wiring | Hit/pass/builder/MIDI events fire `AchievementEngine`; new unlock → toast → delayed drop roll → reveal | `App/AppStore.swift`, `Features/Progress/AchievementToast.swift`, glue in Play / Builder | UI test: trigger unlock event → toast appears → reveal queued; deterministic sequencing | 30, 38, 42, 45 |
| 28 | 47 | MIDI file parser — `.mid` / `.midi` import | Standard MIDI header / track chunks, PPQ timing, running status, note-on, meta/sysex skips; reject SMPTE; map GM drum notes to 6 lanes; quantize to eighth-note (ppq/2); create custom `ExtraLesson` | `Domain/MIDIFileParser.swift`, `GMDrumMapper.swift`, `Features/Library/MIDIImportSheet.swift` | XCTest fixtures: valid, invalid, running-status, multi-track, SMPTE rejection | 29, 43 |
| 29 | 48 | MIDI file exporter — `sp808-pattern.mid` | Type 0 MIDI, PPQ 96, tempo meta, channel 10 note-on/off, GM notes `[49, 42, 38, 36, 45, 51]`; share sheet | `Domain/MIDIFileExporter.swift`, `Features/Builder/MIDIExportSheet.swift` | XCTest: byte-exact match against web export; round-trip parser test | 45, 47 |
| 30 | 49 | CoreMIDI input — USB + Network MIDI + source enumeration | `MIDIClient`, `MIDIInputPort`, source enumeration, marshal hits to MainActor; MIDINetworkSession enabled (`.anyone` dev, `.hostInitiated` release); device-add/remove notifications | `MIDI/MIDIInputManager.swift`, `MIDITransport.swift`, `NetworkMIDISession+Setup.swift`, `GMDrumMapper.swift` | Manual: real/virtual MIDI source → iPad app sees notes → highway responds with low latency; repeat in iPad-app-on-Mac mode where available | 32, 42 |
| 31 | 50 | BLE MIDI pairing + Settings MIDI device picker | Settings → "Pair Bluetooth MIDI" → CABTMIDICentralViewController; list USB + Network sources by name + UID; auto-reconnect; "All Sources" toggle; activity LED on note-on | `Features/Settings/MIDIDevicePicker.swift`, `BluetoothMIDIPairing.swift`, `Audio/MIDIActivityLED.swift` | Manual: BLE pad pairs + streams notes; pick a device → kill app → relaunch → still selected | 26, 49 |
| 32 | 51 | Accessibility pass — VoiceOver labels + reading order | Every interactive element + every card labeled; pads have hints; reading order makes sense; drops grid uses combined elements per cell | (all feature views) | Manual: real VoiceOver navigation across every tab; Accessibility Inspector clean | 36, 41, 43, 44, 45, 50 |
| 33 | 52 | Reduced Motion + Dynamic Type pass | Honor `accessibilityReduceMotion`; cross-fades replace motion; verify AX3 text scaling end-to-end | (all feature views) | Manual: toggle Reduce Motion → animations cross-fade; toggle AX3 → no clipping | 51 |
| 34 | 53 | iPad app on Mac compatibility polish | Keyboard shortcuts (Cmd+1..5 tabs, Cmd+R restart, Space play/pause, L loop, C click); pointer/touch alternatives where supported; verify full-screen/window behavior when the iPad app runs on Apple silicon Mac | `App/SP808KillaApp.swift`, per-feature view modifiers | Manual: run "My Mac (Designed for iPad)" where available; shortcuts respond; UI remains exact and usable | 24, 41 |
| 35 | 54 | App icon + launch screen | 1024×1024 master + Asset Catalog set; SwiftUI launch screen matching v0.3 visual identity | `Resources/Assets.xcassets/AppIcon.appiconset`, `App/LaunchScreen.swift` | Visual review against v0.3 reference | 25 |
| 36 | 55 | Snapshot test suite + CI integration | swift-snapshot-testing SPM dep; baseline images committed; runs in CI | `Tests/Snapshot/*.swift`, `Package.swift` | CI green; snapshot regression fails build | 36, 37, 38 |
| 37 | 56 | XCUITest UI smoke suite | Tab nav, drop reveal, settings round-trip, builder load-into-player | `SP808KillaUITests/*.swift` | CI runs UI tests on iPad simulator; Apple silicon Mac click-through remains manual unless CI supports that destination | 24, 38, 41, 45, 50 |
| 38 | 57 | Manual smoke checklist for native (iPad + iPad app on Mac) | `docs/testing/manual-smoke.md` extended with iPad + Apple silicon Mac sections, per-MIDI-transport coverage | `docs/testing/manual-smoke.md` | Single checklist Markdown; aliases the existing web smoke doc | 49, 50, 53 |
| 39 | 58 | Privacy + entitlements audit + ASC privacy label | Verify Info.plist usage descriptions; capabilities complete; draft "Data Not Collected" privacy label | `Info.plist`, `SP808Killa.entitlements`, `docs/app-store/privacy-label.md` | TestFlight build accepted by ASC with drafted label | 50 |
| 40 | 59 | App Store Connect record + screenshots + 30 s preview | Populate ASC; capture 4-6 screenshots per device class; record preview video | `docs/app-store/{screenshots,preview-script.md}` | Record reaches "Ready for Review" state | 54, 57, 58 |
| 41 | 60 | TestFlight build + external testers + final smoke | Upload archive; invite ≥3 external testers via public link; collect smoke notes | (uploads + tracking, no code) | TestFlight build accepted; ≥3 testers complete a session; smoke passes | 59 |

## Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **Audio latency unacceptable to drummers** (>15 ms felt) | Medium | High | `setPreferredIOBufferDuration(0.005)`; expose `audioLatencyOffsetMs` user calibration in Settings; ship a calibration tone in Phase 10. |
| **MIDI threading bug → dropped notes / UI hangs** | Medium | High | Strict MainActor marshalling; single receive callback path; GMDrumMapper unit tested; manual stress with rapid double-strokes. |
| **iPad app on Mac diverges from iPad hardware** (audio output / MIDI behavior / windowing) | Medium | Medium | Test iPad hardware first; smoke Apple silicon Mac compatibility before verifying App Store Connect Mac availability; treat divergence as P0 in #53. |
| **App Store rejection on entitlements / privacy** | Low | Medium | Pre-flight audit in #58; "Data Not Collected" label = simplest review path. |
| **Voxel art / drum sound licensing not redistributable** | Medium | High | Ambiguity A2 + A4 resolved before Phase 10. Fallback: re-synthesize or replace assets before submission. |
| **Highway perf drops on iPad 6 / mini 5 at 60 Hz** | Low | Medium | Profile in #40 on oldest supported device. Fall back to 60 Hz cap on non-ProMotion and lower particle counts if needed. |
| **Network MIDI doesn't surface `Drumrot Test Source`** | Low | Low | Bonjour `_apple-midi._udp` declared; MIDINetworkSession `.anyone` connection policy in dev. |
| **BLE MIDI pairing or CoreMIDI behaves differently when iPad app runs on Mac** | Medium | Medium | Verify USB/Network/BLE separately on iPad hardware and Apple silicon Mac; if Mac cannot meet MIDI requirements, mark Mac availability as unsupported for v1. |
| **App rejected because parody names / portraits resemble trademarked characters** | Low | High | Pre-submit content review (Ambiguity A5). Revise any direct parodies. |
| **Drum trainer fundamentally requires hardware most reviewers don't have** | Medium | Medium | Build / Drops / Library / Progress all work without MIDI → reviewers can navigate. App description states MIDI hardware required for Play. |
| **Workflow drift: someone wraps WKWebView "as a shortcut"** | Low | High | Decision D5/D6 explicit. Adding WKWebView = new architecture decision + fresh planning round. |
| **iCloud sync expected by users, not implemented in v1** | Medium | Low | App Store description explicitly says "per-device progress in v1." v1.1 backlog item. |
| **Custom lesson MIDI imports use SMPTE timing → silent failure** | Low | Medium | Parser rejects SMPTE explicitly with a user-facing error sheet. Tested in #47. |

## v1.1 backlog (deferred from v1)

- iPhone build (portrait UI, smaller highway, single-finger pads).
- Stage Manager + Split View + Slide Over.
- Apple Pencil hover preview on Drops grid; scribble in Builder coach notes.
- iPad-native UI rethink (sidebar nav, larger pads, sheet-based reveal).
- Native Mac / Mac Catalyst build (menu bar, AppKit-flavored controls, Mac preferences window) if the iPad app on Mac path is not good enough.
- iCloud / CloudKit sync of drops + scores + achievements across devices.
- Web → iPad progress import (one-shot localStorage export + iPad import flow).
- Localizations (Spanish, Japanese, Korean at minimum).
- Crash reporting (MetricKit or TelemetryDeck) — would change privacy label.
- Touch-pad input mode (on-screen 6-pad layout) as a secondary input alongside MIDI.
- Apple Watch companion — show current lesson, log hits via accelerometer.
- Roll-detection (multi-note rolls + flams) extending the scoring engine.
- New drumrots beyond the existing 31.
- Custom user samples (replace kick / snare / etc. via file import).
- Multiplayer / leaderboards (would change privacy label).
- watchOS / visionOS / tvOS surfaces.

## Verification plan

- **Static:** `xcodebuild test` (unit + snapshot + XCUITest) on every PR via GitHub Actions.
- **Domain parity:** XCTest fixtures compare lesson note output, achievement ids, drumrot ids/stats, drop math, MIDI parser/exporter byte-for-byte against the web's `js/*` data.
- **Runtime:** deterministic playback + scoring tests with injected `TestClock`.
- **Persistence:** write / read / relaunch / corrupt-row tests.
- **Sim:** iPad sim run, click through new features per phase.
- **Apple silicon Mac:** "My Mac (Designed for iPad)" run where available, same click-through.
- **Real iPad:** end of Phase 3 (first MIDI device), end of Phase 6 (first full lesson), Phase 10 (TestFlight).
- **MIDI device matrix:** USB / Network / BLE exercised explicitly in Phase 8 and Phase 10.
- **failure-postmortem** runs after every manual smoke, pass or fail (workflow rule).

## Data safety risks

- Do not commit `.DS_Store`, Xcode user state, derived data, or local signing files.
- Do not commit generated voxel PNGs outside `ios/SP808Killa/Resources/Assets.xcassets/`.
- Do not commit tester progress files exported via the debug Settings tool.
- Do not hard-code signing team ids, certificates, or provisioning profile paths.
- Do not commit any audio files unless their license is documented.

## Non-goals

- Adding new drumrots, lessons, or content.
- WKWebView/JavaScriptCore shipping architecture.
- Separate macOS/Catalyst target in v1.
- iPhone target in v1.
- Cross-device sync or web→iPad progress migration in v1.

## Glossary

- **iPad app on Mac** — Apple's Apple silicon Mac path for running compatible iPhone/iPad apps from the Mac App Store without adding a separate Mac target.
- **GM** — General MIDI; the standard drum mapping (kick = 36, snare = 38, hihat closed = 42, etc.).
- **Highway** — the scrolling lane view of upcoming notes in a rhythm game.
- **Holofoil** — the OG-card hover sweep effect on v0.3 cards.
- **OG** — rare gold-foil drop variant; 5% bonus chance flat across tiers.
- **ProMotion** — Apple's 120 Hz display tech on iPad Pro models.
- **Strike line** — the visual line where the player must hit the note.
- **SP-808** — the visual / brand identity of the app.
