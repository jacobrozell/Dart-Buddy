import Foundation

/// Launch arguments read by the app during UI tests.
enum UITestLaunchArguments {
    static let instantBots = "-ui_test_instant_bots"
    static let disableFeedback = "-ui_test_disable_feedback"

    static var instantBotsActive: Bool {
        ProcessInfo.processInfo.arguments.contains(instantBots)
    }
}
