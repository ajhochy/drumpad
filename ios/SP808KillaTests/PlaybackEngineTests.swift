import XCTest
@testable import SP808Killa

@MainActor
final class PlaybackEngineTests: XCTestCase {

    // Single snare note at beat 4. bpm 80 → halfBeat 375ms, countIn 3000ms,
    // loopLength 16*375 = 6000ms, note targetMs = 1500.
    private func lesson() -> Lesson {
        Lesson(name: "T", bpm: 80, tip: "", difficulty: "", genre: "",
               patterns: [PatternLine(lane: "snare", pattern: "....x...........")])
    }

    func testCountInThenPlaying() {
        let clock = TestClock()
        let e = PlaybackEngine(clock: clock)
        e.load(lesson())
        clock.nowMs = 0; e.start()
        XCTAssertEqual(e.phase, .countIn(1))
        clock.nowMs = 375; e.tick()
        XCTAssertEqual(e.phase, .countIn(2))
        clock.nowMs = 375 * 7; e.tick()
        XCTAssertEqual(e.phase, .countIn(8))
        clock.nowMs = 3000; e.tick()
        XCTAssertEqual(e.phase, .playing)
    }

    func testPerfectHitOnTarget() {
        let clock = TestClock()
        let e = PlaybackEngine(clock: clock)
        e.load(lesson())
        clock.nowMs = 0; e.start()
        clock.nowMs = 3000 + 1500   // groove time == note target
        e.tick()
        let j = e.registerHit(lane: DrumLane.snare.rawValue)
        XCTAssertEqual(j, .perfect)
        XCTAssertEqual(e.scoring.hits, 1)
        XCTAssertEqual(e.combo, 1)
    }

    func testNoteMissedWhenPassed() {
        let clock = TestClock()
        let e = PlaybackEngine(clock: clock)
        e.load(lesson())
        clock.nowMs = 0; e.start()
        clock.nowMs = 3000 + 1500 + 250  // past the ~208ms window
        e.tick()
        XCTAssertTrue(e.notes[0].missed)
        XCTAssertEqual(e.scoring.misses, 1)
    }

    func testNonLoopFinishes() {
        let clock = TestClock()
        let e = PlaybackEngine(clock: clock)
        e.load(lesson(), loop: false)
        clock.nowMs = 0; e.start()
        clock.nowMs = 3000 + 1500 + 1800 + 50  // past last target + travel
        e.tick()
        XCTAssertEqual(e.phase, .finished)
        XCTAssertEqual(e.passCount, 1)
    }

    func testLoopRollsOverAndResets() {
        let clock = TestClock()
        let e = PlaybackEngine(clock: clock)
        e.load(lesson(), loop: true)
        clock.nowMs = 0; e.start()
        clock.nowMs = 3000 + 6000  // one full loop length of groove time
        e.tick()
        XCTAssertGreaterThanOrEqual(e.passCount, 1)
        XCTAssertEqual(e.phase, .playing)
        XCTAssertFalse(e.notes[0].missed, "notes reset after rollover")
    }
}
