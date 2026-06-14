import Foundation
import Testing
@testable import DartBuddy

@Suite("Firebase log sinks", .tags(.unit, .logging, .regression))
struct FirebaseLogSinkTests {
    @Test
    func analyticsSinkSkipsWhenCollectionDisabled() {
        let sink = FirebaseAnalyticsLogSink(appVersion: "1.2.3", isCollectionEnabled: false)
        sink.write(makeEntry(level: .info, eventName: "match_started"))
    }

    @Test
    func analyticsSinkSkipsUnmappedEventsWhenEnabled() {
        let sink = FirebaseAnalyticsLogSink(
            appVersion: "1.2.3",
            isCollectionEnabled: FirebaseBootstrap.isAnalyticsCollectionEnabled
        )
        sink.write(makeEntry(level: .debug, eventName: "unmapped_debug_event"))
    }

    @Test
    func crashlyticsSinkSkipsWhenCollectionDisabled() {
        let sink = FirebaseCrashlyticsLogSink(appVersion: "1.2.3", isCollectionEnabled: false)
        sink.write(makeEntry(level: .info, eventName: "play_home_ready"))
        sink.write(makeEntry(level: .error, eventName: "turn_persist_failed"))
        sink.write(makeEntry(level: .fault, eventName: "bootstrap_store_open_failed"))
    }

    @Test
    func crashlyticsSinkAcceptsInfoAndErrorWhenCollectionMatchesBootstrap() {
        let sink = FirebaseCrashlyticsLogSink(
            appVersion: "1.2.3",
            isCollectionEnabled: FirebaseBootstrap.isCrashlyticsCollectionEnabled
        )
        sink.write(makeEntry(level: .info, eventName: "play_home_ready"))
        sink.write(
            makeEntry(
                level: .error,
                eventName: "turn_persist_failed",
                metadata: ["layer": "repository", "matchType": "x01"]
            )
        )
    }

    private func makeEntry(
        level: LogLevel,
        eventName: String,
        metadata: [String: String] = [:]
    ) -> LogEntry {
        LogEntry(
            timestamp: Date(),
            level: level,
            category: .ui,
            eventName: eventName,
            message: "Test.",
            metadata: metadata,
            correlationId: nil
        )
    }
}
