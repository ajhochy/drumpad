import SwiftUI
import SwiftData

@main
struct SP808KillaApp: App {
    @StateObject private var store = AppStore()
    private let container = AppModelContainer.make()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
                .task { store.attach(modelContext: container.mainContext) }
        }
        .modelContainer(container)
    }
}
