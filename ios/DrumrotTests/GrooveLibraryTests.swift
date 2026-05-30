import XCTest
import SwiftData
@testable import Drumrot

@MainActor
final class GrooveLibraryTests: XCTestCase {

    private func makeContext() -> ModelContext {
        let container = AppModelContainer.make(inMemory: true)
        return ModelContext(container)
    }

    // MARK: - BuilderLessonFactory roundtrip (pure, no SwiftData)

    func testGridToLessonToGridRoundtripPreservesHits() throws {
        var grid = Array(repeating: Array(repeating: false, count: 16), count: 6)
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
        grid[DrumLane.ride.rawValue][31] = true
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

    // MARK: - PersistenceService extra-lesson API (SwiftData)

    func testSaveExtraLessonUpsertsByName() throws {
        let ctx = makeContext()
        let svc = PersistenceService(context: ctx)
        svc.saveExtraLesson(name: "Tom Fill", lessonJSON: "{\"first\":1}")
        svc.saveExtraLesson(name: "Tom Fill", lessonJSON: "{\"second\":2}")
        try ctx.save()

        let rows = try ctx.fetch(FetchDescriptor<ExtraLesson>())
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.lessonJSON, "{\"second\":2}")
    }

    func testDeleteExtraLessonRemovesByName() throws {
        let ctx = makeContext()
        let svc = PersistenceService(context: ctx)
        svc.saveExtraLesson(name: "Keep", lessonJSON: "{}")
        svc.saveExtraLesson(name: "Drop", lessonJSON: "{}")
        svc.deleteExtraLesson(name: "Drop")
        try ctx.save()

        let rows = try ctx.fetch(FetchDescriptor<ExtraLesson>())
        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.name, "Keep")

        // No-op when the name is missing.
        svc.deleteExtraLesson(name: "Ghost")
        try ctx.save()
        XCTAssertEqual(try ctx.fetchCount(FetchDescriptor<ExtraLesson>()), 1)
    }

    func testExtraLessonsAsLessonsDecodesAndSkipsCorrupt() throws {
        let ctx = makeContext()
        let svc = PersistenceService(context: ctx)

        var grid = Array(repeating: Array(repeating: false, count: 16), count: 6)
        grid[DrumLane.kick.rawValue][0] = true
        let lesson = try XCTUnwrap(
            BuilderLessonFactory.lesson(grid: grid, bpm: 80, coach: "", name: "Round")
        )
        let json = String(data: try JSONEncoder().encode(lesson), encoding: .utf8)!

        svc.saveExtraLesson(name: "Round", lessonJSON: json)
        svc.saveExtraLesson(name: "Corrupt", lessonJSON: "{ not json")
        try ctx.save()

        let decoded = svc.extraLessonsAsLessons()
        XCTAssertEqual(decoded.count, 1, "corrupt rows are silently skipped")
        XCTAssertEqual(decoded.first?.name, "Round")
        XCTAssertEqual(decoded.first?.bpm, 80)
    }

    func testDeleteExtraLessonPersistsAcrossContexts() throws {
        let container = AppModelContainer.make(inMemory: true)
        let c1 = ModelContext(container)
        let s1 = PersistenceService(context: c1)
        s1.saveExtraLesson(name: "A", lessonJSON: "{}")
        s1.saveExtraLesson(name: "B", lessonJSON: "{}")
        s1.deleteExtraLesson(name: "A")
        try c1.save()

        let c2 = ModelContext(container)
        let rows = try c2.fetch(FetchDescriptor<ExtraLesson>())
        XCTAssertEqual(rows.map(\.name), ["B"])
    }
}
