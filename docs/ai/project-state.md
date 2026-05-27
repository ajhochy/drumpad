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

## Project structure note (Xcode)
- `.xcodeproj` lives at `ios/SP808Killa.xcodeproj`; source root is the synchronized folder `ios/SP808Killa/` (App/, DesignSystem/, Features/, Resources/, and later Domain/Audio/MIDI/Playback/Data/). New `.swift`/asset files dropped into that folder are auto-included — no pbxproj edits needed. Target id in pbxproj = `AA0000000000000000000002`.

## Risks / known gaps
- **Pi hardware perf check** — `content-visibility: auto` was removed in PR #8 to fix the blank-portrait regression. The Pi `≥30 fps` gate has not been re-verified after that removal. If perf regresses on the actual Pi, reintroduce `content-visibility: auto` only on the Drops grid cells (not on reveal-popup cards) and re-check.
- **Playwright smoke** still does not assert pixel painting on portraits — only the manual smoke checklist does. Worth adding a Playwright spec that asserts `naturalWidth > 0` and `rect.width > 0` on `.portrait-img` after the reveal animation.

## Next step
Phase 0 build is done (#12, #13-folded, #15). Remaining Phase 0 item: **#14 asset pipeline** — convert `art/drumrots/*.webp` → PNG @1x/2x/3x into `ios/SP808Killa/Resources/Assets.xcassets/drumrots/` (Pillow is available; do alongside Phase 5 which consumes them). Then Phase 1 (#16–#19 chassis/design-system/Settings+SwiftData/AppStore) and Phase 2 (#20–#23 domain parity + XCTests against `js/*`). A1 (Apple Developer enrollment) is already resolved. Verify each phase with `xcodebuild build`/`test` on the iPad (A16) sim.
