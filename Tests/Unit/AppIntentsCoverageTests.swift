import Testing
@testable import DartBuddy

@Suite("App intents coverage", .tags(.unit, .navigation, .regression))
struct AppIntentsCoverageTests {
    @Test
    func intentNamesMatchSpecIdentifiers() {
        #expect(OpenPlayIntent.intentName == "open_play")
        #expect(ResumeActiveMatchIntent.intentName == "resume_active_match")
    }

    @Test
    func shortcutsProviderRespectsAppIntentsFeatureFlag() {
        if LocalFeatureFlagsProvider().isEnabled(.enableAppIntents) {
            #expect(DartBuddyShortcutsProvider.appShortcuts.count == 2)
        } else {
            #expect(DartBuddyShortcutsProvider.appShortcuts.isEmpty)
        }
    }
}
