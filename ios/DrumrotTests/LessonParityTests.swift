import XCTest
@testable import Drumrot

/// Parity: ported lessons must expand to the same notes as `js/lessons.js`.
final class LessonParityTests: XCTestCase {

    func testLessonCountAndOrder() {
        let names = LessonCatalog.all.map(\.name)
        XCTAssertEqual(names, [
            "Rock Beat 101", "Disco Pulse", "Half-Time Slap", "Tom Fill",
            "Crash & Ride", "Shuffle", "Punk Bash", "Funk Pocket",
        ])
    }

    /// beatsPerBar = length of the first pattern. Every lesson is 16 or 32.
    func testBeatsPerBar() {
        for l in LessonCatalog.all {
            XCTAssertTrue(l.beatsPerBar == 16 || l.beatsPerBar == 32,
                          "\(l.name) beatsPerBar=\(l.beatsPerBar) (expected 16 or 32)")
        }
    }

    /// All per-lane patterns within a lesson must share the same length as the
    /// first pattern, otherwise notes from short rows get truncated.
    func testPatternsUniformLength() {
        for l in LessonCatalog.all {
            let len = l.beatsPerBar
            for p in l.patterns {
                let n = p.pattern.filter { !$0.isWhitespace }.count
                XCTAssertEqual(n, len, "\(l.name) lane \(p.lane) length")
            }
        }
    }

    func testNoteCounts() {
        let expected: [String: Int] = [
            "Rock Beat 101": 24, "Disco Pulse": 16, "Half-Time Slap": 22,
            "Tom Fill": 20, "Crash & Ride": 15, "Shuffle": 16,
            "Punk Bash": 26, "Funk Pocket": 25,
        ]
        for l in LessonCatalog.all {
            XCTAssertEqual(l.notes.count, expected[l.name], "\(l.name) note count")
        }
    }

    func testNotesSortedByBeatThenLane() {
        for l in LessonCatalog.all {
            let notes = l.notes
            for i in 1..<notes.count {
                let a = notes[i - 1], b = notes[i]
                XCTAssertTrue(a.beat < b.beat || (a.beat == b.beat && a.lane <= b.lane),
                              "\(l.name) notes not sorted at \(i)")
            }
        }
    }

    func testLaneMappingMatchesWebOrder() {
        XCTAssertEqual(DrumLane.allCases.map(\.key),
                       ["crash", "hihat", "snare", "kick", "tom", "ride"])
        XCTAssertEqual(DrumLane.allCases.map(\.label),
                       ["CR", "HH", "SN", "KK", "TM", "RD"])
    }
}
