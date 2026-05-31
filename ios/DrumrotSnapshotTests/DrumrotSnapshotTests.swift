import XCTest
import SnapshotTesting
import SwiftUI
@testable import Drumrot

/// Snapshot regression tests (issue #47).
///
/// Uses pointfreeco/swift-snapshot-testing (>= 1.17) which is already
/// declared as an SPM dependency in Drumrot.xcodeproj.
///
/// # Record mode (first run / update baselines)
///   Pass the environment variable `RECORD_SNAPSHOTS=1` when invoking
///   xcodebuild (the CI workflow does this automatically on first run).
///   The generated PNG files are written to
///   `__Snapshots__/DrumrotSnapshotTests/` next to this file.
///   Commit them so subsequent CI runs can diff against the baseline.
///
/// # CI (diff mode)
///   When `RECORD_SNAPSHOTS` is absent or empty the tests use `.missing` —
///   brand-new snapshots are recorded automatically; any mismatch against an
///   existing baseline fails the build.
///
@MainActor
final class DrumrotSnapshotTests: XCTestCase {

    /// Recording policy derived from the `RECORD_SNAPSHOTS` environment variable.
    private var recordPolicy: SnapshotTestingConfiguration.Record {
        ProcessInfo.processInfo.environment["RECORD_SNAPSHOTS"] == "1" ? .all : .missing
    }

    // MARK: - DropsView

    func testDropsViewSnapshot() throws {
        let view = DropsView()
            .modelContainer(AppModelContainer.make(inMemory: true))
            .preferredColorScheme(.dark)
            .frame(width: 1024, height: 768)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 1024, height: 768)),
                       named: "DropsView",
                       record: recordPolicy)
    }

    // MARK: - ProgressTabView

    func testProgressTabViewSnapshot() throws {
        let view = ProgressTabView()
            .modelContainer(AppModelContainer.make(inMemory: true))
            .preferredColorScheme(.dark)
            .frame(width: 1024, height: 768)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 1024, height: 768)),
                       named: "ProgressTabView",
                       record: recordPolicy)
    }

    // MARK: - LibraryView

    func testLibraryViewSnapshot() throws {
        let store = AppStore()
        let view = LibraryView()
            .environmentObject(store)
            .modelContainer(AppModelContainer.make(inMemory: true))
            .preferredColorScheme(.dark)
            .frame(width: 1024, height: 768)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 1024, height: 768)),
                       named: "LibraryView",
                       record: recordPolicy)
    }

    // MARK: - BuildView

    func testBuildViewSnapshot() throws {
        let store = AppStore()
        let view = BuildView()
            .environmentObject(store)
            .modelContainer(AppModelContainer.make(inMemory: true))
            .preferredColorScheme(.dark)
            .frame(width: 1024, height: 768)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 1024, height: 768)),
                       named: "BuildView",
                       record: recordPolicy)
    }

    // MARK: - Achievement tile (locked vs unlocked)

    func testAchievementTileLockedSnapshot() throws {
        // Renders the Progress tab with no unlocks so all tiles are in locked state.
        let view = ProgressTabView()
            .modelContainer(AppModelContainer.make(inMemory: true))
            .preferredColorScheme(.dark)
            .frame(width: 1024, height: 900)

        assertSnapshot(of: view, as: .image(layout: .fixed(width: 1024, height: 900)),
                       named: "ProgressTabView_NoUnlocks",
                       record: recordPolicy)
    }
}
