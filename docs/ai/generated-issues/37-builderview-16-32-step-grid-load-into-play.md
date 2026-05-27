# BuilderView — 16/32-step grid + load into Play

> Plan ID #45 · GitHub #37 · Phase 7

## Goal
6 lane rows × 16/32 steps; BPM (40-200); coach note; clear; load into player (creates/replaces builder lesson, unlocks Creator + Coach if non-empty); persists

## Likely files
- `Features/Builder/BuilderView.swift`
- `BuilderEngine.swift`
- `Domain/BuilderLessonFactory.swift`

## Acceptance criteria / tests
- [ ] Unit: empty pattern → error; load-into-player triggers correct achievements; persistence round-trips

## Dependencies
Depends on: #21, #22, #26

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
