import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct LibraryView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.modelContext) private var context
    @Query private var scores: [LessonScore]
    @Query private var playDays: [PracticeDay]
    @State private var showImporter = false
    @State private var importError: String?
    @State private var searchText = ""
    @State private var filterGenre = "All"

    private var scoreByName: [String: LessonScore] {
        Dictionary(scores.map { ($0.lessonKey, $0) }, uniquingKeysWith: { a, _ in a })
    }

    private var allGenres: [String] {
        let g = Array(Set(LessonCatalog.all.map(\.genre))).sorted()
        return ["All"] + g
    }

    private var filteredLessons: [Lesson] {
        LessonCatalog.all.filter { lesson in
            let genreOK = filterGenre == "All" || lesson.genre == filterGenre
            let searchOK = searchText.isEmpty || lesson.name.localizedCaseInsensitiveContains(searchText)
            return genreOK && searchOK
        }
    }

    private var cleared: Int { scores.filter { $0.stars > 0 }.count }
    private var streak: Int {
        PracticeStreak.current(playDays: Set(playDays.map(\.day)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            pageHeader
            toolbar
            content
            footer
        }
        .padding(.horizontal, 22).padding(.vertical, 16)
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.midi, .data]) { importMIDI($0) }
    }

    // MARK: - Page header

    private var pageHeader: some View {
        HStack(alignment: .bottom) {
            HStack(spacing: 8) {
                Text("Lesson").font(SPFont.display(32)).foregroundStyle(SPColor.text)
                Text("Bank").font(SPFont.display(32)).foregroundStyle(SPColor.ledAmberHot)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(LessonCatalog.all.count) PATCHES LOADED · TAP TO INJECT INTO PLAY")
                    .font(SPFont.monoMicro).tracking(1.8).foregroundStyle(SPColor.textDim)
                if let err = importError {
                    Text(err.uppercased())
                        .font(SPFont.monoMicro).tracking(1.5).foregroundStyle(SPColor.ledRed)
                }
            }
        }
        .padding(.bottom, 12)
        .overlay(Rectangle().fill(SPColor.ink).frame(height: 1), alignment: .bottom)
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            // LCD search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(SPColor.lcdFG)
                ZStack(alignment: .leading) {
                    if searchText.isEmpty {
                        Text("SEARCH PATCHES...")
                            .font(SPFont.lcd(13)).tracking(2)
                            .foregroundStyle(SPColor.lcdDim)
                    }
                    TextField("", text: $searchText)
                        .textInputAutocapitalization(.characters)
                        .font(SPFont.lcd(13))
                        .tracking(2)
                        .foregroundStyle(SPColor.lcdFG)
                        .shadow(color: SPColor.lcdFG.opacity(0.4), radius: 2)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .frame(maxWidth: 280)
            .lcdPanel()

            // Genre filter chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(allGenres, id: \.self) { genre in
                        genreChip(genre)
                    }
                }
            }

            // Import .mid
            Button { showImporter = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.down")
                    Text("IMPORT .MID").font(SPFont.ui(11, weight: .bold)).tracking(1.4)
                }
                .foregroundStyle(SPColor.textDim)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(LinearGradient(colors: [Color(hex: 0x34383F), Color(hex: 0x1F2127)],
                                           startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(SPColor.ink, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Import MIDI file")
        }
    }

    private func genreChip(_ genre: String) -> some View {
        let active = genre == filterGenre
        return Button { filterGenre = genre } label: {
            Text(genre.uppercased())
                .font(SPFont.ui(11, weight: .bold)).tracking(1.4)
                .foregroundStyle(active ? SPColor.ledAmberHot : SPColor.textDim)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(
                    LinearGradient(
                        colors: active ? [SPColor.roomBG, Color(hex: 0x14161A)]
                                       : [Color(hex: 0x2F333A), Color(hex: 0x1F2127)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(SPColor.ink, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(genre)
        .accessibilityAddTraits(active ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: - Content

    private var content: some View {
        HStack(alignment: .top, spacing: 16) {
            if let featured = filteredLessons.first {
                featuredCard(featured, score: scoreByName[featured.name])
                    .frame(maxWidth: 310)
            }

            if !filteredLessons.isEmpty {
                ScrollView {
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 3),
                        spacing: 14
                    ) {
                        let rest = filteredLessons.count > 1
                            ? Array(filteredLessons.dropFirst())
                            : Array(filteredLessons)
                        ForEach(Array(rest.enumerated()), id: \.element.id) { idx, lesson in
                            lessonGridCell(lesson, index: idx + 2, score: scoreByName[lesson.name])
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }

    // MARK: - Featured card

    private func featuredCard(_ lesson: Lesson, score: LessonScore?) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Rectangle()
                .fill(SPColor.stickerYellow.opacity(0.85))
                .frame(width: 80, height: 18)
                .rotationEffect(.degrees(-2))
                .offset(y: -6)

            HStack(spacing: 8) {
                statusStamp(score == nil ? "NEW" : "CURRENT", style: .amber)
                if score != nil { statusStamp("PLAYED", style: .green) }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(lesson.name)
                    .font(SPFont.display(26)).foregroundStyle(SPColor.text).lineLimit(2)
                Text("\(lesson.bpm) BPM · \(lesson.genre) · \(lesson.difficulty)")
                    .font(SPFont.plex(12)).foregroundStyle(SPColor.textDim)
            }

            miniLCDPreview(lesson: lesson, score: score).frame(minHeight: 120)

            SPPushButton(.primary, action: { load(lesson) }) {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                    Text("Load & Play")
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .chassisFace()
        .overlay(alignment: .topTrailing) {
            Text("01")
                .font(.system(size: 110, weight: .black))
                .foregroundStyle(.white.opacity(0.04))
                .offset(x: -14, y: 6)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .bottomTrailing) {
            SPScribble(text: "Let's go!", color: SPColor.stickerPink, rotation: -6)
                .padding(.bottom, 6).padding(.trailing, 50)
        }
    }

    private func miniLCDPreview(lesson: Lesson, score: LessonScore?) -> some View {
        ZStack {
            HStack(spacing: 0) {
                ForEach(0..<6) { i in
                    Rectangle().fill(.clear).frame(maxWidth: .infinity)
                        .overlay(alignment: .leading) {
                            if i > 0 {
                                Rectangle().fill(SPColor.lcdFG.opacity(0.08)).frame(width: 1)
                            }
                        }
                }
            }
            VStack {
                Spacer()
                Rectangle().fill(SPColor.ledRed)
                    .frame(height: 2)
                    .shadow(color: SPColor.ledRed, radius: 4)
                    .padding(.bottom, 20)
            }
            VStack {
                HStack {
                    if let sc = score {
                        Text("BEST \(sc.lastAccuracy)%")
                            .font(SPFont.monoSmall).tracking(1.5).foregroundStyle(SPColor.ledAmber)
                        Spacer()
                        Text("RUNS \(sc.plays)")
                            .font(SPFont.monoSmall).tracking(1.5).foregroundStyle(SPColor.ledAmber)
                    } else {
                        Text("NOT PLAYED YET")
                            .font(SPFont.monoSmall).tracking(1.5).foregroundStyle(SPColor.lcdDim)
                        Spacer()
                    }
                }
                .padding(10)
                Spacer()
            }
        }
        .lcdPanel(cornerRadius: 8)
    }

    // MARK: - Grid cell

    private func lessonGridCell(_ lesson: Lesson, index: Int, score: LessonScore?) -> some View {
        Button { load(lesson) } label: {
            VStack(alignment: .leading, spacing: 10) {
                statusStamp(score == nil ? "NEW" : "PLAYED",
                            style: score == nil ? .pink : .green)

                Text(lesson.name)
                    .font(SPFont.ui(15, weight: .bold))
                    .tracking(0.4).foregroundStyle(SPColor.text).lineLimit(2)

                HStack(spacing: 10) {
                    metaPill(label: "BPM", value: "\(lesson.bpm)")
                    metaPill(label: "DIFF", value: lesson.difficulty.uppercased())
                }

                miniNotationView(lesson: lesson)
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lcdPanel(cornerRadius: 4)

                Spacer(minLength: 0)

                HStack {
                    Text(score.map { "\($0.lastAccuracy)%" } ?? "—")
                        .font(SPFont.monoSmall).foregroundStyle(SPColor.textDim)
                    Spacer()
                    starsRow(filled: score?.stars ?? 0)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 190, alignment: .leading)
            .background(LinearGradient(
                colors: [Color(hex: 0x2C2F36), SPColor.chassis2],
                startPoint: .top, endPoint: .bottom
            ))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(SPColor.ink, lineWidth: 1))
            .shadow(color: .black.opacity(0.4), radius: 8, y: 4)
            .overlay(alignment: .topTrailing) {
                Text(String(format: "%02d", index))
                    .font(.system(size: 42, weight: .black))
                    .foregroundStyle(.white.opacity(0.05))
                    .offset(x: -12, y: 8)
                    .allowsHitTesting(false)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(lesson.name), \(lesson.bpm) BPM. \(score?.stars ?? 0) stars.")
    }

    private func miniNotationView(lesson: Lesson) -> some View {
        let steps = min(lesson.beatsPerBar, 16)
        let laneSet = Array(Set(lesson.notes.map(\.lane))).sorted().prefix(3)
        let beats = Set(lesson.notes.filter { $0.beat < steps }.map { "\($0.lane)-\($0.beat)" })
        return VStack(alignment: .leading, spacing: 2) {
            ForEach(Array(laneSet), id: \.self) { lane in
                HStack(spacing: 4) {
                    Text(DrumLane(rawValue: lane)?.label ?? "?")
                        .font(SPFont.monoSmall).foregroundStyle(SPColor.ledAmber)
                        .frame(width: 22, alignment: .leading)
                    HStack(spacing: 1) {
                        ForEach(0..<steps, id: \.self) { step in
                            let hit = beats.contains("\(lane)-\(step)")
                            Text(hit ? "×" : "·")
                                .font(SPFont.monoSmall)
                                .foregroundStyle(hit ? SPColor.lcdFG : SPColor.lcdDim)
                                .shadow(color: hit ? SPColor.lcdFG.opacity(0.4) : .clear, radius: 2)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 14) {
            footerPill(icon: "trophy.fill", label: "CLEARED",
                       value: "\(cleared)/\(LessonCatalog.all.count)")
            footerPill(icon: "flame.fill", label: "STREAK", value: "\(streak)d")
            SPProgressBar(
                progress: LessonCatalog.all.isEmpty ? 0 : Double(cleared) / Double(LessonCatalog.all.count),
                height: 6
            )
            .frame(maxWidth: .infinity, minHeight: 6)
        }
        .padding(.horizontal, 12).padding(.vertical, 7)
        .background(SPColor.ink)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.black, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func footerPill(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(SPColor.textDim)
            Text(label).font(SPFont.monoSmall).tracking(1.5).foregroundStyle(SPColor.textDim)
            Text(value).font(SPFont.monoSmall).tracking(1.5).foregroundStyle(SPColor.lcdFG)
                .shadow(color: SPColor.lcdFG.opacity(0.4), radius: 2)
        }
    }

    // MARK: - Shared atoms

    private enum StampStyle { case amber, pink, green, dim }

    private func statusStamp(_ text: String, style: StampStyle) -> some View {
        let (fg, border): (Color, Color) = {
            switch style {
            case .amber: return (SPColor.ledAmberHot, SPColor.ledAmber)
            case .pink:  return (SPColor.stickerPink, SPColor.stickerPink)
            case .green: return (SPColor.ledGreen,    SPColor.ledGreen)
            case .dim:   return (SPColor.textDim,     SPColor.metal)
            }
        }()
        return Text(text)
            .font(SPFont.monoMicro).tracking(1.5).foregroundStyle(fg)
            .padding(.horizontal, 9).padding(.vertical, 3)
            .background(fg.opacity(0.15))
            .overlay(RoundedRectangle(cornerRadius: 3).stroke(border, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 3))
    }

    private func metaPill(label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Text(label).font(SPFont.monoSmall).tracking(1.5).foregroundStyle(SPColor.textDim)
            Text(value).font(SPFont.monoSmall).tracking(1.5).foregroundStyle(SPColor.ledAmberHot)
        }
    }

    private func starsRow(filled: Int) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(i < filled ? SPColor.ledAmber : .white.opacity(0.1))
            }
        }
    }

    // MARK: - Actions

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
            importError = (error as? MIDIFileError) == .smpteUnsupported
                ? "SMPTE MIDI not supported"
                : "Invalid MIDI file"
        }
    }
}

#Preview {
    LibraryView()
        .environmentObject(AppStore())
        .modelContainer(AppModelContainer.make(inMemory: true))
        .preferredColorScheme(.dark)
}
