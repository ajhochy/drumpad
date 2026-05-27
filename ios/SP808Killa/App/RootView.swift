import SwiftUI

struct RootView: View {
    enum Tab: Hashable { case play, library, progress, build, drops }

    @State private var selection: Tab = .play

    var body: some View {
        TabView(selection: $selection) {
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
    }
}

#Preview {
    RootView()
        .preferredColorScheme(.dark)
}
