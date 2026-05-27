import CoreMIDI
import Foundation

/// CoreMIDI input: enumerates sources (USB / Network / BLE), receives note-on
/// messages on the RT callback and marshals GM-mapped hits to the MainActor.
/// Live hardware input is a real-device gate; this compiles + enumerates on the sim.
@MainActor
final class MIDIInputManager: ObservableObject {
    struct Source: Identifiable, Equatable { let id: Int32; let name: String }

    @Published private(set) var sources: [Source] = []
    @Published private(set) var activity = false

    /// Called on the MainActor for each incoming drum note-on.
    var onNote: ((DrumLane, Int) -> Void)?

    private var client = MIDIClientRef()
    private var inputPort = MIDIPortRef()
    private var started = false

    func start() {
        guard !started else { refreshSources(); return }
        started = true

        MIDIClientCreateWithBlock("SP808Killa" as CFString, &client) { [weak self] _ in
            Task { @MainActor in self?.refreshSources() }
        }
        MIDIInputPortCreateWithProtocol(client, "in" as CFString, ._1_0, &inputPort) { [weak self] eventList, _ in
            self?.receive(eventList)
        }

        let session = MIDINetworkSession.default()
        session.isEnabled = true
        session.connectionPolicy = .anyone

        refreshSources()
    }

    private func refreshSources() {
        var list: [Source] = []
        let count = MIDIGetNumberOfSources()
        for i in 0..<count {
            let src = MIDIGetSource(i)
            MIDIPortConnectSource(inputPort, src, nil)
            var uid: Int32 = 0
            MIDIObjectGetIntegerProperty(src, kMIDIPropertyUniqueID, &uid)
            var name: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(src, kMIDIPropertyDisplayName, &name)
            list.append(Source(id: uid, name: (name?.takeRetainedValue() as String?) ?? "MIDI \(i)"))
        }
        sources = list
    }

    /// RT-thread callback. Decodes UMP MIDI-1.0 channel-voice note-ons.
    private nonisolated func receive(_ eventList: UnsafePointer<MIDIEventList>) {
        var hits: [(DrumLane, Int)] = []
        var packet = eventList.pointee.packet
        for _ in 0..<eventList.pointee.numPackets {
            let wordCount = Int(packet.wordCount)
            withUnsafePointer(to: packet.words) { tuplePtr in
                tuplePtr.withMemoryRebound(to: UInt32.self, capacity: 64) { words in
                    for w in 0..<min(wordCount, 64) {
                        let word = words[w]
                        guard (word >> 28) & 0xF == 0x2 else { continue }   // MIDI 1.0 channel voice
                        let status = (word >> 16) & 0xFF
                        let note = Int((word >> 8) & 0xFF)
                        let vel = Int(word & 0xFF)
                        if status & 0xF0 == 0x90, vel > 0, let lane = GMDrumMapper.lane(forNote: note) {
                            hits.append((lane, vel))
                        }
                    }
                }
            }
            packet = MIDIEventPacketNext(&packet).pointee
        }
        guard !hits.isEmpty else { return }
        let captured = hits
        Task { @MainActor [weak self] in
            guard let self else { return }
            for (lane, vel) in captured { self.onNote?(lane, vel) }
            self.flashActivity()
        }
    }

    private func flashActivity() {
        activity = true
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            activity = false
        }
    }
}
