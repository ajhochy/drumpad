# AppStore (ObservableObject) + dependency injection skeleton

> Plan ID #27 · GitHub #19 · Phase 1

## Goal
`@MainActor` AppStore, env-injected, owns SwiftData context + AudioEngine + MIDIInputManager handles

## Likely files
- `App/AppStore.swift`

## Acceptance criteria / tests
- [ ] Unit test: AppStore initializes with default state; injection compiles

## Dependencies
Depends on: #18

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
