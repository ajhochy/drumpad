import XCTest
@testable import Drumrot

final class ScoringParityTests: XCTestCase {

    func testJudgmentBoundaries() {
        XCTAssertEqual(ScoringEngine.judgment(dy: 0), .perfect)
        XCTAssertEqual(ScoringEngine.judgment(dy: 19.9), .perfect)
        XCTAssertEqual(ScoringEngine.judgment(dy: 20), .great)
        XCTAssertEqual(ScoringEngine.judgment(dy: 39.9), .great)
        XCTAssertEqual(ScoringEngine.judgment(dy: 40), .good)
        XCTAssertEqual(ScoringEngine.judgment(dy: 59.9), .good)
        XCTAssertNil(ScoringEngine.judgment(dy: 60), "60 is outside the hit window")
        XCTAssertNil(ScoringEngine.judgment(dy: 100))
    }

    func testComboMultiplierMatchesWeb() {
        var s = ScoringEngine()
        // 8 perfect hits: mult = max(1, floor(combo/4)).
        // combos 1..7 → ×1 (300 each), combo 8 → ×2 (600). 7*300 + 600 = 2700.
        for _ in 0..<8 { s.recordHit(dy: 0) }
        XCTAssertEqual(s.combo, 8)
        XCTAssertEqual(s.maxCombo, 8)
        XCTAssertEqual(s.hits, 8)
        XCTAssertEqual(s.score, 2700)
    }

    func testMissResetsCombo() {
        var s = ScoringEngine()
        s.recordHit(dy: 0)
        XCTAssertEqual(s.combo, 1)
        s.recordMiss()
        XCTAssertEqual(s.combo, 0)
        XCTAssertEqual(s.misses, 1)
        // An out-of-window tap changes nothing.
        let before = s
        XCTAssertNil(s.recordHit(dy: 80))
        XCTAssertEqual(s, before)
    }

    func testAccuracyRounding() {
        var s = ScoringEngine()
        s.recordHit(dy: 0); s.recordHit(dy: 0); s.recordHit(dy: 0); s.recordMiss()
        XCTAssertEqual(s.accuracy, 75)
    }

    func testStarThresholds() {
        XCTAssertEqual(ScoringEngine.stars(accuracy: 95), 3)
        XCTAssertEqual(ScoringEngine.stars(accuracy: 94), 2)
        XCTAssertEqual(ScoringEngine.stars(accuracy: 80), 2)
        XCTAssertEqual(ScoringEngine.stars(accuracy: 79), 1)
        XCTAssertEqual(ScoringEngine.stars(accuracy: 50), 1)
        XCTAssertEqual(ScoringEngine.stars(accuracy: 49), 0)
    }

    func testPracticeTierThresholds() {
        XCTAssertEqual(PracticeTier.forPass(accuracy: 90, bpm: 140, lessonBpm: 80), .killingIt)
        XCTAssertEqual(PracticeTier.forPass(accuracy: 80, bpm: 120, lessonBpm: 80), .locked)
        XCTAssertEqual(PracticeTier.forPass(accuracy: 80, bpm: 100, lessonBpm: 80), .grooving)
        XCTAssertEqual(PracticeTier.forPass(accuracy: 80, bpm: 70,  lessonBpm: 80), .steady)
        XCTAssertNil(PracticeTier.forPass(accuracy: 79, bpm: 200, lessonBpm: 80))
        XCTAssertNil(PracticeTier.forPass(accuracy: 80, bpm: 69,  lessonBpm: 80))
        XCTAssertEqual(PracticeTier.allCases.map(\.displayName),
                       ["Steady", "Grooving", "Locked", "Killing It"])
    }

    func testStreakCountsConsecutiveDays() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        let today = cal.date(from: DateComponents(year: 2026, month: 5, day: 26, hour: 12))!
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"; fmt.timeZone = cal.timeZone; fmt.locale = Locale(identifier: "en_US_POSIX")
        func key(_ offset: Int) -> String { fmt.string(from: cal.date(byAdding: .day, value: offset, to: today)!) }

        XCTAssertEqual(PracticeStreak.current(playDays: [key(0), key(-1), key(-2)], today: today), 3)
        XCTAssertEqual(PracticeStreak.current(playDays: [key(0), key(-2)], today: today), 1, "gap breaks streak")
        XCTAssertEqual(PracticeStreak.current(playDays: [key(-1), key(-2)], today: today), 0, "no today = 0")
        XCTAssertEqual(PracticeStreak.current(playDays: [], today: today), 0)
    }
}
