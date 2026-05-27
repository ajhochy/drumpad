import Foundation

/// Difficulty bucket for an achievement (mirror of `ACHIEVEMENT_DIFFICULTY`).
enum DropDifficulty: String {
    case easy, medium, hard, elite

    /// Tier weights `[common, rare, epic, legendary, mythic, god, og]`.
    /// The OG column is 0 — OG is granted by the separate flat `ogChance` bonus.
    var tierWeights: [Double] {
        switch self {
        case .easy:   return [55, 35,  8,  2,  0,  0, 0]
        case .medium: return [20, 40, 25, 10,  4,  1, 0]
        case .hard:   return [ 5, 15, 35, 30, 12,  3, 0]
        case .elite:  return [ 0,  5, 20, 35, 25, 15, 0]
        }
    }
}

/// Drop-roll math, ported verbatim from `rollDrumrot` in `js/drumrots.js`.
/// The RNG is injected so tests are deterministic; production passes `Double.random`.
enum DropRoller {
    static let ogChance = 0.05

    static let achievementDifficulty: [String: DropDifficulty] = [
        "first_hit": .easy, "first_pass": .easy, "creator": .easy,
        "combo_50": .medium, "groove_master": .medium, "streak_3": .medium,
        "slow_burn": .medium, "speed_demon": .medium, "coach": .medium,
        "combo_100": .hard, "sharpshooter": .hard, "all_grooves": .hard,
        "tempo_climber": .hard, "streak_7": .hard,
        "combo_200": .elite, "perfect_pass": .elite, "graduate": .elite, "full_throttle": .elite,
    ]

    struct Roll: Equatable {
        let drumrot: Drumrot
        let tier: DrumrotTier
    }

    /// `rng` yields values in `[0, 1)`. Called in the same order as the JS
    /// `Math.random()` calls: OG check → weighted tier → pool pick.
    static func roll(achievementId: String,
                     catalog: [Drumrot] = DrumrotCatalog.all,
                     rng: () -> Double) -> Roll {
        let difficulty = achievementDifficulty[achievementId] ?? .easy

        let tier: DrumrotTier
        if rng() < ogChance {
            tier = .og
        } else {
            let weights = difficulty.tierWeights
            let r = rng() * 100
            var cum = 0.0
            var idx = 0
            for i in 0..<weights.count {
                cum += weights[i]
                if r < cum { idx = i; break }
            }
            tier = DrumrotTier.order[idx]
        }

        let pool = catalog.filter { $0.tier == tier }
        let source = pool.isEmpty ? catalog : pool
        let pick = min(Int(rng() * Double(source.count)), source.count - 1)
        return Roll(drumrot: source[pick], tier: tier)
    }
}
