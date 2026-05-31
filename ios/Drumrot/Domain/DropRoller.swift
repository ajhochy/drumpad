import Foundation

/// Difficulty bucket for an achievement.
/// The labels drive both the drop-weight table and the UI difficulty badge shown
/// on achievement tiles in the Progress tab.
enum DropDifficulty: String, CaseIterable {
    case entry, easy, medium, hard, elite

    /// Tier weights `[common, rare, epic, legendary, og]` (5 tiers after collapse).
    /// The OG column is 0 here — OG is granted by the separate `ogChance` bonus,
    /// which varies per achievement (see `DropRoller.ogChance(for:)`).
    ///
    /// Elite floor: common and rare removed so elite achievements never drop
    /// the two lowest tiers. Probability redistributed to epic/legendary.
    var tierWeights: [Double] {
        switch self {
        case .entry:  return [60, 32,  8,  0,  0]
        case .easy:   return [30, 45, 20,  5,  0]
        case .medium: return [ 0, 25, 45, 25,  5]
        case .hard:   return [ 0,  0, 35, 50, 15]
        case .elite:  return [ 0,  0, 15, 60, 25]
        }
    }

    var displayName: String {
        switch self {
        case .entry:  return "Entry"
        case .easy:   return "Easy"
        case .medium: return "Medium"
        case .hard:   return "Hard"
        case .elite:  return "Elite"
        }
    }
}

/// Drop-roll math updated for the 5-tier system.
/// The RNG is injected so tests are deterministic; production passes `Double.random`.
enum DropRoller {
    /// Default OG flat-upgrade chance (5%).
    static let defaultOGChance = 0.05

    /// Per-achievement OG upgrade chance. `graduate` and `full_throttle` get 10%
    /// because they are the hardest long-term achievements in the game.
    static func ogChance(for achievementId: String) -> Double {
        switch achievementId {
        case "graduate", "full_throttle": return 0.10
        default: return defaultOGChance
        }
    }

    static let achievementDifficulty: [String: DropDifficulty] = [
        // Entry — first-time actions, no skill barrier
        "first_hit": .entry, "first_pass": .entry, "creator": .entry,
        // Easy — low-bar combos, short streak, chill BPM exploration
        "combo_50": .easy, "streak_3": .easy, "slow_burn": .easy, "coach": .easy,
        // Medium — groove mastery intro, moderate combo, week streak
        "groove_master": .medium, "combo_100": .medium, "streak_7": .medium,
        // Hard — full lesson coverage, high accuracy, speed demon
        "all_grooves": .hard, "sharpshooter": .hard, "speed_demon": .hard, "tempo_climber": .hard,
        // Elite — sustained mastery (200 combo, perfect pass, all 3-star, killing-it x 5)
        "combo_200": .elite, "perfect_pass": .elite, "graduate": .elite, "full_throttle": .elite,
    ]

    struct Roll: Equatable {
        let drumrot: Drumrot
        let tier: DrumrotTier
    }

    /// Rolls a drumrot drop for an achievement.
    ///
    /// - Parameters:
    ///   - achievementId: The achievement that triggered the drop.
    ///   - catalog: The full drumrot roster (injectable for tests).
    ///   - collectionCounts: Map of drumrot id -> how many times that character has
    ///     been pulled. Used for the pity mechanic: picks prefer characters the player
    ///     has pulled the fewest times, eliminating the "I got Drumbeano again" experience.
    ///   - rng: A value in `[0, 1)`. Called in order: OG check -> tier weight -> pool pick.
    static func roll(achievementId: String,
                     catalog: [Drumrot] = DrumrotCatalog.all,
                     collectionCounts: [String: Int] = [:],
                     rng: () -> Double) -> Roll {
        let difficulty = achievementDifficulty[achievementId] ?? .entry

        // Step 1: OG flat-upgrade check (5% or 10% for graduate/full_throttle).
        let tier: DrumrotTier
        if rng() < ogChance(for: achievementId) {
            tier = .og
        } else {
            // Step 2: Weighted tier draw from the 5-tier table.
            let weights = difficulty.tierWeights
            let r = rng() * 100
            var cum = 0.0
            var idx = 0
            for i in 0..<weights.count {
                cum += weights[i]
                if r < cum { idx = i; break }
            }
            tier = DrumrotTier.order[min(idx, DrumrotTier.order.count - 1)]
        }

        // Step 3: Pick a drumrot from the matching-tier pool.
        var pool = catalog.filter { $0.tier == tier }
        if pool.isEmpty { pool = catalog }

        // Pity mechanic: prefer characters the player has collected least.
        // Sort pool by pull count (ascending); pick from the lowest-count cohort.
        // This guarantees that after 3+ duplicates of any character, the next pick
        // in that tier will land on something fresher.
        let sorted = pool.sorted { (collectionCounts[$0.id] ?? 0) < (collectionCounts[$1.id] ?? 0) }
        let minCount = collectionCounts[sorted[0].id] ?? 0
        let pityCandidates = sorted.filter { (collectionCounts[$0.id] ?? 0) == minCount }
        let source = pityCandidates.isEmpty ? pool : pityCandidates

        let pick = min(Int(rng() * Double(source.count)), source.count - 1)
        return Roll(drumrot: source[pick], tier: tier)
    }
}
