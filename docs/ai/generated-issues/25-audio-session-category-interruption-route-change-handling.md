# Audio session category + interruption + route change handling

> Plan ID #33 · GitHub #25 · Phase 3

## Goal
`.playback + .mixWithOthers`; interruption (iPadOS) + route change handlers; click synth (accent + non-accent square)

## Likely files
- `Audio/AudioSessionManager.swift`
- `ClickSynth.swift`

## Acceptance criteria / tests
- [ ] Manual: interruption resumes correctly; headphones unplug pauses; Apple silicon Mac audio route smoke passes

## Dependencies
Depends on: #24

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
