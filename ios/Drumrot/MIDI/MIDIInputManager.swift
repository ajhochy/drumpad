import CoreMIDI
import Foundation
import SwiftMIDI

/// MIDI input layer built on orchetect/MIDIKit (`SwiftMIDI`).
///
/// Replaces the hand-rolled CoreMIDI plumbing from build 1 so iOS 16 USB devices
/// that fail UMP translation fall back through the legacy receive path SwiftMIDI
/// selects automatically — the root cause for the silent-receive symptom on the
/// TD-50X (#57).
///
/// Public API preserved: PlayView and SettingsView keep using `.sources`,
/// `.activity`, `.onNote`, and `start()` exactly as before.
@MainActor
final class MIDIInputManager: ObservableObject {
    struct Source: Identifiable, Equatable { let id: Int32; let name: String }

    /// One incoming MIDI note-on, captured for the on-screen diagnostic overlay
    /// (#58). `lane == nil` means the note is not in the GM drum map — useful
    /// for distinguishing "no CoreMIDI delivery" from "delivery works, mapping
    /// gap" on real hardware. `sourceName` identifies which endpoint sent it so
    /// you can tell WiFi-network idle noise from real hardware input.
    struct RecentEvent: Identifiable, Equatable {
        let id = UUID()
        let timestamp: Date
        let status: UInt8       // 0x90 = note-on (only kind we log today)
        let note: Int
        let velocity: Int
        let lane: DrumLane?     // nil = unmapped
        let sourceName: String  // display name of the originating MIDI endpoint
    }

    @Published private(set) var sources: [Source] = []
    @Published private(set) var activity = false
    @Published private(set) var recentEvents: [RecentEvent] = []
    private let recentEventsCap = 8

    /// Called on the MainActor for each incoming drum note-on.
    /// Use this for game logic (scoring, achievements). Audio is fired earlier
    /// via `audioCallback` directly on the CoreMIDI thread.
    var onNote: ((DrumLane, Int) -> Void)?

    /// Called immediately on the CoreMIDI callback thread — no main-actor hop.
    /// Set this to a thread-safe closure (e.g. `DrumAudioEngine.playImmediate`).
    /// Must not touch any `@MainActor` state directly.
    nonisolated(unsafe) var audioCallback: ((DrumLane, Int) -> Void)?

    /// Allow/block the WiFi Network MIDI session from auto-accepting connections.
    /// Default is `false` (`.noOne`) so a background Ableton or DAW session on the
    /// same network can't inject events. Set to `true` only when the user explicitly
    /// wants Network MIDI (e.g. testing from a Mac).
    var networkMIDIEnabled: Bool = false {
        didSet {
            let policy: MIDINetworkConnectionPolicy = networkMIDIEnabled ? .anyone : .noOne
            MIDINetworkSession.default().connectionPolicy = policy
            print("[MIDI] Network policy → \(networkMIDIEnabled ? "anyone" : "noOne")")
            refreshSources()
        }
    }

    private let manager = MIDIManager(
        clientName: "Drumrot",
        model: "Drumrot",
        manufacturer: "VCRC"
    )
    private let inputTag = "drumrot-in"
    private var started = false

    func start() {
        guard !started else { refreshSources(); return }
        started = true

        // System notifications: hot-plug, rename, removal. Mirrors what
        // MIDIClientCreateWithBlock's callback gave us in build 1.
        manager.notificationHandler = { [weak self] _ in
            Task { @MainActor in self?.refreshSources() }
        }

        do {
            try manager.start()
            try manager.addInputConnection(
                to: .allOutputs,
                tag: inputTag,
                receiver: .events { [weak self] events, _, source in
                    // ── Fast path (CoreMIDI thread, no main-actor hop) ──────────────
                    // Fire audio immediately so the buffer schedules within
                    // microseconds of the event. This eliminates the ~16 ms stall
                    // that occurs when waiting for the next main run-loop tick.
                    if let cb = self?.audioCallback {
                        for event in events {
                            guard case .noteOn(let n) = event else { continue }
                            let vel = n.velocity.midi1Value.intValue
                            guard vel > 0 else { continue }
                            let note = n.note.number.intValue
                            if let lane = GMDrumMapper.lane(forNote: note) {
                                cb(lane, vel)
                            }
                        }
                    }
                    // ── Slow path (main actor) ──────────────────────────────────────
                    // Diagnostics overlay, activity LED, and game-logic callbacks.
                    let name = source?.displayName ?? "unknown"
                    Task { @MainActor in self?.receive(events, from: name) }
                }
            )
            print("[MIDI] MIDIKit started OK — listening on all outputs")
        } catch {
            print("[MIDI] SwiftMIDI start FAILED: \(error)")
            return
        }

        // Network MIDI: enable the session but require explicit connection via
        // Audio MIDI Setup rather than auto-accepting any device on the network.
        // Use .anyone only when the user explicitly enables WiFi MIDI in Settings.
        let session = MIDINetworkSession.default()
        session.isEnabled = true
        session.connectionPolicy = .noOne   // upgraded to .anyone via enableNetworkMIDI()
        print("[MIDI] Network session enabled, policy=noOne (explicit connect required)")

        refreshSources()
        print("[MIDI] Initial source count: \(sources.count)")
    }

    private func refreshSources() {
        let updated = manager.endpoints.outputs.map { ep in
            Source(id: ep.uniqueID, name: ep.displayName)
        }
        if updated != sources {
            print("[MIDI] Sources updated (\(updated.count)): \(updated.map(\.name))")
        }
        sources = updated
    }

    private func receive(_ events: [MIDIEvent], from sourceName: String) {
        var fired = false
        for e in events {
            // Log ALL event types so we can see what the hardware actually sends —
            // non-noteOn messages (CC, SysEx, noteOn vel=0, etc.) are visible in
            // the console even though only mapped noteOns drive the game.
            print("[MIDI] \(sourceName): \(e)")

            guard case .noteOn(let n) = e else { continue }
            let velocity = n.velocity.midi1Value.intValue
            let note = n.note.number.intValue
            guard velocity > 0 else { continue }

            // Log every note-on (mapped or not) into the diagnostic ring so
            // the on-screen overlay can distinguish "no events" from
            // "events arriving but no GM mapping". Source name included so
            // WiFi-network events are visually distinct from USB hardware.
            let lane = GMDrumMapper.lane(forNote: note)
            let entry = RecentEvent(timestamp: Date(), status: 0x90, note: note,
                                    velocity: velocity, lane: lane, sourceName: sourceName)
            recentEvents.append(entry)
            if recentEvents.count > recentEventsCap {
                recentEvents.removeFirst(recentEvents.count - recentEventsCap)
            }

            if let lane {
                onNote?(lane, velocity)
                fired = true
            }
        }
        // Activity LED is gated to mapped notes (preserves build-1 behavior).
        if fired { flashActivity() }
    }

    private func flashActivity() {
        activity = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            activity = false
        }
    }
}
