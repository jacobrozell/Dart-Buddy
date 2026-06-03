import XCTest

final class SettingsUITests: DartBuddyUITestCase {
    func testSettingsFeedbackTogglesPersistAcrossTabs() {
        let app = launchApp(["-seed_players", "-ui_test_disable_feedback"])

        app.tabBars.buttons["Settings"].tap()
        scrollToFeedbackSwitches(app)
        let haptics = app.switches["settings_hapticsToggle"]
        let sound = app.switches["settings_soundToggle"]
        XCTAssertTrue(haptics.waitForExistence(timeout: timeout))
        XCTAssertTrue(sound.waitForExistence(timeout: timeout))
        XCTAssertTrue(waitForSwitch(haptics, on: false, timeout: timeout), "Haptics toggle should load off")
        XCTAssertTrue(waitForSwitch(sound, on: false, timeout: timeout), "Sound toggle should load off")

        app.tabBars.buttons["Play"].tap()
        app.tabBars.buttons["Settings"].tap()
        scrollToFeedbackSwitches(app)

        let hapticsAfter = app.switches["settings_hapticsToggle"]
        let soundAfter = app.switches["settings_soundToggle"]
        XCTAssertTrue(hapticsAfter.waitForExistence(timeout: timeout))
        XCTAssertTrue(waitForSwitch(hapticsAfter, on: false, timeout: timeout), "Haptics toggle should stay off after tab change")
        XCTAssertTrue(waitForSwitch(soundAfter, on: false, timeout: timeout), "Sound toggle should stay off after tab change")
    }
}
