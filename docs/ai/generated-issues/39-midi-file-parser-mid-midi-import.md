# MIDI file parser — `.mid` / `.midi` import

> Plan ID #47 · GitHub #39 · Phase 8

## Goal
Standard MIDI header / track chunks, PPQ timing, running status, note-on, meta/sysex skips; reject SMPTE; map GM drum notes to 6 lanes; quantize to eighth-note (ppq/2); create custom `ExtraLesson`

## Likely files
- `Domain/MIDIFileParser.swift`
- `GMDrumMapper.swift`
- `Features/Library/MIDIImportSheet.swift`

## Acceptance criteria / tests
- [ ] XCTest fixtures: valid, invalid, running-status, multi-track, SMPTE rejection

## Dependencies
Depends on: #21, #35

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
