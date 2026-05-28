import AVFoundation

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

    /// When true, MIDI-triggered `play(lane:velocity:source:.midi)` calls
    /// are dropped before scheduling a buffer. PlayView keeps this in sync
    /// with `AppSettings.externalAudioMode` (#60). On-screen pad gestures
    /// (`.tap`) and the metronome are unaffected.
    var externalAudioMode = false

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
