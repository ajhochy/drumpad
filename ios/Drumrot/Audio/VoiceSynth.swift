import AVFoundation

/// Procedural drum synthesis matching the character of `js/audio.js` `drumSound`.
/// Generates a one-shot PCM buffer per lane (preloaded once at engine start).
enum VoiceSynth {
    static let defaultSampleRate = 44_100.0

    static func buffer(for lane: DrumLane, sampleRate: Double = defaultSampleRate) -> AVAudioPCMBuffer {
        makeBuffer(samples(for: lane, sampleRate: sampleRate), sampleRate: sampleRate)
    }

    /// Float samples for a lane. Mirrors the web durations/filters/envelopes.
    static func samples(for lane: DrumLane, sampleRate sr: Double) -> [Float] {
        switch lane {
        case .kick:
            return kick(sr: sr)
        case .snare:
            return noiseVoice(duration: 0.18, envSeconds: 0.16, gain: 0.35,
                              shapedNoise: true, filter: .highpass(1500), sr: sr)
        case .tom:
            return noiseVoice(duration: 0.18, envSeconds: 0.16, gain: 0.35,
                              shapedNoise: true, filter: .bandpass(350), sr: sr)
        case .crash:
            return noiseVoice(duration: 0.6, envSeconds: 0.6, gain: 0.20,
                              shapedNoise: false, filter: .highpass(4000), sr: sr)
        case .hihat:
            return noiseVoice(duration: 0.08, envSeconds: 0.08, gain: 0.20,
                              shapedNoise: false, filter: .highpass(7000), sr: sr)
        case .ride:
            return noiseVoice(duration: 0.35, envSeconds: 0.35, gain: 0.20,
                              shapedNoise: false, filter: .highpass(4000), sr: sr)
        }
    }

    // Kick: sine, frequency exp sweep 120→40 Hz over 80ms, gain exp 0.45→0.001 over 180ms.
    private static func kick(sr: Double) -> [Float] {
        let dur = 0.2, sweep = 0.08, env = 0.18
        let n = Int(dur * sr)
        var out = [Float](repeating: 0, count: n)
        var phase = 0.0
        for i in 0..<n {
            let t = Double(i) / sr
            let f = t < sweep ? 120 * pow(40.0 / 120.0, t / sweep) : 40
            phase += 2 * .pi * f / sr
            let g = 0.45 * pow(0.001 / 0.45, min(t / env, 1.0))
            out[i] = Float(sin(phase) * g)
        }
        return out
    }

    private enum Filter { case highpass(Double), bandpass(Double) }

    // Noise voice: optional (1 - i/len)^2 amplitude shaping on the raw noise, a
    // biquad filter, then an exponential gain envelope to 0.001 over envSeconds.
    private static func noiseVoice(duration: Double, envSeconds: Double, gain: Double,
                                   shapedNoise: Bool, filter: Filter, sr: Double) -> [Float] {
        let n = Int(duration * sr)
        var noise = [Float](repeating: 0, count: n)
        var rng = SystemRandomNumberGenerator()
        for i in 0..<n {
            let white = Double.random(in: -1...1, using: &rng)
            let shape = shapedNoise ? pow(1 - Double(i) / Double(n), 2) : 1
            noise[i] = Float(white * shape)
        }
        var biquad: Biquad
        switch filter {
        case .highpass(let f): biquad = Biquad.highpass(freq: f, sr: sr)
        case .bandpass(let f): biquad = Biquad.bandpass(freq: f, sr: sr)
        }
        var out = [Float](repeating: 0, count: n)
        for i in 0..<n {
            let filtered = biquad.process(Double(noise[i]))
            let t = Double(i) / sr
            let g = gain * pow(0.001 / gain, min(t / envSeconds, 1.0))
            out[i] = Float(filtered * g)
        }
        return out
    }

    static func makeBuffer(_ samples: [Float], sampleRate: Double) -> AVAudioPCMBuffer {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(samples.count))!
        buffer.frameLength = AVAudioFrameCount(samples.count)
        if let ch = buffer.floatChannelData {
            for i in 0..<samples.count { ch[0][i] = max(-1, min(1, samples[i])) }
        }
        return buffer
    }
}

/// Minimal RBJ biquad (highpass / constant-0dB bandpass), Q ≈ 0.707.
struct Biquad {
    private let b0, b1, b2, a1, a2: Double
    private var x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0

    private init(b0: Double, b1: Double, b2: Double, a0: Double, a1: Double, a2: Double) {
        self.b0 = b0 / a0; self.b1 = b1 / a0; self.b2 = b2 / a0
        self.a1 = a1 / a0; self.a2 = a2 / a0
    }

    static func highpass(freq: Double, sr: Double, q: Double = 0.707) -> Biquad {
        let w0 = 2 * .pi * freq / sr, cw = cos(w0), alpha = sin(w0) / (2 * q)
        return Biquad(b0: (1 + cw) / 2, b1: -(1 + cw), b2: (1 + cw) / 2,
                      a0: 1 + alpha, a1: -2 * cw, a2: 1 - alpha)
    }

    static func bandpass(freq: Double, sr: Double, q: Double = 0.707) -> Biquad {
        let w0 = 2 * .pi * freq / sr, cw = cos(w0), alpha = sin(w0) / (2 * q)
        return Biquad(b0: alpha, b1: 0, b2: -alpha,
                      a0: 1 + alpha, a1: -2 * cw, a2: 1 - alpha)
    }

    mutating func process(_ x: Double) -> Double {
        let y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
        x2 = x1; x1 = x; y2 = y1; y1 = y
        return y
    }
}
