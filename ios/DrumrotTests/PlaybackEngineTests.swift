import XCTest
@testable import Drumrot

@MainActor
final class PlaybackEngineTests: XCTestCase {

    // Single snare note at beat 4. bpm 80 → halfBeat 375ms, quarter 750ms,
    // countIn 8*375 = 3000ms, loopLength 16*375 = 6000ms, note time = 1500ms.
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
        clock.nowMs = 750; e.tick()
        XCTAssertEqual(e.phase, .countIn(2))     // quarter-note count
        clock.nowMs = 2250; e.tick()
        XCTAssertEqual(e.phase, .countIn(4))
        clock.nowMs = 3000; e.tick()
        XCTAssertEqual(e.phase, .playing)
    }

    func testPerfectHitOnTarget() {
        let clock = TestClock()
        let e = PlaybackEngine(clock: clock)
        e.load(lesson())
        clock.nowMs = 0; e.start()
        clock.nowMs = 3000 + 1500   // groove time == note time
        e.tick()
        XCTAssertEqual(e.registerHit(lane: DrumLane.snare.rawValue), .perfect)
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
        clock.nowMs = 3000 + 1500 + 1800 + 50
        e.tick()
        XCTAssertEqual(e.phase, .finished)
        XCTAssertEqual(e.passCount, 1)
    }

    func testLoopRollsOverWithoutResettingPositions() {
        let clock = TestClock()
        let e = PlaybackEngine(clock: clock)
        e.load(lesson(), loop: true)
        clock.nowMs = 0; e.start()
        clock.nowMs = 3000 + 6000   // one full loop length of groove
        e.tick()
        XCTAssertGreaterThanOrEqual(e.passCount, 1)
        XCTAssertEqual(e.phase, .playing)
        XCTAssertFalse(e.notes[0].missed, "flags cleared on rollover")
    }

    // MARK: - The three reported bugs

    /// Metronome must tick on every quarter note THROUGH count-in AND groove
    /// (the bug: it quit once the beat started), accent on every 4th.
    func testMetronomeFiresContinuouslyThroughGroove() {
        let clock = TestClock()
        let e = PlaybackEngine(clock: clock)
        e.load(lesson())
        e.metronomeEnabled = true
        var ticks: [Bool] = []          // accent per tick
        e.onMetronome = { ticks.append($0) }
        clock.nowMs = 0; e.start()
        for t in stride(from: 0.0, through: 4500.0, by: 750.0) {
            clock.nowMs = t; e.tick()
        }
        XCTAssertEqual(ticks.count, 7, "a click on every quarter, count-in + groove")
        XCTAssertEqual(ticks, [true, false, false, false, true, false, false])
        // Indices 4..6 occur at elapsed 3000/3750/4500 — during the groove
        // (countInMs == 3000) — proving the metronome doesn't stop.
    }

    /// BPM must change note timing live (the bug: +/- did nothing).
    func testBpmChangesNoteTimingLive() {
        let clock = TestClock()
        let e = PlaybackEngine(clock: clock)
        e.load(lesson())            // bpm 80
        e.bpm = 160                 // halfBeat 187.5, countIn 1500, note time 750
        clock.nowMs = 0; e.start()
        clock.nowMs = 1500 + 750    // countInMs + noteTime at the NEW bpm
        e.tick()
        XCTAssertEqual(e.registerHit(lane: DrumLane.snare.rawValue), .perfect,
                       "note arrives at the faster-tempo time")
    }

    /// Loop produces a shadow (next-pass) note that slides in near the wrap.
    func testLoopProducesShadowNote() {
        let clock = TestClock()
        let e = PlaybackEngine(clock: clock)
        e.load(lesson(), loop: true)
        clock.nowMs = 0; e.start()
        clock.nowMs = 3000 + 5800   // near the end of pass 0
        e.tick()
        XCTAssertTrue(e.notes[0].shadowVisible, "next-pass shadow visible near the wrap")
    }
}
