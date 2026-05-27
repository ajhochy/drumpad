import SwiftUI

struct PlayView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var engine = PlaybackEngine()

    @State private var loop = false
    @State private var clickOn = true

    private let padLanes: [DrumLane] = [.crash, .hihat, .snare, .kick, .tom, .ride]

    var body: some View {
        ZStack {
            SPColor.background.ignoresSafeArea()
            VStack(spacing: 10) {
                readout
                progressStrip
                HighwayView(engine: engine) { beat in
                    if clickOn { store.audio.playClick(accent: beat == 1) }
                }
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                pads
                rail
            }
            .padding(12)
        }
        .onAppear {
            store.activateAudio()
            if engine.lesson == nil {
                engine.load(store.currentLesson ?? LessonCatalog.all[0], loop: loop)
            }
            if store.autoStartPlay { engine.start(); store.autoStartPlay = false }
        }
        .onChange(of: engine.phase) { _, phase in
            if phase == .finished { persistPass() }
        }
    }

    // MARK: readout

    private var readout: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(engine.lesson?.name ?? "—")
                    .font(SPFont.display(.headline, weight: .bold))
                Text("\(engine.lesson?.bpm ?? 0) BPM · \(engine.lesson?.genre ?? "")")
                    .font(SPFont.mono(.caption2)).foregroundStyle(.secondary)
            }
            Spacer()
            stat("SCORE", "\(engine.score)")
            stat("COMBO", "\(engine.combo)x")
            stat("ACC", engine.scoring.hits + engine.scoring.misses > 0 ? "\(engine.accuracy)%" : "—")
        }
        .foregroundStyle(.primary)
    }

    private func stat(_ k: String, _ v: String) -> some View {
        VStack(spacing: 1) {
            Text(k).font(SPFont.mono(.caption2)).foregroundStyle(.secondary)
            Text(v).font(SPFont.mono(.title3, weight: .bold)).foregroundStyle(SPColor.accentGreen)
        }
        .frame(minWidth: 64)
    }

    private var progressStrip: some View {
        let total = engine.notes.count
        let done = engine.notes.filter { $0.hit || $0.missed }.count
        return GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(SPColor.panel)
                Capsule().fill(SPColor.accentGreen)
                    .frame(width: total > 0 ? geo.size.width * CGFloat(done) / CGFloat(total) : 0)
            }
        }
        .frame(height: 6)
    }

    // MARK: pads

    private var pads: some View {
        HStack(spacing: 8) {
            ForEach(padLanes, id: \.self) { lane in
                PadButton(label: lane.label, color: laneColor(lane)) { hit(lane) }
            }
        }
    }

    private func hit(_ lane: DrumLane) {
        store.audio.play(lane: lane)
        _ = engine.registerHit(lane: lane.rawValue)
    }

    // MARK: rail

    private var rail: some View {
        HStack(spacing: 16) {
            Button {
                engine.load(engine.lesson ?? LessonCatalog.all[0], loop: loop)
                engine.start()
            } label: {
                Label("Play", systemImage: "play.fill")
            }
            .buttonStyle(.borderedProminent).tint(SPColor.accentGreen)

            Button { engine.reset() } label: { Image(systemName: "stop.fill") }
                .buttonStyle(.bordered)

            Toggle(isOn: $loop) { Text("Loop").font(SPFont.mono(.caption)) }
                .toggleStyle(.button).tint(SPColor.accentOrange)

            Toggle(isOn: $clickOn) { Text("Click").font(SPFont.mono(.caption)) }
                .toggleStyle(.button).tint(SPColor.accentOrange)

            Spacer()
            BpmStepper(bpm: Binding(
                get: { engine.bpm },
                set: { engine.bpm = $0 }
            ))
            HStack(spacing: 6) {
                LED(on: false); Text("MIDI").font(SPFont.mono(.caption2)).foregroundStyle(.secondary)
            }
        }
        .tint(SPColor.accentGreen)
    }

    private func laneColor(_ lane: DrumLane) -> Color {
        switch lane {
        case .crash: return SPColor.accentPink
        case .hihat: return SPColor.accentGreen
        case .snare: return Color(hex: "#dde2ea")
        case .kick:  return SPColor.accentRed
        case .tom:   return SPColor.accentOrange
        case .ride:  return Color(hex: "#4ad8ff")
        }
    }

    private func persistPass() {
        guard let lesson = engine.lesson, let p = store.persistence else { return }
        p.recordPass(lessonKey: lesson.name, score: engine.score, accuracy: engine.accuracy)
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"; fmt.timeZone = TimeZone(identifier: "UTC")
        p.recordPlayDay(fmt.string(from: Date()))
    }
}
