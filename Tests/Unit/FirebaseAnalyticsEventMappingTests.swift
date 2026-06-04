import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .logging, .regression))
func mapsAllowlistedMatchLifecycleEvents() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .scoring,
        eventName: "match_started",
        message: "Started.",
        metadata: ["matchType": "x01", "participantCount": "2", "matchId": "secret"],
        correlationId: nil
    )

    let event = FirebaseAnalyticsEventMapping.map(entry, appVersion: "1.0.0")

    #expect(event?.name == "match_started")
    #expect(event?.parameters["matchType"] == "x01")
    #expect(event?.parameters["participantCount"] == "2")
    #expect(event?.parameters["matchId"] == nil)
    #expect(event?.parameters["app_version"] == "1.0.0")
    #expect(event?.parameters["log_category"] == "scoring")
}

@Test(.tags(.unit, .logging, .regression))
func mapsBootstrapReadyToAppOpen() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .appLifecycle,
        eventName: "app_bootstrap_ready",
        message: "Ready.",
        metadata: [:],
        correlationId: nil
    )

    #expect(FirebaseAnalyticsEventMapping.map(entry, appVersion: nil)?.name == "app_open")
}

@Test(.tags(.unit, .logging, .regression))
func mapsUndoToSpecEventName() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .scoring,
        eventName: "turn_undone",
        message: "Undone.",
        metadata: ["matchType": "cricket"],
        correlationId: nil
    )

    #expect(FirebaseAnalyticsEventMapping.map(entry, appVersion: nil)?.name == "undo_used")
}

@Test(.tags(.unit, .logging, .regression))
func mapsBaseballSetupEvent() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .scoring,
        eventName: "match_setup_baseball",
        message: "Starting baseball.",
        metadata: ["matchType": "baseball", "participantCount": "3"],
        correlationId: nil
    )

    let event = FirebaseAnalyticsEventMapping.map(entry, appVersion: "1.0.0")

    #expect(event?.name == "match_setup_baseball")
    #expect(event?.parameters["matchType"] == "baseball")
    #expect(event?.parameters["participantCount"] == "3")
}

@Test(.tags(.unit, .logging, .regression))
func dropsNonAllowlistedEvents() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .ui,
        eventName: "play_home_ready",
        message: "Ready.",
        metadata: [:],
        correlationId: nil
    )

    #expect(FirebaseAnalyticsEventMapping.map(entry, appVersion: nil) == nil)
}
