import Testing
@testable import DartBuddy

@Suite("Firebase bootstrap", .tags(.unit, .logging, .regression))
struct FirebaseBootstrapTests {
    @Test
    func analyticsCollectionRequiresFeatureFlag() {
        let enabled = StubFeatureFlags(flags: [.enableFirebaseAnalytics: true])
        let disabled = StubFeatureFlags(flags: [.enableFirebaseAnalytics: false])

        #expect(
            FirebaseBootstrap.analyticsCollectionEnabled(featureFlags: enabled)
                == FirebaseBootstrap.shouldConfigure
        )
        #expect(!FirebaseBootstrap.analyticsCollectionEnabled(featureFlags: disabled))
    }

    @Test
    func crashlyticsCollectionRequiresFeatureFlag() {
        let enabled = StubFeatureFlags(flags: [.enableFirebaseCrashlytics: true])
        let disabled = StubFeatureFlags(flags: [.enableFirebaseCrashlytics: false])

        #expect(
            FirebaseBootstrap.crashlyticsCollectionEnabled(featureFlags: enabled)
                == FirebaseBootstrap.shouldConfigure
        )
        #expect(!FirebaseBootstrap.crashlyticsCollectionEnabled(featureFlags: disabled))
    }

    @Test
    func collectionGatesOnShouldConfigure() {
        let flags = StubFeatureFlags(flags: [
            .enableFirebaseAnalytics: true,
            .enableFirebaseCrashlytics: true,
        ])
        let shouldConfigure = FirebaseBootstrap.shouldConfigure

        #expect(FirebaseBootstrap.analyticsCollectionEnabled(featureFlags: flags) == shouldConfigure)
        #expect(FirebaseBootstrap.crashlyticsCollectionEnabled(featureFlags: flags) == shouldConfigure)
    }
}

private struct StubFeatureFlags: FeatureFlagsProvider {
    let flags: [FeatureFlag: Bool]

    func isEnabled(_ flag: FeatureFlag) -> Bool {
        flags[flag] ?? false
    }
}
