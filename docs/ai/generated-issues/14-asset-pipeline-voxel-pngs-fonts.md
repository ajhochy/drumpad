# Asset pipeline — voxel PNGs + fonts

> Plan ID #22 · GitHub #14 · Phase 0

## Goal
Add `scripts/export-drumrots-png.mjs` that emits PNG @1x/@2x/@3x from `art/drumrots/*.webp`; populate Asset Catalog; bundle TTFs + declare `UIAppFonts`

## Likely files
- `scripts/export-drumrots-png.mjs`
- `Resources/Assets.xcassets/drumrots/`
- `Resources/Fonts/`

## Acceptance criteria / tests
- [ ] Asset catalog contains 31 image sets; SwiftUI preview shows correct font

## Dependencies
Depends on: #12

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
