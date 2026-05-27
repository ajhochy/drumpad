import SwiftUI

@main
struct DrumrotApp: App {
    @StateObject private var persistence: PersistenceStore
    @StateObject private var store: AppStore

    init() {
        let p = PersistenceStore()
        _persistence = StateObject(wrappedValue: p)
        _store = StateObject(wrappedValue: AppStore(persistence: p))
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(persistence)
                .preferredColorScheme(.dark)
                .task { seedDemoIfRequested() }
        }
    }

    /// Debug-only: `--demo` seeds a few collected drumrots and opens Drops, so the
    /// card chrome can be screenshotted/QA'd without playing through the game.
    private func seedDemoIfRequested() {
        #if DEBUG
        guard CommandLine.arguments.contains("--demo") else { return }
        let svc = store.persistence
        svc.collect(drumrotId: "tung_tung_tamburino", tier: .common)
        svc.collect(drumrotId: "bombardino_crashcino", tier: .epic)
        svc.collect(drumrotId: "lirili_beatlarila", tier: .mythic)
        svc.collect(drumrotId: "grande_maestro_drumbeano", tier: .og)
        svc.recordPass(lessonKey: "Rock Beat 101", score: 5400, accuracy: 96,
                       tier: PracticeTier.grooving.rawValue)
        let fmt = DateFormatter(); fmt.dateFormat = "yyyy-MM-dd"; fmt.timeZone = TimeZone(identifier: "UTC")
        svc.recordPlayDay(fmt.string(from: Date()))
        svc.unlock("first_hit"); svc.unlock("groove_master")
        store.selectedTab = .drops

        if let tabArg = CommandLine.arguments.first(where: {
            ["--library", "--progress", "--build", "--drops"].contains($0)
        }), let tab = RootView.Tab(rawValue: String(tabArg.dropFirst(2))) {
            store.selectedTab = tab
        }

        if CommandLine.arguments.contains("--reveal"),
           let og = DrumrotCatalog.all.first(where: { $0.tier == .og }) {
            store.enqueueReveal(.init(drumrot: og, tier: .og, fromAchievement: "First Hit", isNew: true))
        }
        if CommandLine.arguments.contains("--play") {
            store.currentLesson = LessonCatalog.all.first
            store.autoStartPlay = true
            store.selectedTab = .play
        }
        #endif
    }
}
