import Foundation

/// Drives a lesson's gameplay clock: count-in, note travel, hit judging, a
/// continuous metronome, seamless loop rollover (with shadow notes) and
/// completion. Ported from the `js/highway.js` `animate` model — note positions
/// and metronome are derived live from the current BPM every frame, so changing
/// the tempo mid-play rescales everything (matching the web). UI-independent and
/// deterministic via an injected `Clock`.
@MainActor
final class PlaybackEngine: ObservableObject {
    static let countInBeats = 8           // eighth notes (= 4 quarter-note count-in)
    static let travelMs = 1800.0
    static let travelPx = 520.0           // spawn→strike-line distance
    static var pxPerMs: Double { travelPx / travelMs }
    static var hitWindowMs: Double { ScoringEngine.hitWindow / pxPerMs }

    enum Phase: Equatable {
        case idle
        case countIn(Int)   // 1...4 (quarter-note count)
        case playing
        case finished
    }

    struct ActiveNote: Identifiable, Equatable {
        let id: Int
        let lane: Int
        let beat: Int
        var hit = false
        var missed = false
        /// 0 at spawn, 1 at the strike line (current pass).
        var progress: Double = -1
        /// Position of the SAME note one pass ahead (loop only) — the seamless reel.
        var shadowProgress: Double = -1
        var shadowVisible = false
    }

    @Published private(set) var phase: Phase = .idle
    @Published private(set) var notes: [ActiveNote] = []
    @Published private(set) var passCount = 0
    @Published private(set) var scoring = ScoringEngine()
    /// BPM is observable + drives note timing live, so the +/- control actually moves notes.
    @Published var bpm = 90

    var loop = false
    var metronomeEnabled = true

    /// Fired on each new quarter-note beat (count-in AND groove). `accent` = downbeat.
    var onMetronome: ((_ accent: Bool) -> Void)?

    private(set) var lesson: Lesson?
    private let clock: Clock
    private var startMs: Double?
    private var loopIteration = 0
    private var lastMetronomeBeat = -1

    init(clock: Clock = HostClock()) { self.clock = clock }

    // Derived timing — all live from `bpm`.
    var halfBeatMs: Double { (60_000.0 / Double(bpm)) / 2 }
    var quarterMs: Double { halfBeatMs * 2 }
    var countInMs: Double { Double(Self.countInBeats) * halfBeatMs }
    var loopLengthBeats: Int { lesson.map { $0.beatsPerBar * $0.bars } ?? 16 }
    var grooveMs: Double { Double(loopLengthBeats) * halfBeatMs }

    private func noteTimeMs(_ beat: Int) -> Double { Double(beat) * halfBeatMs }

    func load(_ lesson: Lesson, bpm: Int? = nil, loop: Bool? = nil) {
        self.lesson = lesson
        self.bpm = bpm ?? lesson.bpm
        if let loop { self.loop = loop }
        reset()
    }

    func start() {
        guard lesson != nil else { return }
        rebuildNotes()
        loopIteration = 0
        lastMetronomeBeat = -1
        scoring = ScoringEngine()
        passCount = 0
        startMs = clock.nowMs
        phase = .countIn(1)
    }

    func reset() {
        startMs = nil
        loopIteration = 0
        lastMetronomeBeat = -1
        scoring = ScoringEngine()
        passCount = 0
        phase = .idle
        rebuildNotes()
    }

    private func rebuildNotes() {
        notes = (lesson?.notes ?? []).enumerated().map { idx, n in
            ActiveNote(id: idx, lane: n.lane, beat: n.beat)
        }
    }

    func tick() { update(nowMs: clock.nowMs) }

    func update(nowMs: Double) {
        guard let startMs, phase != .idle, phase != .finished else { return }
        let elapsed = nowMs - startMs

        // ── Continuous metronome — fires through count-in AND groove ──────────
        if metronomeEnabled, elapsed >= 0, quarterMs > 0 {
            let beat = Int(floor(elapsed / quarterMs))
            if beat != lastMetronomeBeat {
                lastMetronomeBeat = beat
                onMetronome?(beat % 4 == 0)
            }
        }

        let grooveElapsed = elapsed - countInMs

        // ── Count-in number (quarter notes) ───────────────────────────────────
        if grooveElapsed < 0 && loopIteration == 0 {
            phase = .countIn(max(1, Int(floor(elapsed / quarterMs)) + 1))
        } else {
            phase = .playing
        }

        // ── Loop rollover: continuous timeline, clear only flags (no reset) ────
        if loop, grooveElapsed >= 0, grooveMs > 0 {
            let pass = Int(floor(grooveElapsed / grooveMs))
            if pass > loopIteration {
                savePass()
                loopIteration = pass
                for i in notes.indices { notes[i].hit = false; notes[i].missed = false }
                scoring.resetPassCounts()
            }
        }

        // ── Position notes (primary + shadow) and detect misses ───────────────
        var allDone = true
        for i in notes.indices {
            let tAbs = noteTimeMs(notes[i].beat) + Double(loopIteration) * grooveMs
            notes[i].progress = (grooveElapsed - (tAbs - Self.travelMs)) / Self.travelMs

            if !notes[i].hit && !notes[i].missed,
               grooveElapsed >= 0, (grooveElapsed - tAbs) > Self.hitWindowMs {
                notes[i].missed = true
                scoring.recordMiss()
            }
            if !notes[i].hit && !notes[i].missed { allDone = false }

            if loop {
                let tAbsNext = noteTimeMs(notes[i].beat) + Double(loopIteration + 1) * grooveMs
                let pNext = (grooveElapsed - (tAbsNext - Self.travelMs)) / Self.travelMs
                notes[i].shadowProgress = pNext
                notes[i].shadowVisible = pNext >= -0.08 && pNext <= 1.2
            } else {
                notes[i].shadowVisible = false
            }
        }

        // ── Non-loop completion ───────────────────────────────────────────────
        if !loop, allDone, !notes.isEmpty {
            let lastMs = noteTimeMs(notes.map(\.beat).max() ?? 0)
            if grooveElapsed > lastMs + Self.travelMs {
                savePass()
                phase = .finished
            }
        }
    }

    /// A pad/MIDI hit on a lane: judge against the nearest in-window note.
    @discardableResult
    func registerHit(lane: Int) -> ScoringEngine.Judgment? {
        guard let startMs, phase == .playing else { return nil }
        let grooveElapsed = (clock.nowMs - startMs) - countInMs
        var bestIndex: Int?
        var bestError = Double.greatestFiniteMagnitude
        for i in notes.indices where !notes[i].hit && !notes[i].missed && notes[i].lane == lane {
            let tAbs = noteTimeMs(notes[i].beat) + Double(loopIteration) * grooveMs
            let err = abs(grooveElapsed - tAbs)
            if err < bestError { bestError = err; bestIndex = i }
        }
        guard let idx = bestIndex, bestError <= Self.hitWindowMs else { return nil }
        notes[idx].hit = true
        return scoring.recordHit(dy: bestError * Self.pxPerMs)
    }

    private func savePass() { passCount += 1 }

    var accuracy: Int { scoring.accuracy }
    var score: Int { scoring.score }
    var combo: Int { scoring.combo }
}
