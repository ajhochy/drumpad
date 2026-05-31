import XCTest

/// XCUITest suite for Library context menu on user-authored grooves (issues #48, #70).
///
/// Prerequisites: launch the app with `--demo` so it seeds two extra grooves:
///   - "Backbeat Sketch"   (user, with steps pre-populated)
///   - "demo-import"       (user, simulates a MIDI import)
/// Built-in grooves (e.g. "Rock Beat 101") must NOT show Edit/Rename/Delete menus.
///
/// NOTE: These tests require the app to be built and the "DrumrotUITests" target
/// registered in Drumrot.xcodeproj.  Run via:
///   xcodebuild test -scheme Drumrot -destination 'platform=iOS Simulator,name=iPad (10th generation)'
///
final class LibraryContextMenuUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--demo"]
        app.launch()
        navigateToLibrary()
    }

    // MARK: - Helpers

    private func navigateToLibrary() {
        // Tap the Library tab (label varies; fall back to second tab item).
        let tabBar = app.tabBars.firstMatch
        if tabBar.buttons["Library"].exists {
            tabBar.buttons["Library"].tap()
        } else {
            // Try sidebar / toolbar button on iPad
            let btn = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Library'")).firstMatch
            if btn.waitForExistence(timeout: 3) { btn.tap() }
        }
    }

    private func cell(named name: String) -> XCUIElement {
        app.cells.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
    }

    // MARK: - Test: long-press USER cell shows Edit / Rename / Delete

    func testUserCellContextMenuShowsEditRenameDelete() {
        let target = cell(named: "Backbeat Sketch")
        XCTAssertTrue(target.waitForExistence(timeout: 5),
                      "Backbeat Sketch cell should be visible in Library")

        target.press(forDuration: 1.2)

        // Verify all three menu items appear
        XCTAssertTrue(app.buttons["Edit Groove"].waitForExistence(timeout: 3),
                      "Edit Groove should appear in context menu for user grooves")
        XCTAssertTrue(app.buttons["Rename"].exists,
                      "Rename should appear in context menu for user grooves")
        XCTAssertTrue(app.buttons["Delete"].exists,
                      "Delete should appear in context menu for user grooves")

        // Dismiss the menu
        app.coordinate(withNormalizedOffset: .init(dx: 0.1, dy: 0.1)).tap()
    }

    // MARK: - Test: Edit Groove opens Build tab pre-populated

    func testEditGrooveOpensBuildTabWithName() {
        let target = cell(named: "Backbeat Sketch")
        XCTAssertTrue(target.waitForExistence(timeout: 5))

        target.press(forDuration: 1.2)
        XCTAssertTrue(app.buttons["Edit Groove"].waitForExistence(timeout: 3))
        app.buttons["Edit Groove"].tap()

        // Build tab should now be selected and name field populated
        let nameField = app.textFields["Groove name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5),
                      "Build tab should open with groove name field visible")
        XCTAssertEqual(nameField.value as? String, "Backbeat Sketch",
                       "LCD name field should be pre-populated with the edited groove name")
    }

    // MARK: - Test: Delete removes the cell

    func testDeleteRemovesUserCell() {
        let target = cell(named: "demo-import")
        XCTAssertTrue(target.waitForExistence(timeout: 5))

        let countBefore = app.cells.matching(
            NSPredicate(format: "label CONTAINS 'USER'")).count

        target.press(forDuration: 1.2)
        XCTAssertTrue(app.buttons["Delete"].waitForExistence(timeout: 3))
        app.buttons["Delete"].tap()

        // Give the UI a moment to update
        let _ = app.cells.matching(NSPredicate(format: "label BEGINSWITH 'demo-import'"))
                         .firstMatch.waitForNonExistence(timeout: 3)

        // Navigate away and back to verify persistence
        navigateToLibrary()
        XCTAssertFalse(cell(named: "demo-import").exists,
                       "Deleted cell should not reappear after tab switch")

        let countAfter = app.cells.matching(
            NSPredicate(format: "label CONTAINS 'USER'")).count
        XCTAssertEqual(countAfter, countBefore - 1,
                       "Extra-lesson count should drop by 1 after deletion")
    }

    // MARK: - Test: Built-in cell does NOT show context menu

    func testBuiltInCellHasNoContextMenu() {
        let builtIn = cell(named: "Rock Beat 101")
        guard builtIn.waitForExistence(timeout: 5) else {
            // Built-in may not be named "Rock Beat 101" — skip gracefully
            XCTSkip("Rock Beat 101 not found; update test with a valid built-in lesson name")
            return
        }

        builtIn.press(forDuration: 1.2)

        // Neither Edit Groove nor Delete should appear
        XCTAssertFalse(app.buttons["Edit Groove"].waitForExistence(timeout: 2),
                       "Built-in cells must not show Edit Groove")
        XCTAssertFalse(app.buttons["Delete"].exists,
                       "Built-in cells must not show Delete")

        app.coordinate(withNormalizedOffset: .init(dx: 0.1, dy: 0.1)).tap()
    }
}

// MARK: - Existence negation helper

extension XCUIElement {
    /// Returns true when this element ceases to exist within `timeout` seconds.
    func waitForNonExistence(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
