import Foundation

struct MatchForfeitStanding: Equatable {
    let playerId: UUID
    let primaryScore: Int
    let tieBreakKey: Int
    let summaryKey: String
    let summaryValue: Int
    let prefersLowerScore: Bool
}

enum MatchForfeitStandingsRegistry {
    static func standing(
        for playerId: UUID,
        in session: MatchLifecycleSession
    ) throws -> MatchForfeitStanding {
        let turnOrder = session.runtime.participants
            .first { ($0.playerId ?? $0.id) == playerId }?
            .turnOrder ?? Int.max

        switch session.runtime.type {
        case .x01:
            guard let state = session.runtime.x01State,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw AppError(
                    code: .invalidGameState,
                    layer: .domain,
                    severity: .error,
                    isRecoverable: false,
                    userMessageKey: "error.match.forfeit.invalid"
                )
            }
            let legsLost = maxLegsLost(in: state, for: player)
            let setsLost = maxSetsLost(in: state, for: player)
            let tieBreak = legsLost * 10_000 + setsLost * 100 + turnOrder
            return MatchForfeitStanding(
                playerId: playerId,
                primaryScore: player.remainingScore,
                tieBreakKey: tieBreak,
                summaryKey: "play.match.forfeit.standingFormat.x01",
                summaryValue: player.remainingScore,
                prefersLowerScore: true
            )

        case .cricket:
            guard let state = session.runtime.cricketState,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw AppError(
                    code: .invalidGameState,
                    layer: .domain,
                    severity: .error,
                    isRecoverable: false,
                    userMessageKey: "error.match.forfeit.invalid"
                )
            }
            let marksClosed = player.marks.values.reduce(0) { $0 + min($1, 3) }
            let tieBreak = -(marksClosed * 100) + turnOrder
            return MatchForfeitStanding(
                playerId: playerId,
                primaryScore: player.score,
                tieBreakKey: tieBreak,
                summaryKey: "play.match.forfeit.standingFormat.cricket",
                summaryValue: player.score,
                prefersLowerScore: false
            )

        case .baseball:
            guard let state = session.runtime.baseballState,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw AppError(
                    code: .invalidGameState,
                    layer: .domain,
                    severity: .error,
                    isRecoverable: false,
                    userMessageKey: "error.match.forfeit.invalid"
                )
            }
            let tieBreak = -(player.runsThisInning * 100) + turnOrder
            return MatchForfeitStanding(
                playerId: playerId,
                primaryScore: player.cumulativeRuns,
                tieBreakKey: tieBreak,
                summaryKey: "play.match.forfeit.standingFormat.baseball",
                summaryValue: player.cumulativeRuns,
                prefersLowerScore: false
            )

        case .killer:
            guard let state = session.runtime.killerState,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw AppError(
                    code: .invalidGameState,
                    layer: .domain,
                    severity: .error,
                    isRecoverable: false,
                    userMessageKey: "error.match.forfeit.invalid"
                )
            }
            let kills = killsDealt(by: playerId, in: session.events)
            let tieBreak = -(kills * 100) + turnOrder
            return MatchForfeitStanding(
                playerId: playerId,
                primaryScore: player.lives,
                tieBreakKey: tieBreak,
                summaryKey: "play.match.forfeit.standingFormat.killer",
                summaryValue: player.lives,
                prefersLowerScore: false
            )

        case .shanghai:
            guard let state = session.runtime.shanghaiState,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw AppError(
                    code: .invalidGameState,
                    layer: .domain,
                    severity: .error,
                    isRecoverable: false,
                    userMessageKey: "error.match.forfeit.invalid"
                )
            }
            let tieBreak = -(player.pointsThisRound * 100) + turnOrder
            return MatchForfeitStanding(
                playerId: playerId,
                primaryScore: player.cumulativePoints,
                tieBreakKey: tieBreak,
                summaryKey: "play.match.forfeit.standingFormat.shanghai",
                summaryValue: player.cumulativePoints,
                prefersLowerScore: false
            )
        }
    }

    static func fixtureSession(for type: MatchType) throws -> MatchLifecycleSession {
        let p1 = UUID()
        let p2 = UUID()
        let p3 = UUID()
        let participants: [MatchParticipant]
        let config: MatchConfigPayload
        switch type {
        case .x01:
            participants = [
                MatchParticipant(playerId: p1, displayNameAtMatchStart: "A", turnOrder: 0),
                MatchParticipant(playerId: p2, displayNameAtMatchStart: "B", turnOrder: 1),
                MatchParticipant(playerId: p3, displayNameAtMatchStart: "C", turnOrder: 2)
            ]
            config = .x01(MatchConfigX01(startScore: 501, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut))
        case .cricket:
            participants = [
                MatchParticipant(playerId: p1, displayNameAtMatchStart: "A", turnOrder: 0),
                MatchParticipant(playerId: p2, displayNameAtMatchStart: "B", turnOrder: 1),
                MatchParticipant(playerId: p3, displayNameAtMatchStart: "C", turnOrder: 2)
            ]
            config = .cricket(MatchConfigCricket())
        case .baseball:
            participants = [
                MatchParticipant(playerId: p1, displayNameAtMatchStart: "A", turnOrder: 0),
                MatchParticipant(playerId: p2, displayNameAtMatchStart: "B", turnOrder: 1),
                MatchParticipant(playerId: p3, displayNameAtMatchStart: "C", turnOrder: 2)
            ]
            config = .baseball(MatchConfigBaseball())
        case .killer:
            participants = [
                MatchParticipant(playerId: p1, displayNameAtMatchStart: "A", turnOrder: 0),
                MatchParticipant(playerId: p2, displayNameAtMatchStart: "B", turnOrder: 1),
                MatchParticipant(playerId: p3, displayNameAtMatchStart: "C", turnOrder: 2)
            ]
            config = .killer(MatchConfigKiller())
        case .shanghai:
            participants = [
                MatchParticipant(playerId: p1, displayNameAtMatchStart: "A", turnOrder: 0),
                MatchParticipant(playerId: p2, displayNameAtMatchStart: "B", turnOrder: 1),
                MatchParticipant(playerId: p3, displayNameAtMatchStart: "C", turnOrder: 2)
            ]
            config = .shanghai(MatchConfigShanghai())
        }
        var session = try MatchLifecycleService.createMatch(type: type, config: config, participants: participants)
        switch type {
        case .x01:
            session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
        case .cricket:
            session = try MatchLifecycleService.submitCricketTurn(
                session: session,
                darts: [DartInput(multiplier: .single, segment: .miss, isMiss: true)],
                timestamp: Date()
            )
        case .baseball:
            session = try MatchLifecycleService.submitBaseballTurn(
                session: session,
                darts: [DartInput(multiplier: .single, segment: .miss, isMiss: true)],
                timestamp: Date()
            )
        case .killer:
            session = try MatchLifecycleService.submitKillerPick(
                session: session,
                dart: DartInput(multiplier: .single, segment: .miss, isMiss: true),
                timestamp: Date()
            )
        case .shanghai:
            session = try MatchLifecycleService.submitShanghaiTurn(
                session: session,
                darts: [DartInput(multiplier: .single, segment: .miss, isMiss: true)],
                timestamp: Date()
            )
        }
        return session
    }

    private static func maxLegsLost(in state: X01State, for player: X01PlayerState) -> Int {
        state.players.map(\.legsWon).max().map { maxWon in max(0, maxWon - player.legsWon) } ?? 0
    }

    private static func maxSetsLost(in state: X01State, for player: X01PlayerState) -> Int {
        state.players.map(\.setsWon).max().map { maxWon in max(0, maxWon - player.setsWon) } ?? 0
    }

    private static func killsDealt(by playerId: UUID, in events: [MatchEventEnvelope]) -> Int {
        events.reduce(into: 0) { total, envelope in
            guard case let .killerTurn(turn) = envelope.payload, turn.playerId == playerId else { return }
            for dart in turn.darts {
                for delta in dart.lifeDeltas.values where delta < 0 {
                    total += -delta
                }
            }
        }
    }
}
