import SwiftUI

struct BuildView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var persistence: PersistenceStore

    @State private var steps = 16
    @State private var grid = Array(repeating: Array(repeating: false, count: 16), count: 6)
    @State private var bpm = 90
    @State private var coach = ""
    @State private var grooveName = ""
    @State private var saveToast: String?
    @State private var exportFile: ExportFile?

    // Overwrite-confirm state (issue #71)
    @State private var overwriteCandidateName: String?
    @State private var overwriteCandidateJSON: String?
    @State private var showOverwriteAlert = false

    // Record mode
    @StateObject private var recorder = BuilderRecordEngine()
    @State private var showRecordPanel = false

    private let lanes: [DrumLane] = DrumLane.allCases
    private var isEmpty: Bool { !grid.contains { $0.contains(true) } }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            sequencerFace
            rail
                .frame(width: 280)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .sheet(item: $exportFile) { ShareSheet(items: [$0.url]) }
        // Overwrite-confirm alert (issue #71)
        .alert("Name Already Taken", isPresented: $showOverwriteAlert) {
            Button("Replace", role: .destructive) {
                if let name = overwriteCandidateName, let json = overwriteCandidateJSON {
                    upsertExtraLesson(name: name, json: json)
                    store.achievements?.fire(.creator(savedCount: extraLessons.count))
                    showSaveToast("Replaced “\(name)” in library")
                }
                overwriteCandidateName = nil; overwriteCandidateJSON = nil
            }
            Button("Save as New") {
                if let name = overwriteCandidateName, let json = overwriteCandidateJSON {
                    let uniqueName = uniqueSuffix(for: name)
                    upsertExtraLesson(name: uniqueName, json: rebrandedJSON(json, newName: uniqueName))
                    store.achievements?.fire(.creator(savedCount: extraLessons.count + 1))
                    showSaveToast("Saved “\(uniqueName)” to library")
                }
                overwriteCandidateName = nil; overwriteCandidateJSON = nil
            }
            Button("Cancel", role: .cancel) {
                overwriteCandidateName = nil; overwriteCandidateJSON = nil
            }
        } message: {
            if let name = overwriteCandidateName {
                Text("A groove named “\(name)” already exists. Replace it, save with a new name, or cancel.")
            }
        }
        .overlay(alignment: .top) {
            if let saveToast {
                Text(saveToast.uppercased())
                    .font(SPFont.monoSmall).tracking(1.6)
                    .foregroundStyle(SPColor.ledGreen)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(SPColor.ink)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(SPColor.ledGreen, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(color: SPColor.ledGreen.opacity(0.4), radius: 6)
                    .padding(.top, 18)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            seedFromEditingLessonIfAny()
            store.activateAudio()
        }
        .onDisappear { recorder.stop() }
        .sheet(isPresented: $showRecordPanel, onDismiss: { recorder.stop() }) {
            RecordPanelView(recorder: recorder, bpm: bpm, steps: steps) { mergedGrid in
                mergeRecordedGrid(mergedGrid)
            }
        }
    }

    // MARK: - Left: sequencer face

    private var sequencerFace: some View {
        VStack(spacing: 10) {
            readout
            transport
            sequencerGrid
            actionRow
        }
        .padding(14)
        .chassisFace()
        .overlay(alignment: .topTrailing) {
            SPScribble(text: "tape it!", color: SPColor.stickerPink, rotation: -3)
                .padding(.top, 8).padding(.trailing, 80)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Readout

    private var readout: some View {
        HStack(spacing: 14) {
            Text("PAT").font(SPFont.monoSmall).tracking(2).foregroundColor(SPColor.ledAmber)
            + Text(" BUILD").font(SPFont.monoSmall).tracking(2).foregroundColor(SPColor.lcdFG)

            ZStack(alignment: .leading) {
                if grooveName.isEmpty {
                    Text("NAME THIS GROOVE…")
                        .font(SPFont.ui(15, weight: .bold)).tracking(0.6)
                        .foregroundStyle(SPColor.lcdDim)
                }
                TextField("", text: $grooveName)
                    .font(SPFont.ui(15, weight: .bold)).tracking(0.6)
                    .foregroundStyle(SPColor.lcdFG)
                    .shadow(color: SPColor.lcdFG.opacity(0.5), radius: 4)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .accessibilityLabel("Groove name")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .lineLimit(1)

            Spacer(minLength: 4)

            statBlock(label: "STEPS", value: "\(steps)")
            statBlock(label: "BPM", value: "\(bpm)", warn: true)
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .lcdPanel(cornerRadius: 8)
    }

    private func statBlock(label: String, value: String, warn: Bool = false) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(label).font(SPFont.monoMicro).tracking(1.5).foregroundStyle(SPColor.lcdDim)
            Text(value)
                .font(SPFont.lcd(18))
                .foregroundStyle(warn ? SPColor.ledAmber : SPColor.lcdFG)
                .shadow(color: (warn ? SPColor.ledAmber : SPColor.lcdFG).opacity(0.6), radius: 4)
        }
    }

    // MARK: - Transport

    private var transport: some View {
        HStack(spacing: 8) {
            // Steps picker
            Picker("Steps", selection: $steps) {
                Text("16 STEPS").tag(16)
                Text("32 STEPS").tag(32)
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
            .onChange(of: steps) { new in resize(to: new) }

            Rectangle().fill(SPColor.ink).frame(width: 1, height: 22).padding(.horizontal, 4)

            // BPM
            HStack(spacing: 6) {
                Text("BPM").font(SPFont.monoMicro).tracking(1.5).foregroundStyle(SPColor.textDim)
                BpmStepper(bpm: $bpm)
            }

            Spacer(minLength: 4)

            // Record button
            Button { showRecordPanel = true } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(SPColor.ledRed)
                        .frame(width: 8, height: 8)
                        .shadow(color: SPColor.ledRed.opacity(0.8), radius: 4)
                    Text("REC").font(SPFont.ui(11, weight: .bold)).tracking(1.4)
                }
                .foregroundStyle(SPColor.ledRed)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(LinearGradient(colors: [Color(hex: 0x34383F), Color(hex: 0x1F2127)],
                                           startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(SPColor.ledRed.opacity(0.4), lineWidth: 1))
                .shadow(color: SPColor.ledRed.opacity(0.2), radius: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open real-time record mode")

            // Clear button
            Button(role: .destructive) { clear() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "trash")
                    Text("CLEAR").font(SPFont.ui(11, weight: .bold)).tracking(1.4)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(LinearGradient(colors: [SPColor.ledRed, Color(hex: 0xA01A35)],
                                           startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(SPColor.ink, lineWidth: 1))
                .shadow(color: SPColor.ledRed.opacity(0.3), radius: 8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(SPColor.ink)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.black, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: - Sequencer grid

    private var sequencerGrid: some View {
        VStack(spacing: 6) {
            // Top: step numbers, indented past the label gutter so they sit
            // directly above the grid cells (not over the lane labels).
            HStack(spacing: 8) {
                Color.clear.frame(width: laneLabelWidth, height: 1)
                stepNumberRow
            }
            // Body: each lane is one HStack of (label, row of step cells) so
            // the label and its cells are guaranteed to share a vertical row.
            ForEach(lanes, id: \.self) { lane in
                HStack(alignment: .center, spacing: 8) {
                    laneLabel(lane)
                    HStack(spacing: 4) {
                        ForEach(0..<steps, id: \.self) { step in
                            stepCell(lane: lane, step: step)
                                .onTapGesture { grid[lane.rawValue][step].toggle() }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(10)
        .background(LinearGradient(colors: [SPColor.roomBG, SPColor.plastic],
                                   startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SPColor.ink, lineWidth: 1))
    }

    private let laneLabelWidth: CGFloat = 90

    private func laneLabel(_ lane: DrumLane) -> some View {
        HStack {
            Rectangle()
                .fill(SPColor.laneColors[lane.rawValue])
                .frame(width: 3, height: 18)
                .shadow(color: SPColor.laneColors[lane.rawValue], radius: 4)
            VStack(alignment: .leading, spacing: 1) {
                Text(SPColor.laneNames[lane.rawValue])
                    .font(SPFont.monoSmall).tracking(1.4)
                    .foregroundStyle(SPColor.laneColors[lane.rawValue])
                Text(lane.keyHint)
                    .font(SPFont.monoMicro).tracking(1.5).foregroundStyle(SPColor.textDim)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .frame(width: laneLabelWidth, height: 42)
        .background(LinearGradient(colors: [Color(hex: 0x2C2F36), SPColor.chassis2],
                                   startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(SPColor.ink, lineWidth: 1))
        .accessibilityLabel(lane.padName)
    }

    private var stepNumberRow: some View {
        HStack(spacing: 4) {
            ForEach(0..<steps, id: \.self) { i in
                let beat = (i % 4) == 0
                Text(beat ? String(format: "%02d", i + 1) : "·")
                    .font(SPFont.monoMicro).tracking(1)
                    .foregroundStyle(beat ? SPColor.ledAmber : SPColor.textDim)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func stepCell(lane: DrumLane, step: Int) -> some View {
        let on = grid[lane.rawValue][step]
        let laneColor = SPColor.laneColors[lane.rawValue]
        let beat = step % 4 == 0

        return ZStack {
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(
                    on
                    ? AnyShapeStyle(RadialGradient(
                        colors: [laneColor.opacity(0.85), laneColor, laneColor.opacity(0.4)],
                        center: .init(x: 0.5, y: 0.3),
                        startRadius: 0, endRadius: 30))
                    : AnyShapeStyle(RadialGradient(
                        colors: [Color(hex: 0x34383F), Color(hex: 0x1F2127), Color(hex: 0x14161A)],
                        center: .init(x: 0.5, y: 0.3),
                        startRadius: 0, endRadius: 30))
                )
            // tiny step LED
            VStack {
                Circle()
                    .fill(on ? Color.white : SPColor.roomBG)
                    .frame(width: 5, height: 5)
                    .overlay(Circle().stroke(.black, lineWidth: 0.5))
                    .shadow(color: on ? .white.opacity(0.6) : .clear, radius: 2)
                    .padding(.top, 4)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, minHeight: 42)
        .overlay(RoundedRectangle(cornerRadius: 5).stroke(SPColor.ink, lineWidth: 1))
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .stroke(beat ? Color.white.opacity(0.06) : .clear, lineWidth: 1)
                .padding(1)
        )
        .shadow(color: on ? laneColor.opacity(0.6) : .clear, radius: 10)
        .accessibilityLabel("Step \(step + 1), \(lane.padName): \(on ? "on" : "off")")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Action row

    private var actionRow: some View {
        HStack(spacing: 8) {
            // Coach note
            HStack(spacing: 8) {
                Image(systemName: "quote.bubble").foregroundStyle(SPColor.textDim)
                ZStack(alignment: .leading) {
                    if coach.isEmpty {
                        Text("COACH NOTE...")
                            .font(SPFont.plex(12)).tracking(1.5).foregroundStyle(SPColor.textDim)
                    }
                    TextField("", text: $coach)
                        .font(SPFont.plex(12)).tracking(1)
                        .foregroundStyle(SPColor.text)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(SPColor.ink)
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(.black, lineWidth: 1))
            .clipShape(RoundedRectangle(cornerRadius: 5))

            // Export .mid
            Button { exportMIDI() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                    Text("EXPORT .MID").font(SPFont.ui(11, weight: .bold)).tracking(1.4)
                }
                .foregroundStyle(isEmpty ? SPColor.textDim : SPColor.ledAmberHot)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(LinearGradient(colors: [Color(hex: 0x34383F), Color(hex: 0x1F2127)],
                                           startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(SPColor.ink, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(isEmpty)
            .accessibilityLabel("Export MIDI file")

            // Save to Library
            Button { saveToLibrary() } label: {
                HStack(spacing: 6) {
                    Image(systemName: "tray.and.arrow.down.fill")
                    Text("ADD TO LIBRARY").font(SPFont.ui(11, weight: .bold)).tracking(1.4)
                }
                .foregroundStyle(isEmpty ? SPColor.textDim : SPColor.ledGreen)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(LinearGradient(colors: [Color(hex: 0x34383F), Color(hex: 0x1F2127)],
                                           startPoint: .top, endPoint: .bottom))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(SPColor.ink, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .disabled(isEmpty)
            .accessibilityLabel("Save groove to library")

            // Load into Play
            SPPushButton(.primary, action: { loadIntoPlayer() }) {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill")
                    Text("Load into Play")
                }
            }
            .frame(maxWidth: 180)
            .disabled(isEmpty)
            .opacity(isEmpty ? 0.5 : 1)
        }
    }

    // MARK: - Right: rail

    private var rail: some View {
        VStack(spacing: 12) {
            kitModule
            toolsModule
        }
    }

    private var kitModule: some View {
        VStack(alignment: .leading, spacing: 8) {
            SPModuleTitle(title: "Kit · Lanes", meta: "DRUMROT V2")
            VStack(spacing: 4) {
                ForEach(lanes, id: \.self) { lane in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(SPColor.laneColors[lane.rawValue])
                            .frame(width: 14, height: 14)
                            .shadow(color: SPColor.laneColors[lane.rawValue], radius: 3)
                        Text(SPColor.laneNames[lane.rawValue])
                            .font(SPFont.monoSmall).tracking(1.5).foregroundStyle(SPColor.textDim)
                        Spacer()
                        Text(lane.padName.uppercased())
                            .font(SPFont.plex(10)).foregroundStyle(SPColor.ledAmberHot)
                    }
                    .padding(.horizontal, 8).padding(.vertical, 6)
                    .background(SPColor.ink)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(.black, lineWidth: 1))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
        .chassisModule()
    }

    private var toolsModule: some View {
        VStack(alignment: .leading, spacing: 8) {
            SPModuleTitle(title: "Tools")
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 2),
                spacing: 6
            ) {
                toolBtn(icon: "eraser", label: "Clear", tint: SPColor.ledRed, action: { clear() })
                toolBtn(icon: "tray.and.arrow.down.fill", label: "Save Lib", tint: SPColor.ledGreen,
                        action: { saveToLibrary() }, disabled: isEmpty)
                toolBtn(icon: "square.and.arrow.up", label: "Export", tint: SPColor.ledAmberHot,
                        action: { exportMIDI() }, disabled: isEmpty)
                toolBtn(icon: "play.fill", label: "Load Play", tint: SPColor.ledGreen,
                        action: { loadIntoPlayer() }, disabled: isEmpty)
                toolBtn(icon: "arrow.clockwise", label: "Resize", tint: SPColor.stickerCyan,
                        action: { steps = steps == 16 ? 32 : 16; resize(to: steps) })
                toolBtn(icon: "record.circle", label: "Record", tint: SPColor.ledRed,
                        action: { showRecordPanel = true })
            }
        }
        .chassisModule()
    }

    private func toolBtn(
        icon: String, label: String, tint: Color,
        action: @escaping () -> Void, disabled: Bool = false
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon).foregroundStyle(disabled ? SPColor.textDim : tint)
                Text(label.uppercased())
                    .font(SPFont.ui(10, weight: .bold)).tracking(1.2)
                    .foregroundStyle(disabled ? SPColor.textDim : SPColor.text)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10).padding(.vertical, 8)
            .background(LinearGradient(colors: [Color(hex: 0x34383F), Color(hex: 0x1F2127)],
                                       startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 5))
            .overlay(RoundedRectangle(cornerRadius: 5).stroke(SPColor.ink, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }

    // MARK: - Record-mode merge

    /// Merges hits captured in real-time recording into the current grid.
    /// Existing steps are OR-ed with recorded ones so manual edits survive.
    private func mergeRecordedGrid(_ recorded: [[Bool]]) {
        guard recorded.count == grid.count else { return }
        for laneIdx in grid.indices {
            guard laneIdx < recorded.count else { continue }
            let recordedRow = recorded[laneIdx]
            for stepIdx in grid[laneIdx].indices {
                if stepIdx < recordedRow.count, recordedRow[stepIdx] {
                    grid[laneIdx][stepIdx] = true
                }
            }
        }
    }

    // MARK: - Business logic (unchanged)

    private func exportMIDI() {
        let data = MIDIFileExporter.export(lanePatterns: grid, bpm: bpm)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("drumrot-pattern.mid")
        guard (try? data.write(to: url)) != nil else { return }
        exportFile = ExportFile(url: url)
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
        guard let lesson = currentLesson() else { return }
        persistBuilderState()
        store.currentLesson = lesson
        store.autoStartPlay = false
        store.selectedTab = .play
    }

    /// Builds the in-memory Lesson without persisting it to the library.
    /// Used by `Load Play` (transient) and `Save to Library` (then persisted
    /// + creator/coach achievements fired).
    private func currentLesson() -> Lesson? {
        let name = resolvedName()
        return BuilderLessonFactory.lesson(grid: grid, bpm: bpm, coach: coach, name: name)
    }

    private func saveToLibrary() {
        guard let lesson = currentLesson() else { return }
        persistBuilderState()
        guard let data = try? JSONEncoder().encode(lesson),
              let json = String(data: data, encoding: .utf8) else { return }

        let isAutoNamed = grooveName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let nameExists = extraLessons.contains { $0.name == lesson.name }

        // Collision check (issue #71): only show alert for user-typed names that
        // already exist.  The auto-numbered “My Groove N” fallback is always unique
        // (resolvedName() guarantees it), so no alert needed for that path.
        if !isAutoNamed && nameExists {
            overwriteCandidateName = lesson.name
            overwriteCandidateJSON = json
            showOverwriteAlert = true
            return
        }

        // No collision — proceed straight to save.
        upsertExtraLesson(name: lesson.name, json: json)
        let savedCount = extraLessons.count + (nameExists ? 0 : 1)
        store.achievements?.fire(.creator(savedCount: savedCount))
        if !coach.isEmpty {
            let coachedCount = extraLessons.filter {
                guard let lessonData = $0.lessonJSON.data(using: .utf8),
                      let decoded = try? JSONDecoder().decode(Lesson.self, from: lessonData)
                else { return false }
                return !decoded.tip.isEmpty
            }.count + 1
            store.achievements?.fire(.coach(coachedCount: coachedCount))
        }
        showSaveToast("Saved “\(lesson.name)” to library")
    }

    /// Returns the smallest `”<base> (N)”` that doesn't collide with an existing name.
    private func uniqueSuffix(for base: String) -> String {
        let existing = Set(extraLessons.map(\.name))
        var n = 2
        while existing.contains("\(base) (\(n))") { n += 1 }
        return "\(base) (\(n))"
    }

    /// Re-encodes a lesson JSON blob with a different `name` field.
    private func rebrandedJSON(_ json: String, newName: String) -> String {
        guard let data = json.data(using: .utf8),
              let orig = try? JSONDecoder().decode(Lesson.self, from: data),
              let encoded = try? JSONEncoder().encode(
                  Lesson(name: newName, bpm: orig.bpm, tip: orig.tip,
                         difficulty: orig.difficulty, genre: orig.genre,
                         patterns: orig.patterns)),
              let result = String(data: encoded, encoding: .utf8)
        else { return json }
        return result
    }

    private func showSaveToast(_ message: String) {
        withAnimation(.easeOut(duration: 0.25)) { saveToast = message }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            withAnimation(.easeIn(duration: 0.25)) { saveToast = nil }
        }
    }

    /// Falls back to a unique auto-numbered "My Groove N" when the user hasn't
    /// typed a name. N is the smallest integer that doesn't already exist in
    /// the user's extra-lesson list so saves don't silently overwrite.
    private func resolvedName() -> String {
        let trimmed = grooveName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let existing = Set(persistence.extraLessons.map(\.name))
        var n = 1
        while existing.contains("\(BuilderLessonFactory.builderLessonName) \(n)") { n += 1 }
        return "\(BuilderLessonFactory.builderLessonName) \(n)"
    }

    private func persistBuilderState() {
        let pattern = Dictionary(uniqueKeysWithValues: lanes.map { ($0.key, grid[$0.rawValue]) })
        let json = (try? JSONEncoder().encode(pattern)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        persistence.saveBuilder(BuilderState(steps: steps, patternJSON: json, bpm: bpm, coachNote: coach))
    }

    private func seedFromEditingLessonIfAny() {
        guard let lesson = store.editingLesson else { return }
        let decoded = BuilderLessonFactory.grid(from: lesson)
        steps = decoded.steps
        grid = decoded.grid
        bpm = decoded.bpm
        coach = decoded.coach
        grooveName = lesson.name
        store.editingLesson = nil
    }
}

#Preview {
    BuildView()
        .environmentObject(AppStore(persistence: PersistenceStore(defaults: nil)))
        .environmentObject(PersistenceStore(defaults: nil))
        .preferredColorScheme(.dark)
}
