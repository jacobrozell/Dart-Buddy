import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .regression))
func clientEnvironmentSnapshotCurrentReturnsStableShape() {
    let snapshot = ClientEnvironmentSnapshot.current()
    #expect(["iphone", "ipad", "mac", "tv", "carplay", "vision", "unspecified"].contains(snapshot.deviceClass))
    #expect(["portrait", "landscape", "unknown"].contains(snapshot.interfaceOrientation))
    #expect(snapshot.analyticsMetadata.keys.contains("deviceClass"))
}

@Test(.tags(.unit, .regression))
func clientEnvironmentAccessorsMirrorSnapshot() {
    let snapshot = ClientEnvironment.snapshot
    #expect(ClientEnvironment.isVoiceOverRunning == snapshot.isVoiceOverRunning)
    #expect(ClientEnvironment.isScreenCaptured == snapshot.isScreenCaptured)
    #expect(ClientEnvironment.isExternalDisplayConnected == snapshot.isExternalDisplayConnected)
    if snapshot.deviceClass == "ipad" {
        #expect(ClientEnvironment.isPad)
        #expect(!ClientEnvironment.isPhone)
    } else if snapshot.deviceClass == "iphone" {
        #expect(ClientEnvironment.isPhone)
        #expect(!ClientEnvironment.isPad)
    }
}

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

@Test(.tags(.unit, .logging, .regression, .critical))
func loggerPreservesClientEnvironmentMetadataThroughRedaction() {
    let sink = ClientEnvironmentRecordingSink()
    let logger = DefaultAppLogger(minimumLevel: .info, sink: sink)

    logger.info(
        .appLifecycle,
        eventName: "app_bootstrap_ready",
        message: "Ready.",
        metadata: ClientEnvironmentSnapshot(
            deviceClass: "ipad",
            isVoiceOverRunning: true,
            isSwitchControlRunning: false,
            isBoldTextEnabled: false,
            isReduceMotionEnabled: false,
            isScreenCaptured: false,
            isExternalDisplayConnected: true,
            interfaceOrientation: "landscape"
        ).analyticsMetadata
    )

    #expect(sink.entries.count == 1)
    #expect(sink.entries.first?.metadata["deviceClass"] == "ipad")
    #expect(sink.entries.first?.metadata["isVoiceOverRunning"] == "true")
    #expect(sink.entries.first?.metadata["isExternalDisplayConnected"] == "true")

    let firebaseEvent = FirebaseAnalyticsEventMapping.map(sink.entries[0], appVersion: "1.0.0")
    #expect(firebaseEvent?.name == "app_open")
    #expect(firebaseEvent?.parameters["deviceClass"] == "ipad")
    #expect(firebaseEvent?.parameters["isVoiceOverRunning"] == "true")
}

@Test(.tags(.unit, .regression))
func clientEnvironmentChangedSignalsIncludesOrientation() {
    let portrait = ClientEnvironmentSnapshot(
        deviceClass: "iphone",
        isVoiceOverRunning: false,
        isSwitchControlRunning: false,
        isBoldTextEnabled: false,
        isReduceMotionEnabled: false,
        isScreenCaptured: false,
        isExternalDisplayConnected: false,
        interfaceOrientation: "portrait"
    )
    let landscape = ClientEnvironmentSnapshot(
        deviceClass: "iphone",
        isVoiceOverRunning: false,
        isSwitchControlRunning: false,
        isBoldTextEnabled: false,
        isReduceMotionEnabled: false,
        isScreenCaptured: false,
        isExternalDisplayConnected: false,
        interfaceOrientation: "landscape"
    )

    #expect(ClientEnvironmentSnapshot.changedSignals(from: portrait, to: landscape) == "orientation")
    #expect(ClientEnvironmentSnapshot.changedSignals(from: landscape, to: portrait) == "orientation")
}

@Test(.tags(.unit, .regression))
func clientEnvironmentChangedSignalsCombinesMultipleChanges() {
    let before = ClientEnvironmentSnapshot(
        deviceClass: "iphone",
        isVoiceOverRunning: false,
        isSwitchControlRunning: false,
        isBoldTextEnabled: false,
        isReduceMotionEnabled: false,
        isScreenCaptured: false,
        isExternalDisplayConnected: false,
        interfaceOrientation: "portrait"
    )
    let after = ClientEnvironmentSnapshot(
        deviceClass: "iphone",
        isVoiceOverRunning: true,
        isSwitchControlRunning: false,
        isBoldTextEnabled: false,
        isReduceMotionEnabled: false,
        isScreenCaptured: false,
        isExternalDisplayConnected: false,
        interfaceOrientation: "landscape"
    )

    #expect(ClientEnvironmentSnapshot.changedSignals(from: before, to: after) == "voiceover,orientation")
}

@Test(.tags(.unit, .logging, .regression, .critical))
func clientEnvironmentMetadataKeysAreAllowlistedForRedactionAndFirebase() {
    let metadata = ClientEnvironmentSnapshot(
        deviceClass: "ipad",
        isVoiceOverRunning: true,
        isSwitchControlRunning: false,
        isBoldTextEnabled: false,
        isReduceMotionEnabled: false,
        isScreenCaptured: false,
        isExternalDisplayConnected: true,
        interfaceOrientation: "landscape"
    ).analyticsMetadata

    for key in AnalyticsMetadataKeys.clientEnvironment where key != "trigger" && key != "changedSignals" {
        #expect(metadata.keys.contains(key))
    }

    let redacted = DefaultRedactionPolicy().redact(metadata: metadata)
    for key in metadata.keys {
        #expect(redacted[key] == metadata[key])
    }

    let entry = LogEntry(
        timestamp: Date(),
        level: .info,
        category: .appLifecycle,
        eventName: "client_environment_changed",
        message: "Changed.",
        metadata: metadata.merging(["trigger": "orientation", "changedSignals": "orientation"]) { _, new in new },
        correlationId: nil
    )
    let event = FirebaseAnalyticsEventMapping.map(entry, appVersion: nil)
    #expect(event?.parameters["interfaceOrientation"] == "landscape")
    #expect(event?.parameters["trigger"] == "orientation")
}

@Test(.tags(.unit, .regression))
func clientEnvironmentChangedSignalsDetectsEachField() {
    let base = ClientEnvironmentSnapshot(
        deviceClass: "iphone",
        isVoiceOverRunning: false,
        isSwitchControlRunning: false,
        isBoldTextEnabled: false,
        isReduceMotionEnabled: false,
        isScreenCaptured: false,
        isExternalDisplayConnected: false,
        interfaceOrientation: "portrait"
    )

    let voiceOver = ClientEnvironmentSnapshot(
        deviceClass: base.deviceClass,
        isVoiceOverRunning: true,
        isSwitchControlRunning: base.isSwitchControlRunning,
        isBoldTextEnabled: base.isBoldTextEnabled,
        isReduceMotionEnabled: base.isReduceMotionEnabled,
        isScreenCaptured: base.isScreenCaptured,
        isExternalDisplayConnected: base.isExternalDisplayConnected,
        interfaceOrientation: base.interfaceOrientation
    )
    #expect(ClientEnvironmentSnapshot.changedSignals(from: base, to: voiceOver) == "voiceover")

    let switchControl = ClientEnvironmentSnapshot(
        deviceClass: base.deviceClass,
        isVoiceOverRunning: base.isVoiceOverRunning,
        isSwitchControlRunning: true,
        isBoldTextEnabled: base.isBoldTextEnabled,
        isReduceMotionEnabled: base.isReduceMotionEnabled,
        isScreenCaptured: base.isScreenCaptured,
        isExternalDisplayConnected: base.isExternalDisplayConnected,
        interfaceOrientation: base.interfaceOrientation
    )
    #expect(ClientEnvironmentSnapshot.changedSignals(from: base, to: switchControl) == "switchControl")

    let boldText = ClientEnvironmentSnapshot(
        deviceClass: base.deviceClass,
        isVoiceOverRunning: base.isVoiceOverRunning,
        isSwitchControlRunning: base.isSwitchControlRunning,
        isBoldTextEnabled: true,
        isReduceMotionEnabled: base.isReduceMotionEnabled,
        isScreenCaptured: base.isScreenCaptured,
        isExternalDisplayConnected: base.isExternalDisplayConnected,
        interfaceOrientation: base.interfaceOrientation
    )
    #expect(ClientEnvironmentSnapshot.changedSignals(from: base, to: boldText) == "boldText")

    let reduceMotion = ClientEnvironmentSnapshot(
        deviceClass: base.deviceClass,
        isVoiceOverRunning: base.isVoiceOverRunning,
        isSwitchControlRunning: base.isSwitchControlRunning,
        isBoldTextEnabled: base.isBoldTextEnabled,
        isReduceMotionEnabled: true,
        isScreenCaptured: base.isScreenCaptured,
        isExternalDisplayConnected: base.isExternalDisplayConnected,
        interfaceOrientation: base.interfaceOrientation
    )
    #expect(ClientEnvironmentSnapshot.changedSignals(from: base, to: reduceMotion) == "reduceMotion")

    let screenCapture = ClientEnvironmentSnapshot(
        deviceClass: base.deviceClass,
        isVoiceOverRunning: base.isVoiceOverRunning,
        isSwitchControlRunning: base.isSwitchControlRunning,
        isBoldTextEnabled: base.isBoldTextEnabled,
        isReduceMotionEnabled: base.isReduceMotionEnabled,
        isScreenCaptured: true,
        isExternalDisplayConnected: base.isExternalDisplayConnected,
        interfaceOrientation: base.interfaceOrientation
    )
    #expect(ClientEnvironmentSnapshot.changedSignals(from: base, to: screenCapture) == "screenCapture")

    let display = ClientEnvironmentSnapshot(
        deviceClass: base.deviceClass,
        isVoiceOverRunning: base.isVoiceOverRunning,
        isSwitchControlRunning: base.isSwitchControlRunning,
        isBoldTextEnabled: base.isBoldTextEnabled,
        isReduceMotionEnabled: base.isReduceMotionEnabled,
        isScreenCaptured: base.isScreenCaptured,
        isExternalDisplayConnected: true,
        interfaceOrientation: base.interfaceOrientation
    )
    #expect(ClientEnvironmentSnapshot.changedSignals(from: base, to: display) == "display")

    let deviceClass = ClientEnvironmentSnapshot(
        deviceClass: "ipad",
        isVoiceOverRunning: base.isVoiceOverRunning,
        isSwitchControlRunning: base.isSwitchControlRunning,
        isBoldTextEnabled: base.isBoldTextEnabled,
        isReduceMotionEnabled: base.isReduceMotionEnabled,
        isScreenCaptured: base.isScreenCaptured,
        isExternalDisplayConnected: base.isExternalDisplayConnected,
        interfaceOrientation: base.interfaceOrientation
    )
    #expect(ClientEnvironmentSnapshot.changedSignals(from: base, to: deviceClass) == "deviceClass")
}

@Test(.tags(.unit, .regression))
func clientEnvironmentChangedSignalsReturnsEmptyWhenUnchanged() {
    let snapshot = ClientEnvironmentSnapshot(
        deviceClass: "iphone",
        isVoiceOverRunning: false,
        isSwitchControlRunning: false,
        isBoldTextEnabled: false,
        isReduceMotionEnabled: false,
        isScreenCaptured: false,
        isExternalDisplayConnected: false,
        interfaceOrientation: "portrait"
    )
    #expect(ClientEnvironmentSnapshot.changedSignals(from: snapshot, to: snapshot).isEmpty)
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

private final class ClientEnvironmentRecordingSink: LogSink, @unchecked Sendable {
    var entries: [LogEntry] = []

    func write(_ entry: LogEntry) {
        entries.append(entry)
    }
}
