import Foundation

/// Builds a `Lesson` from a builder grid (6 lanes × N steps of on/off cells).
enum BuilderLessonFactory {
    static let builderLessonName = "My Groove"

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
                      tip: coach.isEmpty ? "Your custom pattern." : coach,
                      difficulty: "Custom", genre: "Builder", patterns: patterns)
    }
}
