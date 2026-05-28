# Decisions

## 2026-05-27 — Adopt orchetect/MIDIKit (SwiftMIDI 1.x) for CoreMIDI input (#59 closes #57)
- **Decision:** Replace the hand-rolled CoreMIDI plumbing in `Drumrot/MIDI/MIDIInputManager.swift` with a thin wrapper over orchetect's MIDIKit library — added via SPM as the umbrella package URL `https://github.com/orchetect/MIDIKit`, "Up to Next Major Version", linked product **`SwiftMIDI`** on the Drumrot target. MIDIKit 1.1.0 resolved (transitive pins for swift-midi-io 1.1.0, swift-midi-core 1.0.1, swift-midi-controlsurfaces, -file, -sync, -ui, -timecode, swift-data-parsing).
- **Why:** Closes #57's silent-receive root cause on iOS 16 (Roland TD-50X USB devices enumerate but the UMP receive path stays silent). MIDIKit transparently falls back to the legacy `MIDIInputPortCreateWithBlock` path on iOS 16/17 while still surfacing MIDI 2.0 events internally — i.e. the exact dual-path fix #57 originally proposed hand-rolling, already battle-tested in the AudioKit ecosystem. Trade: one SPM dep (Apache-2.0, iOS 12+, pure-Swift, ~300–500 KB est.) for ~70 LOC of CoreMIDI compatibility shim we'd otherwise own + maintain.
- **Alternative rejected:** "#57 as-written" — hand-roll the dual-path receive ourselves with no new dependency. Rejected: more code surface, no test coverage on the iOS-16 path until real hardware lands, and we'd be re-implementing what MIDIKit already does. Recommendation in #59's body is followed: close #57 as superseded.
- **Package architecture note (caught during implementation, not from the issue body):** orchetect renamed the public surface in MIDIKit 1.x. The umbrella **`MIDIKit`** package now exposes a single `SwiftMIDI` library product that `@_exported public import`s `SwiftMIDIIO` + `SwiftMIDICore`. The 0.x product names (`MIDIKitIO`, `MIDIKitCore`) and their parent module `MIDIKit` are gone. **Type names inside are preserved** (`MIDIManager`, `MIDIEvent`, `MIDIReceiver`, `MIDINote`, `MIDIIdentifier = Int32`, etc.), so the issue body's 0.x README sketch still mostly applies — but `import MIDIKitIO` is wrong for 1.x (correct: `import SwiftMIDI`), and `NotificationHandler` is a 1-arg closure `(MIDIIONotification) -> Void` (not 2-arg). Documented here so the next agent doesn't repeat the mistake.
- **Public API surface preserved:** `MIDIInputManager.Source: Identifiable, Equatable { id: Int32; name: String }`, `@Published private(set) var sources: [Source]`, `@Published private(set) var activity: Bool`, `var onNote: ((DrumLane, Int) -> Void)?`, `func start()`. PlayView (`store.midi.onNote = ...`, `store.midi.start()`, `store.midi.activity`, `store.midi.sources.isEmpty`) and SettingsView (`ForEach(store.midi.sources) { source in Text("uid \(source.id)") }`) call-sites are untouched.
- **Network MIDI kept manual:** `MIDINetworkSession.default()` is still configured via direct CoreMIDI for exact build-1 parity on the existing "Network Session 1" source. MIDIKit can manage it too; deferred to a later cleanup.
- **Consequences:**
  - Bundle-size impact unmeasured on simulator; real-device hardware gate is `du -h Drumrot.app` before/after — target < 1 MB delta per #59. Revisit if larger.
  - MIDIKit's recent minimum platform = iOS 13, Swift 6 strict concurrency. We pin to "Up to Next Major" so a Swift 6 forced bump in MIDIKit 2.x won't auto-upgrade us.
  - Receive callback now runs MIDIKit's threading model (still marshalled to MainActor via `Task { @MainActor in ... }`); no behavioural change to scoring path.
- **Cherry-pick to `release/ios16-only`:** the file is conflict-free per `IOS16_BRANCH.md`'s divergence map (`MIDIInputManager.swift` is identical on both branches). After main merges, cherry-pick the commit + commit the new Package.resolved entries; ios16 build/test on the same iPad Pro 11-inch M5 sim.
- **Verification snapshot:** `xcodebuild build` SUCCEEDED + 45/45 tests green on iPad Pro 11-inch M5 sim (CODE_SIGNING_ALLOWED=NO). Hardware verification (TD-50X strike → highway kick lane + audio + scoring increment) remains a real-device gate.

## 2026-05-26 — Native app rebranded SP808Killa → Drumrot; Skibidi scrubbed (A5)
- The implemented Xcode project/target/module/folders/Info.plist/test target were renamed **`SP808Killa` → `Drumrot`** (scheme `Drumrot`, `ios/Drumrot.xcodeproj`, `@main DrumrotApp`, `@testable import Drumrot`). User-facing display name is **`drumrot`** (`CFBundleDisplayName`); bundle id unchanged (`com.visaliacrc.drumrot`). Historical planning docs (`current-plan.md`, `codex-ios-plan.md`, `claudes-ios-plan.md`, `generated-issues/*`) still say "SP808Killa" — left as the planning record; operational docs (runbook, handoff, manual-smoke) + project-state use the live `Drumrot` name.
- Codex started the rename (renamed files on disk) but left the `project.pbxproj` + shared scheme pointing at the old name; completed here via a `SP808Killa→Drumrot` substitution. **Verified: `xcodebuild test` green (8 suites), app launches with display name "drumrot" + Bonjour key present.**
- **A5 — Skibidi card resolved:** `skibidi_tomtomlet` → `trono_tomtomlet` ("Trono Tomtomlet", 👑🥁) renamed across iOS `Drumrots.json`, web `js/drumrots.js`, asset catalog. Codex's first pass renamed labels only — the rendered art was still a drum-ified Skibidi Toilet. **Now fixed: `art/drumrots/trono_tomtomlet.webp` + its iOS imageset were regenerated as an original crowned porcelain-tom-drum design (no toilet/face/character)** via a text-to-image call (gemini-2.5-flash-image, key from the Statement Automator `.env`), and the `brainrots/OG/Skibidi_Toilet.png` source was deleted. **Decision (2026-05-26): other portraits handled reactively.** Every other portrait is a drum-ified meme source too, but the user chose NOT to pre-emptively review/redraw them — ship as-is and only address specific portraits **if Apple App Review flags them**. Skibidi was fixed because it's a clear named-trademark case; the rest are "Italian brainrot" genre pastiche (lower risk). Do not re-raise a blanket content review. Also added `ITSAppUsesNonExemptEncryption=false` (export-compliance) and BpmStepper a11y labels.
- **CI recovery:** `BuildView.swift` was missing from git after the Phase 7 commit (built locally but a clean CI checkout would fail); committed separately. Lesson: confirm `git status` shows no untracked source after each commit, not just a green local build.

## 2026-05-26 — iPad port plan promoted to source of truth + issues filed
- Compared the two parallel planning passes ([claudes-ios-plan.md](claudes-ios-plan.md), Mac Catalyst; [codex-ios-plan.md](codex-ios-plan.md), iPad-first + iPad-on-Mac). They are ~95% identical; the only material divergence is the platform/Mac strategy. **Codex's plan wins** because it matches the locked 2026-05-21 direction; Claude's Catalyst plan would re-open a settled call.
- **Promoted Codex's plan into `docs/ai/current-plan.md`** as the canonical current plan, superseding the v0.3 card-system plan. The two planning passes are preserved as historical artifacts. Grafted from Claude's plan: the explicit Info.plist usage-description detail (`NSBluetoothAlwaysUsageDescription` / `NSLocalNetworkUsageDescription` / `NSBonjourServices`) and the "no audio-input usage description / no recording entitlement" exclusion line. **Dropped** Claude's Catalyst-only macOS sandbox entitlements (`app-sandbox`, `device.usb`, `network.client`, etc.) — they don't apply to an iPad-only target; noted for a possible v1.1 Mac/Catalyst target.
- **Filed all 41 issues** (plan IDs #20–#60) on GitHub. The repo's shared issue/PR sequence was already at #11, so GitHub assigned **#12–#52** (offset −8 from plan IDs). Crosswalk table lives at the top of `current-plan.md`; filed issue bodies express dependencies in live GitHub numbers.
- Trade-off: plan IDs in the docs (#20–#60) differ from GitHub numbers (#12–#52). Kept plan IDs in the issue table for readability and pinned the crosswalk so the two never drift.
- **Ambiguity A1 resolved:** user is already enrolled in the Apple Developer Program; App Store Connect API key + Developer ID certificates exist locally outside the repo. Never commit signing material — load into CI/TestFlight as secrets.
- **Ambiguities A2–A5 addressed (2026-05-26):**
  - A2 — audio re-synthesized in AVAudioEngine (no WAV licensing); confirms D6.
  - A3 — generate a fresh icon/asset set in the SP-808 voxel style; icon must be an original mascot, no third-party character; also closes web favicon #6.
  - A4 — portraits are AI-generated (gemini-2.5-flash-image via OpenRouter) and treated as owned, **but** the generator edits a `parodyImg` source and keeps it "recognizable as a parody," making each a derivative work. Before Phase 10: verify model commercial terms + source-image rights, retain prompts/seeds.
  - A5 — direction (not legal advice): treat drumrots as parody/derivative; original icon/brand; pre-submission content review to scrub specific trademarked characters (e.g. Skibidi); IP-counsel check on borderline names. Parody is a fact-specific copyright defense, weaker under trademark, and Apple (Guideline 5.2) can reject regardless. Weird Al *licenses* his parodies rather than relying on fair use.

## 2026-05-21 — Native iPadOS port direction (planning)
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

## 2026-05-21 — Virtual MIDI test source over mocks (PR #10)
- Chose `node-midi` virtual port over mocking `navigator.requestMIDIAccess`. A real CoreMIDI/ALSA-visible port exercises the full receive chain — enumeration, dropdown rendering, channel decoding in `js/midi-device.js`, GM-map → lane translation. Mocks would only have tested the JS path, not the OS/browser boundary.
- Trade-off: pulls in a native dep (`midi` npm package, RtMIDI binding). Devs on Linux need `libasound2-dev`; Windows can't create virtual ports via this binding (documented in README; loopMIDI is the workaround).
- Kept `package.json` minimal: `midi` is the only dep, no lockfile committed, repo stays "static site you can open in a browser" first, "dev tools available if you want them" second.

## 2026-05-21 — Portrait-rendering regression (PR #8)
- User caught blank-portrait regression after PR #5 merged: revealed cards showed chrome but no character art.
- Cause: `loading="lazy"` on the img + `content-visibility: auto` on `.cell` interacted badly inside the opacity-0 reveal overlay — image element existed but never entered a paintable state.
- Decision: drop `loading="lazy"` and `content-visibility: auto` from the card path entirely. Always emit emoji creature behind the image as a defensive z-index-0 fallback. HTTP 200 is no longer accepted as evidence the portrait is visible — pixel checks are now required in `docs/testing/manual-smoke.md`.
- Trade-off: Pi-perf hooks (lazy + content-visibility) gone. If perf regresses on actual hardware, re-add ONLY on Drops-grid cells, never on reveal-popup cards. The blank-portrait failure mode is worse than slower scrolling.

## 2026-05-21 — v0.3 card system merged
- PR #5 squash-merged to `main` (`f0927d31`). Issues #1–#4 closed.
- Three commits in the run branch: bootstrap docs, `#1+#3` (data + renderer in one file), `#2+#4` (CSS chrome + polish in CSS/HTML/README).
- Smoke verified by Playwright + computer-control before merge; favicon 404 spun out as #6. Portrait regression caught after merge — see PR #8 entry above.

## 2026-05-20 — Drumrot v0.3 adoption
- Primary key stays `id` (snake_case). No `slug`. Maps 1:1 to image filename.
- Tier key renamed `drumrot_god` → `god` everywhere.
- Emoji field renamed `art` → `emoji`.
- Stats remain numeric in data. `∞` / `MAX` are render-time conventions: bpm/groove `99` → `∞` only for OG; power `99` → `MAX` for `god` or `og`.
- Inline `<symbol>` SVG sprite from v0.3 is intentionally skipped — use `drumrotImg` or emoji fallback only.
- v0.3 wording (name/sub/flavor) wins on every conflict with the legacy roster.
