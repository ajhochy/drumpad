# App icon + launch screen

> Plan ID #54 · GitHub #46 · Phase 9

## Goal
1024×1024 master + Asset Catalog set; SwiftUI launch screen matching v0.3 visual identity

## Likely files
- `Resources/Assets.xcassets/AppIcon.appiconset`
- `App/LaunchScreen.swift`

## Acceptance criteria / tests
- [ ] Visual review against v0.3 reference

## Dependencies
Depends on: #17

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
