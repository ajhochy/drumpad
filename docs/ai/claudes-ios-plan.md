# Claude's iPad / Mac Catalyst port plan (v1)

> Preserved for side-by-side comparison with Codex's plan. Written by Claude (Opus 4.7) on 2026-05-20 after one round of upfront-alignment questions. Locked decisions from that round: Mac Catalyst · MIDI hard requirement · App Store public release · straight visual port preserving current IA + v0.3 card chrome. The user later revised the platform direction toward iPad-first with iPad-on-Mac availability instead of Catalyst — that revised direction lives in [current-plan.md](current-plan.md). This file keeps Claude's Catalyst version intact so the two approaches can be compared cleanly.

## Status

Active proposal — supersedes the v0.3 card-system plan (shipped via PR #5 / #8 / #10). The web app at `index.html` is **frozen at v0.3** and remains the reference implementation. The native app is a **clean SwiftUI + AVAudioEngine + CoreMIDI rewrite**, not a wrapped WebView. The two surfaces are intentionally independent — no progress migration in either direction.

## Goal

Ship drumrot / SP-808 KILLA as a native Apple-platform app — **one SwiftUI codebase, one App Store listing**, running on iPadOS 17+ (primary target) and macOS 14+ via **Mac Catalyst** — with real **CoreMIDI** input from a hardware drum controller and a visual experience that preserves the existing v0.3 card chrome, 6-lane highway, and 5-tab information architecture.

## Locked decisions (from upfront orchestrator alignment)

| Decision | Choice | Reason on record |
|---|---|---|
| Platform | **Mac Catalyst** (one SwiftUI target, iPad + Mac) | User chose: single Swift codebase ships both, single App Store listing. |
| MIDI on iPad | **Hard requirement in v1** | Drum trainer is the core; CoreMIDI bridge ships day one. |
| Distribution | **App Store, full public release** | Free app, public review. |
| UX bar | **Straight visual port** — preserve current IA + v0.3 card chrome | Stage Manager / Pencil / multitasking deferred to v1.1. |

## In scope (v1)

- Native iPadOS app, **landscape-locked**, iPad 6th-gen and newer (anything running iPadOS 17).
- Mac Catalyst build (same target, sandboxed, "Scaled to match iPad" — no Mac-specific UI rework).
- All five existing tabs: **Play**, **Library**, **Progress**, **Build**, **Drops**.
- All 31 existing drumrots across all 7 tiers, with the existing voxel art, v0.3 card chrome, OG holofoil, tier system, and drop-roll math (5% OG flat bonus + existing tier weights — math identical to web).
- All 8 existing built-in lessons + custom builder lessons + MIDI-file-import lessons.
- All 18 existing achievements with the existing toast → drop-roll sequencing.
- Hardware MIDI input via USB-C / Lightning-camera-kit / Bluetooth MIDI / Network MIDI (CoreMIDI).
- Drum trainer (6-lane highway + scoring + count-in + metronome + loop) running at 60 Hz everywhere and 120 Hz on ProMotion iPads.
- AVAudioEngine-synthesized drums and click (same character as the Web Audio synthesis in `js/audio.js`).
- MIDI file import (`.mid` / `.midi`) and export (`sp808-pattern.mid`).
- 16/32-step beat builder.
- SwiftData persistence for scores, achievements, tiers (Steady/Grooving/Locked/Killing It), play days, extra lessons, collection, builder pattern, and settings.
- VoiceOver complete, Reduced Motion honored, Dynamic Type supported.
- App Store distribution: free, no IAP, "Data Not Collected" privacy label.

## Out of scope (v1) — see v1.1 backlog at the bottom

- **iPhone** build. The same target accepts iPhone, but the UI is iPad-landscape-shaped; iPhone portrait deserves its own design pass.
- Stage Manager / Split View / Slide Over.
- Apple Pencil interactions on the Build tab.
- iPad-native UI rethink (sidebar nav, larger pads, sheet-based reveal).
- Mac "Optimized for Mac" build (menu bar items, AppKit-flavored controls, Mac-typical preferences window).
- iCloud / CloudKit sync of drops, scores, or progress across devices.
- Progress migration from the web app's `localStorage`.
- Localizations beyond English.
- In-app purchase, ads, telemetry, crash reporting service.
- New drumrots, new lessons, or any content additions.
- Touch-only input mode (on-screen drum pads as primary input).
- watchOS / visionOS / tvOS.
- A WebView wrapper as the shipping architecture (temporary harnesses during development are fine; shipping is native).

## Hard constraints

- **No background audio.** App does **not** request the `audio` `UIBackgroundModes` entitlement — drum trainer is foreground-only. Simplifies App Review.
- **MIDI threading discipline.** CoreMIDI callbacks run on a high-priority real-time thread; UI updates must marshal to MainActor. (Swarm: #1 cause of dropped notes / hangs in indie MIDI apps.)
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
| iPad-native UI vs visual continuity | Sidebar + sheets | TabView mirroring web tabs | TabView + landscape lock (user chose straight port). |
| Catalyst "Optimized for Mac" vs "Scaled" | Mac AppKit feel | iPad-shaped on Mac | Scaled v1 → Optimized v1.1. |
| Audio fidelity vs simplicity | AudioUnit graph | AVAudioEngine | AVAudioEngine — sufficient for sample / synth playback, far less code. |
| Highway fidelity vs build cost | Metal | SpriteKit | SpriteKit. 60-120 Hz with ~20 active sprites is well within budget. |
| Preserve JS field names in storage vs cleaner typed model | Mirror JS keys | Idiomatic Swift naming | Idiomatic Swift; document the mapping in `Persistence/SchemaMapping.md`. |

## Cheapest version that proves the idea

Before the full plan runs, **issues #20–#21 build a 1-screen prototype**:

1. New Xcode project, single target with Catalyst capability checked.
2. SwiftUI `ContentView` shows one hard-coded TIER_GOD/OG drumrot card.
3. AVAudioEngine plays a single drum sample on tap.
4. CoreMIDI enumerates connected sources and logs them to the debug console.

If this builds on iPad sim AND "My Mac (Designed for iPad)" AND plays a sample AND lists `scripts/midi-pulse.mjs`'s virtual MIDI port, the architecture is proven. Everything after is volume, not risk.

## Clarification interview

**Round 1 (orchestrator upfront alignment, complete):**
- Platform → Mac Catalyst.
- MIDI → hard requirement v1.
- Distribution → App Store (public, free).
- UX → straight visual port; iPad polish in v1.1.

**Round 2 skipped** — remaining choices (minimum OS, monetization, accessibility scope, localization, privacy posture, audio engine, render engine, persistence layer) are reasonable-default decisions made by the planner below. User can redirect any at issue-review time without re-interview.

## Decisions made by the planner (redirect any of these before issue creation)

| # | Decision | Rationale | Cost to flip later |
|---|---|---|---|
| D1 | **Minimum: iPadOS 17.0 + macOS 14.0 (Sonoma)** | Unlocks SwiftData, Swift Charts, `.scrollPosition`, native ProMotion 120 Hz APIs. Cuts iPad 5, iPad mini 4, 2016 iPad Pro. Covers ~95% of in-warranty iPads. | Low (Info.plist + a few `@available` checks). |
| D2 | **Free app, no IAP, no ads** | Mirrors current web posture. Simplest App Review path. | Medium (adds StoreKit + receipts). |
| D3 | **Accessibility complete in v1** | VoiceOver labels, Reduced Motion, Dynamic Type. Cheaper to bake in than retrofit. | High (retrofitting doubles the work). |
| D4 | **English only in v1; `Localizable.xcstrings` scaffolded** | Faster ship. No translation pipeline cost. | Low. |
| D5 | **Zero telemetry / analytics / crash reporting** | "Data Not Collected" privacy label = simplest App Review. | Low. |
| D6 | **Audio: AVAudioEngine + synthesized buffers** (matches web's Web Audio synthesis) | First-party, well-documented, sub-10 ms output latency on iPad. AudioUnits is overkill for the existing sound palette. | Medium (engine swap is a contained rewrite of `Core/Audio/`). |
| D7 | **Highway render: SpriteKit via SwiftUI `SpriteView`** | Hits 120 Hz without Metal-level code volume. Easy to mix with SwiftUI overlays. | Medium (re-host in Metal or Canvas later if perf demands). |
| D8 | **Persistence: SwiftData** (one model per concern; JSON snapshot for debug import/export) | iOS 17+ default. Less boilerplate than Core Data. | High (data migration). |
| D9 | **Bundle id `com.visaliacrc.drumrot`** (placeholder) | Matches user's `visaliacrc.com` domain. Rename pre-submit. | Trivial pre-submit; high post-submit. |
| D10 | **Single Xcode target with Catalyst capability checked** (not separate iPad + macOS targets) | One build, two destinations. Apple's official guidance. | Medium (project split later). |
| D11 | **No localStorage migration from web** | Different surface; different progress. iPad install = fresh save. Documented in store description. | Medium (would need a web export → iPad import flow). |
| D12 | **App name on store: "drumrot — SP-808 KILLA"** (placeholder) | Matches existing branding. Confirm pre-submit. | Low pre-submit; medium post-submit. |
| D13 | **Repository layout: new top-level `ios/` directory holding the Xcode project, sibling to existing `js/` and `art/`** | Keeps web app untouched; one git repo. | Trivial. |
| D14 | **Catalyst UI mode: Scaled to match iPad, not Optimized for Mac** | Single layout pass; matches "straight port" decision. v1.1 considers Optimized. | Medium (Optimized rework is a separate pass). |
| D15 | **iPhone target left disabled in v1** | Landscape-locked iPad UI doesn't compose to iPhone portrait without redesign. iPhone is v1.1. | Low (toggle in target settings + new layout work). |

## Known ambiguities (resolve before Phase 7 — App Store submission)

- **A1.** Whether the user has an Apple Developer Program enrollment already, or whether enrollment is part of the v1 timeline.
- **A2.** Whether the existing **drum sounds** (synthesized at runtime by `js/audio.js` from Web Audio oscillators / noise buffers) translate 1:1 to AVAudioEngine synthesis, OR whether v1 ships pre-rendered sample WAVs. If WAVs: source/license must be confirmed before submission.
- **A3.** Final **app icon**. Current web favicon is a 404 (open issue [#6](https://github.com/ajhochy/drumrot/issues/6) on the web side). App Store requires a 1024×1024 PNG plus a full Asset Catalog set.
- **A4.** Voxel-art licensing — whether the 31 portraits in `art/drumrots/` are original, commissioned, or sourced, and whether they are commercially redistributable on the App Store.
- **A5.** Whether any drumrot names / portraits read as direct parody of trademarked characters (review pre-submission).

These five surface before Phase 7. They don't block any earlier phase.

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

### Mac Catalyst review + entitlements (audio / MIDI apps)
- **Entitlements declared up front** in `*.entitlements` — CoreMIDI + AVAudioEngine + USB + Bluetooth + sandbox file paths. Missing entitlements = sandbox denial before review even starts.
- **AVAudioSession `.playback + .duckOthers`** works on iOS but diverges on Mac Catalyst; both interruption flows must be tested.
- **No background audio entitlement needed for v1** — drum trainer is foreground-only.
- **"Optimized for Mac" vs "Scaled to match iPad"** — v1 uses Scaled; v1.1 considers Optimized.
- **Privacy nutrition label "Data Not Collected"** qualifies for the simplest and fastest review.
- **Catalyst's WWDC presence has plateaued** (last major: WWDC21 *"Qualities of a great Mac Catalyst app"*) — platform is stable, not deprecated.

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
- [Mac Catalyst — Qualities of a great Mac Catalyst app (WWDC21)](https://developer.apple.com/videos/play/wwdc2021/10053/)

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
- **Single SwiftUI target** with **Mac Catalyst capability checked**.
- Deployment: **iPadOS 17.0** (primary) and **macOS 14.0** (Catalyst).
- iPhone target box: **unchecked** in v1 (v1.1 backlog).
- `UISupportedInterfaceOrientations~ipad = LandscapeLeft, LandscapeRight` (landscape-locked iPad).
- Mac Catalyst window: minimum size 1366 × 1024 (preserves iPad landscape proportions).
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
- **CoreMIDI** for device enumeration and note input (Phase 12).
- **UniformTypeIdentifiers** (`UTType.midi`) + document picker / exporter for MIDI file I/O (Phase 11).
- **SwiftData** for persistence (Phase 2).
- **XCTest** + **XCUITest** + **swift-snapshot-testing** for tests.

### Audio engine details
- `AVAudioEngine` → `AVAudioMixerNode` (main) → output.
- Voices: one `AVAudioPlayerNode` per drum + one for the click.
- Each voice loads a synthesized PCM buffer at engine start (kick: oscillator 120 Hz → 40 Hz; snare/tom: filtered noise; cymbals: filtered noise; click: square accent / non-accent). Matches the character of `js/audio.js` 1:1.
- `AVAudioSession` category `.playback`, mode `.default`, options `.mixWithOthers`. `setPreferredIOBufferDuration(0.005)` where the device allows it.
- Interruption handler (iOS): on `.began` → pause + mute. On `.ended` with `.shouldResume` → restart.
- Route change handler: restart on `.oldDeviceUnavailable`.
- Mac Catalyst: AVAudioSession is a no-op on macOS; engine still works. Test Now-Playing media-key behavior separately.

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
- SwiftData models map to web `localStorage` keys per `SchemaMapping.md`:

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
- iPad: landscape-locked. Mac: window-resizable above the 1366×1024 minimum.
- Reveal overlay: `.fullScreenCover` on iPad, centered modal on Mac Catalyst.
- Settings: gear in top-right (Mac: also a Cmd+, keyboard shortcut).
- Mac-only keyboard shortcuts: Cmd+1..5 switch tabs; Cmd+R restart current lesson; Spacebar play/pause; L toggle loop; C toggle click.

### Accessibility
- **VoiceOver:** every card emits `accessibilityLabel("\(name), tier \(tier), number \(num). Stats: bpm \(bpm), groove \(groove), power \(power). \(state.description)")`. Pads emit `accessibilityLabel("\(lane) pad")` + `accessibilityHint("Double-tap to play")`. Drops grid combines child elements per cell.
- **Reduced Motion** (`@Environment(\.accessibilityReduceMotion)`): disables holofoil sweep, drop-roll spin, highway camera shake, reveal slide-in. Replaced with cross-fades.
- **Dynamic Type:** every text view uses `.font(.system(... style:))` not fixed pt. AX3 verified.
- **Switch Control:** every interactive element reachable.
- **Increased Contrast:** alternate tier badge colors meet AA contrast.
- **Audio latency offset** (`AppSettings.audioLatencyOffsetMs`): user-tunable -50…+50 ms for BLE headphones / hearing aids.

### App Store compliance
- Apple Developer Program enrollment ($99/yr; gated on Ambiguity A1).
- App Store Connect record: name, subtitle, bundle id, age rating 4+, category Games > Music, screenshots (4-6 per device class), 30 s app preview video.
- **Privacy nutrition label: "Data Not Collected."**
- Required device capabilities: `audio-output`.
- Entitlements (`SP808Killa.entitlements`):
  - `com.apple.security.app-sandbox` = YES (Mac Catalyst)
  - `com.apple.security.device.bluetooth` = YES (BLE MIDI on Mac)
  - `com.apple.security.device.usb` = YES (USB MIDI on Mac)
  - `com.apple.security.network.client` = YES (Network MIDI on Mac)
  - `com.apple.security.files.user-selected.read-only` = YES (MIDI file import)
- Info.plist usage descriptions:
  - `NSBluetoothAlwaysUsageDescription` = "drumrot uses Bluetooth to connect to wireless MIDI drum controllers."
  - `NSLocalNetworkUsageDescription` = "drumrot uses your local network to receive MIDI from network MIDI sources."
  - `NSBonjourServices` = `["_apple-midi._udp"]` (required for iOS 14+ Network MIDI discovery).
- No background modes declared.
- No tracking, no IDFA, no SKAdNetwork.
- Mac App Sandbox: enabled. No `com.apple.security.device.audio-input` (we don't record audio).

## Implementation phases

| Phase | Theme | Issues | Exit criteria |
|---|---|---|---|
| 0 | Project setup, asset pipeline, CI | #20–#23 | Xcode project builds + runs blank tab UI on iPad sim and Mac Catalyst; CI green; 31 voxel PNGs in Asset Catalog. |
| 1 | Visual chassis & navigation | #24–#27 | All 5 tabs present, blank content, design system primitives exist, settings + SwiftData container working. |
| 2 | Domain parity (data + math) | #28–#31 | Lessons / achievements / drumrots / roll math match web byte-for-byte (parity tests). |
| 3 | Audio + AVAudioEngine | #32–#33 | Tap a pad → synthesized drum plays; metronome accents distinguishable; interruption handling works on both platforms. |
| 4 | Persistence + AppStore | #34–#35 | Scores / achievements / collection / settings persist across relaunch; corrupt-row recovery logs error and defaults. |
| 5 | Drops + card chrome + reveal | #36–#38 | Drops grid renders 31 cells; locked + collected + OG variants pixel-correct; reveal overlay queues + auto-dismisses. |
| 6 | Playback + scoring + Play tab UI | #39–#42 | SpriteKit highway scrolls; full lesson plays end-to-end; score / combo / accuracy match web rules. |
| 7 | Library + Progress + Builder | #43–#46 | All 3 tabs functional; builder loads into player; achievement triggers reach drop-roll. |
| 8 | MIDI file I/O + CoreMIDI hardware input | #47–#50 | Import `.mid` → custom lesson; export `sp808-pattern.mid`; USB / Network / BLE MIDI input drives the highway. |
| 9 | Accessibility + Catalyst polish + responsive | #51–#54 | VoiceOver-complete; Reduced Motion honored; Mac shortcuts work; window minimum size enforced. |
| 10 | Tests + App Store prep + TestFlight | #55–#60 | Snapshot suite green; manual smoke checklist captured; ASC record populated; TestFlight build accepted; submission queued. |

## Issue table

(Numbering picks up from `#20` to leave room for any open web-side follow-ups like favicon `#6`.)

| Order | # | Title | Goal | Likely files | Tests / evaluation | Deps |
|---|---|---|---|---|---|---|
| 1 | 20 | Bootstrap `ios/` Xcode project + Catalyst capability | Create `ios/SP808Killa.xcodeproj`, single SwiftUI target, Catalyst capability checked, deployment iPadOS 17 / macOS 14, landscape-lock iPad, Mac min size 1366×1024 | `ios/SP808Killa/App/SP808KillaApp.swift`, `Info.plist`, `.entitlements`, `.gitignore` | App builds for iPad sim and "My Mac (Designed for iPad)"; both launch a blank view | — |
| 2 | 21 | Hello-world prototype: card + sample + MIDI enumeration | One screen: hard-coded TIER_GOD/OG card, plays a synthesized snare on tap (AVAudioEngine), prints connected MIDI sources to debug console | `Features/Drops/PrototypeCard.swift`, `Audio/DrumAudioEngine.swift` (stub), `MIDI/MIDIInputManager.swift` (stub) | Runs on iPad sim + Mac Catalyst; MIDI sources visible when `scripts/midi-pulse.mjs` is running | 20 |
| 3 | 22 | Asset pipeline — voxel PNGs + fonts | Add `scripts/export-drumrots-png.mjs` that emits PNG @1x/@2x/@3x from `art/drumrots/*.webp`; populate Asset Catalog; bundle TTFs + declare `UIAppFonts` | `scripts/export-drumrots-png.mjs`, `Resources/Assets.xcassets/drumrots/`, `Resources/Fonts/` | Asset catalog contains 31 image sets; SwiftUI preview shows correct font | 20 |
| 4 | 23 | CI on GitHub Actions — xcodebuild test | `.github/workflows/ios-build.yml` runs `xcodebuild test` on macOS runner | `.github/workflows/ios-build.yml` | Action passes on a PR | 20 |
| 5 | 24 | Root TabView + 5 placeholder tabs | App shell with Play / Library / Progress / Build / Drops, SF Symbol icons, landscape lock | `App/SP808KillaApp.swift`, `App/RootView.swift`, `Features/*/EmptyView.swift` | Manual: tap each tab on iPad sim + Mac; landscape stays | 20 |
| 6 | 25 | Design system primitives — palette, typography, tier tokens | Centralize colors, fonts, tier gradients; mirror `css/cards.css` tokens; LED, Pad, BpmStepper primitives | `DesignSystem/Theme/Palette.swift`, `Typography.swift`, `Tiers.swift`, `Controls/*.swift` | `#Preview` shows each component; tier badge matches `cards.css` reference | 22 |
| 7 | 26 | Settings tab + SwiftData container + AppSettings | Gear icon → sheet with MIDI device picker placeholder, audio offset slider, haptics toggle, reduced-motion toggle, debug import/export buttons | `Features/Settings/SettingsView.swift`, `Data/ModelContainer+App.swift`, `Data/Models/AppSettings.swift` | Toggle a setting → kill app → reopen → setting persists | 20 |
| 8 | 27 | AppStore (ObservableObject) + dependency injection skeleton | `@MainActor` AppStore, env-injected, owns SwiftData context + AudioEngine + MIDIInputManager handles | `App/AppStore.swift` | Unit test: AppStore initializes with default state; injection compiles | 26 |
| 9 | 28 | Port domain models + Drumrots.json + parity tests | `Drumrot`, `DrumrotTier` (7 cases), `TierWeights`, `DropRoller`; load `Drumrots.json` (mirror of `js/drumrots.js`) | `Domain/Drumrot.swift`, `DrumrotTier.swift`, `TierWeights.swift`, `DropRoller.swift`, `Resources/Content/Drumrots.json` | XCTest: 31 entries, 7 tiers, ids match web; injected-RNG roll distribution within ±2σ; OG bonus = 5% | 26 |
| 10 | 29 | Port lessons + Lessons.json + parity tests | 8 built-in lessons + LANES + LANE_LABEL + LANE_COLORS + `LessonFactory` + `LessonMeta` | `Domain/Lesson.swift`, `LessonFactory.swift`, `DrumLane.swift`, `Resources/Content/Lessons.json` | XCTest: lesson note counts/order match web; tier pips ordering preserved | 28 |
| 11 | 30 | Port achievements + Achievements.json + AchievementEngine | 18 achievements with category metadata + `AchievementEngine` that triggers from hit/pass/builder/MIDI events | `Domain/Achievement.swift`, `AchievementEngine.swift`, `Resources/Content/Achievements.json` | XCTest: 18 ids match web; each rule fires under the right synthetic event sequence | 28 |
| 12 | 31 | Port scoring + streak + tempo tier + stars | `ScoringEngine`, `Streak`, `PracticeTier` (Steady / Grooving / Locked / Killing It), star thresholds (≥95/80/50%) | `Domain/ScoringEngine.swift`, `Streak.swift`, `PracticeTier.swift` | XCTest: perfect/great/good/miss boundary tests; combo multiplier; star calc | 28 |
| 13 | 32 | AVAudioEngine drum synth — kick/snare/tom/crash/hihat/ride | Synthesize matching the web Web Audio character; one `AVAudioPlayerNode` per voice; preloaded buffers; `play(lane:velocity:)` | `Audio/DrumAudioEngine.swift`, `VoiceSynth.swift`, `Resources/Sounds/` (if buffers cached to disk) | Manual: pad tap → distinct sound per lane; latency ≤ 10 ms measured on iPad | 27 |
| 14 | 33 | Audio session category + interruption + route change handling | `.playback + .mixWithOthers`; interruption (iOS) + route change handlers; click synth (accent + non-accent square) | `Audio/AudioSessionManager.swift`, `ClickSynth.swift` | Manual: phone call interrupts + resumes; headphones unplug pauses; Mac media keys behave | 32 |
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
| 30 | 49 | CoreMIDI input — USB + Network MIDI + source enumeration | `MIDIClient`, `MIDIInputPort`, source enumeration, marshal hits to MainActor; MIDINetworkSession enabled (`.anyone` dev, `.hostInitiated` release); device-add/remove notifications | `MIDI/MIDIInputManager.swift`, `MIDITransport.swift`, `NetworkMIDISession+Setup.swift`, `GMDrumMapper.swift` | Manual: `scripts/midi-pulse.mjs` running → iPad app sees notes → highway responds; same on Mac Catalyst with USB pad | 32, 42 |
| 31 | 50 | BLE MIDI pairing + Settings MIDI device picker | Settings → "Pair Bluetooth MIDI" → CABTMIDICentralViewController; list USB + Network sources by name + UID; auto-reconnect; "All Sources" toggle; activity LED on note-on | `Features/Settings/MIDIDevicePicker.swift`, `BluetoothMIDIPairing.swift`, `Audio/MIDIActivityLED.swift` | Manual: BLE pad pairs + streams notes; pick a device → kill app → relaunch → still selected | 26, 49 |
| 32 | 51 | Accessibility pass — VoiceOver labels + reading order | Every interactive element + every card labeled; pads have hints; reading order makes sense; drops grid uses combined elements per cell | (all feature views) | Manual: real VoiceOver navigation across every tab; Accessibility Inspector clean | 36, 41, 43, 44, 45, 50 |
| 33 | 52 | Reduced Motion + Dynamic Type pass | Honor `accessibilityReduceMotion`; cross-fades replace motion; verify AX3 text scaling end-to-end | (all feature views) | Manual: toggle Reduce Motion → animations cross-fade; toggle AX3 → no clipping | 51 |
| 34 | 53 | Mac Catalyst polish | Keyboard shortcuts (Cmd+1..5 tabs, Cmd+R restart, Space play/pause, L loop, C click); cursor support on Drops grid (hover preview); window min size enforced; test interruption on Mac | `App/SP808KillaApp.swift`, per-feature view modifiers | Manual: build "My Mac (Designed for iPad)"; resize window; shortcuts respond; hover preview shows | 24, 41 |
| 35 | 54 | App icon + launch screen | 1024×1024 master + Asset Catalog set; SwiftUI launch screen matching v0.3 visual identity | `Resources/Assets.xcassets/AppIcon.appiconset`, `App/LaunchScreen.swift` | Visual review against v0.3 reference | 25 |
| 36 | 55 | Snapshot test suite + CI integration | swift-snapshot-testing SPM dep; baseline images committed; runs in CI | `Tests/Snapshot/*.swift`, `Package.swift` | CI green; snapshot regression fails build | 36, 37, 38 |
| 37 | 56 | XCUITest UI smoke suite | Tab nav, drop reveal, settings round-trip, builder load-into-player | `SP808KillaUITests/*.swift` | CI runs UI tests on iPad sim + Mac destination | 24, 38, 41, 45, 50 |
| 38 | 57 | Manual smoke checklist for native (iPad + Mac) | `docs/testing/manual-smoke.md` extended with iPad + Mac sections, per-MIDI-transport coverage | `docs/testing/manual-smoke.md` | Single checklist Markdown; aliases the existing web smoke doc | 49, 50, 53 |
| 39 | 58 | Privacy + entitlements audit + ASC privacy label | Verify Info.plist usage descriptions; entitlements complete; draft "Data Not Collected" privacy label | `Info.plist`, `SP808Killa.entitlements`, `docs/app-store/privacy-label.md` | TestFlight build accepted by ASC with drafted label | 50 |
| 40 | 59 | App Store Connect record + screenshots + 30 s preview | Populate ASC; capture 4-6 screenshots per device class; record preview video | `docs/app-store/{screenshots,preview-script.md}` | Record reaches "Ready for Review" state | 54, 57, 58 |
| 41 | 60 | TestFlight build + external testers + final smoke | Upload archive; invite ≥3 external testers via public link; collect smoke notes | (uploads + tracking, no code) | TestFlight build accepted; ≥3 testers complete a session; smoke passes | 59 |

## Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **Audio latency unacceptable to drummers** (>15 ms felt) | Medium | High | `setPreferredIOBufferDuration(0.005)`; expose `audioLatencyOffsetMs` user calibration in Settings; ship a calibration tone in Phase 10. |
| **MIDI threading bug → dropped notes / UI hangs** | Medium | High | Strict MainActor marshalling; single receive callback path; GMDrumMapper unit tested; manual stress with rapid double-strokes. |
| **Mac Catalyst diverges from iPad** (audio interruption / MIDI behavior) | Medium | Medium | Test both targets every phase; treat divergence as P0 in #53. |
| **App Store rejection on entitlements / privacy** | Low | Medium | Pre-flight audit in #58; "Data Not Collected" label = simplest review path. |
| **Voxel art / drum sound licensing not redistributable** | Medium | High | Ambiguity A2 + A4 resolved before Phase 10. Fallback: re-synthesize or replace assets before submission. |
| **Highway perf drops on iPad 6 / mini 5 at 60 Hz** | Low | Medium | Profile in #40 on oldest supported device. Fall back to 60 Hz cap on non-ProMotion and lower particle counts if needed. |
| **Network MIDI doesn't surface `Drumrot Test Source`** | Low | Low | Bonjour `_apple-midi._udp` declared; MIDINetworkSession `.anyone` connection policy in dev. |
| **BLE MIDI pairing UI looks iOS-shaped on Catalyst** | Medium | Low | Document and accept v1; polish v1.1. |
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
- Mac Catalyst "Optimized for Mac" build (menu bar, AppKit-flavored controls, Mac preferences window).
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
- **Mac Catalyst:** "My Mac (Designed for iPad)" run, same click-through.
- **Real iPad:** end of Phase 3 (first MIDI device), end of Phase 6 (first full lesson), Phase 10 (TestFlight).
- **MIDI device matrix:** USB / Network / BLE exercised explicitly in Phase 8 and Phase 10.
- **failure-postmortem** runs after every manual smoke, pass or fail (workflow rule).

## Data safety risks

- Do not commit `.DS_Store`, Xcode user state, derived data, or local signing files.
- Do not commit generated voxel PNGs outside `ios/SP808Killa/Resources/Assets.xcassets/`.
- Do not commit tester progress files exported via the debug Settings tool.
- Do not hard-code signing team ids, certificates, or provisioning profile paths.
- Do not commit any audio files unless their license is documented.

## Glossary

- **Catalyst** — Apple's compatibility layer that runs an iPad app as a Mac app from the same Swift target.
- **GM** — General MIDI; the standard drum mapping (kick = 36, snare = 38, hihat closed = 42, etc.).
- **Highway** — the scrolling lane view of upcoming notes in a rhythm game.
- **Holofoil** — the OG-card hover sweep effect on v0.3 cards.
- **OG** — rare gold-foil drop variant; 5% bonus chance flat across tiers.
- **ProMotion** — Apple's 120 Hz display tech on iPad Pro models.
- **Strike line** — the visual line where the player must hit the note.
- **SP-808** — the visual / brand identity of the app.

## Summary of Claude vs Codex comparison points (fill in once Codex's plan exists)

When comparing this plan against Codex's plan, the high-signal places to look:

1. **Platform / Mac strategy.** Catalyst (this plan) vs iPad-only-with-iPad-on-Mac (current-plan.md) vs native macOS rewrite vs PWA.
2. **Audio engine choice.** AVAudioEngine + synthesized buffers (this plan) vs AudioUnits / AVAudioPlayer / sampled WAVs.
3. **Highway renderer.** SpriteKit + SpriteView (this plan) vs Metal / Canvas / SwiftUI positioning / SceneKit.
4. **Persistence layer.** SwiftData (this plan) vs Core Data / JSON file / SQLite / GRDB.
5. **MIDI transport priority.** USB → Network → BLE (this plan) vs other orderings; whether Network MIDI is enabled by default.
6. **Project structure.** Single SwiftUI target with Catalyst checked (this plan) vs multi-target / Swift Package / monorepo.
7. **Issue count + atomicity.** 41 atomic issues here; compare against Codex's count and per-issue scope.
8. **Risk identification.** Which plan flags more concrete risks, especially around content licensing (drum samples, voxel art, parody naming).
9. **Accessibility scope from v1.** This plan ships full VoiceOver + Reduced Motion + Dynamic Type; compare whether Codex's plan defers any of these.
10. **Distribution / privacy posture.** "Data Not Collected" nutrition label (this plan) vs anything that adds telemetry.

## Completion checklist

- [x] Plan is written
- [x] Clarification interview completed (round 1 captured; round 2 skipped with rationale)
- [x] Acceptance criteria are concrete or listed under `## Known ambiguities`
- [x] Issues are atomic
- [x] Dependencies are clear (every issue lists `Deps` column)
- [x] Tests / evaluation are specified per issue
- [x] Data safety risks are documented
- [x] Prior-art swarm dispatched + synthesized
- [x] Locked decisions, planner decisions, and ambiguities surfaced separately
- [x] Risk register written
- [x] v1.1 backlog written
