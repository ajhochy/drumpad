# Bootstrap `ios/` Xcode project

> Plan ID #20 · GitHub #12 · Phase 0

## Goal
Create `ios/SP808Killa.xcodeproj`, single SwiftUI iPadOS target, deployment iPadOS 17, landscape-lock iPad, App Store/TestFlight-ready signing placeholders, Apple silicon Mac availability documented for App Store Connect

## Likely files
- `ios/SP808Killa/App/SP808KillaApp.swift`
- `Info.plist`
- `.entitlements`
- `.gitignore`

## Acceptance criteria / tests
- [ ] App builds for iPad sim and, where available, "My Mac (Designed for iPad)"; both launch a blank view

## Dependencies
None — this is a root issue with no prerequisites.

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
