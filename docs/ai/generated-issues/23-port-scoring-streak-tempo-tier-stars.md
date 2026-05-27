# Port scoring + streak + tempo tier + stars

> Plan ID #31 · GitHub #23 · Phase 2

## Goal
`ScoringEngine`, `Streak`, `PracticeTier` (Steady / Grooving / Locked / Killing It), star thresholds (≥95/80/50%)

## Likely files
- `Domain/ScoringEngine.swift`
- `Streak.swift`
- `PracticeTier.swift`

## Acceptance criteria / tests
- [ ] XCTest: perfect/great/good/miss boundary tests; combo multiplier; star calc

## Dependencies
Depends on: #20

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
