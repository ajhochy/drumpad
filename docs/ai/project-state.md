# Project state

## Current focus
Native iPadOS app (**Drumrot**, App Store + TestFlight) is the active surface. Phases 0–10 are built and sim-verified; the app ships to TestFlight on both branches (`main` iOS 17+/SwiftData and `release/ios16-only` iOS 16.6+/UserDefaults). Latest visible work: Groove Library + Edit (user grooves from Builder + `.mid` imports persist with a USER stamp + Edit/Delete), lesson-grid normalization, a MIDI→audio fast path, and a pre-launch issue batch (#47–#75). Remaining gates are real-iPad hardware checks and App Store Connect / TestFlight account steps. The original web app is frozen at v0.3 and untouched.

## Active branch / PR
`main`. Working tree has untracked Xcode build artifacts only (`ios/build/*.xcarchive`, `Export*` dirs, `project.pbxproj.bak`, `WorkspaceSettings.xcsettings`) — no tracked source changes pending. Parallel-branch policy: `main` is the iOS 17+ SwiftData target (App Store); `release/ios16-only` is the iOS 16.6+ UserDefaults-persistence fork — one-way `main` → `ios16` via cherry-pick, never reverse.

## In progress
- Web-app visual parity across all native tabs (chassis/LCD chrome + bundled fonts) — Play is done; other tabs reskinned in the 2026-05-27 Claude Design pass. Verify on a real iPad in landscape.
- Hardware/account gates per `docs/app-store/release-runbook.md` and `docs/app-store/handoff.md`: on-device audio latency, USB/Network/BLE MIDI, VoiceOver, iPad-app-on-Mac, external-tester smoke (≥3), A4/A5 content review.

## Risks / known issues
- **Pi hardware perf check** — `content-visibility: auto` was removed in PR #8 to fix the blank-portrait regression. The Pi `≥30 fps` gate has not been re-verified after that removal. If perf regresses on the actual Pi, reintroduce `content-visibility: auto` only on the Drops grid cells (not on reveal-popup cards) and re-check.
- **Playwright smoke** still does not assert pixel painting on portraits — only the manual smoke checklist does. Worth a Playwright spec that asserts `naturalWidth > 0` and `rect.width > 0` on `.portrait-img` after the reveal animation.
- **Real-device MIDI/audio/VoiceOver** remain unverifiable in the simulator (iOS Simulator CoreMIDI is sandboxed; only `Network Session 1` enumerates). These are hardware gates, not bugs.
- **pbxproj is load-bearing** — Xcode holds an exclusive lock while open; SPM additions, signing, deployment-target, and build-number bumps must go through the Xcode UI.

## Test status
Native: `xcodebuild test -project ios/Drumrot.xcodeproj -scheme Drumrot -sdk iphonesimulator -destination 'platform=iOS Simulator,id=6C5FDCB6-8346-4690-A788-B59FBFA26B0F' CODE_SIGNING_ALLOWED=NO` (iPad Pro 11-inch M5). Most recent green run: 53 tests / 0 failures (Groove Library port). CI workflow `.github/workflows/ios-build.yml` resolves an iPad simulator by UDID and runs build + test. Web: no automated runner — smoke is the manual checklist in `docs/testing/manual-smoke.md` plus the `DRUMROTS.length` (== 31) node sanity check.

## Next step
1. Confirm the latest TestFlight build (202 on both branches) finished Apple processing and is installable.
2. Install via TestFlight on the iPad and run the hardware gates per `docs/app-store/release-runbook.md` (§1 latency, §2 USB MIDI, §3 Network MIDI, §4 BLE MIDI, §5 VoiceOver, §6 iPad-app-on-Mac).
3. External-tester smoke (#52, runbook §8) — first external build triggers Beta App Review (~24h).
4. A4/A5 content/IP review (#52 wrap, runbook §9) — meme portraits handled reactively per the 2026-05-26 decision.

**Run history:** one file per run under `docs/ai/runs/` (surfaced as `ai-runs/`). This snapshot is overwritten in place.
