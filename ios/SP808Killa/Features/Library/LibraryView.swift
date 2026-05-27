import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.modelContext) private var context
    @Query private var scores: [LessonScore]
    @State private var showImporter = false
    @State private var importError: String?

    private let columns = [GridItem(.adaptive(minimum: 240), spacing: 14)]

    private var scoreByName: [String: LessonScore] {
        Dictionary(scores.map { ($0.lessonKey, $0) }, uniquingKeysWith: { a, _ in a })
    }

    var body: some View {
        ZStack {
            SPColor.background.ignoresSafeArea()
            ScrollView {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Array(LessonCatalog.all.enumerated()), id: \.element.id) { index, lesson in
                        LessonCardView(index: index, lesson: lesson, score: scoreByName[lesson.name]) {
                            load(lesson)
                        }
                    }
                }
                .padding(16)
            }
        }
        .safeAreaInset(edge: .top) {
            HStack {
                Button { showImporter = true } label: { Label("Import .mid", systemImage: "square.and.arrow.down") }
                    .buttonStyle(.bordered).tint(SPColor.accentGreen)
                if let importError { Text(importError).font(.caption2).foregroundStyle(SPColor.accentRed) }
                Spacer()
            }
            .padding(.horizontal, 16).padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.midi, .data]) { result in
            importMIDI(result)
        }
    }

    private func load(_ lesson: Lesson) {
        store.currentLesson = lesson
        store.autoStartPlay = true
        store.selectedTab = .play
    }

    private func importMIDI(_ result: Result<URL, Error>) {
        importError = nil
        guard case let .success(url) = result else { return }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let parsed = try MIDIFileParser.parse(data)
            let name = url.deletingPathExtension().lastPathComponent
            let lesson = MIDIFileParser.lesson(name: name, events: parsed.events, ppq: parsed.ppq)
            if let json = try? JSONEncoder().encode(lesson),
               let str = String(data: json, encoding: .utf8) {
                context.insert(ExtraLesson(name: name, lessonJSON: str))
                try? context.save()
            }
            load(lesson)
        } catch {
            importError = (error as? MIDIFileError) == .smpteUnsupported ? "SMPTE MIDI not supported" : "Invalid MIDI file"
        }
    }
}

#Preview {
    LibraryView()
        .environmentObject(AppStore())
        .modelContainer(AppModelContainer.make(inMemory: true))
        .preferredColorScheme(.dark)
}
