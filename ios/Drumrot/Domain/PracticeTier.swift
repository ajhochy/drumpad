import Foundation

/// Tempo mastery tier for a lesson pass. Mirror of `TIER_NAMES`/`tierForPass`
/// in `js/achievements.js`.
enum PracticeTier: Int, CaseIterable, Codable {
    case steady = 0, grooving, locked, killingIt

    var displayName: String {
        switch self {
        case .steady:    return "Steady"
        case .grooving:  return "Grooving"
        case .locked:    return "Locked"
        case .killingIt: return "Killing It"
        }
    }

    var hexColor: String {
        switch self {
        case .steady:    return "#5cf07d"
        case .grooving:  return "#ff8a1e"
        case .locked:    return "#ff3a5a"
        case .killingIt: return "#ff2a7a"
        }
    }

    /// The tier earned by a pass, or nil (the web `-1`) if it doesn't qualify.
    static func forPass(accuracy: Int, bpm: Int, lessonBpm: Int) -> PracticeTier? {
        if accuracy >= 90 && bpm >= lessonBpm + 60 { return .killingIt }
        if accuracy >= 80 && bpm >= lessonBpm + 40 { return .locked }
        if accuracy >= 80 && bpm >= lessonBpm + 20 { return .grooving }
        if accuracy >= 80 && bpm >= lessonBpm - 10 { return .steady }
        return nil
    }
}

/// Day-streak calculation, ported from `getStreak` in `js/achievements.js`
/// (count consecutive UTC day-keys backward from today present in playDays).
enum PracticeStreak {
    static func current(playDays: Set<String>,
                        today: Date = Date()) -> Int {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        fmt.locale = Locale(identifier: "en_US_POSIX")
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!

        var streak = 0
        var day = today
        for _ in 0..<365 {
            if !playDays.contains(fmt.string(from: day)) { break }
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return streak
    }
}
