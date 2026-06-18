---
date: 2026-05-21
repo: drumrot
tags: [decision, drumrot]
---

# Native iPadOS port direction (planning)

- Decided to build a **native Swift/SwiftUI iPadOS app**, distributed via App Store/TestFlight. WKWebView wrapping and pure-PWA paths are rejected.
- **Mac support path:** make the iPad app available on Apple silicon Macs where compatible. Do not create a separate Mac Catalyst/native Mac target in v1.
- **Why native over WebView wrapper:** Web MIDI API is not implemented in iPadOS Safari, so a wrapper can't deliver the v1 hard requirement (hardware MIDI input). Once we're writing native code for MIDI, JavaScriptCore-embedding the existing JS engine would add latency to the scoring path and bypass the whole point of going native — rejected.
- **MIDI = hard v1 requirement and main product requirement.** CoreMIDI bridge ships day one. Transport layering: USB → Network MIDI → BLE MIDI. Strict MainActor marshalling from the real-time receive callback.
- **Audio: AVAudioEngine with synthesized PCM buffers** (matches the character of `js/audio.js` Web Audio synthesis). `AVAudioPlayer` (one-player-per-voice) rejected — allocates per play, stutters under load. AudioUnits rejected as overkill.
- **Highway: SpriteKit via SwiftUI `SpriteView`.** SwiftUI `Canvas` rejected for 120 Hz with 20+ sprites + camera shake; Metal rejected as too much code volume for the win.
- **Persistence: SwiftData** (iOS 17+ default). JSON debug import/export retained for testers and for a future web → iPad migration tool.
- **UX: exact visual port** preserving the existing 5-tab IA, SP-808 chassis/readout styling, v0.3 card chrome, 6-lane highway, OG holofoil, Library, Progress, Build, Drops, and reveal overlay. Stage Manager, Apple Pencil, multitasking-aware audio, separate Mac build, iPhone target — all deferred to v1.1.
- **Low latency is vital.** Touch/MIDI input-to-sound and input-to-judgement latency must be measured on real iPad hardware before TestFlight/App Store readiness.
- **No iPhone in v1.** Landscape-locked iPad UI doesn't compose to iPhone portrait without redesign.
- **No background audio entitlement.** Foreground-only drum trainer simplifies App Review.
- **Privacy nutrition label: "Data Not Collected."** Zero telemetry / analytics / crash reporting in v1.
- **Web app frozen at v0.3.** Native app is a clean rewrite; no progress migration in either direction. Documented in App Store description.
- **Repo layout:** new top-level `ios/SP808Killa/` Xcode project, sibling to existing `js/` and `art/`. Web app untouched.
- Trade-offs accepted: native rewrite timeline for v1; two surfaces to maintain (web + native) until web is retired; localStorage progress doesn't carry over.
- Codex plan recorded in [docs/ai/codex-ios-plan.md](codex-ios-plan.md) with phase breakdown, issue table, risk register, and v1.1 backlog. User answered the strategic planning questions directly on 2026-05-21. **(Superseded 2026-05-26: this plan was promoted into `docs/ai/current-plan.md` as the source of truth — see the 2026-05-26 entry above.)**
