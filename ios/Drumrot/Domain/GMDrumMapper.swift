import Foundation

/// General MIDI drum-note ↔ lane mapping (port of `midiNoteToLane` + export notes
/// in `js/midi-file.js` / `js/midi-device.js`).
enum GMDrumMapper {
    /// Export note per lane: crash 49, hihat 42, snare 38, kick 36, tom 45, ride 51.
    static let gmNotes = [49, 42, 38, 36, 45, 51]

    static func gmNote(for lane: DrumLane) -> Int { gmNotes[lane.rawValue] }

    static func lane(forNote note: Int) -> DrumLane? {
        switch note {
        case 35, 36: return .kick
        case 37, 38, 39, 40: return .snare
        case 42, 44, 46: return .hihat
        case 41, 43, 45, 47, 48, 50: return .tom
        case 49, 52, 55, 57: return .crash
        case 51, 53, 56, 59: return .ride
        default: return nil
        }
    }
}
