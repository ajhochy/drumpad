import XCTest
@testable import Drumrot

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
        // Renamed categories (issue #72): on_the_kit / showing_up / speed_runs / craft_crew
        XCTAssertEqual(cats["on_the_kit"],  6, "on_the_kit count")
        XCTAssertEqual(cats["showing_up"],  6, "showing_up count")
        XCTAssertEqual(cats["speed_runs"],  4, "speed_runs count")
        XCTAssertEqual(cats["craft_crew"],  2, "craft_crew count")
    }

    func testEveryAchievementHasNameDescIcon() {
        for a in AchievementCatalog.all {
            XCTAssertFalse(a.name.isEmpty, "\(a.id) name")
            XCTAssertFalse(a.desc.isEmpty, "\(a.id) desc")
            XCTAssertFalse(a.icon.isEmpty, "\(a.id) icon")
        }
    }

    // MARK: - Issue #72 additions

    func testEveryAchievementHasDifficulty() {
        let validDifficulties = Set(DropDifficulty.allCases.map(\.rawValue))
        for a in AchievementCatalog.all {
            XCTAssertTrue(validDifficulties.contains(a.difficulty),
                "\(a.id) difficulty '\(a.difficulty)' is not a valid DropDifficulty")
        }
    }

    func testSecretAchievementsLimitedToThree() {
        let secrets = AchievementCatalog.all.filter(\.isSecret)
        XCTAssertLessThanOrEqual(secrets.count, 3,
            "Issue #72: at most 3 secret achievements allowed (found \(secrets.count))")
    }

    func testSecretAchievementsHaveEmptyHint() {
        for a in AchievementCatalog.all where a.isSecret {
            XCTAssertTrue(a.hint.isEmpty,
                "Secret achievement '\(a.id)' must have an empty hint (currently: '\(a.hint)')")
        }
    }

    func testNonSecretAchievementsHaveHint() {
        for a in AchievementCatalog.all where !a.isSecret {
            XCTAssertFalse(a.hint.isEmpty,
                "Non-secret achievement '\(a.id)' must have a non-empty hint")
        }
    }

    func testCreatorAndCoachAreUpdated() {
        let creator = AchievementCatalog.all.first(where: { $0.id == "creator" })
        let coach = AchievementCatalog.all.first(where: { $0.id == "coach" })
        XCTAssertNotNil(creator)
        XCTAssertNotNil(coach)
        // Issue #72: creator threshold raised to 3 saved grooves, reflected in desc
        XCTAssertTrue(creator?.desc.contains("3") ?? false,
            "creator desc should mention the threshold of 3")
        // coach is now secret (issue #72)
        XCTAssertTrue(coach?.isSecret ?? false, "coach should be a secret achievement")
    }

    func testDifficultyAlignmentForKeyAchievements() {
        let difficulties = Dictionary(AchievementCatalog.all.map { ($0.id, $0.difficulty) },
                                       uniquingKeysWith: { a, _ in a })
        // Entry
        XCTAssertEqual(difficulties["first_hit"],    "entry")
        XCTAssertEqual(difficulties["first_pass"],   "entry")
        XCTAssertEqual(difficulties["creator"],      "entry")
        // Easy
        XCTAssertEqual(difficulties["combo_50"],     "easy")
        XCTAssertEqual(difficulties["streak_3"],     "easy")
        // Medium
        XCTAssertEqual(difficulties["combo_100"],    "medium")
        XCTAssertEqual(difficulties["streak_7"],     "medium")
        // Hard
        XCTAssertEqual(difficulties["sharpshooter"], "hard")
        XCTAssertEqual(difficulties["all_grooves"],  "hard")
        XCTAssertEqual(difficulties["speed_demon"],  "hard")
        // Elite
        XCTAssertEqual(difficulties["combo_200"],    "elite")
        XCTAssertEqual(difficulties["perfect_pass"], "elite")
        XCTAssertEqual(difficulties["graduate"],     "elite")
        XCTAssertEqual(difficulties["full_throttle"], "elite")
    }
}
