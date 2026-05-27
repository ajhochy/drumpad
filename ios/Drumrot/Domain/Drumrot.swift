import Foundation

/// A single collectible drumrot. Mirrors one entry of `DRUMROTS` in `js/drumrots.js`.
/// Stats are numeric; `99` is a sentinel rendered as `∞`/`MAX` per the card rules.
struct Drumrot: Codable, Identifiable, Equatable {
    let id: String
    let tier: DrumrotTier
    let num: String
    let emoji: String
    let name: String
    let sub: String
    let flavor: String
    let bpm: Int
    let groove: Int
    let power: Int

    /// Asset-catalog image name (PNGs land in Phase 5's asset pipeline; mirrors `id`).
    var imageName: String { id }
}

/// Loads the canonical roster from the bundled `Drumrots.json` (a byte-for-byte
/// mirror of the web `DRUMROTS` array).
enum DrumrotCatalog {
    static let all: [Drumrot] = load()

    static func drumrots(in tier: DrumrotTier) -> [Drumrot] {
        all.filter { $0.tier == tier }
    }

    private static func load() -> [Drumrot] {
        guard let url = Bundle.main.url(forResource: "Drumrots", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            assertionFailure("Drumrots.json missing from bundle")
            return []
        }
        do {
            return try JSONDecoder().decode([Drumrot].self, from: data)
        } catch {
            assertionFailure("Drumrots.json decode failed: \(error)")
            return []
        }
    }
}
