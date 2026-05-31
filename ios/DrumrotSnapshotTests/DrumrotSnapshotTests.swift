import XCTest
import SnapshotTesting
import SwiftUI
@testable import Drumrot

/// Snapshot regression tests (issue #47).
///
/// Uses pointfreeco/swift-snapshot-testing.  The SPM dependency must be added
/// to Drumrot.xcodeproj before these compile:
///   URL: https://github.com/pointfreeco/swift-snapshot-testing
///   Version: 1.17 or later
///   Product: SnapshotTesting
///
/// First run (record mode):
///   Set `isRecording = true` on each test, or use
///   `withSnapshotTesting(record: .all) { ... }` once globally, then commit
///   the generated `__Snapshots__/` folder.
///
/// CI: subsequent runs with `isRecording = false` (default) will diff against
/// the committed baseline and fail the build on regression.
///
final class DrumrotSnapshotTests: XCTestCase {

    // MARK: - DropsView

    func testDropsViewSnapshot() throws {
        let view = DropsView()
            .modelContainer(AppModelContainer.make(inMemory: true))
            .preferredColorScheme(.dark)
            .frame(width: 1024, height: 768)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 1024, height: 768)),
                       named: "DropsView")
    }

    // MARK: - ProgressTabView

    func testProgressTabViewSnapshot() throws {
        let view = ProgressTabView()
            .modelContainer(AppModelContainer.make(inMemory: true))
            .preferredColorScheme(.dark)
            .frame(width: 1024, height: 768)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 1024, height: 768)),
                       named: "ProgressTabView")
    }

    // MARK: - LibraryView

    func testLibraryViewSnapshot() throws {
        let view = LibraryView()
            .environmentObject(AppStore())
            .modelContainer(AppModelContainer.make(inMemory: true))
            .preferredColorScheme(.dark)
            .frame(width: 1024, height: 768)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 1024, height: 768)),
                       named: "LibraryView")
    }

    // MARK: - BuildView

    func testBuildViewSnapshot() throws {
        let view = BuildView()
            .environmentObject(AppStore())
            .modelContainer(AppModelContainer.make(inMemory: true))
            .preferredColorScheme(.dark)
            .frame(width: 1024, height: 768)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 1024, height: 768)),
                       named: "BuildView")
    }

    // MARK: - Achievement tile (locked vs unlocked)

    func testAchievementTileLockedSnapshot() throws {
        // Renders the Progress tab with no unlocks so all tiles are in locked state.
        let view = ProgressTabView()
            .modelContainer(AppModelContainer.make(inMemory: true))
            .preferredColorScheme(.dark)
            .frame(width: 1024, height: 900)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 1024, height: 900)),
                       named: "ProgressTabView_NoUnlocks")
    }
}
