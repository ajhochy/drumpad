# Hello-world prototype: card + sample + MIDI enumeration

> Plan ID #21 · GitHub #13 · Phase 0

## Goal
One screen: hard-coded TIER_GOD/OG card, plays a synthesized snare on tap (AVAudioEngine), prints connected MIDI sources to debug console

## Likely files
- `Features/Drops/PrototypeCard.swift`
- `Audio/DrumAudioEngine.swift` (stub)
- `MIDI/MIDIInputManager.swift` (stub)

## Acceptance criteria / tests
- [ ] Runs on iPad sim + iPad-app-on-Mac mode where available; MIDI sources visible when a real/virtual MIDI source is running

## Dependencies
Depends on: #12

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
