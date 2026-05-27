# Port lessons + Lessons.json + parity tests

> Plan ID #29 · GitHub #21 · Phase 2

## Goal
8 built-in lessons + LANES + LANE_LABEL + LANE_COLORS + `LessonFactory` + `LessonMeta`

## Likely files
- `Domain/Lesson.swift`
- `LessonFactory.swift`
- `DrumLane.swift`
- `Resources/Content/Lessons.json`

## Acceptance criteria / tests
- [ ] XCTest: lesson note counts/order match web; tier pips ordering preserved

## Dependencies
Depends on: #20

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
