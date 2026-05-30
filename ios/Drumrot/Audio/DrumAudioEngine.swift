import AVFoundation

/// Thread-safe buffer scheduler — the only state the CoreMIDI callback thread
/// touches.  Written once (on the main actor, inside `start()`), then treated
/// as read-only for `pool` and `laneBuffers`.  The `nextIdx` rotation has a
/// benign data race: worst case is two simultaneous hits sharing a player node,
/// which produces an `.interrupts`-style cut rather than a crash.
internal final class AudioScheduler: @unchecked Sendable {
    var pool: [AVAudioPlayerNode] = []
    var laneBuffers: [DrumLane: AVAudioPCMBuffer] = [:]
    var isReady = false
    var isExternalAudio = false
    private var nextIdx: Int = 0

    func schedule(lane: DrumLane, velocity: Int) {
        guard isReady, !isExternalAudio, !pool.isEmpty else { return }
        guard let buffer = laneBuffers[lane] else { return }
        let node = pool[nextIdx % pool.count]
        nextIdx &+= 1
        node.volume = Float(max(1, min(velocity, 127))) / 127
        // AVAudioPlayerNode.scheduleBuffer is documented thread-safe.
        node.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }
}

/// AVAudioEngine drum + click playback. Preloads one PCM buffer per voice and
/// schedules them on a small pool of player nodes for polyphony.
@MainActor
final class DrumAudioEngine {
    /// Identifies whether a `play(lane:)` call comes from an on-screen pad
    /// gesture or from the MIDI receive path. External-audio mode (#60)
    /// suppresses only `.midi` calls.
    enum PlaySource { case tap, midi }

    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    private var pool: [AVAudioPlayerNode] = []
    private var next = 0

    private var laneBuffers: [DrumLane: AVAudioPCMBuffer] = [:]
    private var clickBuffers: [Bool: AVAudioPCMBuffer] = [:]
    private(set) var isRunning = false

    /// Thread-safe scheduler shared with the CoreMIDI callback thread.
    /// `let` so `playImmediate` can access it from a `nonisolated` context.
    let scheduler = AudioScheduler()

    /// When true, MIDI-triggered `play(lane:velocity:source:.midi)` calls
    /// are dropped before scheduling a buffer. PlayView keeps this in sync
    /// with `AppSettings.externalAudioMode` (#60). On-screen pad gestures
    /// (`.tap`) and the metronome are unaffected.
    var externalAudioMode = false {
        didSet { scheduler.isExternalAudio = externalAudioMode }
    }

    private let poolSize = 8

    func start() {
        guard !isRunning else { return }
        let sr = engine.outputNode.outputFormat(forBus: 0).sampleRate
        let rate = sr > 0 ? sr : VoiceSynth.defaultSampleRate
        let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1)!

        engine.attach(mixer)
        engine.connect(mixer, to: engine.mainMixerNode, format: format)

        for _ in 0..<poolSize {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: mixer, format: format)
            pool.append(node)
        }

        for lane in DrumLane.allCases {
            laneBuffers[lane] = VoiceSynth.buffer(for: lane, sampleRate: rate)
        }
        clickBuffers[true] = ClickSynth.buffer(accent: true, sampleRate: rate)
        clickBuffers[false] = ClickSynth.buffer(accent: false, sampleRate: rate)

        do {
            try engine.start()
            pool.forEach { $0.play() }
            isRunning = true
            // Arm the nonisolated fast path used by the CoreMIDI callback thread.
            scheduler.pool = pool
            scheduler.laneBuffers = laneBuffers
            scheduler.isReady = true
        } catch {
            isRunning = false
            assertionFailure("AVAudioEngine start failed: \(error)")
        }
    }

    func stop() {
        guard isRunning else { return }
        pool.forEach { $0.stop() }
        engine.stop()
        isRunning = false
        scheduler.isReady = false
    }

    /// Nonisolated fast path — may be called from any thread, including the
    /// CoreMIDI callback thread.  Bypasses the main-actor hop so audio fires
    /// within microseconds of the event arriving rather than waiting up to
    /// ~16 ms for the next main run-loop tick.
    nonisolated func playImmediate(lane: DrumLane, velocity: Int) {
        scheduler.schedule(lane: lane, velocity: velocity)
    }

    func play(lane: DrumLane, velocity: Int = 127, source: PlaySource = .tap) {
        if source == .midi, externalAudioMode { return }
        guard isRunning, let buffer = laneBuffers[lane] else { return }
        schedule(buffer, volume: Float(max(1, min(velocity, 127))) / 127)
    }

    func playClick(accent: Bool) {
        guard isRunning, let buffer = clickBuffers[accent] else { return }
        schedule(buffer, volume: 1)
    }

    private func schedule(_ buffer: AVAudioPCMBuffer, volume: Float) {
        let node = pool[next]
        next = (next + 1) % pool.count
        node.volume = volume
        node.scheduleBuffer(buffer, at: nil, options: .interrupts, completionHandler: nil)
    }
}
