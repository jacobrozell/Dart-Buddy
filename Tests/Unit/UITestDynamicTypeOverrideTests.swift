import Testing
@testable import DartBuddy

@Test(.tags(.unit, .regression))
func uiTestAccessibilityTextSizeLaunchArgumentIsStable() {
    #expect(UITestDynamicTypeOverride.launchArgument == "-ui_test_accessibility_text_size")
}
