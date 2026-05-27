# XCUITest UI smoke suite

> Plan ID #56 · GitHub #48 · Phase 10

## Goal
Tab nav, drop reveal, settings round-trip, builder load-into-player

## Likely files
- `SP808KillaUITests/*.swift`

## Acceptance criteria / tests
- [ ] CI runs UI tests on iPad simulator; Apple silicon Mac click-through remains manual unless CI supports that destination

## Dependencies
Depends on: #16, #30, #33, #37, #42

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
