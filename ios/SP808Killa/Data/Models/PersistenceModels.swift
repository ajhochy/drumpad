import Foundation
import SwiftData

// SwiftData models mirroring the web `localStorage` keys (see Data/SchemaMapping
// in the plan). Every model carries `schemaVersion` for future migration / recovery.

/// `drum.scores` — one row per lesson.
@Model
final class LessonScore {
    @Attribute(.unique) var lessonKey: String
    var high: Int
    var stars: Int
    var plays: Int
    var lastAccuracy: Int
    var updatedAt: Date
    var schemaVersion: Int

    init(lessonKey: String, high: Int = 0, stars: Int = 0, plays: Int = 0,
         lastAccuracy: Int = 0, updatedAt: Date = .now, schemaVersion: Int = 1) {
        self.lessonKey = lessonKey
        self.high = high
        self.stars = stars
        self.plays = plays
        self.lastAccuracy = lastAccuracy
        self.updatedAt = updatedAt
        self.schemaVersion = schemaVersion
    }
}

/// `drum.achievements` — one row per unlocked achievement id.
@Model
final class AchievementUnlock {
    @Attribute(.unique) var achievementId: String
    var unlockedAt: Date
    var schemaVersion: Int

    init(achievementId: String, unlockedAt: Date = .now, schemaVersion: Int = 1) {
        self.achievementId = achievementId
        self.unlockedAt = unlockedAt
        self.schemaVersion = schemaVersion
    }
}

/// `drum.playDays` — one row per practiced day (yyyy-MM-dd, UTC).
@Model
final class PracticeDay {
    @Attribute(.unique) var day: String
    var schemaVersion: Int

    init(day: String, schemaVersion: Int = 1) {
        self.day = day
        self.schemaVersion = schemaVersion
    }
}

/// `drum.extraLessons` — custom (builder/MIDI-import) lessons, stored as encoded JSON.
@Model
final class ExtraLesson {
    @Attribute(.unique) var name: String
    var lessonJSON: String
    var createdAt: Date
    var schemaVersion: Int

    init(name: String, lessonJSON: String, createdAt: Date = .now, schemaVersion: Int = 1) {
        self.name = name
        self.lessonJSON = lessonJSON
        self.createdAt = createdAt
        self.schemaVersion = schemaVersion
    }
}

/// `drum.collection` — one row per collected drumrot id (highest tier index kept).
@Model
final class DrumrotCollectionEntry {
    @Attribute(.unique) var drumrotId: String
    var tierIndex: Int
    var count: Int
    var firstAt: Date
    var schemaVersion: Int

    init(drumrotId: String, tierIndex: Int, count: Int = 1, firstAt: Date = .now, schemaVersion: Int = 1) {
        self.drumrotId = drumrotId
        self.tierIndex = tierIndex
        self.count = count
        self.firstAt = firstAt
        self.schemaVersion = schemaVersion
    }
}

/// `drum.builder` — the single builder pattern (16/32 steps × 6 lanes as JSON).
@Model
final class BuilderState {
    var steps: Int
    var patternJSON: String
    var bpm: Int
    var coachNote: String
    var schemaVersion: Int

    init(steps: Int = 16, patternJSON: String = "{}", bpm: Int = 90, coachNote: String = "", schemaVersion: Int = 1) {
        self.steps = steps
        self.patternJSON = patternJSON
        self.bpm = bpm
        self.coachNote = coachNote
        self.schemaVersion = schemaVersion
    }
}
