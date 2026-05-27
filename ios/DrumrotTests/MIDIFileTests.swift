import XCTest
@testable import Drumrot

final class MIDIFileTests: XCTestCase {

    private func emptyGrid() -> [[Bool]] {
        Array(repeating: Array(repeating: false, count: 16), count: 6)
    }

    func testExportThenParseRoundTrip() throws {
        var grid = emptyGrid()
        grid[DrumLane.kick.rawValue][0] = true
        grid[DrumLane.kick.rawValue][4] = true
        let data = MIDIFileExporter.export(lanePatterns: grid, bpm: 120)

        let (ppq, events) = try MIDIFileParser.parse(data)
        XCTAssertEqual(ppq, 96)
        XCTAssertEqual(events.count, 2)
        XCTAssertEqual(events.map(\.note), [36, 36])      // GM kick
        XCTAssertEqual(events.map(\.tick), [0, 192])      // step 4 * (96/2)
        XCTAssertEqual(events.map(\.velocity), [100, 100])
    }

    func testExportHeaderIsSMFType0() {
        let data = MIDIFileExporter.export(lanePatterns: emptyGrid().tap { $0[3][0] = true }, bpm: 90)
        XCTAssertEqual(Array(data.prefix(4)), [0x4D, 0x54, 0x68, 0x64]) // 'MThd'
        // format word (bytes 8-9) == 0, ntrks (10-11) == 1, ppq (12-13) == 96
        XCTAssertEqual(Array(data[8...13]), [0, 0, 0, 1, 0, 96])
    }

    func testParseRejectsSMPTE() {
        let smpte = Data([0x4D, 0x54, 0x68, 0x64, 0, 0, 0, 6, 0, 0, 0, 1, 0x80, 0x00])
        XCTAssertThrowsError(try MIDIFileParser.parse(smpte)) {
            XCTAssertEqual($0 as? MIDIFileError, .smpteUnsupported)
        }
    }

    func testParseRejectsNonMIDI() {
        XCTAssertThrowsError(try MIDIFileParser.parse(Data([1, 2, 3, 4, 5, 6, 7, 8]))) {
            XCTAssertEqual($0 as? MIDIFileError, .notMIDI)
        }
    }

    func testGMMapping() {
        XCTAssertEqual(GMDrumMapper.lane(forNote: 36), .kick)
        XCTAssertEqual(GMDrumMapper.lane(forNote: 38), .snare)
        XCTAssertEqual(GMDrumMapper.lane(forNote: 42), .hihat)
        XCTAssertEqual(GMDrumMapper.lane(forNote: 45), .tom)
        XCTAssertEqual(GMDrumMapper.lane(forNote: 49), .crash)
        XCTAssertEqual(GMDrumMapper.lane(forNote: 51), .ride)
        XCTAssertNil(GMDrumMapper.lane(forNote: 60))
        XCTAssertEqual(GMDrumMapper.gmNote(for: .kick), 36)
    }

    func testLessonFromEventsQuantizes() {
        let events = [
            MIDINoteEvent(tick: 0, note: 36, velocity: 100),   // kick beat 0
            MIDINoteEvent(tick: 96, note: 38, velocity: 100),  // snare beat 2 (96/48)
        ]
        let lesson = MIDIFileParser.lesson(name: "Imp", events: events, ppq: 96)
        XCTAssertEqual(lesson.notes.count, 2)
        XCTAssertTrue(lesson.notes.contains(NoteEvent(lane: DrumLane.kick.rawValue, beat: 0)))
        XCTAssertTrue(lesson.notes.contains(NoteEvent(lane: DrumLane.snare.rawValue, beat: 2)))
    }
}

private extension Array {
    /// Apply a mutation inline (test helper).
    func tap(_ body: (inout Self) -> Void) -> Self {
        var copy = self; body(&copy); return copy
    }
}
