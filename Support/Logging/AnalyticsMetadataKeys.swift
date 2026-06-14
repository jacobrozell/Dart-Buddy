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

    private static let botRoster: Set<String> = [
        "hasBot",
        "botCount",
        "humanCount",
        "botDifficulty",
        "botDifficulties",
        "botKind",
        "botKinds",
        "botEffectiveTier",
        "botEffectiveTiers"
    ]

    private static let gameMode: Set<String> = [
        "gameModeId",
        "gameModeSection",
        "uiTemplate",
        "statKind"
    ]

    private static let matchEntry: Set<String> = [
        "startSource"
    ]

    private static let matchConfig: Set<String> = [
        "configStartScore",
        "configCheckoutMode",
        "configCheckInMode",
        "configLegFormat",
        "configSetsEnabled",
        "configPointsEnabled",
        "configScoringMode",
        "configInningCount",
        "configTieBreaker",
        "configSeventhInningStretch",
        "configStartingLives",
        "configRoundCount",
        "configBonusRule",
        "configWicketsPerInnings",
        "configEndWhenTargetPassed",
        "configStrikesToEliminate",
        "configVisitsPerRound",
        "configEliminationRule",
        "configTargetPoints",
        "configMustFinishExact",
        "configCourseLength",
        "configGoalsToWin",
        "configKickoffMode",
        "configRuleset",
        "configLaps",
        "configHoundStart",
        "configIncludeBullFinish",
        "configResetPolicy",
        "configParScoreEnabled",
        "configParScore",
        "configShipCount",
        "configSonarEnabled",
        "configHandoffEachTurn",
        "configBossTier",
        "configHeroHearts",
        "configEnrageEnabled"
    ]

    private static let onboarding: Set<String> = [
        "skipped",
        "bot_tier",
        "created_player"
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

    private static let generalFirebase: Set<String> = gameMode
        .union(botRoster)
        .union(matchEntry)
        .union(matchConfig)
        .union(onboarding)
        .union([
        "matchType",
        "errorCode",
        "layer",
        "status",
        "participantCount",
        "participant_count",
        "event_count",
        "resolution",
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
    ])

    public static let defaultRedactionAllowed: Set<String> = generalRedaction
        .union(gameMode)
        .union(botRoster)
        .union(matchEntry)
        .union(matchConfig)
        .union(onboarding)
        .union(clientEnvironment)

    public static let firebaseParameters: Set<String> = generalFirebase.union(clientEnvironment)
}
