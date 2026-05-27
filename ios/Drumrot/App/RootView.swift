import SwiftUI

struct RootView: View {
    enum Tab: String, Hashable { case play, library, progress, build, drops }

    @EnvironmentObject private var store: AppStore

    var body: some View {
        TabView(selection: $store.selectedTab) {
            PlayView()
                .tabItem { Label("Play", systemImage: "music.note.list") }
                .tag(Tab.play)
            LibraryView()
                .tabItem { Label("Library", systemImage: "books.vertical") }
                .tag(Tab.library)
            ProgressTabView()
                .tabItem { Label("Progress", systemImage: "chart.bar") }
                .tag(Tab.progress)
            BuildView()
                .tabItem { Label("Build", systemImage: "slider.horizontal.3") }
                .tag(Tab.build)
            DropsView()
                .tabItem { Label("Drops", systemImage: "square.grid.3x3.fill") }
                .tag(Tab.drops)
        }
        .tint(SPColor.accentGreen)
        .overlay(alignment: .topTrailing) {
            Button { store.showSettings = true } label: {
                Image(systemName: "gearshape.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(10)
            }
            .accessibilityLabel("Settings")
            .padding(.trailing, 8)
        }
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

    /// Hardware-keyboard shortcuts (iPad + iPad-app-on-Mac): Cmd+1…5 tabs, Cmd+,
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
        .environmentObject(AppStore())
        .modelContainer(AppModelContainer.make(inMemory: true))
        .preferredColorScheme(.dark)
}
