# SpriteKit Highway scene + note sprites + count-in overlay

> Plan ID #40 · GitHub #32 · Phase 6

## Goal
`SKScene` hosted via `SpriteView`; 6 lanes; strike line; note sprites scroll; count-in text; 120 Hz on ProMotion

## Likely files
- `Features/Play/HighwayScene.swift`
- `HighwayView.swift`
- `NoteNode.swift`

## Acceptance criteria / tests
- [ ] Visual: lane scrolls at 60 Hz iPad sim, 120 Hz ProMotion device; count-in displays 1..8

## Dependencies
Depends on: #17

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
