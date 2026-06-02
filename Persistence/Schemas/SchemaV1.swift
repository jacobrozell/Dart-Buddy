import Foundation
import SwiftData

public enum SchemaV1: VersionedSchema {
    public static var versionIdentifier = Schema.Version(1, 0, 0)

    public static var models: [any PersistentModel.Type] {
        [
            PlayerRecord.self,
            MatchRecord.self,
            MatchParticipantRecord.self,
            MatchSnapshotRecord.self,
            MatchEventRecord.self,
            SettingsRecord.self
        ]
    }

    @Model
    public final class PlayerRecord {
        @Attribute(.unique) public var id: UUID
        public var name: String
        public var isArchived: Bool
        public var isBot: Bool
        public var botDifficultyRaw: String?
        public var createdAt: Date
        public var updatedAt: Date

        public init(
            id: UUID = UUID(),
            name: String,
            isArchived: Bool = false,
            isBot: Bool = false,
            botDifficultyRaw: String? = nil,
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.name = name
            self.isArchived = isArchived
            self.isBot = isBot
            self.botDifficultyRaw = botDifficultyRaw
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    @Model
    public final class MatchRecord {
        @Attribute(.unique) public var id: UUID
        public var typeRaw: String
        public var statusRaw: String
        public var startedAt: Date
        public var endedAt: Date?
        public var winnerPlayerId: UUID?
        public var configPayload: Data
        public var currentTurnPlayerId: UUID?
        public var currentLegIndex: Int
        public var currentSetIndex: Int
        public var eventCount: Int
        public var createdAt: Date
        public var updatedAt: Date

        public init(
            id: UUID = UUID(),
            typeRaw: String,
            statusRaw: String,
            startedAt: Date = Date(),
            endedAt: Date? = nil,
            winnerPlayerId: UUID? = nil,
            configPayload: Data,
            currentTurnPlayerId: UUID? = nil,
            currentLegIndex: Int = 0,
            currentSetIndex: Int = 0,
            eventCount: Int = 0,
            createdAt: Date = Date(),
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.typeRaw = typeRaw
            self.statusRaw = statusRaw
            self.startedAt = startedAt
            self.endedAt = endedAt
            self.winnerPlayerId = winnerPlayerId
            self.configPayload = configPayload
            self.currentTurnPlayerId = currentTurnPlayerId
            self.currentLegIndex = currentLegIndex
            self.currentSetIndex = currentSetIndex
            self.eventCount = eventCount
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }

    @Model
    public final class MatchParticipantRecord {
        @Attribute(.unique) public var id: UUID
        public var matchId: UUID
        public var playerId: UUID?
        public var turnOrder: Int
        public var displayNameAtMatchStart: String
        public var avatarStyleAtMatchStart: String?
        public var botDifficultyRaw: String?

        public init(
            id: UUID = UUID(),
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

    @Model
    public final class MatchSnapshotRecord {
        @Attribute(.unique) public var id: UUID
        public var matchId: UUID
        public var snapshotVersion: Int
        public var snapshotPayload: Data
        public var updatedAt: Date

        public init(
            id: UUID = UUID(),
            matchId: UUID,
            snapshotVersion: Int,
            snapshotPayload: Data,
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.matchId = matchId
            self.snapshotVersion = snapshotVersion
            self.snapshotPayload = snapshotPayload
            self.updatedAt = updatedAt
        }
    }

    @Model
    public final class MatchEventRecord {
        @Attribute(.unique) public var id: UUID
        public var matchId: UUID
        public var eventIndex: Int
        public var eventTypeRaw: String
        public var eventPayload: Data
        public var createdAt: Date

        public init(
            id: UUID = UUID(),
            matchId: UUID,
            eventIndex: Int,
            eventTypeRaw: String,
            eventPayload: Data,
            createdAt: Date = Date()
        ) {
            self.id = id
            self.matchId = matchId
            self.eventIndex = eventIndex
            self.eventTypeRaw = eventTypeRaw
            self.eventPayload = eventPayload
            self.createdAt = createdAt
        }
    }

    @Model
    public final class SettingsRecord {
        @Attribute(.unique) public var id: UUID
        public var appearanceModeRaw: String
        public var hapticsEnabled: Bool
        public var soundEnabled: Bool
        public var defaultMatchTypeRaw: String
        public var defaultX01StartScore: Int
        public var defaultCheckoutModeRaw: String
        public var defaultCheckInModeRaw: String
        public var defaultLegFormatRaw: String
        public var defaultLegsToWin: Int
        public var defaultSetsEnabled: Bool
        public var updatedAt: Date

        public init(
            id: UUID = UUID(),
            appearanceModeRaw: String = "system",
            hapticsEnabled: Bool = true,
            soundEnabled: Bool = true,
            defaultMatchTypeRaw: String = "x01",
            defaultX01StartScore: Int = 501,
            defaultCheckoutModeRaw: String = "doubleOut",
            defaultCheckInModeRaw: String = "straightIn",
            defaultLegFormatRaw: String = "firstTo",
            defaultLegsToWin: Int = 3,
            defaultSetsEnabled: Bool = false,
            updatedAt: Date = Date()
        ) {
            self.id = id
            self.appearanceModeRaw = appearanceModeRaw
            self.hapticsEnabled = hapticsEnabled
            self.soundEnabled = soundEnabled
            self.defaultMatchTypeRaw = defaultMatchTypeRaw
            self.defaultX01StartScore = defaultX01StartScore
            self.defaultCheckoutModeRaw = defaultCheckoutModeRaw
            self.defaultCheckInModeRaw = defaultCheckInModeRaw
            self.defaultLegFormatRaw = defaultLegFormatRaw
            self.defaultLegsToWin = defaultLegsToWin
            self.defaultSetsEnabled = defaultSetsEnabled
            self.updatedAt = updatedAt
        }
    }
}
