import SwiftUI

struct RootView: View {
    enum Tab: String, Hashable { case play, library, progress, build, drops }

    @EnvironmentObject private var store: AppStore

    private var spTabBinding: Binding<SPTab> {
        Binding(
            get: { SPTab(rawValue: store.selectedTab.rawValue) ?? .play },
            set: { store.selectedTab = Tab(rawValue: $0.rawValue) ?? .play }
        )
    }

    private var midiConnectedBinding: Binding<Bool> {
        Binding(get: { !store.midi.sources.isEmpty }, set: { _ in })
    }

    var body: some View {
        ZStack {
            RadialGradient(
                colors: [Color(hex: 0x2A2D35), SPColor.roomBG, SPColor.plastic],
                center: .init(x: 0.3, y: 0), startRadius: 0, endRadius: 1400
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                SPLidBar(
                    selection: spTabBinding,
                    midiConnected: midiConnectedBinding,
                    onOpenSettings: { store.showSettings = true }
                )

                ZStack {
                    switch store.selectedTab {
                    case .play:     PlayView()
                    case .library:  LibraryView()
                    case .progress: ProgressTabView()
                    case .build:    BuildView()
                    case .drops:    DropsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $store.showSettings) {
            SettingsView()
        }
        .fullScreenCover(item: $store.currentReveal) { item in
            RevealOverlay(item: item) { store.dismissCurrentReveal() }
        }
        .overlay(alignment: .top) {
            if let toast = store.currentToast {
                AchievementToast(achievement: toast)
                    .padding(.top, 60)
            }
        }
        .animation(.spring(response: 0.4), value: store.currentToast)
        .background { keyboardShortcuts }
    }

    @ViewBuilder private var keyboardShortcuts: some View {
        Group {
            Button("") { store.selectedTab = .play }.keyboardShortcut("1", modifiers: .command)
            Button("") { store.selectedTab = .library }.keyboardShortcut("2", modifiers: .command)
            Button("") { store.selectedTab = .progress }.keyboardShortcut("3", modifiers: .command)
            Button("") { store.selectedTab = .build }.keyboardShortcut("4", modifiers: .command)
            Button("") { store.selectedTab = .drops }.keyboardShortcut("5", modifiers: .command)
            Button("") { store.showSettings = true }.keyboardShortcut(",", modifiers: .command)
        }
        .opacity(0)
        .frame(width: 0, height: 0)
        .accessibilityHidden(true)
    }
}

#Preview {
    RootView()
        .environmentObject(AppStore(persistence: PersistenceStore(defaults: nil)))
        .environmentObject(PersistenceStore(defaults: nil))
        .preferredColorScheme(.dark)
}
