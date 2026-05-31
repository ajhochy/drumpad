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
    func recordPass(lessonKey: String, score: Int, accuracy: Int, tier: Int? = nil) -> LessonScore {
        let row = fetchOne(LessonScore.self, #Predicate { $0.lessonKey == lessonKey }) ?? {
            let created = LessonScore(lessonKey: lessonKey)
            context.insert(created)
            return created
        }()
        row.high = max(row.high, score)
        row.stars = max(row.stars, ScoringEngine.stars(accuracy: accuracy))
        row.plays += 1
        row.lastAccuracy = accuracy
        if let tier { row.practiceTier = max(row.practiceTier, tier) }
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

    /// Upserts a user-authored lesson (groove-builder save or MIDI import) by
    /// name. Mirrors the ios16 PersistenceStore.saveExtraLesson semantics.
    func saveExtraLesson(name: String, lessonJSON: String) {
        if let row = fetchOne(ExtraLesson.self, #Predicate { $0.name == name }) {
            row.lessonJSON = lessonJSON
            row.createdAt = .now
        } else {
            context.insert(ExtraLesson(name: name, lessonJSON: lessonJSON))
        }
        try? context.save()
    }

    /// Renames a user-authored lesson in-place, preserving its `createdAt` timestamp.
    ///
    /// Implementation note: `ExtraLesson.name` carries `@Attribute(.unique)`, so
    /// we cannot mutate it directly — SwiftData will reject it with a constraint
    /// violation.  Instead we delete the old row and insert a new one, patching
    /// the `name` field inside the JSON payload so the encoded Lesson round-trips
    /// correctly.
    ///
    /// Returns `true` on success, `false` if the source row is missing or the new
    /// name already exists.
    @discardableResult
    func renameExtraLesson(from oldName: String, to newName: String) -> Bool {
        guard let oldRow = fetchOne(ExtraLesson.self, #Predicate { $0.name == oldName }) else { return false }
        guard fetchOne(ExtraLesson.self, #Predicate { $0.name == newName }) == nil else { return false }

        // Patch name inside the JSON payload.
        let newJSON: String
        if let data = oldRow.lessonJSON.data(using: .utf8),
           let orig = try? JSONDecoder().decode(Lesson.self, from: data),
           let encoded = try? JSONEncoder().encode(
               Lesson(name: newName, bpm: orig.bpm, tip: orig.tip,
                      difficulty: orig.difficulty, genre: orig.genre,
                      patterns: orig.patterns)),
           let str = String(data: encoded, encoding: .utf8) {
            newJSON = str
        } else {
            newJSON = oldRow.lessonJSON
        }

        let createdAt = oldRow.createdAt
        context.delete(oldRow)
        context.insert(ExtraLesson(name: newName, lessonJSON: newJSON, createdAt: createdAt))
        try? context.save()
        return true
    }

    /// Removes a user-authored lesson by name. No-op if absent.
    func deleteExtraLesson(name: String) {
        guard let row = fetchOne(ExtraLesson.self, #Predicate { $0.name == name }) else { return }
        context.delete(row)
        try? context.save()
    }

    /// Decoded view of every user-authored lesson. Rows whose JSON fails to
    /// decode are silently skipped — a single corrupt blob shouldn't hide the
    /// rest of the library.
    func extraLessonsAsLessons() -> [Lesson] {
        let rows = (try? context.fetch(FetchDescriptor<ExtraLesson>())) ?? []
        let decoder = JSONDecoder()
        return rows.compactMap { row in
            guard let data = row.lessonJSON.data(using: .utf8) else { return nil }
            return try? decoder.decode(Lesson.self, from: data)
        }
    }

    private func fetchOne<T: PersistentModel>(_ type: T.Type, _ predicate: Predicate<T>) -> T? {
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try? context.fetch(descriptor).first
    }
}
