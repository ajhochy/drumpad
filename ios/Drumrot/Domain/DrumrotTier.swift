import Foundation

/// The 5 collection tiers, in ascending order. Collapsed from the original 7:
/// - legendary absorbs mythic
/// - og absorbs god (both are ultra-rare; one holofoil tier is more impactful)
///
/// Migration: old `mythic` raw values decode to `legendary`; old `god` raw values
/// decode to `og`. The `init(from:)` custom decoder handles legacy data gracefully.
enum DrumrotTier: String, CaseIterable, Codable, Equatable {
    case common, rare, epic, legendary, og

    // MARK: - Codable migration from 7-tier legacy data

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "common":    self = .common
        case "rare":      self = .rare
        case "epic":      self = .epic
        case "legendary", "mythic": self = .legendary   // collapse mythic → legendary
        case "god", "og":           self = .og           // collapse god → og
        default:          self = .common                 // safe fallback
        }
    }

    /// Order index 0...4 (ascending rarity).
    var index: Int { Self.allCases.firstIndex(of: self)! }

    /// Ascending tier order: common … og.
    static let order: [DrumrotTier] = allCases

    var displayName: String {
        switch self {
        case .common:    return "Common"
        case .rare:      return "Rare"
        case .epic:      return "Epic"
        case .legendary: return "Legendary"
        case .og:        return "OG"
        }
    }

    var label: String {
        switch self {
        case .common:    return "COMMON"
        case .rare:      return "RARE"
        case .epic:      return "EPIC"
        case .legendary: return "LEGENDARY"
        case .og:        return "OG · PRISMATIC"
        }
    }

    /// Tier accent color (from original `TIER_CONFIG`, mythic/god colors merged up).
    var hexColor: String {
        switch self {
        case .common:    return "#9aa5b4"
        case .rare:      return "#3b82f6"
        case .epic:      return "#a855f7"
        case .legendary: return "#f59e0b"
        case .og:        return "#ffffff"
        }
    }

}
