import XCTest

/// Shared launch configuration for Dart Buddy UI tests.
class DartBuddyUITestCase: XCTestCase {
    let timeout: TimeInterval = 10

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func launchApp(_ extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui_test_reset", "-disable_firebase_analytics"] + extraArguments
        app.launch()
        return app
    }
}
