# AppStore wired to persistence

> Plan ID #35 · GitHub #27 · Phase 4

## Goal
AppStore reads / writes all SwiftData models; save points after pass / achievement / collection / builder save

## Likely files
- `App/AppStore.swift`
- glue in each Feature ViewModel

## Acceptance criteria / tests
- [ ] XCTest: AppStore mutation → SwiftData query reflects

## Dependencies
Depends on: #19, #26

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
