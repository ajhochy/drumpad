# TestFlight build + external testers + final smoke

> Plan ID #60 · GitHub #52 · Phase 10

## Goal
Upload archive; invite ≥3 external testers via public link; collect smoke notes

## Likely files
- (uploads + tracking, no code)

## Acceptance criteria / tests
- [ ] TestFlight build accepted; ≥3 testers complete a session; smoke passes

## Dependencies
Depends on: #51

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
