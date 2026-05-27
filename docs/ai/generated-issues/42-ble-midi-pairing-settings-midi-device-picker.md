# BLE MIDI pairing + Settings MIDI device picker

> Plan ID #50 · GitHub #42 · Phase 8

## Goal
Settings → "Pair Bluetooth MIDI" → CABTMIDICentralViewController; list USB + Network sources by name + UID; auto-reconnect; "All Sources" toggle; activity LED on note-on

## Likely files
- `Features/Settings/MIDIDevicePicker.swift`
- `BluetoothMIDIPairing.swift`
- `Audio/MIDIActivityLED.swift`

## Acceptance criteria / tests
- [ ] Manual: BLE pad pairs + streams notes; pick a device → kill app → relaunch → still selected

## Dependencies
Depends on: #18, #41

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
