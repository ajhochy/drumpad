# App Store Connect record + screenshots + 30 s preview

> Plan ID #59 · GitHub #51 · Phase 10

## Goal
Populate ASC; capture 4-6 screenshots per device class; record preview video

## Likely files
- `docs/app-store/{screenshots,preview-script.md}`

## Acceptance criteria / tests
- [ ] Record reaches "Ready for Review" state

## Dependencies
Depends on: #46, #49, #50

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
