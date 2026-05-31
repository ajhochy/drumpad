import Foundation

/// Hit scoring, ported verbatim from `js/highway.js` (the hit branch) + `js/scoring.js`.
/// `dy` is the absolute pixel distance from the note to the strike line.
struct ScoringEngine: Equatable {
    static let hitWindow = 60.0

    enum Judgment: Int {
        case good = 100, great = 200, perfect = 300
        var label: String {
            switch self {
            case .perfect: return "perfect!"
            case .great:   return "great!"
            case .good:    return "good"
            }
        }
    }

    private(set) var score = 0
    private(set) var combo = 0
    private(set) var maxCombo = 0
    private(set) var hits = 0
    private(set) var misses = 0
    /// Ghost hits: taps that found no valid in-window note.
    /// Each ghost hit counts as a miss-equivalent in the accuracy denominator,
    /// so spamming produces worse accuracy than playing nothing at all.
    private(set) var ghostHits = 0

    /// Judgment for a distance, or nil if outside the hit window.
    static func judgment(dy: Double) -> Judgment? {
        guard dy < hitWindow else { return nil }
        if dy < 20 { return .perfect }
        if dy < 40 { return .great }
        return .good
    }

    /// Records a hit attempt. Returns the judgment, or nil if it missed the window
    /// (in which case nothing changes — the web only scores in-window taps).
    @discardableResult
    mutating func recordHit(dy: Double) -> Judgment? {
        guard let j = Self.judgment(dy: dy) else { return nil }
        hits += 1
        combo += 1
        maxCombo = max(maxCombo, combo)
        // Multiplier uses the post-increment combo: max(1, floor(combo/4)).
        score += j.rawValue * max(1, combo / 4)
        return j
    }

    /// A note passed the line untouched.
    mutating func recordMiss() {
        misses += 1
        combo = 0
    }

    /// A pad tap that found no matching in-window note (spam / ghost hit).
    /// Counts in the accuracy denominator so spamming lowers accuracy
    /// proportional to how many real notes the lesson has.
    mutating func recordGhostHit() {
        ghostHits += 1
        combo = 0
    }

    /// Reset per-pass hit/miss tallies at a loop rollover (score + combo persist).
    mutating func resetPassCounts() {
        hits = 0
        misses = 0
        ghostHits = 0
    }

    /// Live accuracy over attempted events (hits + misses + ghost hits), rounded
    /// like `Math.round`.  Ghost hits are included in the denominator so spam
    /// produces worse accuracy than playing nothing at all.
    var accuracy: Int {
        let total = hits + misses + ghostHits
        guard total > 0 else { return 0 }
        return Int((Double(hits) / Double(total) * 100).rounded())
    }

    /// Pass stars from an accuracy percentage: 3 ≥95, 2 ≥80, 1 ≥50, else 0.
    static func stars(accuracy: Int) -> Int {
        if accuracy >= 95 { return 3 }
        if accuracy >= 80 { return 2 }
        if accuracy >= 50 { return 1 }
        return 0
    }
}
