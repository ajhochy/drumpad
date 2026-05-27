import SwiftUI
import SwiftData

/// App-wide observable state + service handles, injected at the root.
/// Persistent data lives in SwiftData; this holds transient UI state and
/// (in later phases) the audio/MIDI/playback engine handles.
@MainActor
final class AppStore: ObservableObject {
    @Published var selectedTab: RootView.Tab = .play
    @Published var showSettings = false

    /// Set once the SwiftData context is available (Phase 4 wires persistence here).
    private(set) var modelContext: ModelContext?

    func attach(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
}
