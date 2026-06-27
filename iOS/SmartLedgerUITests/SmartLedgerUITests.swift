import XCTest

final class SmartLedgerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launchApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
        return app
    }

    func testTabNavigation() throws {
        let app = launchApp()

        XCTAssertTrue(app.textFields["chat.input"].waitForExistence(timeout: 5))

        app.buttons["tab.1"].tap()
        XCTAssertTrue(app.textFields["ledger.search"].waitForExistence(timeout: 3))

        app.buttons["tab.2"].tap()
        XCTAssertTrue(app.buttons["stats.range.week"].waitForExistence(timeout: 3))

        app.buttons["tab.3"].tap()
        XCTAssertTrue(app.buttons["settings.recharge.credits_100"].waitForExistence(timeout: 3))

        app.buttons["tab.0"].tap()
        XCTAssertTrue(app.textFields["chat.input"].waitForExistence(timeout: 3))
    }

    func testManualEntryFlow() throws {
        let app = launchApp()

        let manual = app.buttons["chat.manualEntry"]
        if manual.waitForExistence(timeout: 3) {
            manual.tap()
        } else {
            app.buttons["tab.1"].tap()
            app.buttons["tab.0"].tap()
            XCTAssertTrue(app.buttons["chat.manualEntry"].waitForExistence(timeout: 3))
            app.buttons["chat.manualEntry"].tap()
        }

        let opened = app.textFields["confirm.titleField"].waitForExistence(timeout: 8)
            || app.buttons["confirm.saveButton"].waitForExistence(timeout: 2)
        XCTAssertTrue(opened)
    }

    func testLedgerSearchFieldExists() throws {
        let app = launchApp()

        app.buttons["tab.1"].tap()
        XCTAssertTrue(app.textFields["ledger.search"].waitForExistence(timeout: 3))
    }

    func testSettingsThemePicker() throws {
        let app = launchApp()

        app.buttons["tab.3"].tap()
        app.swipeUp()
        XCTAssertTrue(app.buttons["settings.theme.mint"].waitForExistence(timeout: 3))
        app.buttons["settings.theme.sky"].tap()
    }

    func testStatsRangeToggle() throws {
        let app = launchApp()

        app.buttons["tab.2"].tap()
        XCTAssertTrue(app.buttons["stats.range.month"].waitForExistence(timeout: 3))
        app.buttons["stats.range.month"].tap()
        app.buttons["stats.range.year"].tap()
    }

    func testChatInputExists() throws {
        let app = launchApp()

        XCTAssertTrue(app.textFields["chat.input"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["chat.voice"].exists)
        XCTAssertTrue(app.buttons["chat.camera"].exists)
    }
}
