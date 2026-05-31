import XCTest
@testable import Drumrot

/// Parity tests: the ported Swift roster + drop-roll math for the 5-tier system (issue #72).
///
/// Tier collapse:
///   - mythic → legendary (4 chars moved up)
///   - god    → og        (2 chars moved up)
/// New roster counts: common=4, rare=4, epic=5, legendary=8, og=10.
final class DrumrotParityTests: XCTestCase {

    func testRosterCountAndTiers() {
        let all = DrumrotCatalog.all
        XCTAssertEqual(all.count, 31, "expected 31 drumrots")

        let counts = Dictionary(grouping: all, by: \.tier).mapValues(\.count)
        XCTAssertEqual(counts[.common],    4,  "common count")
        XCTAssertEqual(counts[.rare],      4,  "rare count")
        XCTAssertEqual(counts[.epic],      5,  "epic count")
        // legendary now includes former mythic (4+4=8)
        XCTAssertEqual(counts[.legendary], 8,  "legendary count (mythic merged in)")
        // og now includes former god (8+2=10)
        XCTAssertEqual(counts[.og],       10,  "og count (god merged in)")
    }

    func testTierCount() {
        // After collapse: 5 tiers, not 7.
        XCTAssertEqual(DrumrotTier.allCases.count, 5)
    }

    func testUniqueIdsAndNumbers() {
        let all = DrumrotCatalog.all
        XCTAssertEqual(Set(all.map(\.id)).count, all.count, "ids must be unique")
        XCTAssertEqual(Set(all.map(\.num)).count, all.count, "nums must be unique")
        // Numbers run 001...031.
        XCTAssertEqual(all.map(\.num).sorted(), (1...31).map { String(format: "%03d", $0) })
    }

    func testTierOrderIndices() {
        XCTAssertEqual(DrumrotTier.order.map(\.index), Array(0...4))
        XCTAssertEqual(DrumrotTier.common.index, 0)
        XCTAssertEqual(DrumrotTier.og.index, 4)
    }

    // MARK: - Drop roll

    /// First rng() < 0.05 forces OG regardless of difficulty (the flat 5% bonus).
    func testOGBonusTriggersOnLowRoll() {
        var values = [0.01, 0.0]  // OG check hits; then pool pick
        let roll = DropRoller.roll(achievementId: "first_hit") {
            values.removeFirst()
        }
        XCTAssertEqual(roll.tier, .og)
        XCTAssertEqual(roll.drumrot.tier, .og)
    }

    /// graduate and full_throttle get 10% OG chance (issue #72).
    func testEliteHighOGChance() {
        XCTAssertEqual(DropRoller.ogChance(for: "graduate"),     0.10, accuracy: 0.001)
        XCTAssertEqual(DropRoller.ogChance(for: "full_throttle"), 0.10, accuracy: 0.001)
        XCTAssertEqual(DropRoller.ogChance(for: "first_hit"),    0.05, accuracy: 0.001)
    }

    /// entry weights = [60,32,8,0,0]; rng past OG check, weight roll < 60 → common.
    func testEntryRollLandsCommon() {
        // rng order: OG check (>=0.05 to skip), weight roll (*100 = 10 < 60 → common), pool pick
        var values = [0.5, 0.10, 0.0]
        let roll = DropRoller.roll(achievementId: "first_hit") { values.removeFirst() }
        XCTAssertEqual(roll.tier, .common)
    }

    /// Elite weights = [0,0,15,60,25]; a high weight roll lands in legendary bucket.
    func testEliteRollLandsLegendary() {
        // OG check skipped (0.9 >= 0.1); weight roll *100 = 50 → cumulative:
        //   [0,0,15,...] → 50 falls in legendary bucket (15..75)
        var values = [0.9, 0.50, 0.0]
        let roll = DropRoller.roll(achievementId: "full_throttle") { values.removeFirst() }
        XCTAssertEqual(roll.tier, .legendary)
    }

    /// Elite weights = [0,0,15,60,25]; a very high roll lands in og (non-OG-bonus).
    func testEliteHighRollLandsOG() {
        // OG check skipped (0.9 >= 0.1); weight roll *100 = 99 → cumulative:
        //   [0+0+15+60=75..100) → og bucket
        var values = [0.9, 0.99, 0.0]
        let roll = DropRoller.roll(achievementId: "full_throttle") { values.removeFirst() }
        XCTAssertEqual(roll.tier, .og)
    }

    /// Elite floor: entry roll must never land common/rare (weights both 0).
    func testEliteNeverDropsCommonOrRare() {
        var rngState: UInt64 = 0xDEADBEEFCAFEBABE
        func lcg() -> Double {
            rngState = rngState &* 6364136223846793005 &+ 1442695040888963407
            return Double(rngState >> 11) / Double(1 << 53)
        }
        for _ in 0..<5_000 {
            let roll = DropRoller.roll(achievementId: "combo_200", rng: lcg)
            XCTAssertNotEqual(roll.tier, .common, "elite should never drop common")
            XCTAssertNotEqual(roll.tier, .rare,   "elite should never drop rare")
        }
    }

    /// Distribution check: entry rolls should be ~60% common (before OG), within tolerance.
    func testEntryDistributionApproxWeights() {
        var rngState: UInt64 = 0x9E3779B97F4A7C15
        func lcg() -> Double {
            rngState = rngState &* 6364136223846793005 &+ 1442695040888963407
            return Double(rngState >> 11) / Double(1 << 53)
        }
        var commons = 0
        let n = 20_000
        for _ in 0..<n {
            let roll = DropRoller.roll(achievementId: "first_hit", rng: lcg)
            if roll.tier == .common { commons += 1 }
        }
        // Expected ≈ 0.95 (non-og) * 0.60 = 0.57. Allow generous tolerance.
        let frac = Double(commons) / Double(n)
        XCTAssertEqual(frac, 0.57, accuracy: 0.08, "common fraction \(frac) off expected ~0.57")
    }

    // MARK: - Pity mechanic

    func testPityMechanicPrefersLowCountCharacters() {
        let catalog = DrumrotCatalog.all.filter { $0.tier == .og }
        guard !catalog.isEmpty else { return }
        let firstId = catalog[0].id
        // Simulate having pulled the first OG character 5 times.
        let counts: [String: Int] = [firstId: 5]
        // With OG-check forced (rng < 0.01), pity should prefer characters with 0 pulls.
        var values = [0.01, 0.0]
        let roll = DropRoller.roll(achievementId: "first_hit", collectionCounts: counts) {
            values.isEmpty ? Double.random(in: 0..<1) : values.removeFirst()
        }
        XCTAssertEqual(roll.tier, .og)
        // The result should not be the over-pulled character (if pool > 1).
        if catalog.count > 1 {
            XCTAssertNotEqual(roll.drumrot.id, firstId,
                "pity mechanic should prefer un-pulled characters over heavily-pulled ones")
        }
    }

    // MARK: - Collection upgrade rule

    func testCollectionUpgradeOnly() {
        var col = DrumrotCollection()
        XCTAssertTrue(col.add("x", tier: .rare))      // new
        XCTAssertFalse(col.add("x", tier: .common))   // downgrade ignored
        XCTAssertFalse(col.add("x", tier: .rare))     // equal ignored
        XCTAssertTrue(col.add("x", tier: .epic))      // upgrade
        XCTAssertEqual(col.tierIndex(for: "x"), DrumrotTier.epic.index)
        XCTAssertEqual(col.count, 1)
    }
}
