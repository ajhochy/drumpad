# Root TabView + 5 placeholder tabs

> Plan ID #24 · GitHub #16 · Phase 1

## Goal
App shell with Play / Library / Progress / Build / Drops, SF Symbol icons, landscape lock

## Likely files
- `App/SP808KillaApp.swift`
- `App/RootView.swift`
- `Features/*/EmptyView.swift`

## Acceptance criteria / tests
- [ ] Manual: tap each tab on iPad sim and iPad-app-on-Mac mode where available; landscape stays

## Dependencies
Depends on: #12

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
