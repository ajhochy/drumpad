import XCTest
@testable import Drumrot

@MainActor
final class PersistenceRoundTripTests: XCTestCase {

    private func makeStore() -> PersistenceStore {
        PersistenceStore(defaults: nil)
    }

    func testLessonScoreUpsertKeepsBestAndCountsPlays() throws {
        let s = makeStore()
        s.recordPass(lessonKey: "0", score: 1000, accuracy: 70) // 1 star
        s.recordPass(lessonKey: "0", score: 500,  accuracy: 96) // lower score, 3 stars

        XCTAssertEqual(s.scores.count, 1)
        let row = try XCTUnwrap(s.scores.first)
        XCTAssertEqual(row.high, 1000, "high score is the max")
        XCTAssertEqual(row.stars, 3, "stars upgrade to best")
        XCTAssertEqual(row.plays, 2)
        XCTAssertEqual(row.lastAccuracy, 96)
    }

    func testAchievementUnlockIsIdempotent() throws {
        let s = makeStore()
        XCTAssertTrue(s.unlock("first_hit"))
        XCTAssertFalse(s.unlock("first_hit"))
        XCTAssertEqual(s.unlocks.count, 1)
    }

    func testPlayDayIsIdempotent() throws {
        let s = makeStore()
        s.recordPlayDay("2026-05-26")
        s.recordPlayDay("2026-05-26")
        s.recordPlayDay("2026-05-27")
        XCTAssertEqual(s.playDays.count, 2)
    }

    func testCollectionUpgradeOnly() throws {
        let s = makeStore()
        XCTAssertTrue(s.collect(drumrotId: "x", tier: .rare))    // new
        XCTAssertFalse(s.collect(drumrotId: "x", tier: .common)) // downgrade
        XCTAssertTrue(s.collect(drumrotId: "x", tier: .epic))    // upgrade

        let row = try XCTUnwrap(s.collection.first)
        XCTAssertEqual(row.tierIndex, DrumrotTier.epic.index)
        XCTAssertEqual(row.count, 3, "every pull increments count")
        XCTAssertEqual(s.collectedCount(), 1)
    }

    func testSurvivesAcrossStoresInSameDefaults() throws {
        let suite = UserDefaults(suiteName: "drumrot-test-\(UUID().uuidString)")!
        defer { suite.removePersistentDomain(forName: suite.dictionaryRepresentation().keys.first ?? "") }

        let s1 = PersistenceStore(defaults: suite)
        s1.recordPass(lessonKey: "1", score: 4242, accuracy: 88)

        let s2 = PersistenceStore(defaults: suite)
        let row = try XCTUnwrap(s2.scores.first)
        XCTAssertEqual(row.high, 4242)
        XCTAssertEqual(row.stars, 2)
    }
}
