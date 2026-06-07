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

/// Describes a single match used as input for stat aggregation.
public struct MatchStatsInput: Sendable {
    public let matchId: UUID
    public let playedAt: Date
    public let type: MatchType
    public let participantKeys: [UUID]
    public let winnerKey: UUID?
    public let events: [MatchEventEnvelope]
    /// When true, dart/point totals are included but games/wins are not incremented.
    public let isPartial: Bool

    public init(
        matchId: UUID = UUID(),
        playedAt: Date = Date(),
        type: MatchType,
        participantKeys: [UUID],
        winnerKey: UUID?,
        events: [MatchEventEnvelope],
        isPartial: Bool = false
    ) {
        self.matchId = matchId
        self.playedAt = playedAt
        self.type = type
        self.participantKeys = participantKeys
        self.winnerKey = winnerKey
        self.events = events
        self.isPartial = isPartial
    }
}

public struct StatsTrendPoint: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let date: Date
    public let average3Dart: Double

    public init(id: UUID, date: Date, average3Dart: Double) {
        self.id = id
        self.date = date
        self.average3Dart = average3Dart
    }
}

public enum StatsService {
    public static func x01Average3Dart(totalPointsScored: Int, totalDartsThrown: Int) -> Double {
        guard totalDartsThrown > 0 else { return 0 }
        return (Double(totalPointsScored) / Double(totalDartsThrown)) * 3
    }

    /// Cricket dart count for a player — every recorded touch, including misses.
    public static func cricketDartsThrown(from events: [CricketTurnEvent]) -> Int {
        events.reduce(0) { $0 + $1.targetsTouched.count }
    }

    /// Live X01 scorecard average while a visit may still be in progress.
    /// For the opening visit's first two darts (no committed history yet), show the
    /// running per-dart average so a single 11 reads as 11.00 instead of 33.00.
    public static func x01LiveScorecardAverage(
        committedPoints: Int,
        committedDarts: Int,
        previewPoints: Int,
        previewDarts: Int
    ) -> Double {
        let totalPoints = committedPoints + previewPoints
        let totalDarts = committedDarts + previewDarts
        guard totalDarts > 0 else { return 0 }
        if committedDarts == 0, previewDarts > 0, previewDarts < 3 {
            return Double(previewPoints) / Double(previewDarts)
        }
        return x01Average3Dart(totalPointsScored: totalPoints, totalDartsThrown: totalDarts)
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
                if !match.isPartial {
                    entry.games += 1
                    if match.winnerKey == key { entry.wins += 1 }
                }
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
                    for dart in turn.darts {
                        entry.hitsBySector[HitsBySectorKeys.key(for: dart), default: 0] += 1
                        guard !dart.wasMiss else { continue }
                        if dart.multiplierRaw == DartMultiplier.double.rawValue { entry.doubles += 1 }
                        if dart.multiplierRaw == DartMultiplier.triple.rawValue { entry.triples += 1 }
                    }
                    byPlayer[turn.playerId] = entry
                case let .cricketTurn(turn):
                    var entry = breakdown(for: turn.playerId)
                    entry.points += turn.totalPointsAdded
                    entry.cricketRounds += 1
                    for touch in turn.targetsTouched {
                        entry.darts += 1
                        entry.hitsBySector[HitsBySectorKeys.key(for: touch), default: 0] += 1
                        guard !touch.wasMiss else { continue }
                        entry.cricketMarks += touch.marksAdded
                        if touch.multiplierRaw == DartMultiplier.double.rawValue { entry.doubles += 1 }
                        if touch.multiplierRaw == DartMultiplier.triple.rawValue { entry.triples += 1 }
                    }
                    byPlayer[turn.playerId] = entry
                case let .baseballTurn(turn):
                    var entry = breakdown(for: turn.playerId)
                    entry.points += turn.runsThisVisit
                    entry.darts += turn.darts.count
                    for dart in turn.darts {
                        entry.hitsBySector[HitsBySectorKeys.key(for: dart, turn: turn), default: 0] += 1
                        guard !dart.wasMiss else { continue }
                        if dart.multiplierRaw == DartMultiplier.double.rawValue { entry.doubles += 1 }
                        if dart.multiplierRaw == DartMultiplier.triple.rawValue { entry.triples += 1 }
                    }
                    byPlayer[turn.playerId] = entry
                case let .killerPick(pick):
                    var entry = breakdown(for: pick.playerId)
                    entry.darts += 1
                    entry.hitsBySector[HitsBySectorKeys.key(for: pick), default: 0] += 1
                    if !pick.wasMiss {
                        if pick.multiplierRaw == DartMultiplier.double.rawValue { entry.doubles += 1 }
                        if pick.multiplierRaw == DartMultiplier.triple.rawValue { entry.triples += 1 }
                    }
                    byPlayer[pick.playerId] = entry
                case let .killerTurn(turn):
                    var entry = breakdown(for: turn.playerId)
                    entry.darts += turn.darts.count
                    for dart in turn.darts {
                        entry.hitsBySector[HitsBySectorKeys.key(for: dart), default: 0] += 1
                        guard !dart.wasMiss else { continue }
                        if dart.multiplierRaw == DartMultiplier.double.rawValue { entry.doubles += 1 }
                        if dart.multiplierRaw == DartMultiplier.triple.rawValue { entry.triples += 1 }
                    }
                    byPlayer[turn.playerId] = entry
                case let .shanghaiTurn(turn):
                    var entry = breakdown(for: turn.playerId)
                    entry.points += turn.pointsThisVisit
                    entry.darts += turn.darts.count
                    for dart in turn.darts {
                        entry.hitsBySector[HitsBySectorKeys.key(for: dart, turn: turn), default: 0] += 1
                        guard !dart.wasMiss else { continue }
                        if dart.multiplierRaw == DartMultiplier.double.rawValue { entry.doubles += 1 }
                        if dart.multiplierRaw == DartMultiplier.triple.rawValue { entry.triples += 1 }
                    }
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

    /// Per-match X01 3-dart averages for one player, ordered oldest to newest.
    public static func x01TrendPoints(from matches: [MatchStatsInput], playerId: UUID) -> [StatsTrendPoint] {
        matches
            .filter { $0.type == .x01 && !$0.isPartial && $0.participantKeys.contains(playerId) }
            .sorted { $0.playedAt < $1.playedAt }
            .compactMap { match -> StatsTrendPoint? in
                var points = 0
                var darts = 0
                for envelope in match.events {
                    guard case let .x01Turn(turn) = envelope.payload, turn.playerId == playerId else { continue }
                    points += turn.appliedTotal
                    darts += turn.effectiveDartsThrown
                }
                guard darts > 0 else { return nil }
                return StatsTrendPoint(
                    id: match.matchId,
                    date: match.playedAt,
                    average3Dart: x01Average3Dart(totalPointsScored: points, totalDartsThrown: darts)
                )
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
                case .baseballTurn:
                    break
                case .killerPick, .killerTurn:
                    break
                case .shanghaiTurn:
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

    /// Sector keys for `hitsBySector` aggregation (`0` = miss, aligned with the scoring pad).
    private enum HitsBySectorKeys {
        static let miss = "0"

        static func key(for dart: X01DartEvent) -> String {
            dart.wasMiss ? miss : normalized(dart.segmentRaw)
        }

        static func key(for touch: CricketDartTouch) -> String {
            touch.wasMiss ? miss : normalized(touch.targetRaw)
        }

        static func key(for dart: BaseballDartEvent) -> String {
            dart.wasMiss ? miss : normalized(dart.segmentRaw)
        }

        static func key(for dart: BaseballDartEvent, turn: BaseballTurnEvent) -> String {
            if dart.wasMiss { return miss }
            if turn.phase == .bullPlayoff {
                return key(for: dart)
            }
            if dart.runsAwarded > 0 {
                return String(turn.inning)
            }
            return miss
        }

        static func key(for pick: KillerPickEvent) -> String {
            pick.wasMiss ? miss : normalized(pick.segmentRaw)
        }

        static func key(for dart: KillerDartResolution) -> String {
            dart.wasMiss ? miss : normalized(dart.segmentRaw)
        }

        static func key(for dart: ShanghaiDartEvent) -> String {
            dart.wasMiss ? miss : normalized(dart.segmentRaw)
        }

        static func key(for dart: ShanghaiDartEvent, turn: ShanghaiTurnEvent) -> String {
            if dart.wasMiss { return miss }
            if dart.hitTarget {
                return String(turn.round)
            }
            return miss
        }

        private static func normalized(_ raw: String) -> String {
            raw == "miss" ? miss : raw
        }
    }
}
