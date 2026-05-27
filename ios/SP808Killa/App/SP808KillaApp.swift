import SwiftUI
import SwiftData

@main
struct SP808KillaApp: App {
    @StateObject private var store = AppStore()
    private let container = AppModelContainer.make()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .task {
                    store.attach(modelContext: container.mainContext)
                    seedDemoIfRequested()
                }
        }
        .modelContainer(container)
    }

    /// Debug-only: `--demo` seeds a few collected drumrots and opens Drops, so the
    /// card chrome can be screenshotted/QA'd without playing through the game.
    private func seedDemoIfRequested() {
        #if DEBUG
        guard CommandLine.arguments.contains("--demo") else { return }
        let svc = PersistenceService(context: container.mainContext)
        svc.collect(drumrotId: "tung_tung_tamburino", tier: .common)
        svc.collect(drumrotId: "bombardino_crashcino", tier: .epic)
        svc.collect(drumrotId: "lirili_beatlarila", tier: .mythic)
        svc.collect(drumrotId: "grande_maestro_drumbeano", tier: .og)
        try? container.mainContext.save()
        store.selectedTab = .drops

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
