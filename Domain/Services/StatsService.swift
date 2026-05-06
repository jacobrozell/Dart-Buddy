import Foundation

public struct PlayerAggregateStats: Equatable, Sendable {
    public var matchesPlayed: Int
    public var matchesWon: Int
    public var x01Average3Dart: Double
    public var cricketWins: Int
    public var lastPlayedAt: Date?

    public init(
        matchesPlayed: Int = 0,
        matchesWon: Int = 0,
        x01Average3Dart: Double = 0,
        cricketWins: Int = 0,
        lastPlayedAt: Date? = nil
    ) {
        self.matchesPlayed = matchesPlayed
        self.matchesWon = matchesWon
        self.x01Average3Dart = x01Average3Dart
        self.cricketWins = cricketWins
        self.lastPlayedAt = lastPlayedAt
    }
}

public enum StatsService {
    public static func x01Average3Dart(totalPointsScored: Int, totalDartsThrown: Int) -> Double {
        guard totalDartsThrown > 0 else { return 0 }
        return (Double(totalPointsScored) / Double(totalDartsThrown)) * 3
    }

    public static func recomputePlayerAggregates(from completedSessions: [MatchLifecycleSession]) -> [UUID: PlayerAggregateStats] {
        var aggregates: [UUID: PlayerAggregateStats] = [:]
        var x01PointsByPlayer: [UUID: Int] = [:]
        var x01DartsByPlayer: [UUID: Int] = [:]

        for session in completedSessions where session.runtime.status == .completed {
            let participants = session.runtime.participants
            for participant in participants {
                let key = participant.playerId ?? participant.id
                var aggregate = aggregates[key, default: PlayerAggregateStats()]
                aggregate.matchesPlayed += 1
                if session.runtime.winnerPlayerId == key {
                    aggregate.matchesWon += 1
                }
                aggregate.lastPlayedAt = max(aggregate.lastPlayedAt ?? .distantPast, session.runtime.endedAt ?? session.runtime.startedAt)
                aggregates[key] = aggregate
            }

            for event in session.events {
                switch event.payload {
                case let .x01Turn(turn):
                    x01PointsByPlayer[turn.playerId, default: 0] += turn.appliedTotal
                    x01DartsByPlayer[turn.playerId, default: 0] += turn.darts.count
                case .cricketTurn:
                    break
                }
            }

            if session.runtime.type == .cricket, let winner = session.runtime.winnerPlayerId {
                var aggregate = aggregates[winner, default: PlayerAggregateStats()]
                aggregate.cricketWins += 1
                aggregates[winner] = aggregate
            }
        }

        for (playerId, points) in x01PointsByPlayer {
            let darts = x01DartsByPlayer[playerId, default: 0]
            aggregates[playerId, default: PlayerAggregateStats()].x01Average3Dart = x01Average3Dart(totalPointsScored: points, totalDartsThrown: darts)
        }
        return aggregates
    }
}
