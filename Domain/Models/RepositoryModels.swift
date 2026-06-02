import Foundation

public enum MatchType: String, Codable, Sendable {
    case x01
    case cricket
}

public enum MatchStatus: String, Codable, Sendable {
    case notStarted
    case inProgress
    case completed
    case abandoned
}

public struct MatchHistoryFilter: Equatable, Sendable {
    public var matchType: MatchType?
    public var startedAfter: Date?
    public var participantPlayerId: UUID?

    public init(matchType: MatchType? = nil, startedAfter: Date? = nil, participantPlayerId: UUID? = nil) {
        self.matchType = matchType
        self.startedAfter = startedAfter
        self.participantPlayerId = participantPlayerId
    }
}

public struct PlayerSummary: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let isArchived: Bool
    public let isBot: Bool
    public let botDifficultyRaw: String?
    public let avatarStyleRaw: String?
    public let preferredColorToken: String?
    public let notes: String?
    public let createdAt: Date
    public let updatedAt: Date

    public var botDifficulty: BotDifficulty? {
        botDifficultyRaw.flatMap(BotDifficulty.init(rawValue:))
    }

    public var avatarStyle: PlayerAvatarStyle {
        if let avatarStyleRaw { return PlayerAvatarStyle.resolved(raw: avatarStyleRaw) }
        return PlayerAvatarStyle.defaultForPlayer(id: id, isBot: isBot)
    }

    public var colorToken: PlayerColorToken {
        if let preferredColorToken { return PlayerColorToken.resolved(raw: preferredColorToken) }
        return PlayerColorToken.defaultForPlayer(id: id)
    }

    public init(
        id: UUID,
        name: String,
        isArchived: Bool,
        isBot: Bool = false,
        botDifficultyRaw: String? = nil,
        avatarStyleRaw: String? = nil,
        preferredColorToken: String? = nil,
        notes: String? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.isArchived = isArchived
        self.isBot = isBot
        self.botDifficultyRaw = botDifficultyRaw
        self.avatarStyleRaw = avatarStyleRaw
        self.preferredColorToken = preferredColorToken
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct MatchParticipantSummary: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let matchId: UUID
    public let playerId: UUID?
    public let turnOrder: Int
    public let displayNameAtMatchStart: String
    public let avatarStyleAtMatchStart: String?
    public let botDifficultyRaw: String?

    public init(
        id: UUID,
        matchId: UUID,
        playerId: UUID?,
        turnOrder: Int,
        displayNameAtMatchStart: String,
        avatarStyleAtMatchStart: String? = nil,
        botDifficultyRaw: String? = nil
    ) {
        self.id = id
        self.matchId = matchId
        self.playerId = playerId
        self.turnOrder = turnOrder
        self.displayNameAtMatchStart = displayNameAtMatchStart
        self.avatarStyleAtMatchStart = avatarStyleAtMatchStart
        self.botDifficultyRaw = botDifficultyRaw
    }
}

public struct MatchSummary: Identifiable, Equatable, Sendable {
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
}

public struct MatchEventSummary: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let matchId: UUID
    public let eventIndex: Int
    public let eventTypeRaw: String
    public let eventPayload: Data
    public let createdAt: Date
}

public struct MatchSnapshotSummary: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let matchId: UUID
    public let snapshotVersion: Int
    public let snapshotPayload: Data
    public let updatedAt: Date
}

public struct SettingsSummary: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let appearanceModeRaw: String
    public let hapticsEnabled: Bool
    public let soundEnabled: Bool
    public let turnTotalCallerEnabled: Bool
    public let defaultMatchTypeRaw: String
    public let defaultX01StartScore: Int
    public let defaultCheckoutModeRaw: String
    public let defaultCheckInModeRaw: String
    public let defaultLegFormatRaw: String
    public let defaultLegsToWin: Int
    public let defaultSetsEnabled: Bool
    public let botStaggerEnabled: Bool
    public let botDartHapticsEnabled: Bool
    public let updatedAt: Date
}
