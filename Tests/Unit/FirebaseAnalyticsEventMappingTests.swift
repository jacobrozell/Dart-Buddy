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

@Test(.tags(.unit, .logging, .regression))
func mapsDeepLinkAppliedEvent() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .debug,
        category: .ui,
        eventName: "deep_link_applied",
        message: "Deep link routed.",
        metadata: ["path": "play", "version": "v1", "matchId": "secret"],
        correlationId: nil
    )

    let event = FirebaseAnalyticsEventMapping.map(entry, appVersion: "1.0.0")

    #expect(event?.name == "deep_link_applied")
    #expect(event?.parameters["path"] == "play")
    #expect(event?.parameters["version"] == "v1")
    #expect(event?.parameters["matchId"] == nil)
}

@Test(.tags(.unit, .logging, .regression))
func mapsDeepLinkDeferredAndFailedEvents() {
    let deferred = LogEntry(
        timestamp: Date(),
        level: .debug,
        category: .ui,
        eventName: "deep_link_deferred",
        message: "Waiting for onboarding.",
        metadata: ["version": "v1"],
        correlationId: nil
    )
    let failed = LogEntry(
        timestamp: Date(),
        level: .debug,
        category: .ui,
        eventName: "deep_link_failed",
        message: "Resume deep link with no active match.",
        metadata: ["path": "play/resume", "version": "v1"],
        correlationId: nil
    )

    #expect(FirebaseAnalyticsEventMapping.map(deferred, appVersion: nil)?.name == "deep_link_deferred")
    #expect(FirebaseAnalyticsEventMapping.map(failed, appVersion: nil)?.name == "deep_link_failed")
    #expect(FirebaseAnalyticsEventMapping.map(failed, appVersion: nil)?.parameters["path"] == "play/resume")
}

@Test(.tags(.unit, .logging, .regression))
func mapsIntentPerformedEvent() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .debug,
        category: .ui,
        eventName: "intent_performed",
        message: "App intent routed.",
        metadata: ["intentName": "open_play", "playerId": "secret"],
        correlationId: nil
    )

    let event = FirebaseAnalyticsEventMapping.map(entry, appVersion: nil)

    #expect(event?.name == "intent_performed")
    #expect(event?.parameters["intentName"] == "open_play")
    #expect(event?.parameters["playerId"] == nil)
}
