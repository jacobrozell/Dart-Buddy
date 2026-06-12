import Foundation
import SwiftData

// Shared mapping helpers and the throwing-call wrapper used by the SwiftData repositories.
// Module-internal so each repository file can reuse them.

func historyMatchPredicate(
    filter: MatchHistoryFilter,
    completedRaw: String,
    forfeitedRaw: String,
    restrictedToMatchIds matchIds: [UUID]?
) -> Predicate<SchemaV3.MatchRecord> {
    switch (filter.matchType, filter.startedAfter, matchIds) {
    case (nil, nil, nil):
        return #Predicate<SchemaV3.MatchRecord> {
            $0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw
        }
    case (nil, nil, let ids?):
        return #Predicate<SchemaV3.MatchRecord> {
            ($0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw) && ids.contains($0.id)
        }
    case (let type?, nil, nil):
        let typeRaw = type.rawValue
        return #Predicate<SchemaV3.MatchRecord> {
            ($0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw) && $0.typeRaw == typeRaw
        }
    case (let type?, nil, let ids?):
        let typeRaw = type.rawValue
        return #Predicate<SchemaV3.MatchRecord> {
            ($0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw) && $0.typeRaw == typeRaw && ids.contains($0.id)
        }
    case (nil, let startedAfter?, nil):
        return #Predicate<SchemaV3.MatchRecord> {
            ($0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw) && $0.startedAt >= startedAfter
        }
    case (nil, let startedAfter?, let ids?):
        return #Predicate<SchemaV3.MatchRecord> {
            ($0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw) && $0.startedAt >= startedAfter && ids.contains($0.id)
        }
    case (let type?, let startedAfter?, nil):
        let typeRaw = type.rawValue
        return #Predicate<SchemaV3.MatchRecord> {
            ($0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw) && $0.typeRaw == typeRaw && $0.startedAt >= startedAfter
        }
    case (let type?, let startedAfter?, let ids?):
        let typeRaw = type.rawValue
        return #Predicate<SchemaV3.MatchRecord> {
            ($0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw) && $0.typeRaw == typeRaw && $0.startedAt >= startedAfter && ids.contains($0.id)
        }
    }
}

func finishedHistoryPredicate(completedRaw: String, forfeitedRaw: String) -> Predicate<SchemaV3.MatchRecord> {
    #Predicate<SchemaV3.MatchRecord> {
        $0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw
    }
}

func mapPlayer(_ record: SchemaV3.PlayerRecord) -> PlayerSummary {
    let isBot = record.isBot ?? false
    let botKind: String?
    if let rawKind = record.botKindRaw {
        botKind = rawKind
    } else if isBot, CustomBotConfigurationCodec.decode(botDifficultyRaw: record.botDifficultyRaw) != nil {
        botKind = BotKind.custom.rawValue
    } else if isBot, record.botDifficultyRaw != nil {
        botKind = BotKind.preset.rawValue
    } else {
        botKind = nil
    }
    return PlayerSummary(
        id: record.id,
        name: record.name,
        isArchived: record.isArchived,
        isBot: isBot,
        botDifficultyRaw: record.botDifficultyRaw,
        botKindRaw: botKind,
        linkedPlayerId: record.linkedPlayerId,
        avatarStyleRaw: record.avatarStyleRaw,
        preferredColorToken: record.preferredColorToken,
        notes: record.notes,
        playerRoleRaw: record.playerRoleRaw,
        createdAt: record.createdAt,
        updatedAt: record.updatedAt
    )
}

func mapMatch(_ record: SchemaV3.MatchRecord) -> MatchSummary {
    MatchSummary(
        id: record.id,
        type: MatchType(rawValue: record.typeRaw) ?? .x01,
        status: MatchStatus(rawValue: record.statusRaw) ?? .notStarted,
        startedAt: record.startedAt,
        endedAt: record.endedAt,
        winnerPlayerId: record.winnerPlayerId,
        forfeitedByPlayerId: record.forfeitedByPlayerId,
        currentTurnPlayerId: record.currentTurnPlayerId,
        currentLegIndex: record.currentLegIndex,
        currentSetIndex: record.currentSetIndex,
        eventCount: record.eventCount,
        isCampaignMatch: record.isCampaignMatch ?? false,
        campaignStageId: record.campaignStageId,
        createdAt: record.createdAt,
        updatedAt: record.updatedAt
    )
}

func mapEvent(_ record: SchemaV3.MatchEventRecord) -> MatchEventSummary {
    MatchEventSummary(
        id: record.id,
        matchId: record.matchId,
        eventIndex: record.eventIndex,
        eventTypeRaw: record.eventTypeRaw,
        eventPayload: record.eventPayload,
        createdAt: record.createdAt
    )
}

func mapSnapshot(_ record: SchemaV3.MatchSnapshotRecord) -> MatchSnapshotSummary {
    MatchSnapshotSummary(
        id: record.id,
        matchId: record.matchId,
        snapshotVersion: record.snapshotVersion,
        snapshotPayload: record.snapshotPayload,
        updatedAt: record.updatedAt
    )
}

func mapSettings(_ record: SchemaV3.SettingsRecord) -> SettingsSummary {
    SettingsSummary(
        id: record.id,
        appearanceModeRaw: record.appearanceModeRaw,
        hapticsEnabled: record.hapticsEnabled,
        soundEnabled: record.soundEnabled,
        turnTotalCallerEnabled: record.turnTotalCallerEnabled,
        defaultMatchTypeRaw: record.defaultMatchTypeRaw,
        defaultX01StartScore: record.defaultX01StartScore,
        defaultCheckoutModeRaw: record.defaultCheckoutModeRaw,
        defaultCheckInModeRaw: record.defaultCheckInModeRaw.isEmpty ? "straightIn" : record.defaultCheckInModeRaw,
        defaultLegFormatRaw: record.defaultLegFormatRaw.isEmpty ? "firstTo" : record.defaultLegFormatRaw,
        defaultLegsToWin: record.defaultLegsToWin,
        defaultSetsEnabled: record.defaultSetsEnabled,
        botStaggerEnabled: record.botStaggerEnabled ?? true,
        botDartHapticsEnabled: record.botDartHapticsEnabled ?? true,
        updatedAt: record.updatedAt
    )
}

func mapParticipant(_ record: SchemaV3.MatchParticipantRecord) -> MatchParticipantSummary {
    MatchParticipantSummary(
        id: record.id,
        matchId: record.matchId,
        playerId: record.playerId,
        turnOrder: record.turnOrder,
        displayNameAtMatchStart: record.displayNameAtMatchStart,
        avatarStyleAtMatchStart: record.avatarStyleAtMatchStart,
        botDifficultyRaw: record.botDifficultyRaw,
        botKindRaw: record.botKindRaw,
        botSkillProfilePayload: record.botSkillProfilePayload,
        botEffectiveTierRaw: record.botEffectiveTierRaw
    )
}

func dataCall<T>(_ block: () throws -> T) throws -> T {
    do {
        return try block()
    } catch let error as AppError {
        throw error
    } catch {
        throw AppError(
            code: .storageUnavailable,
            layer: .data,
            severity: .error,
            isRecoverable: true,
            userMessageKey: "error.repository.storage",
            underlyingError: error
        )
    }
}
