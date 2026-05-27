import SwiftUI
import SwiftData

/// App-wide observable state + service handles, injected at the root.
/// Persistent data lives in SwiftData; this holds transient UI state and
/// (in later phases) the audio/MIDI/playback engine handles.
@MainActor
final class AppStore: ObservableObject {
    @Published var selectedTab: RootView.Tab = .play
    @Published var showSettings = false

    /// Lesson currently loaded into Play (set by Library; defaults to the first).
    @Published var currentLesson: Lesson?
    /// Debug: auto-start playback when Play appears (set by the `--play` launch arg).
    var autoStartPlay = false

    // Shared audio + MIDI input (activated on first Play appearance).
    let audio = DrumAudioEngine()
    let midi = MIDIInputManager()
    private lazy var audioSession = AudioSessionManager(engine: audio)
    private var audioActivated = false

    func activateAudio() {
        guard !audioActivated else { return }
        audioActivated = true
        audioSession.activate()
    }

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

    // Achievement engine + toast.
    private(set) var achievements: AchievementEngine?
    @Published var currentToast: Achievement?
    private var toastQueue: [Achievement] = []
    var consecutiveAccuratePasses = 0

    func attach(modelContext: ModelContext) {
        self.modelContext = modelContext
        let engine = AchievementEngine(context: modelContext)
        engine.store = self
        self.achievements = engine
    }

    func enqueueToast(_ achievement: Achievement) {
        toastQueue.append(achievement)
        showNextToastIfIdle()
    }

    private func showNextToastIfIdle() {
        guard currentToast == nil, !toastQueue.isEmpty else { return }
        currentToast = toastQueue.removeFirst()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            currentToast = nil
            showNextToastIfIdle()
        }
    }

    /// Write/upsert layer over the live context (nil before `attach`).
    var persistence: PersistenceService? {
        modelContext.map(PersistenceService.init(context:))
    }
}
