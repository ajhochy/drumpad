import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var persistence: PersistenceStore
    @Environment(\.dismiss) private var dismiss
    @State private var showBluetooth = false
    @State private var selectedSection: PanelSection = .midi

    enum PanelSection: String, CaseIterable, Identifiable {
        case midi, audio, feel, about
        var id: String { rawValue }
        var title: String {
            switch self {
            case .midi:  return "MIDI & In"
            case .audio: return "Audio"
            case .feel:  return "Feel"
            case .about: return "About"
            }
        }
        var icon: String {
            switch self {
            case .midi:  return "pianokeys"
            case .audio: return "speaker.wave.2.fill"
            case .feel:  return "paintpalette.fill"
            case .about: return "info.circle.fill"
            }
        }
        var number: String { String(format: "·0%d", (Self.allCases.firstIndex(of: self) ?? 0) + 1) }
    }

    var body: some View {
        ZStack {
            SPColor.ink.opacity(0.5).ignoresSafeArea()
            sheet
                .frame(maxWidth: 900)
                .padding(.horizontal, 30)
                .padding(.vertical, 36)
        }
        .sheet(isPresented: $showBluetooth) {
            NavigationStack {
                BluetoothMIDIView()
                    .navigationTitle("Bluetooth MIDI")
                    .navigationBarTitleDisplayMode(.inline)
                    .ignoresSafeArea()
            }
        }
    }

    private var sheet: some View {
        VStack(spacing: 0) {
            panelHead
            Divider().background(SPColor.ink)
            HStack(spacing: 0) {
                sidebar
                pane
            }
            .frame(maxHeight: .infinity)
        }
        .background(
            LinearGradient(
                colors: [Color(hex: 0x2C2F36), Color(hex: 0x232730), Color(hex: 0x1A1D23)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(SPColor.ink, lineWidth: 1))
        .shadow(color: .black.opacity(0.7), radius: 40, y: 20)
        .overlay(alignment: .topLeading)     { SPScrew().padding(10) }
        .overlay(alignment: .topTrailing)    { SPScrew().padding(10) }
        .overlay(alignment: .bottomLeading)  { SPScrew().padding(10) }
        .overlay(alignment: .bottomTrailing) { SPScrew().padding(10) }
    }

    // MARK: - Head

    private var panelHead: some View {
        HStack(spacing: 14) {
            HStack(spacing: 8) {
                Text("Service").font(SPFont.display(24)).foregroundStyle(SPColor.text)
                Text("Panel").font(SPFont.display(24)).foregroundStyle(SPColor.ledAmberHot)
            }
            Spacer()
            Text("FACTORY BAY · CHANGES SAVE INSTANTLY")
                .font(SPFont.monoMicro).tracking(1.8)
                .foregroundStyle(SPColor.textDim)
                .multilineTextAlignment(.trailing)
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(LinearGradient(colors: [SPColor.ledRed, Color(hex: 0xA01A35)],
                                               startPoint: .top, endPoint: .bottom))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(SPColor.ink, lineWidth: 1))
                    .shadow(color: SPColor.ledRed.opacity(0.4), radius: 8)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close settings")
        }
        .padding(.horizontal, 40).padding(.vertical, 14)
        .background(LinearGradient(
            colors: [Color(hex: 0x34383F), SPColor.chassis, SPColor.chassis2],
            startPoint: .top, endPoint: .bottom
        ))
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(PanelSection.allCases) { s in
                Button { selectedSection = s } label: {
                    HStack(spacing: 10) {
                        Image(systemName: s.icon)
                            .font(.system(size: 16))
                            .foregroundStyle(selectedSection == s ? SPColor.ledAmberHot : SPColor.textDim)
                            .frame(width: 20)
                        Text(s.title.uppercased())
                            .font(SPFont.ui(12, weight: .bold))
                            .tracking(1).foregroundStyle(selectedSection == s ? SPColor.ledAmberHot : SPColor.textDim)
                        Spacer()
                        Text(s.number)
                            .font(SPFont.monoMicro).tracking(1.5)
                            .foregroundStyle(selectedSection == s ? SPColor.ledAmberHot : SPColor.textDim)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10).padding(.leading, 2)
                    .background(
                        selectedSection == s
                        ? AnyShapeStyle(LinearGradient(
                            colors: [SPColor.ledAmber.opacity(0.12), .clear],
                            startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(Color.clear)
                    )
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(selectedSection == s ? SPColor.ledAmber : .clear)
                            .frame(width: 3)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(s.title)
                .accessibilityAddTraits(selectedSection == s ? [.isSelected, .isButton] : .isButton)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
        .frame(width: 200)
        .background(LinearGradient(colors: [SPColor.chassis2, Color(hex: 0x14161A)],
                                   startPoint: .top, endPoint: .bottom))
        .overlay(Rectangle().fill(SPColor.ink).frame(width: 1), alignment: .trailing)
    }

    // MARK: - Pane

    @ViewBuilder private var pane: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                switch selectedSection {
                case .midi:  midiPane
                case .audio: audioPane
                case .feel:  feelPane
                case .about: aboutPane
                }
            }
            .padding(.horizontal, 24).padding(.vertical, 18)
        }
    }

    private var midiPane: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHead("MIDI Input", meta: "BUS · LIVE")

            // MIDI source list
            VStack(alignment: .leading, spacing: 10) {
                if store.midi.sources.isEmpty {
                    HStack {
                        SPLED(tone: .off, size: 8)
                        Text("NO MIDI SOURCES CONNECTED")
                            .font(SPFont.monoSmall).tracking(1.8).foregroundStyle(SPColor.lcdDim)
                    }
                } else {
                    HStack {
                        SPLED(tone: .red, size: 8)
                        Text("BUS A — \(store.midi.sources.count) SOURCE\(store.midi.sources.count == 1 ? "" : "S")")
                            .font(SPFont.monoSmall).tracking(1.8).foregroundStyle(SPColor.lcdFG)
                            .shadow(color: SPColor.lcdFG.opacity(0.4), radius: 2)
                    }
                    ForEach(store.midi.sources) { source in
                        HStack(spacing: 10) {
                            Text(source.name)
                                .font(SPFont.monoSmall).tracking(1.5).foregroundStyle(SPColor.lcdFG)
                                .shadow(color: SPColor.lcdFG.opacity(0.4), radius: 2)
                            Spacer()
                            Text("uid \(source.id)")
                                .font(SPFont.monoMicro).tracking(1).foregroundStyle(SPColor.lcdDim)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.black.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .lcdPanel()

            rowShell("Pair Bluetooth MIDI", "add a BLE drumkit or controller") {
                Button { showBluetooth = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "bluetooth")
                        Text("PAIR").font(SPFont.ui(11, weight: .bold)).tracking(1.4)
                    }
                    .foregroundStyle(SPColor.ledAmberHot)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(LinearGradient(colors: [Color(hex: 0x34383F), Color(hex: 0x1F2127)],
                                               startPoint: .top, endPoint: .bottom))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(SPColor.ink, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var audioPane: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHead("Audio", meta: "MS · OFFSET")

            rowShell(
                "Latency offset",
                "compensate for bluetooth or output lag"
            ) {
                HStack(spacing: 8) {
                    Button {
                        persistence.updateSettings { $0.audioLatencyOffsetMs = max(-50, $0.audioLatencyOffsetMs - 1) }
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 30, height: 30)
                            .background(SPColor.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(.black, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    Text("\(settings.audioLatencyOffsetMs) ms")
                        .font(SPFont.lcd(14)).foregroundStyle(SPColor.lcdFG)
                        .shadow(color: SPColor.lcdFG.opacity(0.4), radius: 2)
                        .frame(width: 70)
                        .padding(.horizontal, 8).padding(.vertical, 5)
                        .background(SPColor.lcdBG)
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(.black, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                    Button {
                        persistence.updateSettings { $0.audioLatencyOffsetMs = min(50, $0.audioLatencyOffsetMs + 1) }
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 30, height: 30)
                            .background(SPColor.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .overlay(RoundedRectangle(cornerRadius: 5).stroke(.black, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(SPColor.text)
            }
        }
    }

    private var feelPane: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHead("Feel", meta: "DEFAULTS")

            toggleRow("Haptics", "vibration feedback on pad hits",
                      isOn: bind(\.hapticsEnabled))
            toggleRow("Reduce Motion", "minimal animations throughout the app",
                      isOn: bind(\.reduceMotionOverride))
        }
    }

    private var aboutPane: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHead("About", meta: "SERIAL #\(settings.schemaVersion)")

            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Drumrot").font(SPFont.display(22)).foregroundStyle(SPColor.text)
                    Text("SP-808 DRUM TRAINER · IPAD EDITION")
                        .font(SPFont.monoSmall).tracking(1.8).foregroundStyle(SPColor.ledAmberHot)
                    Text("PROGRESS STORED PER-DEVICE.\nNO CROSS-PLATFORM SYNC IN V1.")
                        .font(SPFont.monoMicro).tracking(1.5).foregroundStyle(SPColor.textDim)
                        .padding(.top, 4)
                    Text("SCHEMA v\(settings.schemaVersion)")
                        .font(SPFont.monoMicro).tracking(1.5).foregroundStyle(SPColor.textDim)
                        .padding(.top, 2)
                }
                Spacer()
                SPDymo(text: "TESTED & PASSED", rotation: 2)
            }
            .padding(18)
            .background(LinearGradient(colors: [SPColor.chassis2, Color(hex: 0x14161A)],
                                       startPoint: .top, endPoint: .bottom))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(SPColor.ink, lineWidth: 1))
        }
    }

    // MARK: - Row primitives

    private func sectionHead(_ title: String, meta: String) -> some View {
        HStack(spacing: 8) {
            Rectangle().fill(SPColor.ledAmber).frame(width: 14, height: 1)
            Text(title.uppercased())
                .font(SPFont.ui(13, weight: .bold)).tracking(2.5)
                .foregroundStyle(SPColor.textDim)
            Spacer()
            Text(meta)
                .font(SPFont.monoMicro).tracking(1.5).foregroundStyle(SPColor.ledAmberHot)
        }
        .padding(.bottom, 4)
    }

    private func rowShell<C: View>(_ title: String, _ desc: String, @ViewBuilder control: () -> C) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(SPFont.ui(13, weight: .bold)).tracking(0.4).foregroundStyle(SPColor.text)
                Text(desc.uppercased())
                    .font(SPFont.monoMicro).tracking(1).foregroundStyle(SPColor.textDim)
            }
            Spacer()
            control()
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(SPColor.ink)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(.black, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func toggleRow(_ title: String, _ desc: String, isOn: Binding<Bool>) -> some View {
        rowShell(title, desc) { SPSwitch(isOn: isOn) }
    }

    // MARK: - Settings access

    private var settings: AppSettings { persistence.settings }

    private func bind<Value>(_ keyPath: WritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        Binding(
            get: { persistence.settings[keyPath: keyPath] },
            set: { newValue in
                persistence.updateSettings { $0[keyPath: keyPath] = newValue }
            }
        )
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppStore(persistence: PersistenceStore(defaults: nil)))
        .environmentObject(PersistenceStore(defaults: nil))
        .preferredColorScheme(.dark)
}
