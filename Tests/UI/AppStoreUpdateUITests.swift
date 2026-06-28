import XCTest

/// Live App Store update prompt — hits the real iTunes Lookup API.
/// Requires network; store version must be newer than the spoofed installed version.
final class AppStoreUpdateUITests: DartBuddyUITestCase {
    func testUpdateAvailableAlertWhenStoreIsNewerThanInstalled() {
        let app = launchApp([
            "-enable_app_store_update_check",
            "-app_store_update_installed_version",
            "0.9.0",
            "-skip_onboarding",
        ])

        let alert = app.alerts["Update Available"]
        XCTAssertTrue(
            alert.waitForExistence(timeout: 15),
            "Live App Store lookup should offer an update when installed version is 0.9.0 and store is 1.0.0"
        )
        XCTAssertTrue(alert.buttons["Update"].exists)
        XCTAssertTrue(alert.buttons["Not Now"].exists)
    }
}
