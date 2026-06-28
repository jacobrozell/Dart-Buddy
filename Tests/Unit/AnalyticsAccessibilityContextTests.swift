import Foundation
import Testing
@testable import DartBuddy

@Suite("Analytics accessibility context", .tags(.unit, .logging, .regression))
@MainActor
struct AnalyticsAccessibilityContextTests {
    @Test
    func userPropertyValuesMirrorClientEnvironmentSnapshot() {
        let snapshot = ClientEnvironmentSnapshot(
            deviceClass: "iphone",
            isVoiceOverRunning: true,
            isSwitchControlRunning: false,
            isBoldTextEnabled: true,
            isReduceMotionEnabled: false,
            isScreenCaptured: false,
            isExternalDisplayConnected: false,
            interfaceOrientation: "portrait",
            contentSizeCategory: "accessibility",
            colorScheme: "dark",
            isLowPowerModeEnabled: false
        )

        let values = AnalyticsAccessibilityContext.userPropertyValues(from: snapshot)

        #expect(values["voiceover_enabled"] == "true")
        #expect(values["switch_control_enabled"] == "false")
        #expect(values["content_size_category"] == "accessibility")
        #expect(values["reduce_motion_enabled"] == "false")
        #expect(values["bold_text_enabled"] == "true")
    }
}
