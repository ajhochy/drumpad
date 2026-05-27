import XCTest
import AVFoundation
@testable import SP808Killa

/// Headless checks on the synthesized buffers (audio output itself / latency is a
/// real-device gate). Verifies durations, that buffers aren't silent, and PCM range.
final class VoiceSynthTests: XCTestCase {
    private let sr = 44_100.0

    func testBufferDurationsPerLane() {
        let expected: [DrumLane: Double] = [
            .kick: 0.2, .snare: 0.18, .tom: 0.18, .crash: 0.6, .hihat: 0.08, .ride: 0.35,
        ]
        for (lane, dur) in expected {
            let buf = VoiceSynth.buffer(for: lane, sampleRate: sr)
            XCTAssertEqual(Int(buf.frameLength), Int(dur * sr), "\(lane) frame count")
        }
    }

    func testBuffersAreAudibleAndInRange() {
        for lane in DrumLane.allCases {
            let buf = VoiceSynth.buffer(for: lane, sampleRate: sr)
            let ch = buf.floatChannelData![0]
            var peak: Float = 0
            for i in 0..<Int(buf.frameLength) {
                let v = ch[i]
                XCTAssertTrue(v.isFinite, "\(lane) non-finite sample")
                peak = max(peak, abs(v))
            }
            XCTAssertGreaterThan(peak, 0.01, "\(lane) is silent")
            XCTAssertLessThanOrEqual(peak, 1.0, "\(lane) clips")
        }
    }

    func testClickAccentLouderThanNormal() {
        func peak(_ accent: Bool) -> Float {
            let buf = ClickSynth.buffer(accent: accent, sampleRate: sr)
            let ch = buf.floatChannelData![0]
            var p: Float = 0
            for i in 0..<Int(buf.frameLength) { p = max(p, abs(ch[i])) }
            return p
        }
        XCTAssertGreaterThan(peak(true), peak(false))
        XCTAssertGreaterThan(peak(false), 0.01)
    }
}
