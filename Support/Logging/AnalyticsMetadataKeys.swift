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

    /// Keys that must never reach analytics sinks, even if accidentally allowlisted.
    private static let blockedPersonalDataKeys: Set<String> = [
        "playerId",
        "playerName",
        "displayName",
        "displayNameAtMatchStart",
        "botName",
        "userName",
        "linkedPlayerId",
        "forfeited_by_player_id",
        "winner_player_id",
        "notes"
    ]

    /// Substrings matched against lowercased metadata keys to catch name-like fields.
    private static let blockedPersonalDataKeyFragments: [String] = [
        "playername",
        "displayname",
        "botname",
        "username",
        "profilename",
        "linkedplayer",
        "participantname",
        "rostername"
    ]

    public static func isBlockedPersonalDataKey(_ key: String) -> Bool {
        if blockedPersonalDataKeys.contains(key) {
            return true
        }
        let lowercased = key.lowercased()
        return blockedPersonalDataKeyFragments.contains { lowercased.contains($0) }
    }

    public static func withoutPersonalData(_ metadata: [String: String]) -> [String: String] {
        metadata.filter { !isBlockedPersonalDataKey($0.key) }
    }

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
        "durationSeconds",
        "resolution",
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
        "eventCount",
        "durationSeconds",
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

    public static let crashlyticsParameters: Set<String> = [
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
        "isBot"
    ]
}
