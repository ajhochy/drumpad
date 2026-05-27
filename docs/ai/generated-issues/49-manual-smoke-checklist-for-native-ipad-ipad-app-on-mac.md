# Manual smoke checklist for native (iPad + iPad app on Mac)

> Plan ID #57 · GitHub #49 · Phase 10

## Goal
`docs/testing/manual-smoke.md` extended with iPad + Apple silicon Mac sections, per-MIDI-transport coverage

## Likely files
- `docs/testing/manual-smoke.md`

## Acceptance criteria / tests
- [ ] Single checklist Markdown; aliases the existing web smoke doc

## Dependencies
Depends on: #41, #42, #45

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
