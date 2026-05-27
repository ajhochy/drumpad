# iPad app on Mac compatibility polish

> Plan ID #53 · GitHub #45 · Phase 9

## Goal
Keyboard shortcuts (Cmd+1..5 tabs, Cmd+R restart, Space play/pause, L loop, C click); pointer/touch alternatives where supported; verify full-screen/window behavior when the iPad app runs on Apple silicon Mac

## Likely files
- `App/SP808KillaApp.swift`
- per-feature view modifiers

## Acceptance criteria / tests
- [ ] Manual: run "My Mac (Designed for iPad)" where available; shortcuts respond; UI remains exact and usable

## Dependencies
Depends on: #16, #33

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
