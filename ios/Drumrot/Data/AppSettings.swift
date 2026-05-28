import Foundation
import SwiftData

/// Singleton app settings (mirror of the `drum.settings` localStorage blob).
/// `schemaVersion` supports corrupt-row recovery / future migrations.
@Model
final class AppSettings {
    var schemaVersion: Int
    var midiDeviceUID: String?
    var audioLatencyOffsetMs: Int
    var hapticsEnabled: Bool
    var reduceMotionOverride: Bool
    var lastTab: String
    /// When true, MIDI-triggered note-ons skip in-app sample playback so the
    /// user can monitor through their drum module's own headphone output
    /// without a doubled hit. On-screen pad gestures + metronome are
    /// unaffected (#60).
    var externalAudioMode: Bool

    init(
        schemaVersion: Int = 1,
        midiDeviceUID: String? = nil,
        audioLatencyOffsetMs: Int = 0,
        hapticsEnabled: Bool = true,
        reduceMotionOverride: Bool = false,
        lastTab: String = "play",
        externalAudioMode: Bool = false
    ) {
        self.schemaVersion = schemaVersion
        self.midiDeviceUID = midiDeviceUID
        self.audioLatencyOffsetMs = audioLatencyOffsetMs
        self.hapticsEnabled = hapticsEnabled
        self.reduceMotionOverride = reduceMotionOverride
        self.lastTab = lastTab
        self.externalAudioMode = externalAudioMode
    }
}
