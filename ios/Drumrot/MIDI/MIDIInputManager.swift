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

    @Published private(set) var sources: [Source] = []
    @Published private(set) var activity = false

    /// Called on the MainActor for each incoming drum note-on.
    var onNote: ((DrumLane, Int) -> Void)?

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
            guard velocity > 0, let lane = GMDrumMapper.lane(forNote: note) else { continue }
            onNote?(lane, velocity)
            fired = true
        }
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
