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

    init(
        schemaVersion: Int = 1,
        midiDeviceUID: String? = nil,
        audioLatencyOffsetMs: Int = 0,
        hapticsEnabled: Bool = true,
        reduceMotionOverride: Bool = false,
        lastTab: String = "play"
    ) {
        self.schemaVersion = schemaVersion
        self.midiDeviceUID = midiDeviceUID
        self.audioLatencyOffsetMs = audioLatencyOffsetMs
        self.hapticsEnabled = hapticsEnabled
        self.reduceMotionOverride = reduceMotionOverride
        self.lastTab = lastTab
    }
}
