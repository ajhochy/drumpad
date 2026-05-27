# PlaybackEngine + NoteTravel + test clock

> Plan ID #39 · GitHub #31 · Phase 6

## Goal
Monotonic gameplay clock; count-in; note travel (1800 ms); loop rollover (save pass + reset); non-loop completion; test-clock for determinism

## Likely files
- `Playback/PlaybackEngine.swift`
- `NoteTravel.swift`
- `TestClock.swift`

## Acceptance criteria / tests
- [ ] XCTest: count-in timing; loop rollover saves exactly one pass; non-loop terminates after last note

## Dependencies
Depends on: #23

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
