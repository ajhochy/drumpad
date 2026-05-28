import XCTest
@testable import Drumrot

/// Regression coverage for the AppSettings Codable decode path.
///
/// Background: Swift's auto-synthesized `init(from:)` does NOT use property
/// default values as fallbacks for missing JSON keys. If we shipped a new
/// non-optional field on AppSettings without a custom decoder, the next
/// build would fail to decode every existing user's stored blob and the
/// `?? AppSettings()` fallback in `PersistenceStore.load()` would silently
/// wipe latency offset, haptics, MIDI device UID, last tab, etc.
///
/// These tests pin the tolerant-decode behavior so future schema additions
/// stay append-safe.
@MainActor
final class AppSettingsDecodeFallbackTests: XCTestCase {

    private static let settingsKey = "drum.settings"

    private func makeSuite() -> UserDefaults {
        let name = "drumrot-test-\(UUID().uuidString)"
        let suite = UserDefaults(suiteName: name)!
        suite.removePersistentDomain(forName: name)
        return suite
    }

    /// Older build's JSON shape: no `externalAudioMode` key at all.
    /// Existing fields (latency, haptics, MIDI UID, lastTab) MUST survive
    /// the upgrade. The missing key falls back to its declared default.
    func testDecodesLegacyPayloadWithoutExternalAudioMode() throws {
        let suite = makeSuite()
        let legacy: [String: Any] = [
            "schemaVersion": 1,
            "midiDeviceUID": "TD-17:1",
            "audioLatencyOffsetMs": -18,
            "hapticsEnabled": false,
            "reduceMotionOverride": true,
            "lastTab": "lessons"
            // externalAudioMode intentionally absent (pre-#60 build)
        ]
        let data = try JSONSerialization.data(withJSONObject: legacy)
        suite.set(data, forKey: Self.settingsKey)

        let store = PersistenceStore(defaults: suite)

        XCTAssertEqual(store.settings.midiDeviceUID, "TD-17:1",
                       "MIDI device UID must survive schema upgrade")
        XCTAssertEqual(store.settings.audioLatencyOffsetMs, -18,
                       "audio latency offset must NOT reset to 0")
        XCTAssertFalse(store.settings.hapticsEnabled,
                       "haptics toggle must survive schema upgrade")
        XCTAssertTrue(store.settings.reduceMotionOverride,
                      "reduce-motion override must survive schema upgrade")
        XCTAssertEqual(store.settings.lastTab, "lessons",
                       "last-tab must survive schema upgrade")
        XCTAssertFalse(store.settings.externalAudioMode,
                       "missing field falls back to declared default")
    }

    /// Even older build: only `schemaVersion` was persisted. Every
    /// post-schema-v1 field must fall back to its declared default
    /// rather than failing the entire decode.
    func testDecodesMinimalPayloadWithOnlySchemaVersion() {
        let suite = makeSuite()
        let minimal: [String: Any] = ["schemaVersion": 1]
        let data = try! JSONSerialization.data(withJSONObject: minimal)
        suite.set(data, forKey: Self.settingsKey)

        let store = PersistenceStore(defaults: suite)

        XCTAssertNil(store.settings.midiDeviceUID)
        XCTAssertEqual(store.settings.audioLatencyOffsetMs, 0)
        XCTAssertTrue(store.settings.hapticsEnabled)
        XCTAssertFalse(store.settings.reduceMotionOverride)
        XCTAssertEqual(store.settings.lastTab, "play")
        XCTAssertFalse(store.settings.externalAudioMode)
    }

    /// Future-build simulation: the stored blob contains a key this build
    /// doesn't know about. Decoding must ignore the unknown key and still
    /// honor every key it does recognize. (Codable already does this with
    /// auto-synthesized init; the test guards against a future refactor
    /// that switches to a strict decoder.)
    func testIgnoresUnknownKeysFromFutureBuild() throws {
        let suite = makeSuite()
        let future: [String: Any] = [
            "schemaVersion": 1,
            "audioLatencyOffsetMs": 12,
            "hapticsEnabled": true,
            "lastTab": "play",
            "externalAudioMode": true,
            "accentVolumeDb": -6.0,            // hypothetical future field
            "midiChannelFilter": [10, 11]      // hypothetical future field
        ]
        let data = try JSONSerialization.data(withJSONObject: future)
        suite.set(data, forKey: Self.settingsKey)

        let store = PersistenceStore(defaults: suite)

        XCTAssertEqual(store.settings.audioLatencyOffsetMs, 12)
        XCTAssertTrue(store.settings.externalAudioMode)
    }

    /// Fresh install (no stored data) must produce a default AppSettings
    /// without throwing.
    func testFreshInstallYieldsDefaults() {
        let suite = makeSuite()
        let store = PersistenceStore(defaults: suite)

        XCTAssertEqual(store.settings, AppSettings(),
                       "no stored data -> all defaults")
    }

    /// Corrupted blob (not JSON at all) must also fall back to defaults
    /// rather than crash.
    func testCorruptedBlobFallsBackToDefaults() {
        let suite = makeSuite()
        suite.set(Data([0xDE, 0xAD, 0xBE, 0xEF]), forKey: Self.settingsKey)

        let store = PersistenceStore(defaults: suite)

        XCTAssertEqual(store.settings, AppSettings())
    }

    /// Round-trip: persist with the new encoder, decode with the new
    /// decoder. Confirms the custom init(from:) doesn't break the
    /// happy path.
    func testRoundTripPreservesAllFields() {
        let suite = makeSuite()
        let s1 = PersistenceStore(defaults: suite)
        s1.updateSettings { st in
            st.midiDeviceUID = "Module:42"
            st.audioLatencyOffsetMs = 27
            st.hapticsEnabled = false
            st.reduceMotionOverride = true
            st.lastTab = "builder"
            st.externalAudioMode = true
        }

        let s2 = PersistenceStore(defaults: suite)
        XCTAssertEqual(s2.settings.midiDeviceUID, "Module:42")
        XCTAssertEqual(s2.settings.audioLatencyOffsetMs, 27)
        XCTAssertFalse(s2.settings.hapticsEnabled)
        XCTAssertTrue(s2.settings.reduceMotionOverride)
        XCTAssertEqual(s2.settings.lastTab, "builder")
        XCTAssertTrue(s2.settings.externalAudioMode)
    }
}
