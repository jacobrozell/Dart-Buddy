import Foundation
import SwiftData

// Shared mapping helpers and the throwing-call wrapper used by the SwiftData repositories.
// Module-internal so each repository file can reuse them.

func historyMatchPredicate(
    filter: MatchHistoryFilter,
    completedRaw: String,
    forfeitedRaw: String,
    restrictedToMatchIds matchIds: [UUID]?
) -> Predicate<SchemaV1.MatchRecord> {
    let allowedTypeRaws: [String]?
    if let matchType = filter.matchType {
        allowedTypeRaws = [matchType.rawValue]
    } else if let included = filter.includedMatchTypes, !included.isEmpty {
        allowedTypeRaws = included.map(\.rawValue)
    } else {
        allowedTypeRaws = nil
    }

    let startedAfter = filter.startedAfter

    switch (allowedTypeRaws, startedAfter, matchIds) {
    case (nil, nil, nil):
        return #Predicate<SchemaV1.MatchRecord> {
            $0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw
        }
    case (nil, nil, let ids?):
        return #Predicate<SchemaV1.MatchRecord> {
            ($0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw) && ids.contains($0.id)
        }
    case (nil, let startedAfter?, nil):
        return #Predicate<SchemaV1.MatchRecord> {
            ($0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw) && $0.startedAt >= startedAfter
        }
    case (nil, let startedAfter?, let ids?):
        return #Predicate<SchemaV1.MatchRecord> {
            ($0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw) && $0.startedAt >= startedAfter && ids.contains($0.id)
        }
    case (let typeRaws?, nil, nil):
        return #Predicate<SchemaV1.MatchRecord> {
            ($0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw) && typeRaws.contains($0.typeRaw)
        }
    case (let typeRaws?, nil, let ids?):
        return #Predicate<SchemaV1.MatchRecord> {
            ($0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw) && typeRaws.contains($0.typeRaw) && ids.contains($0.id)
        }
    case (let typeRaws?, let startedAfter?, nil):
        return #Predicate<SchemaV1.MatchRecord> {
            ($0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw) && typeRaws.contains($0.typeRaw) && $0.startedAt >= startedAfter
        }
    case (let typeRaws?, let startedAfter?, let ids?):
        return #Predicate<SchemaV1.MatchRecord> {
            ($0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw) && typeRaws.contains($0.typeRaw) && $0.startedAt >= startedAfter && ids.contains($0.id)
        }
    }
}

func finishedHistoryPredicate(completedRaw: String, forfeitedRaw: String) -> Predicate<SchemaV1.MatchRecord> {
    #Predicate<SchemaV1.MatchRecord> {
        $0.statusRaw == completedRaw || $0.statusRaw == forfeitedRaw
    }
}

func mapPlayer(_ record: SchemaV1.PlayerRecord) -> PlayerSummary {
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

func mapMatch(_ record: SchemaV1.MatchRecord) -> MatchSummary {
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

func mapEvent(_ record: SchemaV1.MatchEventRecord) -> MatchEventSummary {
    MatchEventSummary(
        id: record.id,
        matchId: record.matchId,
        eventIndex: record.eventIndex,
        eventTypeRaw: record.eventTypeRaw,
        eventPayload: record.eventPayload,
        createdAt: record.createdAt
    )
}

func mapSnapshot(_ record: SchemaV1.MatchSnapshotRecord) -> MatchSnapshotSummary {
    MatchSnapshotSummary(
        id: record.id,
        matchId: record.matchId,
        snapshotVersion: record.snapshotVersion,
        snapshotPayload: record.snapshotPayload,
        updatedAt: record.updatedAt
    )
}

func mapSettings(_ record: SchemaV1.SettingsRecord) -> SettingsSummary {
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
        defaultDartEntryPresentationRaw: record.defaultDartEntryPresentationRaw ?? "numberPad",
        updatedAt: record.updatedAt
    )
}

func mapParticipant(_ record: SchemaV1.MatchParticipantRecord) -> MatchParticipantSummary {
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
