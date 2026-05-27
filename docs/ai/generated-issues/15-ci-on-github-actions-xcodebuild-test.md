# CI on GitHub Actions — xcodebuild test

> Plan ID #23 · GitHub #15 · Phase 0

## Goal
`.github/workflows/ios-build.yml` runs `xcodebuild test` on macOS runner

## Likely files
- `.github/workflows/ios-build.yml`

## Acceptance criteria / tests
- [ ] Action passes on a PR

## Dependencies
Depends on: #12

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
