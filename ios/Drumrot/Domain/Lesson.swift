import Foundation

/// One note in a lesson: a lane index and an eighth-note beat position.
struct NoteEvent: Equatable, Codable {
    let lane: Int
    let beat: Int
}

/// A per-lane pattern string, e.g. `"x.x.x.x."`.
struct PatternLine: Codable, Equatable {
    let lane: String
    let pattern: String
}

/// A lesson definition mirroring one entry of `LESSONS` in `js/lessons.js`.
/// `notes`/`beatsPerBar` are derived exactly as the web `lessonFromPatterns` does.
struct Lesson: Codable, Equatable, Identifiable {
    let name: String
    let bpm: Int
    let tip: String
    let difficulty: String
    let genre: String
    let patterns: [PatternLine]

    var id: String { name }

    /// Built-in lessons are a single bar (`bars = 1`), matching the web `lesson()` helper.
    var bars: Int { 1 }

    /// beatsPerBar = whitespace-stripped length of the FIRST pattern (web behavior —
    /// note this makes Disco Pulse 15, not 16).
    var beatsPerBar: Int {
        guard let first = patterns.first else { return 0 }
        return first.pattern.filter { !$0.isWhitespace }.count
    }

    var notes: [NoteEvent] { LessonFactory.notes(patterns: patterns, bars: bars) }
}

enum LessonFactory {
    /// Expands per-lane pattern strings into sorted notes — verbatim port of
    /// `lessonFromPatterns` (len from the first pattern; `beat = i + bar*len`).
    static func notes(patterns: [PatternLine], bars: Int) -> [NoteEvent] {
        guard let first = patterns.first else { return [] }
        let len = first.pattern.filter { !$0.isWhitespace }.count
        var notes: [NoteEvent] = []
        for bar in 0..<bars {
            for p in patterns {
                guard let laneIdx = DrumLane.from(key: p.lane)?.rawValue else { continue }
                let chars = Array(p.pattern.filter { !$0.isWhitespace })
                for (i, c) in chars.enumerated() where c == "x" || c == "X" {
                    notes.append(NoteEvent(lane: laneIdx, beat: i + bar * len))
                }
            }
        }
        notes.sort { $0.beat != $1.beat ? $0.beat < $1.beat : $0.lane < $1.lane }
        return notes
    }
}

enum LessonCatalog {
    static let all: [Lesson] = load()

    private static func load() -> [Lesson] {
        guard let url = Bundle.main.url(forResource: "Lessons", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            assertionFailure("Lessons.json missing from bundle")
            return []
        }
        do {
            return try JSONDecoder().decode([Lesson].self, from: data)
        } catch {
            assertionFailure("Lessons.json decode failed: \(error)")
            return []
        }
    }
}
