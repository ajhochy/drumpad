import XCTest
@testable import Drumrot

/// Parity tests: the ported Swift roster + drop-roll math must match `js/drumrots.js`.
final class DrumrotParityTests: XCTestCase {

    func testRosterCountAndTiers() {
        let all = DrumrotCatalog.all
        XCTAssertEqual(all.count, 31, "expected 31 drumrots")

        let counts = Dictionary(grouping: all, by: \.tier).mapValues(\.count)
        XCTAssertEqual(counts[.common], 4)
        XCTAssertEqual(counts[.rare], 4)
        XCTAssertEqual(counts[.epic], 5)
        XCTAssertEqual(counts[.legendary], 4)
        XCTAssertEqual(counts[.mythic], 4)
        XCTAssertEqual(counts[.god], 2)
        XCTAssertEqual(counts[.og], 8)
    }

    func testUniqueIdsAndNumbers() {
        let all = DrumrotCatalog.all
        XCTAssertEqual(Set(all.map(\.id)).count, all.count, "ids must be unique")
        XCTAssertEqual(Set(all.map(\.num)).count, all.count, "nums must be unique")
        // Numbers run 001...031.
        XCTAssertEqual(all.map(\.num).sorted(), (1...31).map { String(format: "%03d", $0) })
    }

    func testTierOrderIndices() {
        XCTAssertEqual(DrumrotTier.order.map(\.index), Array(0...6))
        XCTAssertEqual(DrumrotTier.common.index, 0)
        XCTAssertEqual(DrumrotTier.og.index, 6)
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

    /// easy weights = [55,35,8,2,0,0,0]; rng past OG check, then a weight roll
    /// landing in the first bucket → common.
    func testEasyRollLandsCommon() {
        // rng order: OG check (>=0.05 to skip), weight roll (*100 < 55 → common), pool pick
        var values = [0.5, 0.10, 0.0]
        let roll = DropRoller.roll(achievementId: "first_hit") { values.removeFirst() }
        XCTAssertEqual(roll.tier, .common)
    }

    /// elite weights = [0,5,20,35,25,15,0]; a high weight roll lands in god (last
    /// non-zero bucket before og).
    func testEliteHighRollLandsGod() {
        // OG check skipped; weight roll *100 = 99 → cumulative falls in god bucket (85..100)
        var values = [0.9, 0.99, 0.0]
        let roll = DropRoller.roll(achievementId: "full_throttle") { values.removeFirst() }
        XCTAssertEqual(roll.tier, .god)
    }

    /// Distribution check: many easy rolls (no OG) should be ~55% common, within tolerance.
    func testEasyDistributionApproxWeights() {
        var rngState: UInt64 = 0x9E3779B97F4A7C15
        func lcg() -> Double {
            rngState = rngState &* 6364136223846793005 &+ 1442695040888963407
            return Double(rngState >> 11) / Double(1 << 53)
        }
        var commons = 0
        let n = 20_000
        for _ in 0..<n {
            // skip OG by consuming a value >= 0.05 first is not possible with single rng;
            // instead count only non-og outcomes.
            let roll = DropRoller.roll(achievementId: "first_hit", rng: lcg)
            if roll.tier == .common { commons += 1 }
        }
        // Expected ≈ 0.95 (non-og) * 0.55 ≈ 0.5225. Allow generous tolerance.
        let frac = Double(commons) / Double(n)
        XCTAssertEqual(frac, 0.52, accuracy: 0.06, "common fraction \(frac) off expected ~0.52")
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
