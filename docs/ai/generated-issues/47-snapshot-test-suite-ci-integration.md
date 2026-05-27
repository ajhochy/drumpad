# Snapshot test suite + CI integration

> Plan ID #55 · GitHub #47 · Phase 10

## Goal
swift-snapshot-testing SPM dep; baseline images committed; runs in CI

## Likely files
- `Tests/Snapshot/*.swift`
- `Package.swift`

## Acceptance criteria / tests
- [ ] CI green; snapshot regression fails build

## Dependencies
Depends on: #28, #29, #30

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
