import Foundation

/// The 6 drum lanes, in canonical order (mirror of `LANES` in `js/lessons.js`).
/// rawValue == lane index used throughout scoring/notes.
enum DrumLane: Int, CaseIterable, Codable {
    case crash, hihat, snare, kick, tom, ride

    var key: String {
        switch self {
        case .crash: return "crash"
        case .hihat: return "hihat"
        case .snare: return "snare"
        case .kick:  return "kick"
        case .tom:   return "tom"
        case .ride:  return "ride"
        }
    }

    var label: String {
        switch self {
        case .crash: return "CR"
        case .hihat: return "HH"
        case .snare: return "SN"
        case .kick:  return "KK"
        case .tom:   return "TM"
        case .ride:  return "RD"
        }
    }

    /// Pad display name (matches the web pad labels).
    var padName: String {
        switch self {
        case .crash: return "Crash"
        case .hihat: return "Hi-Hat"
        case .snare: return "Snare"
        case .kick:  return "Kick"
        case .tom:   return "Tom"
        case .ride:  return "Ride"
        }
    }

    /// Keyboard hint shown on the pad (web A/S/D/F/J/K mapping).
    var keyHint: String {
        switch self {
        case .crash: return "A"
        case .hihat: return "S"
        case .snare: return "D"
        case .kick:  return "F"
        case .tom:   return "J"
        case .ride:  return "K"
        }
    }

    static func from(key: String) -> DrumLane? {
        allCases.first { $0.key == key }
    }
}
