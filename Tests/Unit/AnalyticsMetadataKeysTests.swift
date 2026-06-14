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
        for key in ["matchType", "participantCount", "path", "intentName", "errorCode", "gameModeId", "gameModeSection", "botDifficulty", "hasBot"] {
            #expect(AnalyticsMetadataKeys.firebaseParameters.contains(key))
        }
    }

    @Test
    func defaultRedactionIncludesSensitiveIdentifiers() {
        for key in ["matchId", "playerId", "correlationId", "settingsId"] {
            #expect(AnalyticsMetadataKeys.defaultRedactionAllowed.contains(key))
        }
    }
}
