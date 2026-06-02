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

public struct PlayerStatBreakdown: Identifiable, Equatable, Sendable {
    public let playerId: UUID
    public var name: String
    public var games: Int
    public var wins: Int
    public var legs: Int
    public var darts: Int
    public var points: Int
    public var highestScore: Int
    public var highestCheckout: Int
    public var checkouts: Int
    public var doubles: Int
    public var triples: Int
    public var hitsBySector: [String: Int]
    public var cricketMarks: Int
    public var cricketRounds: Int

    public init(
        playerId: UUID,
        name: String,
        games: Int = 0,
        wins: Int = 0,
        legs: Int = 0,
        darts: Int = 0,
        points: Int = 0,
        highestScore: Int = 0,
        highestCheckout: Int = 0,
        checkouts: Int = 0,
        doubles: Int = 0,
        triples: Int = 0,
        hitsBySector: [String: Int] = [:],
        cricketMarks: Int = 0,
        cricketRounds: Int = 0
    ) {
        self.playerId = playerId
        self.name = name
        self.games = games
        self.wins = wins
        self.legs = legs
        self.darts = darts
        self.points = points
        self.highestScore = highestScore
        self.highestCheckout = highestCheckout
        self.checkouts = checkouts
        self.doubles = doubles
        self.triples = triples
        self.hitsBySector = hitsBySector
        self.cricketMarks = cricketMarks
        self.cricketRounds = cricketRounds
    }

    public var id: UUID { playerId }

    public var average3Dart: Double {
        darts > 0 ? (Double(points) / Double(darts)) * 3 : 0
    }

    public var doublePercent: Double {
        darts > 0 ? Double(doubles) / Double(darts) * 100 : 0
    }

    public var triplePercent: Double {
        darts > 0 ? Double(triples) / Double(darts) * 100 : 0
    }

    public var winPercent: Double {
        games > 0 ? Double(wins) / Double(games) * 100 : 0
    }

    public var marksPerRound: Double {
        cricketRounds > 0 ? Double(cricketMarks) / Double(cricketRounds) : 0
    }
}

/// Describes a single completed match used as input for stat aggregation.
public struct MatchStatsInput: Sendable {
    public let type: MatchType
    public let participantKeys: [UUID]
    public let winnerKey: UUID?
    public let events: [MatchEventEnvelope]

    public init(type: MatchType, participantKeys: [UUID], winnerKey: UUID?, events: [MatchEventEnvelope]) {
        self.type = type
        self.participantKeys = participantKeys
        self.winnerKey = winnerKey
        self.events = events
    }
}

public enum StatsService {
    public static func x01Average3Dart(totalPointsScored: Int, totalDartsThrown: Int) -> Double {
        guard totalDartsThrown > 0 else { return 0 }
        return (Double(totalPointsScored) / Double(totalDartsThrown)) * 3
    }

    /// Aggregates detailed per-player stats across the supplied matches.
    /// Deterministic and derived entirely from immutable turn/dart events.
    public static func breakdowns(
        from matches: [MatchStatsInput],
        nameById: [UUID: String]
    ) -> [PlayerStatBreakdown] {
        var byPlayer: [UUID: PlayerStatBreakdown] = [:]

        func breakdown(for key: UUID) -> PlayerStatBreakdown {
            byPlayer[key] ?? PlayerStatBreakdown(playerId: key, name: nameById[key] ?? "Player")
        }

        for match in matches {
            for key in Set(match.participantKeys) {
                var entry = breakdown(for: key)
                entry.games += 1
                if match.winnerKey == key { entry.wins += 1 }
                byPlayer[key] = entry
            }

            for envelope in match.events {
                switch envelope.payload {
                case let .x01Turn(turn):
                    var entry = breakdown(for: turn.playerId)
                    entry.darts += turn.effectiveDartsThrown
                    entry.points += turn.appliedTotal
                    if turn.appliedTotal > entry.highestScore { entry.highestScore = turn.appliedTotal }
                    if turn.didCheckout {
                        entry.checkouts += 1
                        entry.legs += 1
                        if turn.startRemaining > entry.highestCheckout { entry.highestCheckout = turn.startRemaining }
                    }
                    for dart in turn.darts where !dart.wasMiss {
                        if dart.multiplierRaw == DartMultiplier.double.rawValue { entry.doubles += 1 }
                        if dart.multiplierRaw == DartMultiplier.triple.rawValue { entry.triples += 1 }
                        entry.hitsBySector[dart.segmentRaw, default: 0] += 1
                    }
                    byPlayer[turn.playerId] = entry
                case let .cricketTurn(turn):
                    var entry = breakdown(for: turn.playerId)
                    entry.points += turn.totalPointsAdded
                    entry.cricketRounds += 1
                    for touch in turn.targetsTouched where !touch.wasMiss {
                        entry.darts += 1
                        entry.cricketMarks += touch.marksAdded
                        if touch.multiplierRaw == DartMultiplier.double.rawValue { entry.doubles += 1 }
                        if touch.multiplierRaw == DartMultiplier.triple.rawValue { entry.triples += 1 }
                        entry.hitsBySector[touch.targetRaw, default: 0] += 1
                    }
                    // Count missed darts toward total throws as well.
                    let misses = turn.targetsTouched.filter(\.wasMiss).count
                    entry.darts += misses
                    byPlayer[turn.playerId] = entry
                }
            }
        }

        return byPlayer.values.sorted {
            if $0.wins != $1.wins { return $0.wins > $1.wins }
            if $0.games != $1.games { return $0.games > $1.games }
            return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
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
                    x01DartsByPlayer[turn.playerId, default: 0] += turn.effectiveDartsThrown
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
