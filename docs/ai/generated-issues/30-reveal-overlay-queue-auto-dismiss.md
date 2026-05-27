# Reveal overlay + queue + auto-dismiss

> Plan ID #38 · GitHub #30 · Phase 5

## Goal
`.fullScreenCover` shows new card; queue handles multiple rolls; auto-dismiss 6 s (9 s OG); honors Reduced Motion

## Likely files
- `Features/Drops/RevealOverlay.swift`
- `RevealQueue.swift`

## Acceptance criteria / tests
- [ ] UI test: trigger fake achievement → overlay → dismiss; queue handles N rolls

## Dependencies
Depends on: #22, #28

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
