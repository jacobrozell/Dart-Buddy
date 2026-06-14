import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .logging, .regression))
func mapsAllowlistedFaultToNonFatalError() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .fault,
        category: .migration,
        eventName: "bootstrap_store_open_failed",
        message: "Migration failed.",
        metadata: ["errorCode": "schema_mismatch", "playerName": "Alice"],
        correlationId: nil
    )

    let error = FirebaseCrashlyticsEventMapping.nonFatalError(for: entry, appVersion: "1.0.0")

    #expect(error?.domain == "com.jacobrozell.DartBuddy.logger")
    #expect(error?.code == 1001)
    #expect(error?.userInfo["event_name"] as? String == "bootstrap_store_open_failed")
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

@Test(.tags(.unit, .logging, .regression))
func mapsEveryAllowlistedCrashlyticsEventCode() {
    for (eventName, code) in FirebaseCrashlyticsEventMapping.eventCodes {
        let entry = LogEntry(
            timestamp: Date(),
            level: .error,
            category: .persistence,
            eventName: eventName,
            message: "Failure.",
            metadata: ["errorCode": "test", "matchType": "x01"],
            correlationId: nil
        )
        let error = FirebaseCrashlyticsEventMapping.nonFatalError(for: entry, appVersion: "1.0.0")
        #expect(error?.code == code)
        #expect(error?.userInfo["event_name"] as? String == eventName)
    }
}

@Test(.tags(.unit, .logging, .regression))
func crashlyticsSanitizesLongParameterValues() {
    let longValue = String(repeating: "y", count: 150)
    let entry = LogEntry(
        timestamp: Date(),
        level: .error,
        category: .persistence,
        eventName: "turn_persist_failed",
        message: "Failed.",
        metadata: ["matchType": longValue],
        correlationId: nil
    )

    let value = FirebaseCrashlyticsEventMapping.nonFatalError(for: entry, appVersion: nil)?.userInfo["matchType"] as? String
    #expect(value?.count == 100)
}

@Test(.tags(.unit, .logging, .regression))
func crashlyticsOmitsEmptyAppVersion() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .error,
        category: .persistence,
        eventName: "match_start_failed",
        message: "Failed.",
        metadata: ["matchType": "x01"],
        correlationId: nil
    )

    let withVersion = FirebaseCrashlyticsEventMapping.nonFatalError(for: entry, appVersion: "1.0.0")
    let withoutVersion = FirebaseCrashlyticsEventMapping.nonFatalError(for: entry, appVersion: "")
    #expect(withVersion?.userInfo["app_version"] as? String == "1.0.0")
    #expect(withoutVersion?.userInfo["app_version"] == nil)
}
