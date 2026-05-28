# Agent guide — drumrot / SP-808 KILLA

Static web app: vanilla JS modules, no build step, no test runner. Opened directly via `index.html`.

## First files to read
- `index.html` — shell, tabs, reveal overlay.
- `js/main.js` — bootstraps modules.
- `js/drumrots.js` — collection roster, tier config, drop roll, card renderer.
- `css/main.css` — historic stylesheet (chassis + cards).
- `css/cards.css` — v0.3 card chrome (post-issue-#2).

## Data safety
- Do not commit anything in `art/.DS_Store`, `.DS_Store`, generated images outside `art/drumrots/` and `brainrots/`, or any user data.

## Testing
- No automated test runner. Validation is a smoke pass: open `index.html` in a browser, switch tabs, trigger a drop via achievement, check the Drops tab.
- For data shape changes, sanity-check with `node --input-type=module -e "import('./js/drumrots.js').then(m => console.log(m.DRUMROTS.length))"`.

## Git / merge
- Feature branch per workflow run (`workflow/run-YYYY-MM-DD`). Never commit to `main` directly.
- Merge is a manual human step after manual smoke.

## Memory updates
After verified work, update `docs/ai/project-state.md` with what changed and the current status.

## iOS native target
drumrot also ships as a native iOS app (App Store + TestFlight). Source root is the synchronized folder `ios/Drumrot/` under `ios/Drumrot.xcodeproj` — new `.swift` files there are auto-included, no pbxproj edit needed.

- **Branches**: `main` = iOS 17+ SwiftData (App Store). `release/ios16-only` = iOS 16.6+ UserDefaults-backed `PersistenceStore` (older-iPad TestFlight). One-way main → ios16 via cherry-pick; never reverse. See `IOS16_BRANCH.md` on the ios16 branch for the conflict-zone map.
- **pbxproj is load-bearing**: Xcode holds an exclusive lock on `ios/Drumrot.xcodeproj/project.pbxproj` while open, so SPM additions, signing settings, deployment-target changes, and build-number bumps must go through the Xcode UI. Ask the user up front rather than failing at archive time.
- **Canonical test**: `xcodebuild test -project ios/Drumrot.xcodeproj -scheme Drumrot -sdk iphonesimulator -destination 'platform=iOS Simulator,id=6C5FDCB6-8346-4690-A788-B59FBFA26B0F' CODE_SIGNING_ALLOWED=NO` (iPad Pro 11-inch M5). The Xcode `BuildProject` MCP tool is faster for incremental builds when local signing is configured.
- **Ops docs**: `docs/app-store/release-runbook.md` (hardware gates 1–9), `docs/app-store/handoff.md` (ASC + TestFlight). ASC API key ID + Issuer ID + `.p8` path live in auto-memory at `reference_asc_credentials.md` — NEVER commit signing material.
