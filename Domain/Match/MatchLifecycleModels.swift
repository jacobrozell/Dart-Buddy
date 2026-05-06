import Foundation

public enum MatchLifecycleStatus: String, Codable, Sendable {
    case notStarted
    case inProgress
    case completed
    case abandoned
}

public enum X01CheckoutMode: String, Codable, Sendable {
    case singleOut
    case doubleOut
}

public struct MatchConfigX01: Codable, Equatable, Sendable {
    public let payloadVersion: Int
    public let startScore: Int
    public let legsToWin: Int
    public let setsEnabled: Bool
    public let setsToWin: Int?
    public let checkoutMode: X01CheckoutMode

    public init(
        payloadVersion: Int = 1,
        startScore: Int,
        legsToWin: Int,
        setsEnabled: Bool,
        setsToWin: Int?,
        checkoutMode: X01CheckoutMode
    ) {
        self.payloadVersion = payloadVersion
        self.startScore = startScore
        self.legsToWin = legsToWin
        self.setsEnabled = setsEnabled
        self.setsToWin = setsToWin
        self.checkoutMode = checkoutMode
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

    public init(
        id: UUID = UUID(),
        playerId: UUID?,
        displayNameAtMatchStart: String,
        turnOrder: Int
    ) {
        self.id = id
        self.playerId = playerId
        self.displayNameAtMatchStart = displayNameAtMatchStart
        self.turnOrder = turnOrder
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
