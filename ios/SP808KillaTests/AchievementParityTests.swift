import XCTest
@testable import SP808Killa

final class AchievementParityTests: XCTestCase {

    func testAchievementIdsAndOrder() {
        let ids = AchievementCatalog.all.map(\.id)
        XCTAssertEqual(ids, [
            "first_hit", "combo_50", "combo_100", "combo_200", "sharpshooter", "perfect_pass",
            "first_pass", "groove_master", "all_grooves", "graduate", "streak_3", "streak_7",
            "tempo_climber", "full_throttle", "speed_demon", "slow_burn",
            "creator", "coach",
        ])
        XCTAssertEqual(ids.count, 18)
    }

    func testCategories() {
        let cats = Dictionary(grouping: AchievementCatalog.all, by: \.cat).mapValues(\.count)
        XCTAssertEqual(cats["performance"], 6)
        XCTAssertEqual(cats["consistency"], 6)
        XCTAssertEqual(cats["tempo"], 4)
        XCTAssertEqual(cats["builder"], 2)
    }

    func testEveryAchievementHasNameDescIcon() {
        for a in AchievementCatalog.all {
            XCTAssertFalse(a.name.isEmpty, "\(a.id) name")
            XCTAssertFalse(a.desc.isEmpty, "\(a.id) desc")
            XCTAssertFalse(a.icon.isEmpty, "\(a.id) icon")
        }
    }
}
