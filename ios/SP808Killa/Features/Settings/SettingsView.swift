import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var rows: [AppSettings]

    var body: some View {
        NavigationStack {
            Form {
                Section("MIDI") {
                    LabeledContent("Device") {
                        Text(settings.midiDeviceUID ?? "None selected")
                            .foregroundStyle(.secondary)
                    }
                    Text("Device picker + Bluetooth pairing arrive with CoreMIDI (Phase 8).")
                        .font(.caption).foregroundStyle(.secondary)
                }

                Section("Audio") {
                    Stepper(
                        "Latency offset: \(settings.audioLatencyOffsetMs) ms",
                        value: bind(\.audioLatencyOffsetMs), in: -50...50
                    )
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
        .modelContainer(AppModelContainer.make(inMemory: true))
        .preferredColorScheme(.dark)
}
