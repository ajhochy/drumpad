import Foundation
import SwiftData

/// Thin write/upsert layer over a `ModelContext`, encoding the web's persistence
/// rules (score = max, achievement unlock once, play day once, collection
/// upgrade-only). Pure enough to unit-test against an in-memory container.
@MainActor
struct PersistenceService {
    let context: ModelContext

    /// Records a completed pass for a lesson, returning the (created/updated) row.
    @discardableResult
    func recordPass(lessonKey: String, score: Int, accuracy: Int) -> LessonScore {
        let row = fetchOne(LessonScore.self, #Predicate { $0.lessonKey == lessonKey }) ?? {
            let created = LessonScore(lessonKey: lessonKey)
            context.insert(created)
            return created
        }()
        row.high = max(row.high, score)
        row.stars = max(row.stars, ScoringEngine.stars(accuracy: accuracy))
        row.plays += 1
        row.lastAccuracy = accuracy
        row.updatedAt = .now
        return row
    }

    /// Unlocks an achievement. Returns true if it was newly unlocked.
    @discardableResult
    func unlock(_ achievementId: String) -> Bool {
        guard fetchOne(AchievementUnlock.self, #Predicate { $0.achievementId == achievementId }) == nil else {
            return false
        }
        context.insert(AchievementUnlock(achievementId: achievementId))
        return true
    }

    /// Marks a practice day (idempotent).
    func recordPlayDay(_ day: String) {
        if fetchOne(PracticeDay.self, #Predicate { $0.day == day }) == nil {
            context.insert(PracticeDay(day: day))
        }
    }

    /// Adds a drumrot pull. Returns true if new or a tier upgrade (count always ++).
    @discardableResult
    func collect(drumrotId: String, tier: DrumrotTier) -> Bool {
        if let row = fetchOne(DrumrotCollectionEntry.self, #Predicate { $0.drumrotId == drumrotId }) {
            row.count += 1
            if tier.index > row.tierIndex {
                row.tierIndex = tier.index
                return true
            }
            return false
        }
        context.insert(DrumrotCollectionEntry(drumrotId: drumrotId, tierIndex: tier.index))
        return true
    }

    func collectedCount() -> Int {
        (try? context.fetchCount(FetchDescriptor<DrumrotCollectionEntry>())) ?? 0
    }

    private func fetchOne<T: PersistentModel>(_ type: T.Type, _ predicate: Predicate<T>) -> T? {
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
