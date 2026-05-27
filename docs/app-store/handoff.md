# SP-808 KILLA — native iPad build handoff

Status as of 2026-05-26: **Phases 0–9 implemented and verified on the iPad
(A16) simulator** (all unit/parity suites green); PR #53 on branch
`workflow/run-2026-05-26`. The items below are the parts I could **not** do
from here — they need your hardware, your Apple account, or App Store Connect.

## Must do on a real iPad (hardware gates)
- **Audio latency** (#24/#41): confirm pad/MIDI-to-sound feels tight (~≤10ms). Tune `setPreferredIOBufferDuration` / the in-Settings audio offset if needed.
- **MIDI matrix** (#41/#42): USB-C/camera-kit, Network MIDI, and BLE pairing each drive the highway. Use `scripts/midi-pulse.mjs` as a virtual source for Network MIDI.
- **VoiceOver** (#43): walk every tab with VoiceOver on; check reading order + labels with Accessibility Inspector.
- **ProMotion** (#40): confirm the highway runs 120Hz on a ProMotion iPad, 60Hz floor on iPad (A16)/mini.

## Optional engineering follow-ups (not blocking)
- **#47 snapshot tests** + **#48 XCUITest**: not added — they need the
  `swift-snapshot-testing` SPM dependency and a UI-test target wired into the
  hand-built `project.pbxproj`. The existing unit/parity suite already gates CI
  (`.github/workflows/ios-build.yml`). Add these in Xcode when convenient.

## App Store Connect (your account — A1 enrollment already confirmed)
- **#51**: create the ASC record (name "drumrot — SP-808 KILLA", subtitle, bundle id `com.visaliacrc.drumrot`, age 4+, category Games > Music), 4–6 screenshots per device class, optional 30s preview. Privacy: **Data Not Collected** (see privacy-label.md).
- **#52**: archive in Xcode, upload to TestFlight, invite ≥3 external testers via public link, collect smoke notes (docs/testing/manual-smoke.md → native section).
- Rename bundle id / app name pre-submit if desired (D9/D12 placeholders).

## Pre-submission content review (A4/A5)
- Confirm the image model's commercial-use terms for the AI-generated portraits and that source images are owned/licensable (A4).
- Run the parody-name content pass — scrub any specific trademarked character (e.g. "Skibidi"); IP-counsel check on borderline names (A5).

## How to run what exists
```
open ios/SP808Killa.xcodeproj      # scheme SP808Killa, iPad (A16) sim or device
xcodebuild -project ios/SP808Killa.xcodeproj -scheme SP808Killa \
  -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPad (A16)' test
```
Debug launch args: `--play`, `--demo`, `--reveal`, `--library/--progress/--build/--drops`.
