import Foundation

public enum MatchLifecycleStatus: String, Codable, Sendable {
    case notStarted
    case inProgress
    case completed
    case abandoned
}

public enum X01CheckoutMode: String, Codable, CaseIterable, Sendable {
    case singleOut
    case doubleOut
    case masterOut

    public var displayName: String {
        switch self {
        case .singleOut: return "Straight Out"
        case .doubleOut: return "Double Out"
        case .masterOut: return "Master Out"
        }
    }
}

public enum X01CheckInMode: String, Codable, CaseIterable, Sendable {
    case straightIn
    case doubleIn
    case masterIn

    public var displayName: String {
        switch self {
        case .straightIn: return "Straight In"
        case .doubleIn: return "Double In"
        case .masterIn: return "Master In"
        }
    }
}

/// How leg/set targets are interpreted. `firstTo` plays until a player reaches
/// the target; `bestOf` plays a fixed number where the majority wins.
public enum X01LegFormat: String, Codable, CaseIterable, Sendable {
    case firstTo
    case bestOf

    public var displayName: String {
        switch self {
        case .firstTo: return "First to"
        case .bestOf: return "Best of"
        }
    }
}

public struct MatchConfigX01: Codable, Equatable, Sendable {
    public let payloadVersion: Int
    public let startScore: Int
    public let legsToWin: Int
    public let setsEnabled: Bool
    public let setsToWin: Int?
    public let checkoutMode: X01CheckoutMode
    // Optional so payloads persisted before these existed still decode; the
    // accessors below supply the historical defaults (straight in / first to).
    public let checkInModeRaw: String?
    public let legFormatRaw: String?

    public var checkInMode: X01CheckInMode {
        checkInModeRaw.flatMap(X01CheckInMode.init(rawValue:)) ?? .straightIn
    }

    public var legFormat: X01LegFormat {
        legFormatRaw.flatMap(X01LegFormat.init(rawValue:)) ?? .firstTo
    }

    public init(
        payloadVersion: Int = 1,
        startScore: Int,
        legsToWin: Int,
        setsEnabled: Bool,
        setsToWin: Int?,
        checkoutMode: X01CheckoutMode,
        checkInMode: X01CheckInMode = .straightIn,
        legFormat: X01LegFormat = .firstTo
    ) {
        self.payloadVersion = payloadVersion
        self.startScore = startScore
        self.legsToWin = legsToWin
        self.setsEnabled = setsEnabled
        self.setsToWin = setsToWin
        self.checkoutMode = checkoutMode
        self.checkInModeRaw = checkInMode.rawValue
        self.legFormatRaw = legFormat.rawValue
    }
}

public struct MatchConfigCricket: Codable, Equatable, Sendable {
    public let payloadVersion: Int
    public let bullScoreValue: Int

    public init(payloadVersion: Int = 1, bullScoreValue: Int = 25) {
        self.payloadVersion = payloadVersion
        self.bullScoreValue = bullScoreValue
    }
}

public enum MatchConfigPayload: Codable, Equatable, Sendable {
    case x01(MatchConfigX01)
    case cricket(MatchConfigCricket)

    private enum CodingKeys: String, CodingKey {
        case type
        case x01
        case cricket
    }

    private enum PayloadType: String, Codable {
        case x01
        case cricket
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(PayloadType.self, forKey: .type)
        switch type {
        case .x01:
            self = .x01(try container.decode(MatchConfigX01.self, forKey: .x01))
        case .cricket:
            self = .cricket(try container.decode(MatchConfigCricket.self, forKey: .cricket))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .x01(config):
            try container.encode(PayloadType.x01, forKey: .type)
            try container.encode(config, forKey: .x01)
        case let .cricket(config):
            try container.encode(PayloadType.cricket, forKey: .type)
            try container.encode(config, forKey: .cricket)
        }
    }
}

public struct MatchParticipant: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let playerId: UUID?
    public let displayNameAtMatchStart: String
    public let turnOrder: Int
    /// Present when this participant is a computer opponent.
    public let botDifficultyRaw: String?

    public var botDifficulty: BotDifficulty? {
        botDifficultyRaw.flatMap(BotDifficulty.init(rawValue:))
    }

    public var isBot: Bool { botDifficulty != nil }

    public init(
        id: UUID = UUID(),
        playerId: UUID?,
        displayNameAtMatchStart: String,
        turnOrder: Int,
        botDifficultyRaw: String? = nil
    ) {
        self.id = id
        self.playerId = playerId
        self.displayNameAtMatchStart = displayNameAtMatchStart
        self.turnOrder = turnOrder
        self.botDifficultyRaw = botDifficultyRaw
    }
}

public struct MatchSnapshot: Codable, Sendable {
    public let payloadVersion: Int
    public let eventCount: Int
    public let createdAt: Date
    public let payload: Data

    public init(payloadVersion: Int = 1, eventCount: Int, createdAt: Date, payload: Data) {
        self.payloadVersion = payloadVersion
        self.eventCount = eventCount
        self.createdAt = createdAt
        self.payload = payload
    }
}
