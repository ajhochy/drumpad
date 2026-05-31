import Foundation
import SwiftUI

// MARK: - Model types (Codable replacements for the SwiftData @Model classes)

struct LessonScore: Codable, Identifiable, Equatable {
    var lessonKey: String
    var high: Int = 0
    var stars: Int = 0
    var plays: Int = 0
    var lastAccuracy: Int = 0
    var practiceTier: Int = -1
    var updatedAt: Date = .now
    var schemaVersion: Int = 1
    var id: String { lessonKey }
}

struct AchievementUnlock: Codable, Identifiable, Equatable {
    var achievementId: String
    var unlockedAt: Date = .now
    var schemaVersion: Int = 1
    var id: String { achievementId }
}

struct PracticeDay: Codable, Identifiable, Equatable {
    var day: String
    var schemaVersion: Int = 1
    var id: String { day }
}

struct ExtraLesson: Codable, Identifiable, Equatable {
    var name: String
    var lessonJSON: String
    var createdAt: Date = .now
    var schemaVersion: Int = 1
    var id: String { name }
}

struct DrumrotCollectionEntry: Codable, Identifiable, Equatable {
    var drumrotId: String
    var tierIndex: Int
    var count: Int = 1
    var firstAt: Date = .now
    var schemaVersion: Int = 1
    var id: String { drumrotId }
}

struct BuilderState: Codable, Equatable {
    var steps: Int = 16
    var patternJSON: String = "{}"
    var bpm: Int = 90
    var coachNote: String = ""
    var schemaVersion: Int = 1
}

struct AppSettings: Codable, Equatable {
    var schemaVersion: Int = 1
    var midiDeviceUID: String? = nil
    var audioLatencyOffsetMs: Int = 0
    var hapticsEnabled: Bool = true
    var reduceMotionOverride: Bool = false
    var lastTab: String = "play"
    /// When true, MIDI-triggered note-ons skip in-app sample playback so the
    /// user can monitor through their drum module's own headphone output
    /// without a doubled hit. On-screen pad gestures + metronome are
    /// unaffected (#60).
    var externalAudioMode: Bool = false

    init(schemaVersion: Int = 1,
         midiDeviceUID: String? = nil,
         audioLatencyOffsetMs: Int = 0,
         hapticsEnabled: Bool = true,
         reduceMotionOverride: Bool = false,
         lastTab: String = "play",
         externalAudioMode: Bool = false) {
        self.schemaVersion = schemaVersion
        self.midiDeviceUID = midiDeviceUID
        self.audioLatencyOffsetMs = audioLatencyOffsetMs
        self.hapticsEnabled = hapticsEnabled
        self.reduceMotionOverride = reduceMotionOverride
        self.lastTab = lastTab
        self.externalAudioMode = externalAudioMode
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, midiDeviceUID, audioLatencyOffsetMs,
             hapticsEnabled, reduceMotionOverride, lastTab, externalAudioMode
    }

    /// Tolerates missing keys so additive schema changes don't reset
    /// users' existing settings to defaults on first launch of the new
    /// build. Each field falls back to its declared default if absent.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion        = (try? c.decode(Int.self,    forKey: .schemaVersion)) ?? 1
        midiDeviceUID        =  try? c.decode(String.self, forKey: .midiDeviceUID)
        audioLatencyOffsetMs = (try? c.decode(Int.self,    forKey: .audioLatencyOffsetMs)) ?? 0
        hapticsEnabled       = (try? c.decode(Bool.self,   forKey: .hapticsEnabled)) ?? true
        reduceMotionOverride = (try? c.decode(Bool.self,   forKey: .reduceMotionOverride)) ?? false
        lastTab              = (try? c.decode(String.self, forKey: .lastTab)) ?? "play"
        externalAudioMode    = (try? c.decode(Bool.self,   forKey: .externalAudioMode)) ?? false
    }
}

// MARK: - PersistenceStore

/// UserDefaults-backed replacement for the SwiftData stack. Holds all
/// persistent collections + a single AppSettings + BuilderState row,
/// publishes changes so SwiftUI views observe them, and encodes/decodes
/// to UserDefaults via Codable. Compatible back to iOS 14.
@MainActor
final class PersistenceStore: ObservableObject {
    @Published private(set) var scores: [LessonScore] = []
    @Published private(set) var unlocks: [AchievementUnlock] = []
    @Published private(set) var playDays: [PracticeDay] = []
    @Published private(set) var extraLessons: [ExtraLesson] = []
    @Published private(set) var collection: [DrumrotCollectionEntry] = []
    @Published private(set) var builder: BuilderState = BuilderState()
    @Published private(set) var settings: AppSettings = AppSettings()

    private let defaults: UserDefaults?
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Key {
        static let scores = "drum.scores"
        static let unlocks = "drum.achievements"
        static let playDays = "drum.playDays"
        static let extraLessons = "drum.extraLessons"
        static let collection = "drum.collection"
        static let builder = "drum.builder"
        static let settings = "drum.settings"
    }

    /// Production initializer — backed by `UserDefaults.standard`.
    convenience init() {
        self.init(defaults: .standard)
    }

    /// `defaults = nil` produces an ephemeral store (tests).
    init(defaults: UserDefaults?) {
        self.defaults = defaults
        load()
    }

    // MARK: - Loading

    private func load() {
        guard let defaults else { return }
        scores       = decode([LessonScore].self,            from: defaults, key: Key.scores) ?? []
        unlocks      = decode([AchievementUnlock].self,      from: defaults, key: Key.unlocks) ?? []
        playDays     = decode([PracticeDay].self,            from: defaults, key: Key.playDays) ?? []
        extraLessons = decode([ExtraLesson].self,            from: defaults, key: Key.extraLessons) ?? []
        collection   = decode([DrumrotCollectionEntry].self, from: defaults, key: Key.collection) ?? []
        builder      = decode(BuilderState.self,             from: defaults, key: Key.builder) ?? BuilderState()
        settings     = decode(AppSettings.self,              from: defaults, key: Key.settings) ?? AppSettings()
    }

    private func decode<T: Decodable>(_ type: T.Type, from defaults: UserDefaults, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }

    private func persist<T: Encodable>(_ value: T, key: String) {
        guard let defaults else { return }
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    // MARK: - Write API (mirrors the old PersistenceService)

    /// Records a completed pass. Returns the row state after the upsert.
    @discardableResult
    func recordPass(lessonKey: String, score: Int, accuracy: Int, tier: Int? = nil) -> LessonScore {
        var row = scores.first(where: { $0.lessonKey == lessonKey }) ?? LessonScore(lessonKey: lessonKey)
        row.high = max(row.high, score)
        row.stars = max(row.stars, ScoringEngine.stars(accuracy: accuracy))
        row.plays += 1
        row.lastAccuracy = accuracy
        if let tier { row.practiceTier = max(row.practiceTier, tier) }
        row.updatedAt = .now
        upsert(&scores, row, key: \.lessonKey)
        persist(scores, key: Key.scores)
        return row
    }

    /// Unlocks an achievement. Returns true if newly unlocked.
    @discardableResult
    func unlock(_ achievementId: String) -> Bool {
        guard !unlocks.contains(where: { $0.achievementId == achievementId }) else { return false }
        unlocks.append(AchievementUnlock(achievementId: achievementId))
        persist(unlocks, key: Key.unlocks)
        return true
    }

    /// Marks a practice day (idempotent).
    func recordPlayDay(_ day: String) {
        guard !playDays.contains(where: { $0.day == day }) else { return }
        playDays.append(PracticeDay(day: day))
        persist(playDays, key: Key.playDays)
    }

    /// Adds a drumrot pull. Returns true if new or a tier upgrade.
    @discardableResult
    func collect(drumrotId: String, tier: DrumrotTier) -> Bool {
        if var row = collection.first(where: { $0.drumrotId == drumrotId }) {
            row.count += 1
            let isUpgrade = tier.index > row.tierIndex
            if isUpgrade { row.tierIndex = tier.index }
            upsert(&collection, row, key: \.drumrotId)
            persist(collection, key: Key.collection)
            return isUpgrade
        }
        collection.append(DrumrotCollectionEntry(drumrotId: drumrotId, tierIndex: tier.index))
        persist(collection, key: Key.collection)
        return true
    }

    func collectedCount() -> Int { collection.count }

    /// Returns a map of drumrot id -> pull count for the pity mechanic.
    func collectionCounts() -> [String: Int] {
        Dictionary(collection.map { ($0.drumrotId, $0.count) }, uniquingKeysWith: max)
    }

    func saveBuilder(_ state: BuilderState) {
        builder = state
        persist(builder, key: Key.builder)
    }

    func saveExtraLesson(name: String, lessonJSON: String) {
        var row = extraLessons.first(where: { $0.name == name })
            ?? ExtraLesson(name: name, lessonJSON: lessonJSON)
        row.lessonJSON = lessonJSON
        row.createdAt = .now
        upsert(&extraLessons, row, key: \.name)
        persist(extraLessons, key: Key.extraLessons)
    }

    /// Renames a user-authored lesson, preserving its `createdAt` timestamp.
    /// Returns `true` on success, `false` if the source is missing or the new name is taken.
    @discardableResult
    func renameExtraLesson(from oldName: String, to newName: String) -> Bool {
        guard let oldRow = extraLessons.first(where: { $0.name == oldName }) else { return false }
        guard !extraLessons.contains(where: { $0.name == newName }) else { return false }

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
        extraLessons.removeAll { $0.name == oldName }
        extraLessons.append(ExtraLesson(name: newName, lessonJSON: newJSON, createdAt: createdAt))
        persist(extraLessons, key: Key.extraLessons)
        return true
    }

    /// Removes a user-authored lesson by name. No-op if absent.
    func deleteExtraLesson(name: String) {
        let before = extraLessons.count
        extraLessons.removeAll { $0.name == name }
        guard extraLessons.count != before else { return }
        persist(extraLessons, key: Key.extraLessons)
    }

    /// Decoded view of the user-authored lessons in store order.
    /// Rows whose JSON fails to decode are silently skipped — a single
    /// corrupt blob shouldn't hide the rest of the library.
    func extraLessonsAsLessons() -> [Lesson] {
        extraLessons.compactMap { row in
            guard let data = row.lessonJSON.data(using: .utf8) else { return nil }
            return try? decoder.decode(Lesson.self, from: data)
        }
    }

    func updateSettings(_ block: (inout AppSettings) -> Void) {
        block(&settings)
        persist(settings, key: Key.settings)
    }

    // MARK: - Helpers

    private func upsert<T, K: Equatable>(_ arr: inout [T], _ row: T, key: KeyPath<T, K>) {
        if let i = arr.firstIndex(where: { $0[keyPath: key] == row[keyPath: key] }) {
            arr[i] = row
        } else {
            arr.append(row)
        }
    }
}
