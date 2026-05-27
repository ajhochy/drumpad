# AVAudioEngine drum synth — kick/snare/tom/crash/hihat/ride

> Plan ID #32 · GitHub #24 · Phase 3

## Goal
Synthesize matching the web Web Audio character; one `AVAudioPlayerNode` per voice; preloaded buffers; `play(lane:velocity:)`

## Likely files
- `Audio/DrumAudioEngine.swift`
- `VoiceSynth.swift`
- `Resources/Sounds/` (if buffers cached to disk)

## Acceptance criteria / tests
- [ ] Manual: pad tap → distinct sound per lane; input-to-sound latency target ≤ 10 ms measured on real iPad

## Dependencies
Depends on: #19

## Notes
- Manual merge only; branch per workflow run.
- Data safety: do not commit `.DS_Store`, Xcode user state, derived data, signing files, or generated images outside the asset catalog.
