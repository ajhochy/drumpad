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
    }
}

#Preview {
    RootView()
        .environmentObject(AppStore())
        .modelContainer(AppModelContainer.make(inMemory: true))
        .preferredColorScheme(.dark)
}
