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

    static func from(key: String) -> DrumLane? {
        allCases.first { $0.key == key }
    }
}
