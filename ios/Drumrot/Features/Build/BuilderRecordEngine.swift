import Foundation
import QuartzCore

/// Drives a looping metronome for the Builder's real-time record mode.
///
/// The engine fires `onMetronome` on every sub-beat tick and calls
/// `onStepChange` with the currently-active step index (0-based) so the UI
/// can highlight the playhead.  Call `registerHit(lane:)` from pad taps to
/// record hits into the next (or current) step slot in the pattern.
///
/// Thread-safety: all public methods must be called from the MainActor.
@MainActor
final class BuilderRecordEngine: ObservableObject {

    // MARK: - Published state

    @Published private(set) var isRecording = false
    @Published private(set) var isCountingIn = false
    @Published private(set) var countInBeat  = 0   // 1-based quarter note (1…4)
    @Published private(set) var currentStep  = -1  // -1 = not playing
    @Published private(set) var hitFlash: [Bool]   // one entry per lane (6)

    // MARK: - Configuration (set before calling start())

    var steps: Int = 16
    var bpm: Int   = 90
    /// Fires when a metronome click is due. `accent` = downbeat (beat 0 of 4/4 bar).
    var onMetronome: ((_ accent: Bool) -> Void)?

    // MARK: - Private

    private let countInQuarters = 4            // 4-quarter count-in
    private var displayLink: CADisplayLink?
    private var startMs: Double = 0
    private var lastMetronomeSub = -1

    private var hitFlashTimers: [Task<Void, Never>?] = Array(repeating: nil, count: 6)

    // MARK: - Init / deinit

    init() {
        hitFlash = Array(repeating: false, count: 6)
    }

    deinit {
        // CADisplayLink must be invalidated before release.
        // `deinit` is not on the MainActor but displayLink.invalidate() is
        // thread-safe (documented by Apple).
        displayLink?.invalidate()
    }

    // MARK: - Public API

    /// Starts a 4-quarter count-in then begins looping recording.
    /// The passed `capture` closure is called each time the loop wraps
    /// so callers can merge the recorded pattern into their grid.
    func start(capturing: @escaping (_ recordedGrid: [[Bool]]) -> Void) {
        guard !isRecording else { return }
        isRecording   = true
        isCountingIn  = true
        countInBeat   = 1
        currentStep   = -1
        lastMetronomeSub = -1
        self.captureCallback = capturing

        // Initialise a fresh recording buffer (6 lanes × steps).
        recordBuffer = Array(repeating: Array(repeating: false, count: steps), count: 6)

        startMs = CACurrentMediaTime() * 1000

        let dl = CADisplayLink(target: self, selector: #selector(tick))
        dl.add(to: .main, forMode: .common)
        displayLink = dl
    }

    /// Stops recording and invalidates the display link.
    /// Does NOT fire the capture callback — partial loops are discarded.
    func stop() {
        displayLink?.invalidate()
        displayLink = nil
        isRecording  = false
        isCountingIn = false
        currentStep  = -1
        captureCallback = nil
    }

    /// Call this from a pad tap to record a hit into the nearest step slot.
    func registerHit(lane: Int) {
        guard isRecording, !isCountingIn, lane >= 0, lane < 6 else { return }
        guard currentStep >= 0, currentStep < steps else { return }
        recordBuffer[lane][currentStep] = true
        flashLane(lane)
    }

    // MARK: - Private helpers

    private var captureCallback: (([[Bool]]) -> Void)?
    private var recordBuffer: [[Bool]] = []
    private var lastLoopIteration = 0

    /// Milliseconds per quarter note at current BPM.
    private var quarterMs: Double { 60_000.0 / Double(max(1, bpm)) }

    /// Duration of the count-in.
    private var countInMs: Double { Double(countInQuarters) * quarterMs }

    /// Duration of one groove loop (steps are 1/8th notes = half a quarter).
    private var halfBeatMs: Double { quarterMs / 2.0 }
    private var loopMs: Double { Double(steps) * halfBeatMs }

    @objc private func tick() {
        guard isRecording else { return }
        let nowMs = CACurrentMediaTime() * 1000
        let elapsed = nowMs - startMs

        // ── Continuous metronome (quarter-note clicks) ─────────────────
        if quarterMs > 0, elapsed >= 0 {
            let subBeat = Int(floor(elapsed / quarterMs))
            if subBeat != lastMetronomeSub {
                lastMetronomeSub = subBeat
                let accent = subBeat % 4 == 0
                onMetronome?(accent)
            }
        }

        // ── Count-in ───────────────────────────────────────────────────
        let grooveElapsed = elapsed - countInMs
        if grooveElapsed < 0 {
            // Still in count-in; update the displayed beat number.
            isCountingIn = true
            countInBeat  = max(1, min(countInQuarters, Int(floor(elapsed / quarterMs)) + 1))
            currentStep  = -1
            return
        }

        // ── Recording phase ────────────────────────────────────────────
        if isCountingIn {
            isCountingIn = false
            // Reset the recording buffer fresh for the first loop.
            recordBuffer = Array(repeating: Array(repeating: false, count: steps), count: 6)
            lastLoopIteration = 0
        }

        guard loopMs > 0 else { return }
        let iteration = Int(floor(grooveElapsed / loopMs))

        // Detect loop wrap: fire the capture callback.
        if iteration > lastLoopIteration {
            captureCallback?(recordBuffer)
            // Clear for the next loop.
            recordBuffer = Array(repeating: Array(repeating: false, count: steps), count: 6)
            lastLoopIteration = iteration
        }

        let posInLoop = grooveElapsed.truncatingRemainder(dividingBy: loopMs)
        currentStep = min(steps - 1, Int(floor(posInLoop / halfBeatMs)))
    }

    private func flashLane(_ lane: Int) {
        hitFlashTimers[lane]?.cancel()
        hitFlash[lane] = true
        hitFlashTimers[lane] = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 120_000_000) // 120 ms
            self?.hitFlash[lane] = false
        }
    }
}
