# CoreMIDI input — USB + Network MIDI + source enumeration

> Plan ID #49 · GitHub #41 · Phase 8

## Goal
`MIDIClient`, `MIDIInputPort`, source enumeration, marshal hits to MainActor; MIDINetworkSession enabled (`.anyone` dev, `.hostInitiated` release); device-add/remove notifications

## Likely files
- `MIDI/MIDIInputManager.swift`
- `MIDITransport.swift`
- `NetworkMIDISession+Setup.swift`
- `GMDrumMapper.swift`

## Acceptance criteria / tests
- [ ] Manual: real/virtual MIDI source → iPad app sees notes → highway responds with low latency; repeat in iPad-app-on-Mac mode where available

## Dependencies
Depends on: #24, #34

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
