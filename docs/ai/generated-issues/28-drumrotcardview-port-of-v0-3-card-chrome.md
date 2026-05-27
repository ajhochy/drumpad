# DrumrotCardView (port of v0.3 card chrome)

> Plan ID #36 · GitHub #28 · Phase 5

## Goal
SwiftUI card: screws, banner with tier + #NNN, portrait image, stats footer, OG `∞/MAX`, locked variant, emoji fallback

## Likely files
- `DesignSystem/Cards/DrumrotCardView.swift`
- `LockedDrumrotCardView.swift`
- `TierBadge.swift`
- `PortraitView.swift`

## Acceptance criteria / tests
- [ ] Snapshot tests for all 7 tiers × {locked, collected} + OG variant

## Dependencies
Depends on: #14, #17, #20

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
