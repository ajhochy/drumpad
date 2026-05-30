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
    /// gap" on real hardware.
    struct RecentEvent: Identifiable, Equatable {
        let id = UUID()
        let timestamp: Date
        let status: UInt8       // 0x90 = note-on (only kind we log today)
        let note: Int
        let velocity: Int
        let lane: DrumLane?     // nil = unmapped
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
                receiver: .events { [weak self] events, _, _ in
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
                    Task { @MainActor in self?.receive(events) }
                }
            )
        } catch {
            #if DEBUG
            print("[MIDIInputManager] SwiftMIDI start failed: \(error)")
            #endif
            return
        }

        // Network MIDI: kept as an explicit CoreMIDI call so behavior on the
        // existing "Network Session 1" source matches build 1 exactly.
        let session = MIDINetworkSession.default()
        session.isEnabled = true
        session.connectionPolicy = .anyone

        refreshSources()
    }

    private func refreshSources() {
        sources = manager.endpoints.outputs.map { ep in
            Source(id: ep.uniqueID, name: ep.displayName)
        }
    }

    private func receive(_ events: [MIDIEvent]) {
        var fired = false
        for e in events {
            guard case .noteOn(let n) = e else { continue }
            let velocity = n.velocity.midi1Value.intValue
            let note = n.note.number.intValue
            guard velocity > 0 else { continue }

            // Log every note-on (mapped or not) into the diagnostic ring so
            // the on-screen overlay can distinguish "no events" from
            // "events arriving but no GM mapping".
            let lane = GMDrumMapper.lane(forNote: note)
            let entry = RecentEvent(timestamp: Date(), status: 0x90, note: note, velocity: velocity, lane: lane)
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
