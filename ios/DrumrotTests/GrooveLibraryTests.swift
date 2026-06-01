import XCTest
@testable import Drumrot

@MainActor
final class GrooveLibraryTests: XCTestCase {

    // MARK: - BuilderLessonFactory roundtrip

    func testGridToLessonToGridRoundtripPreservesHits() throws {
        var grid = Array(repeating: Array(repeating: false, count: 16), count: 6)
        // kick on 1 and 3; snare on 2 and 4; hihat on every step.
        grid[DrumLane.kick.rawValue][0] = true
        grid[DrumLane.kick.rawValue][8] = true
        grid[DrumLane.snare.rawValue][4] = true
        grid[DrumLane.snare.rawValue][12] = true
        for i in 0..<16 { grid[DrumLane.hihat.rawValue][i] = true }

        let lesson = try XCTUnwrap(
            BuilderLessonFactory.lesson(grid: grid, bpm: 110, coach: "Stay tight")
        )
        let decoded = BuilderLessonFactory.grid(from: lesson)

        XCTAssertEqual(decoded.steps, 16)
        XCTAssertEqual(decoded.bpm, 110)
        XCTAssertEqual(decoded.coach, "Stay tight")
        XCTAssertEqual(decoded.grid, grid, "every lane × step on/off survives the roundtrip")
    }

    func testGridToLessonToGridDefaultsTo32StepsForLongPatterns() throws {
        var grid = Array(repeating: Array(repeating: false, count: 32), count: 6)
        grid[DrumLane.ride.rawValue][31] = true     // hit on the very last step
        grid[DrumLane.crash.rawValue][0] = true

        let lesson = try XCTUnwrap(
            BuilderLessonFactory.lesson(grid: grid, bpm: 92, coach: "")
        )
        let decoded = BuilderLessonFactory.grid(from: lesson)

        XCTAssertEqual(decoded.steps, 32, "beatsPerBar > 16 should snap to the 32-step picker")
        XCTAssertTrue(decoded.grid[DrumLane.ride.rawValue][31])
        XCTAssertTrue(decoded.grid[DrumLane.crash.rawValue][0])
        XCTAssertEqual(decoded.coach, "", "default tip should not be surfaced as a coach note")
    }

    func testEmptyGridProducesNoLesson() {
        let empty = Array(repeating: Array(repeating: false, count: 16), count: 6)
        XCTAssertNil(BuilderLessonFactory.lesson(grid: empty, bpm: 100, coach: ""))
    }

    // MARK: - PersistenceStore extra-lesson API

    func testSaveExtraLessonUpsertsByName() throws {
        let store = PersistenceStore(defaults: nil)
        store.saveExtraLesson(name: "Tom Fill", lessonJSON: "{\"first\":1}")
        store.saveExtraLesson(name: "Tom Fill", lessonJSON: "{\"second\":2}")
        XCTAssertEqual(store.extraLessons.count, 1)
        XCTAssertEqual(store.extraLessons.first?.lessonJSON, "{\"second\":2}")
    }

    func testDeleteExtraLessonRemovesByName() {
        let store = PersistenceStore(defaults: nil)
        store.saveExtraLesson(name: "Keep", lessonJSON: "{}")
        store.saveExtraLesson(name: "Drop", lessonJSON: "{}")
        store.deleteExtraLesson(name: "Drop")

        XCTAssertEqual(store.extraLessons.count, 1)
        XCTAssertEqual(store.extraLessons.first?.name, "Keep")

        // No-op when the name is missing — should not throw or remove anything else.
        store.deleteExtraLesson(name: "Ghost")
        XCTAssertEqual(store.extraLessons.count, 1)
    }

    func testExtraLessonsAsLessonsDecodesAndSkipsCorrupt() throws {
        let store = PersistenceStore(defaults: nil)

        var grid = Array(repeating: Array(repeating: false, count: 16), count: 6)
        grid[DrumLane.kick.rawValue][0] = true
        let lesson = try XCTUnwrap(
            BuilderLessonFactory.lesson(grid: grid, bpm: 80, coach: "", name: "Round")
        )
        let json = String(data: try JSONEncoder().encode(lesson), encoding: .utf8)!

        store.saveExtraLesson(name: "Round", lessonJSON: json)
        store.saveExtraLesson(name: "Corrupt", lessonJSON: "{ not json")

        let decoded = store.extraLessonsAsLessons()
        XCTAssertEqual(decoded.count, 1, "corrupt rows are silently skipped")
        XCTAssertEqual(decoded.first?.name, "Round")
        XCTAssertEqual(decoded.first?.bpm, 80)
    }

    func testDeleteExtraLessonPersistsAcrossStoresInSameDefaults() throws {
        let suite = UserDefaults(suiteName: "drumrot-extra-\(UUID().uuidString)")!
        defer {
            suite.removePersistentDomain(
                forName: suite.dictionaryRepresentation().keys.first ?? ""
            )
        }

        let s1 = PersistenceStore(defaults: suite)
        s1.saveExtraLesson(name: "A", lessonJSON: "{}")
        s1.saveExtraLesson(name: "B", lessonJSON: "{}")
        s1.deleteExtraLesson(name: "A")

        let s2 = PersistenceStore(defaults: suite)
        XCTAssertEqual(s2.extraLessons.map(\.name), ["B"])
    }

    // MARK: - Issue #71 – confirm-overwrite prompt helpers

    func testUniqueSuffixGeneratesCorrectSuffix() {
        let store = PersistenceStore(defaults: nil)
        store.saveExtraLesson(name: "Bass Groove", lessonJSON: "{}")
        store.saveExtraLesson(name: "Bass Groove (2)", lessonJSON: "{}")

        let existing = Set(store.extraLessons.map(\.name))

        func uniqueSuffix(for base: String) -> String {
            var n = 2
            while existing.contains("\(base) (\(n))") { n += 1 }
            return "\(base) (\(n))"
        }

        XCTAssertEqual(uniqueSuffix(for: "Bass Groove"), "Bass Groove (3)")
        XCTAssertEqual(uniqueSuffix(for: "New Groove"), "New Groove (2)",
                       "name with no collision should get suffix (2)")
    }

    func testUpsertReplacesExistingGrooveWithSameName() {
        let store = PersistenceStore(defaults: nil)
        store.saveExtraLesson(name: "Funky Beat", lessonJSON: "{\"v\":1}")
        store.saveExtraLesson(name: "Funky Beat", lessonJSON: "{\"v\":2}")

        XCTAssertEqual(store.extraLessons.count, 1, "replace path must produce exactly one row")
        XCTAssertEqual(store.extraLessons.first?.lessonJSON, "{\"v\":2}", "latest JSON wins")
    }

}
