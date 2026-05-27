import SwiftUI
import SwiftData

struct BuildView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.modelContext) private var context

    @State private var steps = 16
    @State private var grid = Array(repeating: Array(repeating: false, count: 16), count: 6)
    @State private var bpm = 90
    @State private var coach = ""
    @State private var exportFile: ExportFile?

    private let lanes: [DrumLane] = DrumLane.allCases

    private var isEmpty: Bool { !grid.contains { $0.contains(true) } }

    var body: some View {
        ZStack {
            SPColor.background.ignoresSafeArea()
            VStack(spacing: 14) {
                controls
                gridView
                TextField("Coach note (optional)", text: $coach)
                    .textFieldStyle(.roundedBorder)
                    .font(SPFont.mono(.caption))
                HStack {
                    Button(role: .destructive) { clear() } label: { Label("Clear", systemImage: "trash") }
                        .buttonStyle(.bordered)
                    Button { exportMIDI() } label: { Label("Export .mid", systemImage: "square.and.arrow.up") }
                        .buttonStyle(.bordered).tint(SPColor.accentOrange)
                        .disabled(isEmpty)
                    Spacer()
                    Button { loadIntoPlayer() } label: { Label("Load into Play", systemImage: "play.fill") }
                        .buttonStyle(.borderedProminent).tint(SPColor.accentGreen)
                        .disabled(isEmpty)
                }
            }
            .padding(16)
        }
        .sheet(item: $exportFile) { ShareSheet(items: [$0.url]) }
    }

    private func exportMIDI() {
        let data = MIDIFileExporter.export(lanePatterns: grid, bpm: bpm)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("drumrot-pattern.mid")
        guard (try? data.write(to: url)) != nil else { return }
        exportFile = ExportFile(url: url)
    }

    private var controls: some View {
        HStack {
            Picker("Steps", selection: $steps) {
                Text("16").tag(16); Text("32").tag(32)
            }
            .pickerStyle(.segmented)
            .frame(width: 140)
            .onChange(of: steps) { _, new in resize(to: new) }
            Spacer()
            BpmStepper(bpm: $bpm)
        }
    }

    private var gridView: some View {
        VStack(spacing: 5) {
            ForEach(lanes, id: \.self) { lane in
                HStack(spacing: 4) {
                    Text(lane.label)
                        .font(SPFont.mono(.caption2, weight: .bold))
                        .frame(width: 30, alignment: .leading)
                        .foregroundStyle(.secondary)
                    ForEach(0..<steps, id: \.self) { step in
                        let on = grid[lane.rawValue][step]
                        RoundedRectangle(cornerRadius: 4)
                            .fill(on ? SPColor.accentGreen : SPColor.panel)
                            .frame(height: 26)
                            .overlay(RoundedRectangle(cornerRadius: 4)
                                .stroke(step % 4 == 0 ? Color.white.opacity(0.25) : .clear, lineWidth: 1))
                            .onTapGesture { grid[lane.rawValue][step].toggle() }
                    }
                }
            }
        }
    }

    private func resize(to newSteps: Int) {
        grid = grid.map { row in
            if row.count < newSteps { return row + Array(repeating: false, count: newSteps - row.count) }
            return Array(row.prefix(newSteps))
        }
    }

    private func clear() {
        grid = Array(repeating: Array(repeating: false, count: steps), count: 6)
        coach = ""
    }

    private func loadIntoPlayer() {
        guard let lesson = BuilderLessonFactory.lesson(grid: grid, bpm: bpm, coach: coach) else { return }
        persistBuilderState()
        if let data = try? JSONEncoder().encode(lesson),
           let json = String(data: data, encoding: .utf8) {
            upsertExtraLesson(name: lesson.name, json: json)
        }
        // Achievements: creator always; coach if a note was attached.
        store.achievements?.fire(.creator)
        if !coach.isEmpty { store.achievements?.fire(.coach) }
        store.currentLesson = lesson
        store.autoStartPlay = false
        store.selectedTab = .play
    }

    private func persistBuilderState() {
        let pattern = Dictionary(uniqueKeysWithValues: lanes.map { ($0.key, grid[$0.rawValue]) })
        let json = (try? JSONEncoder().encode(pattern)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        let existing = try? context.fetch(FetchDescriptor<BuilderState>()).first
        if let row = existing ?? nil {
            row.steps = steps; row.patternJSON = json; row.bpm = bpm; row.coachNote = coach
        } else {
            context.insert(BuilderState(steps: steps, patternJSON: json, bpm: bpm, coachNote: coach))
        }
    }

    private func upsertExtraLesson(name: String, json: String) {
        let existing = try? context.fetch(FetchDescriptor<ExtraLesson>()).first { $0.name == name }
        if let row = existing ?? nil {
            row.lessonJSON = json; row.createdAt = .now
        } else {
            context.insert(ExtraLesson(name: name, lessonJSON: json))
        }
    }
}

#Preview {
    BuildView()
        .environmentObject(AppStore())
        .modelContainer(AppModelContainer.make(inMemory: true))
        .preferredColorScheme(.dark)
}
