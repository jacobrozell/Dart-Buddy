import Testing
@testable import DartBuddy

@Test(.tags(.unit, .regression))
func uiTestLaunchArgumentsExposeInstantBotsFlag() {
    #expect(UITestLaunchArguments.instantBots == "-ui_test_instant_bots")
    #expect(UITestLaunchArguments.disableFeedback == "-ui_test_disable_feedback")
}
