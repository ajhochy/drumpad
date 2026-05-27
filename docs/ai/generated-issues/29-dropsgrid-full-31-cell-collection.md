# DropsGrid — full 31-cell collection

> Plan ID #37 · GitHub #29 · Phase 5

## Goal
LazyVGrid of cards; locked variants for un-collected; data backed by SwiftData query; N/31 header

## Likely files
- `Features/Drops/DropsGrid.swift`
- `DropsViewModel.swift`

## Acceptance criteria / tests
- [ ] Snapshot of full grid; manual: collect one → cell unlocks

## Dependencies
Depends on: #20, #26, #28

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
