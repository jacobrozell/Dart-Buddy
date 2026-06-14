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
        eventName: "bot_turn_started",
        message: "Bot turn.",
        metadata: [:],
        correlationId: nil
    )

    #expect(FirebaseAnalyticsEventMapping.map(entry, appVersion: nil) == nil)
}

@Test(.tags(.unit, .logging, .regression))
func mapsNavigationAndSetupBreadcrumbEvents() {
    let screen = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .ui,
        eventName: "match_screen_appeared",
        message: "Presented.",
        metadata: ["matchType": "x01", "matchId": "secret"],
        correlationId: nil
    )
    let setup = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .scoring,
        eventName: "match_setup_start",
        message: "Starting setup.",
        metadata: ["matchType": "cricket", "participantCount": "2"],
        correlationId: nil
    )
    let home = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .ui,
        eventName: "play_home_ready",
        message: "Ready.",
        metadata: [:],
        correlationId: nil
    )

    #expect(FirebaseAnalyticsEventMapping.map(screen, appVersion: nil)?.name == "match_screen_appeared")
    #expect(FirebaseAnalyticsEventMapping.map(screen, appVersion: nil)?.parameters["matchType"] == "x01")
    #expect(FirebaseAnalyticsEventMapping.map(setup, appVersion: nil)?.name == "match_setup_start")
    #expect(FirebaseAnalyticsEventMapping.map(home, appVersion: nil)?.name == "play_home_ready")
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

@Test(.tags(.unit, .logging, .regression))
func mapsIntentFailedEvent() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .debug,
        category: .ui,
        eventName: "intent_failed",
        message: "Intent routing failed.",
        metadata: ["intentName": "resume_match", "errorCode": "no_active_match"],
        correlationId: nil
    )

    let event = FirebaseAnalyticsEventMapping.map(entry, appVersion: "2.0.0")

    #expect(event?.name == "intent_failed")
    #expect(event?.parameters["intentName"] == "resume_match")
    #expect(event?.parameters["errorCode"] == "no_active_match")
    #expect(event?.parameters["app_version"] == "2.0.0")
}

@Test(.tags(.unit, .logging, .regression))
func mapsGameModePlayedAndCompletedEvents() {
    let played = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .scoring,
        eventName: "game_mode_played",
        message: "Started.",
        metadata: [
            "matchType": "x01",
            "gameModeId": "standard.x01",
            "gameModeSection": "standard",
            "uiTemplate": "checkoutScore",
            "statKind": "checkout",
            "participantCount": "2",
            "hasBot": "true",
            "botCount": "1",
            "humanCount": "1",
            "botDifficulty": "medium",
            "botKind": "preset",
            "startSource": "setup",
            "configStartScore": "501",
            "configCheckoutMode": "doubleOut",
            "matchId": "secret"
        ],
        correlationId: nil
    )
    let completed = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .appLifecycle,
        eventName: "game_mode_completed",
        message: "Finished.",
        metadata: [
            "matchType": "cricket",
            "gameModeId": "standard.cricket",
            "status": "completed"
        ],
        correlationId: nil
    )

    let playedEvent = FirebaseAnalyticsEventMapping.map(played, appVersion: "1.0.0")
    #expect(playedEvent?.name == "game_mode_played")
    #expect(playedEvent?.parameters["gameModeId"] == "standard.x01")
    #expect(playedEvent?.parameters["gameModeSection"] == "standard")
    #expect(playedEvent?.parameters["botDifficulty"] == "medium")
    #expect(playedEvent?.parameters["botKind"] == "preset")
    #expect(playedEvent?.parameters["startSource"] == "setup")
    #expect(playedEvent?.parameters["configStartScore"] == "501")
    #expect(playedEvent?.parameters["matchId"] == nil)

    let completedEvent = FirebaseAnalyticsEventMapping.map(completed, appVersion: nil)
    #expect(completedEvent?.name == "game_mode_completed")
    #expect(completedEvent?.parameters["gameModeId"] == "standard.cricket")
    #expect(completedEvent?.parameters["status"] == "completed")
}

@Test(.tags(.unit, .logging, .regression))
func mapsMatchResumedAndOnboardingCompletedEvents() {
    let resumed = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .ui,
        eventName: "match_resumed",
        message: "Resumed.",
        metadata: [
            "matchType": "cricket",
            "gameModeId": "standard.cricket",
            "startSource": "resume",
            "status": "inProgress",
            "matchId": "secret"
        ],
        correlationId: nil
    )
    let onboarding = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .ui,
        eventName: "onboarding_completed",
        message: "Finished.",
        metadata: [
            "skipped": "false",
            "bot_tier": "medium",
            "created_player": "true"
        ],
        correlationId: nil
    )

    let resumedEvent = FirebaseAnalyticsEventMapping.map(resumed, appVersion: nil)
    #expect(resumedEvent?.name == "match_resumed")
    #expect(resumedEvent?.parameters["startSource"] == "resume")
    #expect(resumedEvent?.parameters["matchId"] == nil)

    let onboardingEvent = FirebaseAnalyticsEventMapping.map(onboarding, appVersion: "1.0.0")
    #expect(onboardingEvent?.name == "onboarding_completed")
    #expect(onboardingEvent?.parameters["bot_tier"] == "medium")
    #expect(onboardingEvent?.parameters["skipped"] == "false")
}

@Test(.tags(.unit, .logging, .regression))
func mapsMatchAbandonedAndDartUndoneEvents() {
    let abandoned = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .appLifecycle,
        eventName: "match_abandoned",
        message: "Abandoned.",
        metadata: [
            "matchType": "x01",
            "gameModeId": "standard.x01",
            "configStartScore": "501",
            "botDifficulty": "easy",
            "eventCount": "3",
            "matchId": "secret"
        ],
        correlationId: nil
    )
    let dartUndone = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .scoring,
        eventName: "dart_undone",
        message: "Dart removed.",
        metadata: ["matchType": "x01"],
        correlationId: nil
    )

    let abandonedEvent = FirebaseAnalyticsEventMapping.map(abandoned, appVersion: nil)
    #expect(abandonedEvent?.name == "match_abandoned")
    #expect(abandonedEvent?.parameters["configStartScore"] == "501")
    #expect(abandonedEvent?.parameters["botDifficulty"] == "easy")
    #expect(abandonedEvent?.parameters["matchId"] == nil)
    #expect(FirebaseAnalyticsEventMapping.map(dartUndone, appVersion: nil)?.name == "undo_used")
}

@Test(.tags(.unit, .logging, .regression))
func mapsMatchCompletedAndTurnSubmittedEvents() {
    let completed = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .scoring,
        eventName: "match_completed",
        message: "Done.",
        metadata: ["matchType": "cricket", "participantCount": "2"],
        correlationId: nil
    )
    let submitted = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .scoring,
        eventName: "turn_submitted",
        message: "Turn saved.",
        metadata: ["matchType": "x01", "legIndex": "0", "matchId": "secret"],
        correlationId: nil
    )

    #expect(FirebaseAnalyticsEventMapping.map(completed, appVersion: nil)?.name == "match_completed")
    #expect(FirebaseAnalyticsEventMapping.map(submitted, appVersion: nil)?.name == "turn_submitted")
    #expect(FirebaseAnalyticsEventMapping.map(submitted, appVersion: nil)?.parameters["matchId"] == nil)
    #expect(FirebaseAnalyticsEventMapping.map(submitted, appVersion: nil)?.parameters["legIndex"] == "0")
}

@Test(.tags(.unit, .logging, .regression))
func mapsMatchForfeitedAndForfeitFailedEvents() {
    let forfeited = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .appLifecycle,
        eventName: "match_forfeited",
        message: "Match forfeited by user.",
        metadata: [
            "eventCount": "2",
            "participantCount": "2",
            "durationSeconds": "90",
            "resolution": "automatic"
        ],
        correlationId: nil
    )
    let failed = LogEntry(
        timestamp: Date(),
        level: .error,
        category: .appLifecycle,
        eventName: "match_forfeit_failed",
        message: "Forfeit persist failed.",
        metadata: ["matchType": "x01"],
        correlationId: nil
    )

    let forfeitedEvent = FirebaseAnalyticsEventMapping.map(forfeited, appVersion: "1.0.0")
    #expect(forfeitedEvent?.name == "match_forfeited")
    #expect(forfeitedEvent?.parameters["eventCount"] == "2")
    #expect(forfeitedEvent?.parameters["durationSeconds"] == "90")
    #expect(forfeitedEvent?.parameters["resolution"] == "automatic")

    let failedEvent = FirebaseAnalyticsEventMapping.map(failed, appVersion: nil)
    #expect(failedEvent?.name == "match_forfeit_failed")
    #expect(failedEvent?.parameters["matchType"] == "x01")
}

@Test(.tags(.unit, .logging, .regression))
func mapsDeepLinkReceivedEvent() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .debug,
        category: .ui,
        eventName: "deep_link_received",
        message: "Received.",
        metadata: ["path": "play", "version": "v1"],
        correlationId: nil
    )

    let event = FirebaseAnalyticsEventMapping.map(entry, appVersion: nil)
    #expect(event?.name == "deep_link_received")
    #expect(event?.parameters["path"] == "play")
}

@Test(.tags(.unit, .logging, .regression))
func sanitizesLongMetadataValues() {
    let longValue = String(repeating: "x", count: 150)
    let entry = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .scoring,
        eventName: "match_started",
        message: "Started.",
        metadata: ["matchType": longValue],
        correlationId: nil
    )

    let value = FirebaseAnalyticsEventMapping.map(entry, appVersion: nil)?.parameters["matchType"]
    #expect(value?.count == 100)
}

@Test(.tags(.unit, .logging, .regression))
func dropsEmptyAllowlistedParameterValues() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .scoring,
        eventName: "match_started",
        message: "Started.",
        metadata: ["matchType": "", "participantCount": "2"],
        correlationId: nil
    )

    let event = FirebaseAnalyticsEventMapping.map(entry, appVersion: nil)
    #expect(event?.parameters["matchType"] == nil)
    #expect(event?.parameters["participantCount"] == "2")
}

@Test(.tags(.unit, .logging, .regression, .critical))
func dropsPersonalDataKeysFromFirebaseParameters() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .scoring,
        eventName: "match_started",
        message: "Started.",
        metadata: [
            "matchType": "x01",
            "participantCount": "2",
            "displayName": "Jacob",
            "playerName": "Jacob",
            "botName": "Medium Bot",
            "forfeited_by_player_id": UUID().uuidString,
            "botDifficulty": "medium"
        ],
        correlationId: nil
    )

    let event = FirebaseAnalyticsEventMapping.map(entry, appVersion: nil)

    #expect(event?.parameters["matchType"] == "x01")
    #expect(event?.parameters["botDifficulty"] == "medium")
    #expect(event?.parameters["displayName"] == nil)
    #expect(event?.parameters["playerName"] == nil)
    #expect(event?.parameters["botName"] == nil)
    #expect(event?.parameters["forfeited_by_player_id"] == nil)
}

