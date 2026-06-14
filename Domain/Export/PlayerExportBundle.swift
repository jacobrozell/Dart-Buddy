import Foundation

public struct PlayerExportBundle: Codable, Sendable, Equatable {
    public static let supportedVersion = 1

    public let dbpeVersion: Int
    public let producer: String
    public let producerVersion: String
    public let exportedAt: Date
    public let persistenceSchemaVersion: String
    public let anchorPlayerId: UUID
    public let player: PlayerExportRecord
    public let referencedPlayers: [PlayerExportRecord]
    public let matches: [MatchExportBundle]
}

public struct PlayerExportRecord: Codable, Sendable, Equatable {
    public let id: UUID
    public let name: String
    public let isArchived: Bool
    public let isBot: Bool
    public let botDifficultyRaw: String?
    public let botKindRaw: String?
    public let linkedPlayerId: UUID?
    public let avatarStyleRaw: String?
    public let preferredColorToken: String?
    public let notes: String?
    public let createdAt: Date
    public let updatedAt: Date

    public init(from summary: PlayerSummary) {
        id = summary.id
        name = summary.name
        isArchived = summary.isArchived
        isBot = summary.isBot
        botDifficultyRaw = summary.botDifficultyRaw
        botKindRaw = summary.botKindRaw
        linkedPlayerId = summary.linkedPlayerId
        avatarStyleRaw = summary.avatarStyleRaw
        preferredColorToken = summary.preferredColorToken
        notes = summary.notes
        createdAt = summary.createdAt
        updatedAt = summary.updatedAt
    }
}

public struct MatchExportBundle: Codable, Sendable, Equatable {
    public let match: MatchExportRecord
    public let configPayload: Data?
    public let participants: [MatchParticipantExportRecord]
    public let events: [MatchEventExportRecord]
    public let snapshot: MatchSnapshotExportRecord?
}

public struct MatchExportRecord: Codable, Sendable, Equatable {
    public let id: UUID
    public let type: MatchType
    public let status: MatchStatus
    public let startedAt: Date
    public let endedAt: Date?
    public let winnerPlayerId: UUID?
    public let currentTurnPlayerId: UUID?
    public let currentLegIndex: Int
    public let currentSetIndex: Int
    public let eventCount: Int
    public let createdAt: Date
    public let updatedAt: Date

    public init(from summary: MatchSummary) {
        id = summary.id
        type = summary.type
        status = summary.status
        startedAt = summary.startedAt
        endedAt = summary.endedAt
        winnerPlayerId = summary.winnerPlayerId
        currentTurnPlayerId = summary.currentTurnPlayerId
        currentLegIndex = summary.currentLegIndex
        currentSetIndex = summary.currentSetIndex
        eventCount = summary.eventCount
        createdAt = summary.createdAt
        updatedAt = summary.updatedAt
    }
}

public struct MatchParticipantExportRecord: Codable, Sendable, Equatable {
    public let id: UUID
    public let matchId: UUID
    public let playerId: UUID?
    public let turnOrder: Int
    public let displayNameAtMatchStart: String
    public let avatarStyleAtMatchStart: String?
    public let botDifficultyRaw: String?
    public let botKindRaw: String?
    public let botSkillProfilePayload: Data?
    public let botEffectiveTierRaw: String?

    public init(from summary: MatchParticipantSummary) {
        id = summary.id
        matchId = summary.matchId
        playerId = summary.playerId
        turnOrder = summary.turnOrder
        displayNameAtMatchStart = summary.displayNameAtMatchStart
        avatarStyleAtMatchStart = summary.avatarStyleAtMatchStart
        botDifficultyRaw = summary.botDifficultyRaw
        botKindRaw = summary.botKindRaw
        botSkillProfilePayload = summary.botSkillProfilePayload
        botEffectiveTierRaw = summary.botEffectiveTierRaw
    }
}

public struct MatchEventExportRecord: Codable, Sendable, Equatable {
    public let id: UUID
    public let matchId: UUID
    public let eventIndex: Int
    public let eventTypeRaw: String
    public let eventPayload: Data
    public let createdAt: Date

    public init(from summary: MatchEventSummary) {
        id = summary.id
        matchId = summary.matchId
        eventIndex = summary.eventIndex
        eventTypeRaw = summary.eventTypeRaw
        eventPayload = summary.eventPayload
        createdAt = summary.createdAt
    }
}

public struct MatchSnapshotExportRecord: Codable, Sendable, Equatable {
    public let id: UUID
    public let matchId: UUID
    public let snapshotVersion: Int
    public let snapshotPayload: Data
    public let updatedAt: Date

    public init(from summary: MatchSnapshotSummary) {
        id = summary.id
        matchId = summary.matchId
        snapshotVersion = summary.snapshotVersion
        snapshotPayload = summary.snapshotPayload
        updatedAt = summary.updatedAt
    }
}

public enum PlayerExportBundleCoding {
    private static func normalizedExportDate(_ date: Date) -> Date {
        let milliseconds = (date.timeIntervalSince1970 * 1_000).rounded() / 1_000
        return Date(timeIntervalSince1970: milliseconds)
    }

    public static func encode(_ bundle: PlayerExportBundle) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            var container = encoder.singleValueContainer()
            let normalized = normalizedExportDate(date)
            try container.encode(formatter.string(from: normalized))
        }
        return try encoder.encode(bundle)
    }

    public static func decode(_ data: Data) throws -> PlayerExportBundle {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let fractionalISO8601 = ISO8601DateFormatter()
            fractionalISO8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let wholeSecondISO8601 = ISO8601DateFormatter()
            wholeSecondISO8601.formatOptions = [.withInternetDateTime]
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            if let date = fractionalISO8601.date(from: string) {
                return normalizedExportDate(date)
            }
            if let date = wholeSecondISO8601.date(from: string) {
                return normalizedExportDate(date)
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid ISO8601 date: \(string)"
            )
        }
        return try decoder.decode(PlayerExportBundle.self, from: data)
    }
}
