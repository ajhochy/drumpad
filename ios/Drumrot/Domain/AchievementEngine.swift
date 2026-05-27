import Foundation

/// Evaluates achievement rules on game events (port of `checkAchievements`),
/// unlocks new ones, and fires toast + drop-reveal through the AppStore.
@MainActor
final class AchievementEngine {
    private let persistence: PersistenceStore
    weak var store: AppStore?

    init(persistence: PersistenceStore) { self.persistence = persistence }

    enum Event {
        case hit(combo: Int)
        case pass(accuracy: Int, stars: Int, bpm: Int, lessonKey: String, lessonBpm: Int?, isPrebuilt: Bool)
        case creator
        case coach
    }

    func fire(_ event: Event) {
        var ids: [String] = []
        switch event {
        case .hit(let combo):
            ids.append("first_hit")
            if combo >= 50 { ids.append("combo_50") }
            if combo >= 100 { ids.append("combo_100") }
            if combo >= 200 { ids.append("combo_200") }

        case let .pass(acc, stars, bpm, key, lessonBpm, isPrebuilt):
            ids.append("first_pass")
            if acc == 100 { ids.append("perfect_pass") }
            if stars == 3 { ids.append("groove_master") }
            if acc >= 80 && bpm >= 160 { ids.append("speed_demon") }
            if acc >= 80 && bpm <= 60 { ids.append("slow_burn") }

            if let store {
                store.consecutiveAccuratePasses = acc >= 90 ? store.consecutiveAccuratePasses + 1 : 0
                if store.consecutiveAccuratePasses >= 3 { ids.append("sharpshooter") }
            }

            if isPrebuilt, let lessonBpm,
               let tier = PracticeTier.forPass(accuracy: acc, bpm: bpm, lessonBpm: lessonBpm) {
                persistence.recordPass(lessonKey: key, score: 0, accuracy: 0, tier: tier.rawValue)
                // (score/accuracy already recorded by the caller; this only lifts the tier)
            }

            let streak = PracticeStreak.current(playDays: Set(persistence.playDays.map(\.day)))
            if streak >= 3 { ids.append("streak_3") }
            if streak >= 7 { ids.append("streak_7") }

            let prebuilt = Set(LessonCatalog.all.map(\.name))
            let scores = persistence.scores
            let played = scores.filter { prebuilt.contains($0.lessonKey) }
            if played.count >= prebuilt.count { ids.append("all_grooves") }
            if played.filter({ $0.stars >= 3 }).count >= prebuilt.count { ids.append("graduate") }
            if scores.filter({ $0.practiceTier >= PracticeTier.grooving.rawValue }).count >= 3 { ids.append("tempo_climber") }
            if scores.filter({ $0.practiceTier >= PracticeTier.killingIt.rawValue }).count >= 5 { ids.append("full_throttle") }

        case .creator:
            ids.append("creator")
        case .coach:
            ids.append("coach")
        }

        ids.forEach(award)
    }

    private func award(_ id: String) {
        guard persistence.unlock(id) else { return }
        guard let ach = AchievementCatalog.all.first(where: { $0.id == id }) else { return }
        store?.enqueueToast(ach)
        let roll = DropRoller.roll(achievementId: id) { Double.random(in: 0..<1) }
        let isNew = persistence.collect(drumrotId: roll.drumrot.id, tier: roll.tier)
        store?.enqueueReveal(.init(drumrot: roll.drumrot, tier: roll.tier, fromAchievement: ach.name, isNew: isNew))
    }
}
