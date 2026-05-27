# MIDI file exporter — `sp808-pattern.mid`

> Plan ID #48 · GitHub #40 · Phase 8

## Goal
Type 0 MIDI, PPQ 96, tempo meta, channel 10 note-on/off, GM notes `[49, 42, 38, 36, 45, 51]`; share sheet

## Likely files
- `Domain/MIDIFileExporter.swift`
- `Features/Builder/MIDIExportSheet.swift`

## Acceptance criteria / tests
- [ ] XCTest: byte-exact match against web export; round-trip parser test

## Dependencies
Depends on: #37, #39

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
