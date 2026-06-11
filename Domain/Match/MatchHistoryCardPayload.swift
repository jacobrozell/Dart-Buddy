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
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let configText: String
    public let standings: [MatchHistoryCardStanding]

    public init(payloadVersion: Int = currentPayloadVersion, configText: String, standings: [MatchHistoryCardStanding]) {
        self.payloadVersion = payloadVersion
        self.configText = configText
        self.standings = standings
    }
}
