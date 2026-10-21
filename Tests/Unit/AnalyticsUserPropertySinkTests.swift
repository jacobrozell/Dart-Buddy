import Testing
@testable import DartBuddy

@Suite("Analytics user property sink", .tags(.unit, .logging, .regression))
struct AnalyticsUserPropertySinkTests {
    @Test
    func allowlistIncludesSurfaceAndLastModeProperties() {
        #expect(AnalyticsUserPropertySink.allowlistedNames.contains("product_surface"))
        #expect(AnalyticsUserPropertySink.allowlistedNames.contains("last_match_type"))
        #expect(AnalyticsUserPropertySink.allowlistedNames.contains("last_game_mode_id"))
        #expect(AnalyticsUserPropertySink.allowlistedNames.contains("voiceover_enabled"))
        #expect(!AnalyticsUserPropertySink.allowlistedNames.contains("playerId"))
        #expect(!AnalyticsUserPropertySink.allowlistedNames.contains("displayName"))
    }
}
