# LibraryView

> Plan ID #43 · GitHub #35 · Phase 7

## Goal
Lesson cards with number / New-Played stamp / metadata / mini-notation / stars / high score / tier pips; tap → loads into Play and starts

## Likely files
- `Features/Library/LibraryView.swift`
- `LessonCardView.swift`
- `MiniNotationView.swift`
- `TierPipsView.swift`

## Acceptance criteria / tests
- [ ] UI test: card tap → Play tab open with lesson loaded

## Dependencies
Depends on: #21, #34

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
