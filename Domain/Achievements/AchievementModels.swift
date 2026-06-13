import Foundation

public enum AchievementDeltaKind: String, Sendable {
    case unlock
    case progressUpdate
    case revoke
}

public struct AchievementDelta: Equatable, Sendable {
    public let playerId: UUID
    public let achievementId: String
    public let kind: AchievementDeltaKind
    public let progressPercent: Int?
    public let unlockedAt: Date?

    public init(
        playerId: UUID,
        achievementId: String,
        kind: AchievementDeltaKind,
        progressPercent: Int? = nil,
        unlockedAt: Date? = nil
    ) {
        self.playerId = playerId
        self.achievementId = achievementId
        self.kind = kind
        self.progressPercent = progressPercent
        self.unlockedAt = unlockedAt
    }
}

public struct PlayerAchievementProgress: Equatable, Sendable {
    public let achievementId: String
    public let unlockedAt: Date?
    public let progressPercent: Int
    public let sourceMatchId: UUID?

    public var isUnlocked: Bool { unlockedAt != nil }

    public init(
        achievementId: String,
        unlockedAt: Date? = nil,
        progressPercent: Int = 0,
        sourceMatchId: UUID? = nil
    ) {
        self.achievementId = achievementId
        self.unlockedAt = unlockedAt
        self.progressPercent = progressPercent
        self.sourceMatchId = sourceMatchId
    }
}

public struct AchievementLifetimeCounters: Equatable, Sendable {
    public var completedMatchesPlayed: Int
    public var matchWins: Int
    public var hasHitT20: Bool
    public var legsWon: Int
    public var lifetime180Visits: Int
    public var consecutiveMatchWins: Int
    public var consecutiveCalendarDaysPlayed: Int
    public var lastPlayedCalendarDay: DateComponents?

    public init(
        completedMatchesPlayed: Int = 0,
        matchWins: Int = 0,
        hasHitT20: Bool = false,
        legsWon: Int = 0,
        lifetime180Visits: Int = 0,
        consecutiveMatchWins: Int = 0,
        consecutiveCalendarDaysPlayed: Int = 0,
        lastPlayedCalendarDay: DateComponents? = nil
    ) {
        self.completedMatchesPlayed = completedMatchesPlayed
        self.matchWins = matchWins
        self.hasHitT20 = hasHitT20
        self.legsWon = legsWon
        self.lifetime180Visits = lifetime180Visits
        self.consecutiveMatchWins = consecutiveMatchWins
        self.consecutiveCalendarDaysPlayed = consecutiveCalendarDaysPlayed
        self.lastPlayedCalendarDay = lastPlayedCalendarDay
    }
}

public struct AchievementEvaluationContext: Sendable {
    public let matchId: UUID
    public let matchType: MatchType
    public let matchStatus: MatchLifecycleStatus
    public let isCampaignMatch: Bool
    public let humanPlayerIds: [UUID]
    public let winnerPlayerId: UUID?
    public let latestTurn: MatchEventEnvelope?
    public let matchEvents: [MatchEventEnvelope]
    public let lifetimeByPlayer: [UUID: AchievementLifetimeCounters]
    public let existingProgressByPlayer: [UUID: [String: PlayerAchievementProgress]]
    public let evaluationDate: Date

    public init(
        matchId: UUID,
        matchType: MatchType,
        matchStatus: MatchLifecycleStatus,
        isCampaignMatch: Bool,
        humanPlayerIds: [UUID],
        winnerPlayerId: UUID?,
        latestTurn: MatchEventEnvelope?,
        matchEvents: [MatchEventEnvelope],
        lifetimeByPlayer: [UUID: AchievementLifetimeCounters],
        existingProgressByPlayer: [UUID: [String: PlayerAchievementProgress]],
        evaluationDate: Date = Date()
    ) {
        self.matchId = matchId
        self.matchType = matchType
        self.matchStatus = matchStatus
        self.isCampaignMatch = isCampaignMatch
        self.humanPlayerIds = humanPlayerIds
        self.winnerPlayerId = winnerPlayerId
        self.latestTurn = latestTurn
        self.matchEvents = matchEvents
        self.lifetimeByPlayer = lifetimeByPlayer
        self.existingProgressByPlayer = existingProgressByPlayer
        self.evaluationDate = evaluationDate
    }
}

public struct AchievementUnlockPresentation: Identifiable, Equatable, Sendable {
    public let id: String
    public let playerId: UUID
    public let achievementId: String
    public let progressPercent: Int?
    public let isNewUnlock: Bool

    public init(
        playerId: UUID,
        achievementId: String,
        progressPercent: Int? = nil,
        isNewUnlock: Bool
    ) {
        self.id = "\(playerId.uuidString)-\(achievementId)"
        self.playerId = playerId
        self.achievementId = achievementId
        self.progressPercent = progressPercent
        self.isNewUnlock = isNewUnlock
    }
}
