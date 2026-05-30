import SwiftUI

struct PlayView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var persistence: PersistenceStore
    @StateObject private var engine = PlaybackEngine()

    @State private var loop = false
    @State private var clickOn = true

    private var externalAudioMode: Bool { persistence.settings.externalAudioMode }

    private let padLanes: [DrumLane] = [.crash, .hihat, .snare, .kick, .tom, .ride]
    private let laneTags = ["CRSH", "HHAT", "SNRE", "KICK", "TOMS", "RIDE"]

    var body: some View {
        ZStack {
            SPColor.bgRoom.ignoresSafeArea()
            HStack(alignment: .top, spacing: 12) {
                face
                rail.frame(width: 300)
            }
            .padding(14)
        }
        .background { transportShortcuts }
        .onAppear {
            store.activateAudio()
            // Fast path: audio fires directly on the CoreMIDI thread via
            // playImmediate, bypassing the main-actor hop (~16 ms saved).
            store.midi.audioCallback = { [audio = store.audio] lane, vel in
                audio.playImmediate(lane: lane, velocity: vel)
            }
            // Slow path (main actor): game logic only — audio already fired above.
            store.midi.onNote = { lane, vel in
                if engine.registerHit(lane: lane.rawValue) != nil {
                    store.achievements?.fire(.hit(combo: engine.combo))
                }
            }
            store.midi.start()
            store.audio.externalAudioMode = externalAudioMode
            engine.onMetronome = { accent in store.audio.playClick(accent: accent) }
            engine.metronomeEnabled = clickOn
            if engine.lesson == nil {
                engine.load(store.currentLesson ?? LessonCatalog.all[0], loop: loop)
            }
            if store.autoStartPlay { engine.start(); store.autoStartPlay = false }
        }
        .onChange(of: clickOn) { on in engine.metronomeEnabled = on }
        .onChange(of: loop) { on in engine.loop = on }
        .onChange(of: externalAudioMode) { mode in store.audio.externalAudioMode = mode }
        .onChange(of: engine.phase) { phase in if phase == .finished { persistPass() } }
        .onChange(of: store.currentLesson) { lesson in
            guard let lesson else { return }
            engine.load(lesson, loop: loop)
            if store.autoStartPlay { engine.start(); store.autoStartPlay = false }
        }
    }

    // MARK: - Face (chassis)

    private var face: some View {
        VStack(spacing: 12) {
            readout
            barStrip
            lcdWrap
            pads
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: LCD readout

    private var readout: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text("PRG").font(SPFont.mono(.caption2)).tracking(3).foregroundStyle(SPColor.ledAmber)
                    Text(engine.lesson.map { lessonNumber($0) } ?? "01")
                        .font(SPFont.mono(.caption2)).tracking(2).foregroundStyle(SPColor.lcdFg)
                }
                Text((engine.lesson?.name ?? "—").uppercased())
                    .font(SPFont.display(.headline, weight: .bold))
                    .foregroundStyle(SPColor.lcdFg)
                    .shadow(color: SPColor.lcdFg.opacity(0.5), radius: 4)
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
            Spacer()
            lcdStat("SCORE", "\(engine.score)", SPColor.lcdFg)
            lcdStat("COMBO", "\(engine.combo)x", SPColor.ledAmber)
            lcdStat("ACC", engine.scoring.hits + engine.scoring.misses > 0 ? "\(engine.accuracy)%" : "—", SPColor.lcdFg)
        }
        .padding(.horizontal, 14).padding(.vertical, 9)
        .lcdPanel()
    }

    private func lcdStat(_ label: String, _ value: String, _ color: Color) -> some View {
        VStack(alignment: .trailing, spacing: 3) {
            Text(label).font(SPFont.mono(.caption2)).tracking(1.5).foregroundStyle(SPColor.lcdDim)
            Text(value).font(SPFont.mono(.title3, weight: .bold)).foregroundStyle(color)
                .shadow(color: color.opacity(0.5), radius: 4)
        }
        .frame(minWidth: 58)
    }

    private var barStrip: some View {
        let total = engine.notes.count
        let done = engine.notes.filter { $0.hit || $0.missed }.count
        return HStack(spacing: 10) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(SPColor.bgRoom)
                    Capsule()
                        .fill(LinearGradient(colors: [SPColor.ledAmber, SPColor.ledRed], startPoint: .leading, endPoint: .trailing))
                        .frame(width: total > 0 ? geo.size.width * CGFloat(done) / CGFloat(total) : 0)
                        .shadow(color: SPColor.ledAmber.opacity(0.6), radius: 4)
                }
            }
            .frame(height: 8)
            Text("\(done) / \(total)")
                .font(SPFont.mono(.caption2)).foregroundStyle(SPColor.textDim)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .background(SPColor.ink)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    // MARK: highway (LCD)

    private var lcdWrap: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(laneTags.enumerated()), id: \.offset) { i, tag in
                    Text(tag)
                        .font(SPFont.mono(.caption2, weight: .bold)).tracking(1)
                        .foregroundStyle(SPColor.lane(i))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .overlay(Rectangle().fill(SPColor.lcdFg.opacity(0.1)).frame(width: 1), alignment: .trailing)
                }
            }
            .background(Color.black.opacity(0.4))
            .overlay(Rectangle().fill(SPColor.lcdFg.opacity(0.15)).frame(height: 1), alignment: .bottom)

            HighwayView(engine: engine)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .lcdPanel()
        .overlay(alignment: .topTrailing) {
            #if DEBUG
            MIDIDiagnosticOverlay(midi: store.midi)
                .padding(.top, 40)
                .padding(.trailing, 8)
            #else
            EmptyView()
            #endif
        }
    }

    // MARK: pads

    private var pads: some View {
        HStack(spacing: 10) {
            ForEach(Array(padLanes.enumerated()), id: \.offset) { i, lane in
                PlayPad(label: lane.padName, key: lane.keyHint, color: SPColor.lane(i)) { hit(lane) }
            }
        }
        .padding(8)
        .background(LinearGradient(colors: [SPColor.chassis, SPColor.plastic], startPoint: .top, endPoint: .bottom))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(SPColor.ink, lineWidth: 1))
    }

    // MARK: rail

    private var rail: some View {
        VStack(spacing: 12) {
            miniNotation.chassisModule("Pattern")
            Text(engine.lesson?.tip ?? "—")
                .font(SPFont.mono(.caption2)).foregroundStyle(SPColor.text).lineSpacing(3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .chassisModule("Coach Note")
            transport.chassisModule("Transport")
            ioSync.chassisModule("I/O · Sync")
            Spacer()
        }
    }

    private var miniNotation: some View {
        let lanesUsed = Array(Set((engine.lesson?.notes ?? []).map(\.lane))).sorted()
        let steps = min(engine.lesson?.beatsPerBar ?? 16, 16)
        let hits = Set((engine.lesson?.notes ?? []).filter { $0.beat < steps }.map { "\($0.lane)-\($0.beat)" })
        return VStack(spacing: 3) {
            ForEach(lanesUsed, id: \.self) { lane in
                HStack(spacing: 2) {
                    ForEach(0..<steps, id: \.self) { step in
                        RoundedRectangle(cornerRadius: 1)
                            .fill(hits.contains("\(lane)-\(step)") ? SPColor.lane(lane) : SPColor.lcdFg.opacity(0.08))
                            .frame(height: 6)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var transport: some View {
        VStack(spacing: 8) {
            Button { restart() } label: {
                Label(engine.phase == .playing ? "Restart" : "Play", systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).tint(SPColor.ledGreen)
            HStack(spacing: 8) {
                Button { engine.reset() } label: { Label("Stop", systemImage: "stop.fill").frame(maxWidth: .infinity) }
                    .buttonStyle(.bordered)
                Button { nextLesson() } label: { Label("Next", systemImage: "arrow.right").frame(maxWidth: .infinity) }
                    .buttonStyle(.bordered)
            }
        }
        .tint(SPColor.lcdFg)
        .font(SPFont.mono(.caption))
    }

    private var ioSync: some View {
        VStack(spacing: 10) {
            Toggle(isOn: $clickOn) {
                Label("Click", systemImage: "metronome").font(SPFont.mono(.caption))
            }.tint(SPColor.ledAmber)
            Toggle(isOn: $loop) {
                Label("Loop", systemImage: "repeat").font(SPFont.mono(.caption))
            }.tint(SPColor.ledAmber)
            HStack {
                Text("TEMPO").font(SPFont.mono(.caption2)).foregroundStyle(SPColor.textDim)
                Spacer()
                BpmStepper(bpm: $engine.bpm)
            }
            HStack(spacing: 6) {
                LED(on: store.midi.activity, color: SPColor.ledGreen)
                Text("MIDI \(store.midi.sources.isEmpty ? "—" : "✓")")
                    .font(SPFont.mono(.caption2)).foregroundStyle(SPColor.textDim)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Logic (unchanged behavior)

    private func hit(_ lane: DrumLane, source: DrumAudioEngine.PlaySource = .tap) {
        store.audio.play(lane: lane, source: source)
        if engine.registerHit(lane: lane.rawValue) != nil {
            store.achievements?.fire(.hit(combo: engine.combo))
        }
    }

    private func restart() {
        if engine.lesson == nil { engine.load(LessonCatalog.all[0], loop: loop) }
        engine.loop = loop
        engine.start()
    }

    private func nextLesson() {
        guard let current = engine.lesson,
              let idx = LessonCatalog.all.firstIndex(where: { $0.name == current.name }) else {
            store.currentLesson = LessonCatalog.all.first; return
        }
        store.currentLesson = LessonCatalog.all[(idx + 1) % LessonCatalog.all.count]
        store.autoStartPlay = false
    }

    private func lessonNumber(_ lesson: Lesson) -> String {
        let idx = (LessonCatalog.all.firstIndex { $0.name == lesson.name } ?? 0) + 1
        return String(format: "%02d", idx)
    }

    @ViewBuilder private var transportShortcuts: some View {
        Group {
            Button("") { restart() }.keyboardShortcut(.space, modifiers: [])
            Button("") { restart() }.keyboardShortcut("r", modifiers: .command)
            Button("") { loop.toggle() }.keyboardShortcut("l", modifiers: [])
            Button("") { clickOn.toggle() }.keyboardShortcut("c", modifiers: [])
        }
        .opacity(0).frame(width: 0, height: 0).accessibilityHidden(true)
    }

    private func persistPass() {
        guard let lesson = engine.lesson else { return }
        let p = store.persistence
        let acc = engine.accuracy
        let isPrebuilt = LessonCatalog.all.contains { $0.name == lesson.name }
        let tier = isPrebuilt ? PracticeTier.forPass(accuracy: acc, bpm: engine.bpm, lessonBpm: lesson.bpm)?.rawValue : nil
        p.recordPass(lessonKey: lesson.name, score: engine.score, accuracy: acc, tier: tier)
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"; fmt.timeZone = TimeZone(identifier: "UTC")
        p.recordPlayDay(fmt.string(from: Date()))
        store.achievements?.fire(.pass(
            accuracy: acc, stars: ScoringEngine.stars(accuracy: acc), bpm: engine.bpm,
            lessonKey: lesson.name, lessonBpm: isPrebuilt ? lesson.bpm : nil, isPrebuilt: isPrebuilt
        ))
    }
}

/// Rubber drum pad with a rim, LED that lights on strike, label and key hint.
///
/// Uses `DragGesture(minimumDistance: 0)` so the action fires on first contact
/// (touch DOWN) rather than waiting for finger-lift like a standard `Button`.
/// This eliminates the 80–200 ms button-confirmation delay that makes drum
/// pads feel sluggish. An accessibility action restores tap-to-fire for
/// VoiceOver users.
private struct PlayPad: View {
    let label: String
    let key: String
    let color: Color
    let action: () -> Void
    @State private var lit = false
    @State private var didFire = false  // prevents repeat fires during a held drag

    var body: some View {
        padShape
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        guard !didFire else { return }
                        didFire = true
                        action()
                        withAnimation(.easeOut(duration: 0.06)) { lit = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                            withAnimation(.easeOut(duration: 0.1)) { lit = false }
                        }
                    }
                    .onEnded { _ in didFire = false }
            )
            .accessibilityLabel("\(label) pad")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { action() }
    }

    private var padShape: some View {
        VStack(spacing: 5) {
            Circle()
                .fill(lit ? color : color.opacity(0.25))
                .frame(width: 9, height: 9)
                .shadow(color: lit ? color : .clear, radius: 6)
            Text(label).font(SPFont.mono(.caption2, weight: .bold)).foregroundStyle(SPColor.text)
            Text(key).font(SPFont.mono(.caption2)).foregroundStyle(SPColor.textDim)
        }
        .frame(maxWidth: .infinity).frame(height: 78)
        .background(
            RadialGradient(colors: [SPColor.rubberHi, SPColor.rubber, SPColor.bgRoom],
                           center: .init(x: 0.5, y: 0.3), startRadius: 2, endRadius: 60)
        )
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(SPColor.ink, lineWidth: 1))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(color.opacity(lit ? 0.8 : 0.2), lineWidth: 1.5))
        .scaleEffect(lit ? 0.97 : 1)
        .contentShape(Rectangle())  // ensures full hit area, not just visible pixels
    }
}
