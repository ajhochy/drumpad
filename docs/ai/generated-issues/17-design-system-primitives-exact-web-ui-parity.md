# Design system primitives — exact web UI parity

> Plan ID #25 · GitHub #17 · Phase 1

## Goal
Centralize colors, fonts, tier gradients; mirror `css/main.css` and `css/cards.css` tokens; LED, Pad, BpmStepper primitives

## Likely files
- `DesignSystem/Theme/Palette.swift`
- `Typography.swift`
- `Tiers.swift`
- `Controls/*.swift`

## Acceptance criteria / tests
- [ ] `#Preview` shows each component; controls and tier badges match web reference screenshots

## Dependencies
Depends on: #14

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
