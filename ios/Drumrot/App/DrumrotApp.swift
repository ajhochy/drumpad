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

        // Seed a couple of user-authored lessons so Library visual smoke
        // exercises the USER stamp + Edit/Delete context menu added in
        // the groove-library feature. Builder + Import genres also show up
        // as filter chips when these are present.
        if let builderLesson = demoBuilderLesson(),
           let json = try? JSONEncoder().encode(builderLesson),
           let str = String(data: json, encoding: .utf8) {
            svc.saveExtraLesson(name: builderLesson.name, lessonJSON: str)
        }
        if let importLesson = demoImportLesson(),
           let json = try? JSONEncoder().encode(importLesson),
           let str = String(data: json, encoding: .utf8) {
            svc.saveExtraLesson(name: importLesson.name, lessonJSON: str)
        }

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

    #if DEBUG
    private func demoBuilderLesson() -> Lesson? {
        var grid = Array(repeating: Array(repeating: false, count: 16), count: 6)
        for i in 0..<16 { grid[DrumLane.hihat.rawValue][i] = true }
        grid[DrumLane.kick.rawValue][0]  = true
        grid[DrumLane.kick.rawValue][8]  = true
        grid[DrumLane.snare.rawValue][4] = true
        grid[DrumLane.snare.rawValue][12] = true
        return BuilderLessonFactory.lesson(
            grid: grid, bpm: 92, coach: "Lock the backbeat", name: "Backbeat Sketch"
        )
    }

    private func demoImportLesson() -> Lesson? {
        var grid = Array(repeating: Array(repeating: false, count: 16), count: 6)
        grid[DrumLane.kick.rawValue][0]  = true
        grid[DrumLane.kick.rawValue][6]  = true
        grid[DrumLane.snare.rawValue][4] = true
        grid[DrumLane.snare.rawValue][12] = true
        grid[DrumLane.ride.rawValue][2]  = true
        grid[DrumLane.ride.rawValue][10] = true
        // Stamp it with the Import genre so it slots under the Import filter chip.
        guard let l = BuilderLessonFactory.lesson(
            grid: grid, bpm: 104, coach: "", name: "demo-import"
        ) else { return nil }
        return Lesson(
            name: l.name, bpm: l.bpm, tip: "MIDI file: demo-import",
            difficulty: "Custom", genre: "Import", patterns: l.patterns
        )
    }
    #endif
}
