import AVFoundation

/// Metronome click, matching `clickSound` in `js/audio.js`: square wave,
/// 1800 Hz accent / 1100 Hz normal, short percussive envelope.
enum ClickSynth {
    static func buffer(accent: Bool, sampleRate: Double = VoiceSynth.defaultSampleRate) -> AVAudioPCMBuffer {
        let dur = 0.06, attack = 0.002, decayTo = 0.06
        let freq = accent ? 1800.0 : 1100.0
        let peak = accent ? 0.18 : 0.10
        let n = Int(dur * sampleRate)
        var out = [Float](repeating: 0, count: n)
        var phase = 0.0
        for i in 0..<n {
            let t = Double(i) / sampleRate
            phase += 2 * .pi * freq / sampleRate
            let square = sin(phase) >= 0 ? 1.0 : -1.0
            let g: Double
            if t < attack {
                g = peak * (t / attack)
            } else {
                g = peak * pow(0.0001 / peak, min((t - attack) / decayTo, 1.0))
            }
            out[i] = Float(square * g)
        }
        return VoiceSynth.makeBuffer(out, sampleRate: sampleRate)
    }
}
