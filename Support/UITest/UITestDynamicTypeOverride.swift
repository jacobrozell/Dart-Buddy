import SwiftUI

/// UI-test hook to exercise accessibility Dynamic Type layouts without relying on simulator category strings.
enum UITestDynamicTypeOverride {
    static let launchArgument = "-ui_test_accessibility_text_size"

    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains(launchArgument)
    }
}

extension View {
    @ViewBuilder
    func uiTestAccessibilityDynamicTypeOverride() -> some View {
        if UITestDynamicTypeOverride.isActive {
            dynamicTypeSize(.accessibility5)
        } else {
            self
        }
    }
}
