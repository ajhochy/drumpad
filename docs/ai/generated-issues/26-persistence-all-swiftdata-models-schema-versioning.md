# Persistence — all SwiftData models + schema versioning

> Plan ID #34 · GitHub #26 · Phase 4

## Goal
`LessonScore`, `AchievementUnlock`, `PracticeDay`, `ExtraLesson`, `DrumrotCollectionEntry`, `BuilderState` + `schemaVersion` on each

## Likely files
- `Data/Models/*.swift`
- `Data/ModelContainer+App.swift`
- `Data/SchemaMapping.md`

## Acceptance criteria / tests
- [ ] XCTest: save → kill container → reload round-trips; corrupt-row recovery logs error, defaults

## Dependencies
Depends on: #18

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
