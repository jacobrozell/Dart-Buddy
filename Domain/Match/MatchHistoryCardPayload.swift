import Foundation

public struct MatchHistoryCardStanding: Codable, Equatable, Sendable {
    public let playerId: UUID
    public let name: String
    public let isWinner: Bool
    public let sets: Int
    public let legs: Int
    public let score: Int

    public init(playerId: UUID, name: String, isWinner: Bool, sets: Int, legs: Int, score: Int) {
        self.playerId = playerId
        self.name = name
        self.isWinner = isWinner
        self.sets = sets
        self.legs = legs
        self.score = score
    }
}

/// Denormalized history list row data written at match completion.
public struct MatchHistoryCardPayload: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 2

    public let payloadVersion: Int
    public let configText: String
    public let standings: [MatchHistoryCardStanding]
    public let isForfeited: Bool
    public let forfeitedByPlayerId: UUID?

    public init(
        payloadVersion: Int = currentPayloadVersion,
        configText: String,
        standings: [MatchHistoryCardStanding],
        isForfeited: Bool = false,
        forfeitedByPlayerId: UUID? = nil
    ) {
        self.payloadVersion = payloadVersion
        self.configText = configText
        self.standings = standings
        self.isForfeited = isForfeited
        self.forfeitedByPlayerId = forfeitedByPlayerId
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decodeIfPresent(Int.self, forKey: .payloadVersion) ?? 1
        configText = try container.decode(String.self, forKey: .configText)
        standings = try container.decode([MatchHistoryCardStanding].self, forKey: .standings)
        if version < 2 {
            isForfeited = false
            forfeitedByPlayerId = nil
        } else {
            isForfeited = try container.decodeIfPresent(Bool.self, forKey: .isForfeited) ?? false
            forfeitedByPlayerId = try container.decodeIfPresent(UUID.self, forKey: .forfeitedByPlayerId)
        }
        payloadVersion = max(version, Self.currentPayloadVersion)
    }

    private enum CodingKeys: String, CodingKey {
        case payloadVersion
        case configText
        case standings
        case isForfeited
        case forfeitedByPlayerId
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(payloadVersion, forKey: .payloadVersion)
        try container.encode(configText, forKey: .configText)
        try container.encode(standings, forKey: .standings)
        try container.encode(isForfeited, forKey: .isForfeited)
        try container.encodeIfPresent(forfeitedByPlayerId, forKey: .forfeitedByPlayerId)
    }
}
