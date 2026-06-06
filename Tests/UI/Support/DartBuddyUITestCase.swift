import XCTest

/// Shared launch configuration for Dart Buddy UI tests.
class DartBuddyUITestCase: XCTestCase {
    static let brandTitle = "Dart Buddy"
    let timeout: TimeInterval = 10

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    override func tearDown() {
        XCUIApplication().terminate()
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    func launchApp(_ extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui_test_reset", "-disable_firebase_analytics"] + extraArguments
        applyDefaultLaunchEnvironment(to: app)
        app.launch()
        return app
    }

}
