import Testing
@testable import DartBuddy

@Suite("Analytics metadata keys", .tags(.unit, .logging, .regression))
struct AnalyticsMetadataKeysTests {
    @Test
    func clientEnvironmentKeysAreSubsetOfDefaultRedactionAllowlist() {
        for key in AnalyticsMetadataKeys.clientEnvironment {
            #expect(AnalyticsMetadataKeys.defaultRedactionAllowed.contains(key))
        }
    }

    @Test
    func clientEnvironmentKeysAreSubsetOfFirebaseParameters() {
        for key in AnalyticsMetadataKeys.clientEnvironment {
            #expect(AnalyticsMetadataKeys.firebaseParameters.contains(key))
        }
    }

    @Test
    func firebaseParametersIncludeMatchLifecycleFields() {
        for key in ["matchType", "participantCount", "path", "intentName", "errorCode", "gameModeId", "gameModeSection", "botDifficulty", "hasBot", "startSource", "configCheckoutMode", "bot_tier", "skipped"] {
            #expect(AnalyticsMetadataKeys.firebaseParameters.contains(key))
        }
    }

    @Test
    func crashlyticsParametersAreSubsetOfDefaultRedactionAllowlist() {
        for key in AnalyticsMetadataKeys.crashlyticsParameters {
            #expect(AnalyticsMetadataKeys.defaultRedactionAllowed.contains(key))
        }
    }

    @Test
    func defaultRedactionIncludesSensitiveIdentifiers() {
        for key in ["matchId", "correlationId", "settingsId"] {
            #expect(AnalyticsMetadataKeys.defaultRedactionAllowed.contains(key))
        }
        #expect(AnalyticsMetadataKeys.isBlockedPersonalDataKey("playerId"))
    }
}
