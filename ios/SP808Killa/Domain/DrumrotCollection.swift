import Foundation

/// In-memory collection state: drumrot id → highest tier index collected.
/// Mirrors the `addToCollection` upgrade rule in `js/drumrots.js` (a lower or
/// equal pull never downgrades). Persistence (SwiftData) lands in Phase 4.
struct DrumrotCollection: Equatable {
    private(set) var entries: [String: Int]

    init(entries: [String: Int] = [:]) {
        self.entries = entries
    }

    var count: Int { entries.count }

    func tierIndex(for id: String) -> Int? { entries[id] }

    /// Adds/upgrades a pull. Returns `true` if it was new or a tier upgrade.
    @discardableResult
    mutating func add(_ id: String, tier: DrumrotTier) -> Bool {
        let newIdx = tier.index
        let curIdx = entries[id] ?? -1
        guard newIdx > curIdx else { return false }
        entries[id] = newIdx
        return true
    }
}
