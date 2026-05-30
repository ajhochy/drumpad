import Foundation

/// Builds a `Lesson` from a builder grid (6 lanes × N steps of on/off cells).
enum BuilderLessonFactory {
    static let builderLessonName = "My Groove"
    static let defaultTip = "Your custom pattern."

    /// Returns nil if the grid is empty (no cells on).
    static func lesson(grid: [[Bool]], bpm: Int, coach: String,
                       name: String = builderLessonName) -> Lesson? {
        var patterns: [PatternLine] = []
        for laneIdx in grid.indices where grid[laneIdx].contains(true) {
            guard let lane = DrumLane(rawValue: laneIdx) else { continue }
            let pattern = grid[laneIdx].map { $0 ? "x" : "." }.joined()
            patterns.append(PatternLine(lane: lane.key, pattern: pattern))
        }
        guard !patterns.isEmpty else { return nil }
        // Pad shorter rows so the first pattern reflects the full step count.
        let steps = grid.first?.count ?? 16
        let lead = PatternLine(lane: patterns[0].lane,
                               pattern: patterns[0].pattern.padding(toLength: steps, withPad: ".", startingAt: 0))
        patterns[0] = lead
        return Lesson(name: name, bpm: bpm,
                      tip: coach.isEmpty ? defaultTip : coach,
                      difficulty: "Custom", genre: "Builder", patterns: patterns)
    }

    /// Reverse of `lesson(grid:bpm:coach:)`. Decodes a Lesson's pattern strings
    /// back into a 6-lane on/off grid sized to the lesson's beats-per-bar
    /// (clamped to 16 or 32 to match the BuildView resolution picker).
    /// Lanes the lesson doesn't reference stay empty.
    struct DecodedGrid: Equatable {
        var grid: [[Bool]]
        var steps: Int
        var bpm: Int
        var coach: String
    }

    static func grid(from lesson: Lesson) -> DecodedGrid {
        let rawSteps = max(lesson.beatsPerBar, 16)
        let steps = rawSteps <= 16 ? 16 : 32
        var grid = Array(repeating: Array(repeating: false, count: steps),
                         count: DrumLane.allCases.count)
        for line in lesson.patterns {
            guard let lane = DrumLane.from(key: line.lane) else { continue }
            let chars = Array(line.pattern.filter { !$0.isWhitespace })
            for (i, c) in chars.enumerated() where i < steps && (c == "x" || c == "X") {
                grid[lane.rawValue][i] = true
            }
        }
        let coach = lesson.tip == defaultTip ? "" : lesson.tip
        return DecodedGrid(grid: grid, steps: steps, bpm: lesson.bpm, coach: coach)
    }
}
