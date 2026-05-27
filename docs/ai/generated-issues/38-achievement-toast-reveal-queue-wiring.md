# Achievement → toast → reveal queue wiring

> Plan ID #46 · GitHub #38 · Phase 7

## Goal
Hit/pass/builder/MIDI events fire `AchievementEngine`; new unlock → toast → delayed drop roll → reveal

## Likely files
- `App/AppStore.swift`
- `Features/Progress/AchievementToast.swift`
- glue in Play / Builder

## Acceptance criteria / tests
- [ ] UI test: trigger unlock event → toast appears → reveal queued; deterministic sequencing

## Dependencies
Depends on: #22, #30, #34, #37

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
