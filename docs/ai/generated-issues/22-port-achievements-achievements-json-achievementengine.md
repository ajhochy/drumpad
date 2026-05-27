# Port achievements + Achievements.json + AchievementEngine

> Plan ID #30 · GitHub #22 · Phase 2

## Goal
18 achievements with category metadata + `AchievementEngine` that triggers from hit/pass/builder/MIDI events

## Likely files
- `Domain/Achievement.swift`
- `AchievementEngine.swift`
- `Resources/Content/Achievements.json`

## Acceptance criteria / tests
- [ ] XCTest: 18 ids match web; each rule fires under the right synthetic event sequence

## Dependencies
Depends on: #20

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
