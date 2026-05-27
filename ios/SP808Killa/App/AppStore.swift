import SwiftUI
import SwiftData

/// App-wide observable state + service handles, injected at the root.
/// Persistent data lives in SwiftData; this holds transient UI state and
/// (in later phases) the audio/MIDI/playback engine handles.
@MainActor
final class AppStore: ObservableObject {
    @Published var selectedTab: RootView.Tab = .play
    @Published var showSettings = false

    /// A drumrot drop awaiting its reveal overlay.
    struct RevealItem: Identifiable, Equatable {
        let id = UUID()
        let drumrot: Drumrot
        let tier: DrumrotTier
        let fromAchievement: String
        let isNew: Bool
    }

    @Published var currentReveal: RevealItem?
    private var revealQueue: [RevealItem] = []

    /// Queue a reveal; shows immediately if nothing is on screen.
    func enqueueReveal(_ item: RevealItem) {
        revealQueue.append(item)
        showNextRevealIfIdle()
    }

    func dismissCurrentReveal() {
        currentReveal = nil
        showNextRevealIfIdle()
    }

    private func showNextRevealIfIdle() {
        guard currentReveal == nil, !revealQueue.isEmpty else { return }
        currentReveal = revealQueue.removeFirst()
    }

    /// Set once the SwiftData context is available (Phase 4 wires persistence here).
    private(set) var modelContext: ModelContext?

    func attach(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Write/upsert layer over the live context (nil before `attach`).
    var persistence: PersistenceService? {
        modelContext.map(PersistenceService.init(context:))
    }
}
