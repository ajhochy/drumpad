import XCTest
@testable import SP808Killa

/// Parity: ported lessons must expand to the same notes as `js/lessons.js`.
final class LessonParityTests: XCTestCase {

    func testLessonCountAndOrder() {
        let names = LessonCatalog.all.map(\.name)
        XCTAssertEqual(names, [
            "Rock Beat 101", "Disco Pulse", "Half-Time Slap", "Tom Fill",
            "Crash & Ride", "Shuffle", "Punk Bash", "Funk Pocket",
        ])
    }

    /// beatsPerBar = length of the first pattern. Disco Pulse's first pattern is
    /// 15 chars (the web quirk), every other lesson is 16.
    func testBeatsPerBar() {
        var byName: [String: Int] = [:]
        for l in LessonCatalog.all { byName[l.name] = l.beatsPerBar }
        XCTAssertEqual(byName["Disco Pulse"], 15)
        for (name, bpb) in byName where name != "Disco Pulse" {
            XCTAssertEqual(bpb, 16, "\(name) beatsPerBar")
        }
    }

    func testNoteCounts() {
        let expected: [String: Int] = [
            "Rock Beat 101": 24, "Disco Pulse": 15, "Half-Time Slap": 22,
            "Tom Fill": 19, "Crash & Ride": 14, "Shuffle": 16,
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
