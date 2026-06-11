import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .regression))
func clientEnvironmentSnapshotBuildsAnalyticsMetadata() {
    let snapshot = ClientEnvironmentSnapshot(
        deviceClass: "ipad",
        isVoiceOverRunning: true,
        isSwitchControlRunning: false,
        isBoldTextEnabled: true,
        isReduceMotionEnabled: false,
        isScreenCaptured: true,
        isExternalDisplayConnected: true,
        interfaceOrientation: "landscape"
    )

    #expect(snapshot.analyticsMetadata["deviceClass"] == "ipad")
    #expect(snapshot.analyticsMetadata["isVoiceOverRunning"] == "true")
    #expect(snapshot.analyticsMetadata["isSwitchControlRunning"] == "false")
    #expect(snapshot.analyticsMetadata["isBoldTextEnabled"] == "true")
    #expect(snapshot.analyticsMetadata["isReduceMotionEnabled"] == "false")
    #expect(snapshot.analyticsMetadata["isScreenCaptured"] == "true")
    #expect(snapshot.analyticsMetadata["isExternalDisplayConnected"] == "true")
    #expect(snapshot.analyticsMetadata["interfaceOrientation"] == "landscape")
}

@Test(.tags(.unit, .logging, .regression))
func mapsBootstrapReadyClientEnvironmentMetadata() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .appLifecycle,
        eventName: "app_bootstrap_ready",
        message: "Ready.",
        metadata: ClientEnvironmentSnapshot(
            deviceClass: "iphone",
            isVoiceOverRunning: true,
            isSwitchControlRunning: false,
            isBoldTextEnabled: false,
            isReduceMotionEnabled: false,
            isScreenCaptured: false,
            isExternalDisplayConnected: false,
            interfaceOrientation: "portrait"
        ).analyticsMetadata,
        correlationId: nil
    )

    let event = FirebaseAnalyticsEventMapping.map(entry, appVersion: "1.0.0")

    #expect(event?.name == "app_open")
    #expect(event?.parameters["deviceClass"] == "iphone")
    #expect(event?.parameters["isVoiceOverRunning"] == "true")
    #expect(event?.parameters["interfaceOrientation"] == "portrait")
}

@Test(.tags(.unit, .logging, .regression))
func mapsClientEnvironmentChangedEvent() {
    let entry = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .appLifecycle,
        eventName: "client_environment_changed",
        message: "Changed.",
        metadata: [
            "deviceClass": "iphone",
            "isVoiceOverRunning": "true",
            "trigger": "voiceover",
            "changedSignals": "voiceover"
        ],
        correlationId: nil
    )

    let event = FirebaseAnalyticsEventMapping.map(entry, appVersion: nil)

    #expect(event?.name == "client_environment_changed")
    #expect(event?.parameters["trigger"] == "voiceover")
    #expect(event?.parameters["isVoiceOverRunning"] == "true")
    #expect(event?.parameters["changedSignals"] == "voiceover")
}
