import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var rows: [AppSettings]
    @State private var showBluetooth = false
    @State private var showRecentMIDI = false

    var body: some View {
        NavigationStack {
            Form {
                Section("MIDI") {
                    if store.midi.sources.isEmpty {
                        Text("No MIDI sources connected.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        ForEach(store.midi.sources) { source in
                            LabeledContent(source.name) {
                                Text("uid \(source.id)").font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Button("Pair Bluetooth MIDI device") { showBluetooth = true }
                    DisclosureGroup("Recent activity", isExpanded: $showRecentMIDI) {
                        MIDIDiagnosticOverlay(midi: store.midi, compact: false)
                            .padding(.vertical, 4)
                    }
                }

                Section {
                    Stepper(
                        "Latency offset: \(settings.audioLatencyOffsetMs) ms",
                        value: bind(\.audioLatencyOffsetMs), in: -50...50
                    )
                    Toggle("External audio mode", isOn: bind(\.externalAudioMode))
                } header: {
                    Text("Audio")
                } footer: {
                    Text("Suppress in-app drum samples when triggered by MIDI. Use only when monitoring through your drum module's own headphone output. MIDI scoring, visual highway, click, and on-screen pad taps remain active.")
                }

                Section("Feel") {
                    Toggle("Haptics", isOn: bind(\.hapticsEnabled))
                    Toggle("Reduce motion", isOn: bind(\.reduceMotionOverride))
                }

                Section {
                    LabeledContent("Schema version", value: "\(settings.schemaVersion)")
                } footer: {
                    Text("Progress is stored per-device. No cross-platform sync in v1.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
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
    }

    /// The singleton settings row, created on first access.
    private var settings: AppSettings {
        if let existing = rows.first { return existing }
        let created = AppSettings()
        context.insert(created)
        return created
    }

    private func bind<Value>(_ keyPath: ReferenceWritableKeyPath<AppSettings, Value>) -> Binding<Value> {
        let s = settings
        return Binding(get: { s[keyPath: keyPath] }, set: { s[keyPath: keyPath] = $0 })
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppStore())
        .modelContainer(AppModelContainer.make(inMemory: true))
        .preferredColorScheme(.dark)
}
