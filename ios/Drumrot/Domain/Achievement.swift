import Foundation

/// One achievement definition. Mirror of an `ACHIEVEMENTS` entry in `js/achievements.js`.
///
/// Issue #72 additions:
/// - `difficulty`: the drop-weight bucket, also shown as a badge on achievement tiles.
/// - `isSecret`: fully hidden achievements show a padlock, no name or hint. Limited to <= 3.
/// - `hint`: a brief unlock condition shown to players for non-secret achievements.
/// - `cat` uses renamed category labels: "on_the_kit", "showing_up", "speed_runs", "craft_crew".
struct Achievement: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let desc: String
    let icon: String
    let cat: String
    /// Drop difficulty bucket — drives the rarity badge on the achievement tile.
    let difficulty: String
    /// Whether this achievement is fully hidden (lock icon, no name or hint).
    let isSecret: Bool
    /// A short unlock hint shown to players. Empty for secret achievements.
    let hint: String

    var dropDifficulty: DropDifficulty {
        DropDifficulty(rawValue: difficulty) ?? .entry
    }

    var categoryDisplayName: String {
        switch cat {
        case "on_the_kit":   return "On the Kit"
        case "showing_up":   return "Showing Up"
        case "speed_runs":   return "Speed Runs"
        case "craft_crew":   return "Craft Crew"
        // legacy fallbacks
        case "performance":  return "On the Kit"
        case "consistency":  return "Showing Up"
        case "tempo":        return "Speed Runs"
        case "builder":      return "Craft Crew"
        default:             return cat
        }
    }

    var categoryIcon: String {
        switch cat {
        case "on_the_kit", "performance":  return "🥁"
        case "showing_up", "consistency":  return "📅"
        case "speed_runs", "tempo":        return "⚡"
        case "craft_crew", "builder":      return "🎛️"
        default: return "★"
        }
    }
}

enum AchievementCatalog {
    static let all: [Achievement] = load()

    private static func load() -> [Achievement] {
        guard let url = Bundle.main.url(forResource: "Achievements", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            assertionFailure("Achievements.json missing from bundle")
            return []
        }
        do {
            return try JSONDecoder().decode([Achievement].self, from: data)
        } catch {
            assertionFailure("Achievements.json decode failed: \(error)")
            return []
        }
    }
}
