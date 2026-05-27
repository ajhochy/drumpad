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
- **#46 / #6 local asset pass** — Added a deterministic procedural generator at `scripts/generate-app-icon.py` that creates an original SP-style pad-device mark with no external API call or source image. Generated `ios/SP808Killa/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png` (1024x1024 RGB, no alpha), `LaunchMark.imageset`, `ios/SP808Killa/App/LaunchScreen.swift`, `favicon.ico` (16/32), `favicon-32.png`, and `apple-touch-icon.png`; `index.html` now links the favicon assets.

## Risks / known gaps
- **iOS project wiring for #46** — this checkout does not yet contain `ios/SP808Killa.xcodeproj`, so the SwiftUI `LaunchScreen` and asset catalog were added at the planned paths but could not be validated inside Xcode target membership. Validate target wiring once #12 bootstraps the project.
- **Pi hardware perf check** — `content-visibility: auto` was removed in PR #8 to fix the blank-portrait regression. The Pi `≥30 fps` gate has not been re-verified after that removal. If perf regresses on the actual Pi, reintroduce `content-visibility: auto` only on the Drops grid cells (not on reveal-popup cards) and re-check.
- **Playwright smoke** still does not assert pixel painting on portraits — only the manual smoke checklist does. Worth adding a Playwright spec that asserts `naturalWidth > 0` and `rect.width > 0` on `.portrait-img` after the reveal animation.

## Next step
Start Phase 0: implement #12 (bootstrap `ios/SP808Killa` Xcode project) → #13 (1-screen prototype: card + AVAudioEngine sample + CoreMIDI enumeration) → #14 (asset pipeline) → #15 (CI). Resolve Apple Developer enrollment (Ambiguity A1) before Phase 7. After #12, wire the existing app icon / launch assets into the Xcode target. Web-side follow-up remains stronger portrait pixel-paint smoke.
