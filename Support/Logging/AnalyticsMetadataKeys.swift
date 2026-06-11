import Foundation

/// Shared allowlists for log metadata that must survive redaction and reach Firebase Analytics.
public enum AnalyticsMetadataKeys {
    /// Keys emitted by `ClientEnvironmentSnapshot.analyticsMetadata` plus change-event fields.
    public static let clientEnvironment: Set<String> = [
        "deviceClass",
        "isVoiceOverRunning",
        "isSwitchControlRunning",
        "isBoldTextEnabled",
        "isReduceMotionEnabled",
        "isScreenCaptured",
        "isExternalDisplayConnected",
        "interfaceOrientation",
        "trigger",
        "changedSignals"
    ]

    private static let generalRedaction: Set<String> = [
        "errorCode",
        "layer",
        "matchId",
        "matchType",
        "playerId",
        "settingsId",
        "schemaVersion",
        "fromSchema",
        "toSchema",
        "correlationId",
        "operation",
        "elapsedMs",
        "participantCount",
        "eventCount",
        "legIndex",
        "setIndex",
        "status",
        "source",
        "isBot",
        "path",
        "version",
        "intentName"
    ]

    private static let generalFirebase: Set<String> = [
        "matchType",
        "errorCode",
        "layer",
        "status",
        "participantCount",
        "operation",
        "schemaVersion",
        "fromSchema",
        "toSchema",
        "legIndex",
        "setIndex",
        "source",
        "isBot",
        "path",
        "version",
        "intentName"
    ]

    public static let defaultRedactionAllowed: Set<String> = generalRedaction.union(clientEnvironment)

    public static let firebaseParameters: Set<String> = generalFirebase.union(clientEnvironment)
}
