# App Store privacy nutrition label — SP-808 KILLA

## Data collection: **Data Not Collected**

The app collects **no** data. No analytics SDK, no telemetry, no crash
reporter, no IDFA, no SKAdNetwork, no accounts. All progress (scores,
achievements, collection, builder pattern, settings) is stored **on-device**
in SwiftData and never leaves the device. No network calls are made for
user data; the only network use is **local-network Network MIDI** input
(no data leaves the LAN, and nothing is uploaded).

When filling App Store Connect → App Privacy, answer **"No, we do not collect
data from this app."**

## Entitlements / capabilities (iPad-only target)
- **Bluetooth** — BLE MIDI pairing (`NSBluetoothAlwaysUsageDescription`).
- **Local Network** — Network MIDI (`NSLocalNetworkUsageDescription`).
- **Bonjour Services** — Network MIDI discovery (`NSBonjourServices = _apple-midi._udp`).
- User-selected file access via the document picker (MIDI import/export) — no persistent entitlement.
- **No** background-audio mode (foreground-only).
- **No** microphone / audio-input entitlement (the app does not record).
- **No** App Tracking Transparency (no tracking).

Pre-submission TODO (still open):
- Confirm `audio-output` required-device-capability if desired.

## Review notes
- The drum trainer's Play tab is best with a hardware MIDI controller, but
  Build / Library / Progress / Drops + on-screen pads work without hardware so
  reviewers can navigate the whole app.
