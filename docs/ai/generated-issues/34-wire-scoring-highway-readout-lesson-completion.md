# Wire scoring → highway → readout + lesson completion

> Plan ID #42 · GitHub #34 · Phase 6

## Goal
Hit at strike line → judgment → score / combo / accuracy update; loop rollover saves pass; pass completion writes `LessonScore`

## Likely files
- `Features/Play/PlayViewModel.swift` (glue)

## Acceptance criteria / tests
- [ ] Manual: play through a lesson; score writes to SwiftData; loop saves multiple passes

## Dependencies
Depends on: #27, #31, #32, #33

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
