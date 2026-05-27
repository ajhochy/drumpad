# Privacy + entitlements audit + ASC privacy label

> Plan ID #58 · GitHub #50 · Phase 10

## Goal
Verify Info.plist usage descriptions; capabilities complete; draft "Data Not Collected" privacy label

## Likely files
- `Info.plist`
- `SP808Killa.entitlements`
- `docs/app-store/privacy-label.md`

## Acceptance criteria / tests
- [ ] TestFlight build accepted by ASC with drafted label

## Dependencies
Depends on: #42

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
