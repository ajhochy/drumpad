import XCTest
import SwiftData
@testable import SP808Killa

@MainActor
final class PersistenceRoundTripTests: XCTestCase {

    private func makeContext() -> ModelContext {
        let container = AppModelContainer.make(inMemory: true)
        return ModelContext(container)
    }

    func testLessonScoreUpsertKeepsBestAndCountsPlays() throws {
        let ctx = makeContext()
        let svc = PersistenceService(context: ctx)

        svc.recordPass(lessonKey: "0", score: 1000, accuracy: 70) // 1 star
        svc.recordPass(lessonKey: "0", score: 500,  accuracy: 96) // lower score, 3 stars
        try ctx.save()

        let rows = try ctx.fetch(FetchDescriptor<LessonScore>())
        XCTAssertEqual(rows.count, 1)
        let row = try XCTUnwrap(rows.first)
        XCTAssertEqual(row.high, 1000, "high score is the max")
        XCTAssertEqual(row.stars, 3, "stars upgrade to best")
        XCTAssertEqual(row.plays, 2)
        XCTAssertEqual(row.lastAccuracy, 96)
    }

    func testAchievementUnlockIsIdempotent() throws {
        let ctx = makeContext()
        let svc = PersistenceService(context: ctx)
        XCTAssertTrue(svc.unlock("first_hit"))
        XCTAssertFalse(svc.unlock("first_hit"))
        try ctx.save()
        XCTAssertEqual(try ctx.fetchCount(FetchDescriptor<AchievementUnlock>()), 1)
    }

    func testPlayDayIsIdempotent() throws {
        let ctx = makeContext()
        let svc = PersistenceService(context: ctx)
        svc.recordPlayDay("2026-05-26")
        svc.recordPlayDay("2026-05-26")
        svc.recordPlayDay("2026-05-27")
        try ctx.save()
        XCTAssertEqual(try ctx.fetchCount(FetchDescriptor<PracticeDay>()), 2)
    }

    func testCollectionUpgradeOnly() throws {
        let ctx = makeContext()
        let svc = PersistenceService(context: ctx)
        XCTAssertTrue(svc.collect(drumrotId: "x", tier: .rare))   // new
        XCTAssertFalse(svc.collect(drumrotId: "x", tier: .common)) // downgrade
        XCTAssertTrue(svc.collect(drumrotId: "x", tier: .epic))    // upgrade
        try ctx.save()

        let row = try XCTUnwrap(try ctx.fetch(FetchDescriptor<DrumrotCollectionEntry>()).first)
        XCTAssertEqual(row.tierIndex, DrumrotTier.epic.index)
        XCTAssertEqual(row.count, 3, "every pull increments count")
        XCTAssertEqual(svc.collectedCount(), 1)
    }

    func testSurvivesAcrossContextsInSameContainer() throws {
        let container = AppModelContainer.make(inMemory: true)
        let c1 = ModelContext(container)
        PersistenceService(context: c1).recordPass(lessonKey: "1", score: 4242, accuracy: 88)
        try c1.save()

        let c2 = ModelContext(container)
        let row = try XCTUnwrap(try c2.fetch(FetchDescriptor<LessonScore>()).first)
        XCTAssertEqual(row.high, 4242)
        XCTAssertEqual(row.stars, 2)
    }
}
