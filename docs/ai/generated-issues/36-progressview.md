# ProgressView

> Plan ID #44 · GitHub #36 · Phase 7

## Goal
Day streak; 14-day calendar; total notes / sessions; best score; top accuracy; achievement grid; recent sessions

## Likely files
- `Features/Progress/ProgressView.swift`
- `AchievementGrid.swift`
- `RecentSessions.swift`

## Acceptance criteria / tests
- [ ] Unit: aggregate calcs match web; UI: empty / partial / full preview

## Dependencies
Depends on: #22, #26, #27

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
