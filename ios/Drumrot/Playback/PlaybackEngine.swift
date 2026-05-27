import Foundation

/// Drives a lesson's gameplay clock: count-in, note travel, hit judging, loop
/// rollover and completion. Ported from the `js/highway.js` timing model
/// (8-eighth count-in, 1800 ms travel, dy-based scoring). UI-independent and
/// deterministic via an injected `Clock`.
@MainActor
final class PlaybackEngine: ObservableObject {
    // Timing constants (from js/state.js + js/highway.js).
    static let countInBeats = 8           // eighth notes
    static let travelMs = 1800.0
    static let travelPx = 520.0           // spawn→strike-line distance
    static var pxPerMs: Double { travelPx / travelMs }
    static var hitWindowMs: Double { ScoringEngine.hitWindow / pxPerMs }

    enum Phase: Equatable {
        case idle
        case countIn(Int)   // 1...8
        case playing
        case finished
    }

    struct ActiveNote: Identifiable, Equatable {
        let id: Int
        let lane: Int
        let targetMs: Double
        var hit = false
        var missed = false
        /// 0 at spawn, 1 at the strike line, >1 past it. Valid while playing.
        var progress: Double = 0
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var notes: [ActiveNote] = []
    @Published private(set) var passCount = 0
    @Published private(set) var scoring = ScoringEngine()

    private(set) var lesson: Lesson?
    var bpm = 90
    var loop = false

    private let clock: Clock
    private var startMs: Double?
    private var loopIteration = 0

    init(clock: Clock = HostClock()) { self.clock = clock }

    var halfBeatMs: Double { (60_000.0 / Double(bpm)) / 2 }
    var countInMs: Double { Double(Self.countInBeats) * halfBeatMs }
    var loopLengthMs: Double {
        guard let lesson else { return 0 }
        return Double(lesson.beatsPerBar * lesson.bars) * halfBeatMs
    }
    private var lastTargetMs: Double { notes.map(\.targetMs).max() ?? 0 }

    func load(_ lesson: Lesson, bpm: Int? = nil, loop: Bool? = nil) {
        self.lesson = lesson
        if let bpm { self.bpm = bpm } else { self.bpm = lesson.bpm }
        if let loop { self.loop = loop }
        reset()
    }

    func start() {
        guard lesson != nil else { return }
        resetNotes()
        loopIteration = 0
        scoring = ScoringEngine()
        passCount = 0
        startMs = clock.nowMs
        phase = .countIn(1)
    }

    func reset() {
        startMs = nil
        loopIteration = 0
        scoring = ScoringEngine()
        passCount = 0
        phase = .idle
        resetNotes()
    }

    private func resetNotes() {
        notes = (lesson?.notes ?? []).enumerated().map { idx, n in
            ActiveNote(id: idx, lane: n.lane, targetMs: Double(n.beat) * halfBeatMs)
        }
    }

    /// Advance to the clock's current time. Returns the count-in beat that just
    /// began (for click triggering), or nil.
    @discardableResult
    func tick() -> Int? { update(nowMs: clock.nowMs) }

    @discardableResult
    func update(nowMs: Double) -> Int? {
        guard let startMs, phase != .idle, phase != .finished else { return nil }
        let elapsed = nowMs - startMs

        if elapsed < countInMs {
            let beat = min(Self.countInBeats, Int(elapsed / halfBeatMs) + 1)
            let prevBeat = (phase.countInBeat ?? 0)
            phase = .countIn(beat)
            return beat != prevBeat ? beat : nil
        }

        phase = .playing
        var grooveElapsed = elapsed - countInMs

        if loop, loopLengthMs > 0 {
            // Roll over: save the pass, reset, advance the loop window.
            while grooveElapsed - Double(loopIteration) * loopLengthMs >= loopLengthMs {
                finishPass()
                loopIteration += 1
                resetNotes()
            }
            grooveElapsed -= Double(loopIteration) * loopLengthMs
        }

        for i in notes.indices {
            notes[i].progress = (grooveElapsed - (notes[i].targetMs - Self.travelMs)) / Self.travelMs
            if !notes[i].hit && !notes[i].missed {
                let timeError = grooveElapsed - notes[i].targetMs
                if timeError > Self.hitWindowMs {
                    notes[i].missed = true
                    scoring.recordMiss()
                }
            }
        }

        if !loop, grooveElapsed > lastTargetMs + Self.travelMs {
            finishPass()
            phase = .finished
        }
        return nil
    }

    /// A pad/MIDI hit on a lane: judge against the nearest in-window note.
    @discardableResult
    func registerHit(lane: Int) -> ScoringEngine.Judgment? {
        guard let startMs, phase == .playing else { return nil }
        let grooveElapsed = (clock.nowMs - startMs) - countInMs - Double(loopIteration) * loopLengthMs
        var bestIndex: Int?
        var bestError = Double.greatestFiniteMagnitude
        for i in notes.indices where !notes[i].hit && !notes[i].missed && notes[i].lane == lane {
            let err = abs(grooveElapsed - notes[i].targetMs)
            if err < bestError { bestError = err; bestIndex = i }
        }
        guard let idx = bestIndex, bestError <= Self.hitWindowMs else { return nil }
        notes[idx].hit = true
        return scoring.recordHit(dy: bestError * Self.pxPerMs)
    }

    private func finishPass() {
        passCount += 1
    }

    var accuracy: Int { scoring.accuracy }
    var score: Int { scoring.score }
    var combo: Int { scoring.combo }
}

private extension PlaybackEngine.Phase {
    var countInBeat: Int? {
        if case let .countIn(b) = self { return b }
        return nil
    }
}
