import SwiftUI

struct BuildView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var persistence: PersistenceStore

    @State private var steps = 16
    @State private var grid = Array(repeating: Array(repeating: false, count: 16), count: 6)
    @State private var bpm = 90
    @State private var coach = ""
    @State private var exportFile: ExportFile?

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

            Text("CUSTOM PATTERN")
                .font(SPFont.ui(15, weight: .bold)).tracking(0.6)
                .foregroundStyle(SPColor.lcdFG)
                .shadow(color: SPColor.lcdFG.opacity(0.5), radius: 4)
                .lineLimit(1)

            Spacer()

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
        HStack(alignment: .top, spacing: 8) {
            // Lane labels
            VStack(spacing: 6) {
                ForEach(lanes, id: \.self) { lane in
                    laneLabel(lane)
                }
            }
            .frame(width: 90)

            // Grid
            VStack(spacing: 6) {
                stepNumberRow
                ForEach(lanes, id: \.self) { lane in
                    HStack(spacing: 4) {
                        ForEach(0..<steps, id: \.self) { step in
                            stepCell(lane: lane, step: step)
                                .onTapGesture { grid[lane.rawValue][step].toggle() }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(10)
        .background(LinearGradient(colors: [SPColor.roomBG, SPColor.plastic],
                                   startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SPColor.ink, lineWidth: 1))
    }

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
        .frame(height: 42)
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
                toolBtn(icon: "square.and.arrow.up", label: "Export", tint: SPColor.ledAmberHot,
                        action: { exportMIDI() }, disabled: isEmpty)
                toolBtn(icon: "play.fill", label: "Load Play", tint: SPColor.ledGreen,
                        action: { loadIntoPlayer() }, disabled: isEmpty)
                toolBtn(icon: "arrow.clockwise", label: "Resize", tint: SPColor.stickerCyan,
                        action: { steps = steps == 16 ? 32 : 16; resize(to: steps) })
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
        guard let lesson = BuilderLessonFactory.lesson(grid: grid, bpm: bpm, coach: coach) else { return }
        persistBuilderState()
        if let data = try? JSONEncoder().encode(lesson),
           let json = String(data: data, encoding: .utf8) {
            upsertExtraLesson(name: lesson.name, json: json)
        }
        store.achievements?.fire(.creator)
        if !coach.isEmpty { store.achievements?.fire(.coach) }
        store.currentLesson = lesson
        store.autoStartPlay = false
        store.selectedTab = .play
    }

    private func persistBuilderState() {
        let pattern = Dictionary(uniqueKeysWithValues: lanes.map { ($0.key, grid[$0.rawValue]) })
        let json = (try? JSONEncoder().encode(pattern)).flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        persistence.saveBuilder(BuilderState(steps: steps, patternJSON: json, bpm: bpm, coachNote: coach))
    }

    private func upsertExtraLesson(name: String, json: String) {
        persistence.saveExtraLesson(name: name, lessonJSON: json)
    }
}

#Preview {
    BuildView()
        .environmentObject(AppStore(persistence: PersistenceStore(defaults: nil)))
        .environmentObject(PersistenceStore(defaults: nil))
        .preferredColorScheme(.dark)
}
