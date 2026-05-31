import SwiftUI

/// Full-screen sheet that lets the user play pads in real time while a looping
/// metronome runs.  Each completed loop is merged back into the Builder grid.
struct RecordPanelView: View {
    @ObservedObject var recorder: BuilderRecordEngine
    let bpm: Int
    let steps: Int
    /// Called with the recorded grid after every completed loop.
    let onLoopComplete: ([[Bool]]) -> Void

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss

    private let lanes: [DrumLane] = DrumLane.allCases

    var body: some View {
        ZStack {
            SPColor.roomBG.ignoresSafeArea()
            VStack(spacing: 16) {
                headerBar
                if recorder.isCountingIn {
                    countInDisplay
                } else {
                    stepBar
                }
                padsGrid
                Spacer(minLength: 0)
                if !recorder.isRecording {
                    startButton
                } else {
                    stopButton
                }
            }
            .padding(20)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .onDisappear { recorder.stop() }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("REC MODE")
                    .font(SPFont.ui(11, weight: .bold)).tracking(2)
                    .foregroundStyle(SPColor.ledRed)
                Text("\(bpm) BPM · \(steps) STEPS")
                    .font(SPFont.monoSmall).tracking(1.5)
                    .foregroundStyle(SPColor.textDim)
            }
            Spacer()
            // Recording indicator dot
            if recorder.isRecording {
                HStack(spacing: 6) {
                    Circle()
                        .fill(SPColor.ledRed)
                        .frame(width: 9, height: 9)
                        .shadow(color: SPColor.ledRed, radius: 5)
                    Text(recorder.isCountingIn ? "COUNT IN" : "RECORDING")
                        .font(SPFont.ui(10, weight: .bold)).tracking(1.4)
                        .foregroundStyle(SPColor.ledRed)
                }
                .transition(.opacity)
            }
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(SPColor.textDim)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close record panel")
        }
    }

    // MARK: - Count-in display

    private var countInDisplay: some View {
        VStack(spacing: 4) {
            Text("GET READY")
                .font(SPFont.ui(11, weight: .bold)).tracking(2)
                .foregroundStyle(SPColor.textDim)
            HStack(spacing: 12) {
                ForEach(1...4, id: \.self) { beat in
                    Circle()
                        .fill(beat <= recorder.countInBeat ? SPColor.ledAmber : SPColor.chassis2)
                        .frame(width: 22, height: 22)
                        .shadow(color: beat == recorder.countInBeat ? SPColor.ledAmber.opacity(0.8) : .clear,
                                radius: 6)
                        .overlay(Circle().stroke(SPColor.ink, lineWidth: 1))
                        .animation(.easeOut(duration: 0.12), value: recorder.countInBeat)
                }
            }
        }
        .frame(height: 54)
    }

    // MARK: - Step progress bar

    private var stepBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(SPColor.chassis2)
                    .overlay(RoundedRectangle(cornerRadius: 3).stroke(SPColor.ink, lineWidth: 1))

                // Step cells
                HStack(spacing: 2) {
                    ForEach(0..<steps, id: \.self) { step in
                        let active = step == recorder.currentStep
                        let beatStart = step % 4 == 0
                        RoundedRectangle(cornerRadius: 2)
                            .fill(active
                                  ? AnyShapeStyle(SPColor.ledRed)
                                  : AnyShapeStyle(beatStart
                                                  ? SPColor.ledAmber.opacity(0.25)
                                                  : SPColor.roomBG))
                            .frame(maxWidth: .infinity)
                            .shadow(color: active ? SPColor.ledRed.opacity(0.8) : .clear, radius: 4)
                            .animation(.easeOut(duration: 0.05), value: recorder.currentStep)
                    }
                }
                .padding(3)
            }
        }
        .frame(height: 24)
    }

    // MARK: - Pads grid

    private var padsGrid: some View {
        let cols = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
        return LazyVGrid(columns: cols, spacing: 10) {
            ForEach(lanes, id: \.self) { lane in
                recordPad(lane: lane)
            }
        }
    }

    private func recordPad(lane: DrumLane) -> some View {
        let laneIdx  = lane.rawValue
        let color    = SPColor.laneColors[laneIdx]
        let flashing = recorder.hitFlash[laneIdx]

        return Button {
            recorder.registerHit(lane: laneIdx)
            store_audio_play(lane: lane)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [SPColor.rubberHi, SPColor.rubber, SPColor.roomBG],
                            center: .init(x: 0.5, y: 0.3),
                            startRadius: 0, endRadius: 80
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(color.opacity(flashing ? 1.0 : 0.3),
                                          lineWidth: flashing ? 2.5 : 1.5)
                    )
                    .shadow(color: flashing ? color.opacity(0.6) : .clear, radius: 10)
                    .scaleEffect(flashing ? 0.96 : 1)
                    .animation(.spring(response: 0.1, dampingFraction: 0.6), value: flashing)

                VStack(spacing: 4) {
                    Text(SPColor.laneNames[laneIdx])
                        .font(SPFont.ui(13, weight: .bold)).tracking(1)
                        .foregroundStyle(color)
                    Text(lane.keyHint)
                        .font(SPFont.monoMicro).tracking(1.5)
                        .foregroundStyle(SPColor.textDim)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(SPColor.ink)
                        .clipShape(RoundedRectangle(cornerRadius: 2))
                }
            }
            .frame(height: 86)
        }
        .buttonStyle(.plain)
        .disabled(!recorder.isRecording || recorder.isCountingIn)
        .accessibilityLabel("\(lane.padName) pad")
        .accessibilityHint("Tap to record a hit")
    }

    // MARK: - Transport buttons

    private var startButton: some View {
        Button {
            recorder.steps = steps
            recorder.bpm   = bpm
            recorder.onMetronome = { [audio = store.audio] accent in
                audio.playClick(accent: accent)
            }
            recorder.start { recorded in
                onLoopComplete(recorded)
            }
        } label: {
            HStack(spacing: 10) {
                Circle().fill(SPColor.ledRed).frame(width: 10, height: 10)
                    .shadow(color: SPColor.ledRed, radius: 4)
                Text("START RECORDING")
                    .font(SPFont.ui(13, weight: .bold)).tracking(1.4)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(LinearGradient(colors: [SPColor.ledRed, Color(hex: 0xA01A35)],
                                       startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(SPColor.ink, lineWidth: 1))
            .shadow(color: SPColor.ledRed.opacity(0.4), radius: 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start recording")
    }

    private var stopButton: some View {
        Button {
            recorder.stop()
        } label: {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2).fill(.white).frame(width: 10, height: 10)
                Text("STOP")
                    .font(SPFont.ui(13, weight: .bold)).tracking(1.4)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity).padding(.vertical, 14)
            .background(LinearGradient(colors: [Color(hex: 0x34383F), Color(hex: 0x1F2127)],
                                       startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(SPColor.ink, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Stop recording")
    }

    // MARK: - Audio helper

    private func store_audio_play(lane: DrumLane) {
        store.audio.play(lane: lane, velocity: 100)
    }
}

// MARK: - Preview

#Preview {
    let engine = BuilderRecordEngine()
    RecordPanelView(
        recorder: engine,
        bpm: 90,
        steps: 16,
        onLoopComplete: { _ in }
    )
    .environmentObject(AppStore(persistence: PersistenceStore(defaults: nil)))
    .preferredColorScheme(.dark)
}
