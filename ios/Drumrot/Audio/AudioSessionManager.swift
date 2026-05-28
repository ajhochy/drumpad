import AVFoundation

/// Configures the audio session for low-latency foreground playback and routes
/// interruption / route-change events to the engine. Mirrors the plan's audio
/// session policy (.playback + .mixWithOthers, no background audio).
@MainActor
final class AudioSessionManager {
    private let engine: DrumAudioEngine
    private var observersInstalled = false

    init(engine: DrumAudioEngine) {
        self.engine = engine
    }

    func activate() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setPreferredIOBufferDuration(0.005)
            try session.setActive(true)
        } catch {
            // Non-fatal: engine can still run at default latency.
            print("AudioSession configuration failed: \(error)")
        }
        // Diagnostic: log the buffer size the system actually granted.
        // If ioBufferDuration > 0.010 on your device, the system isn't honouring
        // the 5 ms preference — look into using AudioUnit / kAudioSessionProperty_PreferredHardwareIOBufferDuration.
        #if DEBUG
        let granted = session.ioBufferDuration * 1_000
        let outLatency = session.outputLatency * 1_000
        print("🎵 AudioSession — buffer: \(String(format: "%.2f", granted)) ms  |  output latency: \(String(format: "%.2f", outLatency)) ms")
        #endif
        installObservers()
        engine.start()
    }

    private func installObservers() {
        guard !observersInstalled else { return }
        observersInstalled = true
        let center = NotificationCenter.default

        center.addObserver(forName: AVAudioSession.interruptionNotification,
                           object: nil, queue: .main) { [weak self] note in
            MainActor.assumeIsolated { self?.handleInterruption(note) }
        }
        center.addObserver(forName: AVAudioSession.routeChangeNotification,
                           object: nil, queue: .main) { [weak self] note in
            MainActor.assumeIsolated { self?.handleRouteChange(note) }
        }
    }

    private func handleInterruption(_ note: Notification) {
        guard let raw = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        switch type {
        case .began:
            engine.stop()
        case .ended:
            try? AVAudioSession.sharedInstance().setActive(true)
            engine.start()
        @unknown default:
            break
        }
    }

    private func handleRouteChange(_ note: Notification) {
        guard let raw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: raw) else { return }
        switch reason {
        case .oldDeviceUnavailable,   // headphones/BT unplugged
             .newDeviceAvailable,     // headphones/BT plugged in
             .override,              // inter-device audio mode toggled
             .categoryChange:        // session category changed externally
            print("AudioSession route change (\(reason.rawValue)) — restarting engine")
            engine.stop()
            try? AVAudioSession.sharedInstance().setActive(true)
            engine.start()
        default:
            break
        }
    }
}
