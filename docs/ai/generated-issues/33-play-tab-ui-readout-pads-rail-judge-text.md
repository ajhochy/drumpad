# Play tab UI — readout + pads + rail + judge text

> Plan ID #41 · GitHub #33 · Phase 6

## Goal
All Play surface: lesson header, score/combo/accuracy readout, progress strip, 6 pads (touch + visual pulse), notation, coach note, transport (play/pause/restart/next), tempo input (clamp 40-200), loop toggle, click toggle, MIDI selector slot

## Likely files
- `Features/Play/PlayView.swift`
- `Readout.swift`
- `Pads.swift`
- `Rail.swift`
- `JudgeText.swift`

## Acceptance criteria / tests
- [ ] Manual: every control responds; pads pulse on tap; tempo clamp works

## Dependencies
Depends on: #24, #31, #32

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
