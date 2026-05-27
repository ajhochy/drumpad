import Foundation

/// The 7 collection tiers, in ascending order. Mirrors `TIERS_ORDER` / `TIER_CONFIG`
/// in `js/drumrots.js`. Declaration order IS the tier order (index 0...6).
enum DrumrotTier: String, CaseIterable, Codable, Equatable {
    case common, rare, epic, legendary, mythic, god, og

    /// Order index 0...6 (matches the web `idx`).
    var index: Int { Self.allCases.firstIndex(of: self)! }

    /// Ascending tier order: common … og.
    static let order: [DrumrotTier] = allCases

    var displayName: String {
        switch self {
        case .common: return "Common"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        case .mythic: return "Mythic"
        case .god: return "Drumrot God"
        case .og: return "OG"
        }
    }

    var label: String {
        switch self {
        case .common: return "COMMON"
        case .rare: return "RARE"
        case .epic: return "EPIC"
        case .legendary: return "LEGENDARY"
        case .mythic: return "MYTHIC"
        case .god: return "DRUMROT GOD"
        case .og: return "OG · PRISMATIC"
        }
    }

    /// Tier accent color hex (from `TIER_CONFIG`).
    var hexColor: String {
        switch self {
        case .common: return "#9aa5b4"
        case .rare: return "#3b82f6"
        case .epic: return "#a855f7"
        case .legendary: return "#f59e0b"
        case .mythic: return "#ec4899"
        case .god: return "#ff3a5a"
        case .og: return "#ffffff"
        }
    }
}
