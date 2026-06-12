import XCTest

/// Shared launch configuration for Dart Buddy UI tests.
class DartBuddyUITestCase: XCTestCase {
    static let brandTitle = "Dart Buddy"
    static let instantBotsLaunchArgument = "-ui_test_instant_bots"
    static let disableFeedbackLaunchArgument = "-ui_test_disable_feedback"
    let timeout: TimeInterval = 10

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    override func tearDown() {
        XCUIApplication().terminate()
        resetSimulatorOrientationToPortrait()
        super.tearDown()
    }

    func setSimulatorOrientation(_ orientation: UIDeviceOrientation) {
        let apply = { XCUIDevice.shared.orientation = orientation }
        if Thread.isMainThread {
            apply()
        } else {
            DispatchQueue.main.sync(execute: apply)
        }
    }

    func resetSimulatorOrientationToPortrait() {
        if XCUIDevice.shared.orientation != .portrait {
            setSimulatorOrientation(.portrait)
        }
    }

    func launchApp(
        _ extraArguments: [String] = [],
        localeLanguage: String? = nil,
        localeIdentifier: String? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui_test_reset", "-disable_firebase_analytics"] + extraArguments
        applyDefaultLaunchEnvironment(to: app)
        if let localeLanguage, let localeIdentifier {
            var environment = app.launchEnvironment
            environment["AppleLanguages"] = "(\(localeLanguage))"
            environment["AppleLocale"] = localeIdentifier
            app.launchEnvironment = environment
        }
        app.launch()
        _ = app.tabBars.firstMatch.waitForExistence(timeout: 15)
        return app
    }

    func launchAppWithFullProductSurface(
        _ extraArguments: [String] = [],
        localeLanguage: String? = nil,
        localeIdentifier: String? = nil
    ) -> XCUIApplication {
        launchApp(
            ["-enable_full_product_surface"] + extraArguments,
            localeLanguage: localeLanguage,
            localeIdentifier: localeIdentifier
        )
    }

}
