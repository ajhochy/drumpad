import XCTest
@testable import Drumrot

final class ScoringParityTests: XCTestCase {

    // MARK: - Existing parity tests

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
        // An out-of-window tap via ScoringEngine directly changes nothing
        // (only PlaybackEngine.registerHit calls recordGhostHit on no-match taps).
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

    // MARK: - Anti-spam / ghost hit tests (issue #68)

    func testGhostHitLowersAccuracy() {
        // Spam simulation: ghost hits count in the accuracy denominator.
        var s = ScoringEngine()
        s.recordHit(dy: 0)           // 1 real hit
        for _ in 0..<9 { s.recordGhostHit() }   // 9 ghost hits
        // accuracy = 1 / (1 + 0 misses + 9 ghosts) = 10%
        XCTAssertEqual(s.accuracy, 10)
        XCTAssertEqual(s.ghostHits, 9)
        XCTAssertEqual(s.combo, 0, "last ghost hit should break combo")
    }

    func testGhostHitBreaksCombo() {
        var s = ScoringEngine()
        for _ in 0..<5 { s.recordHit(dy: 0) }
        XCTAssertEqual(s.combo, 5)
        s.recordGhostHit()
        XCTAssertEqual(s.combo, 0)
        XCTAssertEqual(s.maxCombo, 5, "maxCombo should preserve the pre-ghost run")
    }

    func testResetPassCountsClearsGhosts() {
        var s = ScoringEngine()
        for _ in 0..<3 { s.recordGhostHit() }
        XCTAssertEqual(s.ghostHits, 3)
        s.resetPassCounts()
        XCTAssertEqual(s.ghostHits, 0)
    }

    // MARK: - Latency offset (issue #56)

    @MainActor
    func testLatencyOffsetDoesNotBreakHitOnTime() {
        // Verify that a hit arriving exactly at the note time still registers
        // when a latency offset is set (offset shifts window but perfect hits still land).
        let lesson = Lesson(name: "Offset Test", bpm: 120, tip: "", difficulty: "easy", genre: "test",
                            patterns: [PatternLine(lane: "kick", pattern: "....x...........")])
        let clock = TestClock()
        let engine = PlaybackEngine(clock: clock)
        engine.load(lesson, bpm: 120)
        engine.latencyOffsetMs = 30   // simulate 30 ms device-side output latency

        // bpm=120 → halfBeatMs=250 → countInMs=8×250=2000; note at beat 4 → 4×250=1000.
        clock.nowMs = 0; engine.start()
        let noteTime = 2000.0 + 1000.0
        clock.nowMs = noteTime; engine.tick()
        let j = engine.registerHit(lane: DrumLane.kick.rawValue)
        XCTAssertNotNil(j, "Hit exactly at note time should register a judgment even with offset active")
    }
}
