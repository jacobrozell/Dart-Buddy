import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .logging, .regression))
func mapsAllowlistedFaultToNonFatalError() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .fault,
        category: .migration,
        eventName: "app_bootstrap_migration_failure",
        message: "Migration failed.",
        metadata: ["errorCode": "schema_mismatch", "playerName": "Alice"],
        correlationId: nil
    )

    let error = FirebaseCrashlyticsEventMapping.nonFatalError(for: entry, appVersion: "1.0.0")

    #expect(error?.domain == "com.jacobrozell.DartBuddy.logger")
    #expect(error?.code == 1001)
    #expect(error?.userInfo["event_name"] as? String == "app_bootstrap_migration_failure")
    #expect(error?.userInfo["log_category"] as? String == "migration")
    #expect(error?.userInfo["errorCode"] as? String == "schema_mismatch")
    #expect(error?.userInfo["playerName"] == nil)
    #expect(error?.userInfo["app_version"] as? String == "1.0.0")
}

@Test(.tags(.unit, .logging, .regression))
func mapsAllowlistedErrorEvent() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .error,
        category: .persistence,
        eventName: "turn_persist_failed",
        message: "Could not save turn.",
        metadata: ["layer": "repository", "matchType": "x01"],
        correlationId: nil
    )

    let error = FirebaseCrashlyticsEventMapping.nonFatalError(for: entry, appVersion: nil)

    #expect(error?.code == 1003)
    #expect(error?.userInfo["layer"] as? String == "repository")
    #expect(error?.userInfo["matchType"] as? String == "x01")
}

@Test(.tags(.unit, .logging, .regression))
func dropsInfoLevelAndNonAllowlistedEvents() {
    let infoEntry = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .ui,
        eventName: "play_home_ready",
        message: "Ready.",
        metadata: [:],
        correlationId: nil
    )
    #expect(FirebaseCrashlyticsEventMapping.nonFatalError(for: infoEntry, appVersion: nil) == nil)

    let errorEntry = LogEntry(
        timestamp: Date(),
        level: .error,
        category: .ui,
        eventName: "play_home_ready",
        message: "Load failed.",
        metadata: [:],
        correlationId: nil
    )
    #expect(FirebaseCrashlyticsEventMapping.nonFatalError(for: errorEntry, appVersion: nil) == nil)
}
