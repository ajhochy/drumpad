import Foundation
import SwiftData

/// Central SwiftData schema + container factory. Additional `@Model` types
/// (scores, achievements, collection, builder, play days) join `schema` in Phase 4.
enum AppModelContainer {
    static let schema = Schema([
        AppSettings.self,
    ])

    static func make(inMemory: Bool = false) -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemory)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
