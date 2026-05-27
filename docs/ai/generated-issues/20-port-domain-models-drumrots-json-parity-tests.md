# Port domain models + Drumrots.json + parity tests

> Plan ID #28 · GitHub #20 · Phase 2

## Goal
`Drumrot`, `DrumrotTier` (7 cases), `TierWeights`, `DropRoller`; load `Drumrots.json` (mirror of `js/drumrots.js`)

## Likely files
- `Domain/Drumrot.swift`
- `DrumrotTier.swift`
- `TierWeights.swift`
- `DropRoller.swift`
- `Resources/Content/Drumrots.json`

## Acceptance criteria / tests
- [ ] XCTest: 31 entries, 7 tiers, ids match web; injected-RNG roll distribution within ±2σ; OG bonus = 5%

## Dependencies
Depends on: #18

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
