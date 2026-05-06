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

public struct PlayerSummary: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let isArchived: Bool
    public let createdAt: Date
    public let updatedAt: Date
}

public struct MatchParticipantSummary: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let matchId: UUID
    public let playerId: UUID?
    public let turnOrder: Int
    public let displayNameAtMatchStart: String
    public let avatarStyleAtMatchStart: String?
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
    public let defaultMatchTypeRaw: String
    public let defaultX01StartScore: Int
    public let defaultCheckoutModeRaw: String
    public let defaultLegsToWin: Int
    public let defaultSetsEnabled: Bool
    public let updatedAt: Date
}
