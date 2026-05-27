# Settings tab + SwiftData container + AppSettings

> Plan ID #26 · GitHub #18 · Phase 1

## Goal
Gear icon → sheet with MIDI device picker placeholder, audio offset slider, haptics toggle, reduced-motion toggle, debug import/export buttons

## Likely files
- `Features/Settings/SettingsView.swift`
- `Data/ModelContainer+App.swift`
- `Data/Models/AppSettings.swift`

## Acceptance criteria / tests
- [ ] Toggle a setting → kill app → reopen → setting persists

## Dependencies
Depends on: #12

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
