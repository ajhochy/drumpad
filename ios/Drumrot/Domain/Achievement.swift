import Foundation

/// One achievement definition. Mirror of an `ACHIEVEMENTS` entry in `js/achievements.js`.
struct Achievement: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let desc: String
    let icon: String
    let cat: String
}

enum AchievementCatalog {
    static let all: [Achievement] = load()

    private static func load() -> [Achievement] {
        guard let url = Bundle.main.url(forResource: "Achievements", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            assertionFailure("Achievements.json missing from bundle")
            return []
        }
        do {
            return try JSONDecoder().decode([Achievement].self, from: data)
        } catch {
            assertionFailure("Achievements.json decode failed: \(error)")
            return []
        }
    }
}
