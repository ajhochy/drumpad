import Foundation
import SwiftData

/// Evaluates achievement rules on game events (port of `checkAchievements`),
/// unlocks new ones, and fires toast + drop-reveal through the AppStore.
///
/// Issue #72 changes:
/// - `creator` threshold raised to 3 saved grooves (was 1)
/// - `coach` threshold raised to 3 grooved with coach notes (was 1)
/// - drop roller now receives collection counts for the pity mechanic
@MainActor
final class AchievementEngine {
    private let context: ModelContext
    weak var store: AppStore?

    init(context: ModelContext) { self.context = context }

    private var persistence: PersistenceService { PersistenceService(context: context) }

    enum Event {
        case hit(combo: Int)
        case pass(accuracy: Int, stars: Int, bpm: Int, lessonKey: String, lessonBpm: Int?, isPrebuilt: Bool)
        /// `savedCount`: total number of grooves the user has ever saved.
        case creator(savedCount: Int)
        /// `coachedCount`: total number of grooves that have a coach note attached.
        case coach(coachedCount: Int)
    }

    func fire(_ event: Event) {
        var ids: [String] = []
        switch event {
        case .hit(let combo):
            ids.append("first_hit")
            if combo >= 50  { ids.append("combo_50") }
            if combo >= 100 { ids.append("combo_100") }
            if combo >= 200 { ids.append("combo_200") }

        case let .pass(acc, stars, bpm, key, lessonBpm, isPrebuilt):
            ids.append("first_pass")
            if acc == 100 { ids.append("perfect_pass") }
            if stars == 3 { ids.append("groove_master") }
            if acc >= 80 && bpm >= 160 { ids.append("speed_demon") }
            if acc >= 80 && bpm <= 60  { ids.append("slow_burn") }

            if let store {
                store.consecutiveAccuratePasses = acc >= 90 ? store.consecutiveAccuratePasses + 1 : 0
                if store.consecutiveAccuratePasses >= 3 { ids.append("sharpshooter") }
            }

            if isPrebuilt, let lessonBpm,
               let tier = PracticeTier.forPass(accuracy: acc, bpm: bpm, lessonBpm: lessonBpm) {
                persistence.recordPass(lessonKey: key, score: 0, accuracy: 0, tier: tier.rawValue)
            }

            let streak = PracticeStreak.current(playDays: playDaySet())
            if streak >= 3 { ids.append("streak_3") }
            if streak >= 7 { ids.append("streak_7") }

            let prebuilt = Set(LessonCatalog.all.map(\.name))
            let scores = allScores()
            let played = scores.filter { prebuilt.contains($0.lessonKey) }
            if played.count >= prebuilt.count { ids.append("all_grooves") }
            if played.filter({ $0.stars >= 3 }).count >= prebuilt.count { ids.append("graduate") }
            if scores.filter({ $0.practiceTier >= PracticeTier.grooving.rawValue }).count >= 3 { ids.append("tempo_climber") }
            if scores.filter({ $0.practiceTier >= PracticeTier.killingIt.rawValue }).count >= 5 { ids.append("full_throttle") }

        case .creator(let savedCount):
            // Threshold raised from 1 to 3 (issue #72)
            if savedCount >= 3 { ids.append("creator") }

        case .coach(let coachedCount):
            // Threshold raised from 1 to 3 (issue #72)
            if coachedCount >= 3 { ids.append("coach") }
        }

        ids.forEach(award)
    }

    private func award(_ id: String) {
        guard persistence.unlock(id) else { return }
        try? context.save()
        guard let ach = AchievementCatalog.all.first(where: { $0.id == id }) else { return }
        store?.enqueueToast(ach)
        // Pass collection counts for the pity mechanic.
        let counts = collectionCounts()
        let roll = DropRoller.roll(achievementId: id, collectionCounts: counts) { Double.random(in: 0..<1) }
        let isNew = persistence.collect(drumrotId: roll.drumrot.id, tier: roll.tier)
        try? context.save()
        store?.enqueueReveal(.init(drumrot: roll.drumrot, tier: roll.tier, fromAchievement: ach.name, isNew: isNew))
    }

    private func allScores() -> [LessonScore] {
        (try? context.fetch(FetchDescriptor<LessonScore>())) ?? []
    }

    private func playDaySet() -> Set<String> {
        Set(((try? context.fetch(FetchDescriptor<PracticeDay>())) ?? []).map(\.day))
    }

    /// Returns a map of drumrot id -> pull count for the pity mechanic.
    private func collectionCounts() -> [String: Int] {
        let entries = (try? context.fetch(FetchDescriptor<DrumrotCollectionEntry>())) ?? []
        return Dictionary(entries.map { ($0.drumrotId, $0.count) }, uniquingKeysWith: max)
    }
}
