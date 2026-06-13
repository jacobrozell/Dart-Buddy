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

        case .americanCricket:
            guard let state = session.runtime.americanCricketState,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw invalidForfeitState()
            }
            return pointsStanding(playerId: playerId, score: player.cumulativePoints, turnOrder: turnOrder, summaryKey: "play.match.forfeit.standingFormat.cricket")

        case .mickeyMouse, .mulligan:
            let marks = closedMarks(for: playerId, in: session)
            return pointsStanding(playerId: playerId, score: marks, turnOrder: turnOrder)

        case .englishCricket:
            guard let state = session.runtime.englishCricketState,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw invalidForfeitState()
            }
            return pointsStanding(playerId: playerId, score: player.totalRuns, turnOrder: turnOrder, summaryKey: "play.match.forfeit.standingFormat.baseball")

        case .knockout:
            guard let state = session.runtime.knockoutState,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw invalidForfeitState()
            }
            return MatchForfeitStanding(
                playerId: playerId,
                primaryScore: player.strikes,
                tieBreakKey: player.strikes * 100 + turnOrder,
                summaryKey: "play.match.forfeit.standingFormat.killer",
                summaryValue: player.strikes,
                prefersLowerScore: true
            )

        case .suddenDeath:
            guard let state = session.runtime.suddenDeathState,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw invalidForfeitState()
            }
            return pointsStanding(playerId: playerId, score: player.cumulativeTotal, turnOrder: turnOrder)

        case .fiftyOneByFives:
            guard let state = session.runtime.fiftyOneByFivesState,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw invalidForfeitState()
            }
            return pointsStanding(playerId: playerId, score: player.cumulativePoints, turnOrder: turnOrder)

        case .golf:
            guard let state = session.runtime.golfState,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw invalidForfeitState()
            }
            return MatchForfeitStanding(
                playerId: playerId,
                primaryScore: player.runningTotal,
                tieBreakKey: player.runningTotal * 100 + turnOrder,
                summaryKey: "play.match.forfeit.standingFormat.x01",
                summaryValue: player.runningTotal,
                prefersLowerScore: true
            )

        case .football:
            guard let state = session.runtime.footballState,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw invalidForfeitState()
            }
            return pointsStanding(playerId: playerId, score: player.goals, turnOrder: turnOrder, summaryKey: "play.match.forfeit.standingFormat.baseball")

        case .grandNational:
            guard let state = session.runtime.grandNationalState,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw invalidForfeitState()
            }
            let progress = player.lapsCompleted * 100 + player.segmentIndex
            return pointsStanding(playerId: playerId, score: progress, turnOrder: turnOrder)

        case .hareAndHounds:
            guard let state = session.runtime.hareAndHoundsState,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw invalidForfeitState()
            }
            return pointsStanding(playerId: playerId, score: player.positionIndex, turnOrder: turnOrder)

        case .aroundTheClock:
            guard let state = session.runtime.aroundTheClockState,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw invalidForfeitState()
            }
            return pointsStanding(playerId: playerId, score: player.targetIndex, turnOrder: turnOrder)

        case .aroundTheClock180:
            guard let state = session.runtime.aroundTheClock180State,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw invalidForfeitState()
            }
            return pointsStanding(playerId: playerId, score: player.cumulativePoints, turnOrder: turnOrder)

        case .chaseTheDragon:
            guard let state = session.runtime.chaseTheDragonState,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw invalidForfeitState()
            }
            let progress = player.lapsCompleted * 100 + player.stepIndex
            return pointsStanding(playerId: playerId, score: progress, turnOrder: turnOrder)

        case .nineLives:
            guard let state = session.runtime.nineLivesState,
                  let player = state.players.first(where: { $0.playerId == playerId }) else {
                throw invalidForfeitState()
            }
            return MatchForfeitStanding(
                playerId: playerId,
                primaryScore: player.lives,
                tieBreakKey: -(player.lives * 100) + turnOrder,
                summaryKey: "play.match.forfeit.standingFormat.killer",
                summaryValue: player.lives,
                prefersLowerScore: false
            )

        case .fleet:
            guard let state = session.runtime.fleetState else {
                throw invalidForfeitState()
            }
            let shipsSunk = FleetEngine.shipsSunk(by: playerId, in: state)
            let dartsThrown = session.events.reduce(into: 0) { count, envelope in
                if case let .fleetDart(event) = envelope.payload, event.playerId == playerId {
                    count += 1
                }
            }
            return MatchForfeitStanding(
                playerId: playerId,
                primaryScore: shipsSunk,
                tieBreakKey: -(shipsSunk * 100) + dartsThrown * 10 + turnOrder,
                summaryKey: "play.match.forfeit.standingFormat.fleet",
                summaryValue: shipsSunk,
                prefersLowerScore: false
            )

        case .raid:
            guard let state = session.runtime.raidState else {
                throw invalidForfeitState()
            }
            return MatchForfeitStanding(
                playerId: playerId,
                primaryScore: state.bossHP,
                tieBreakKey: state.bossHP * 100 + turnOrder,
                summaryKey: "play.match.forfeit.standingFormat.raid",
                summaryValue: state.bossHP,
                prefersLowerScore: true
            )

        case .blindKiller, .followTheLeader, .loop, .prisoner, .scam, .snooker, .ticTacToe, .bobs27, .halveIt:
            throw invalidForfeitState()
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
        case .americanCricket, .mickeyMouse, .mulligan, .englishCricket, .knockout,
             .fiftyOneByFives, .golf, .football, .grandNational, .hareAndHounds, .nineLives, .fleet, .raid:
            participants = [
                MatchParticipant(playerId: p1, displayNameAtMatchStart: "A", turnOrder: 0),
                MatchParticipant(playerId: p2, displayNameAtMatchStart: "B", turnOrder: 1)
            ]
            config = MatchConfigDefaults.config(for: type)
        case .suddenDeath:
            participants = [
                MatchParticipant(playerId: p1, displayNameAtMatchStart: "A", turnOrder: 0),
                MatchParticipant(playerId: p2, displayNameAtMatchStart: "B", turnOrder: 1),
                MatchParticipant(playerId: p3, displayNameAtMatchStart: "C", turnOrder: 2)
            ]
            config = MatchConfigDefaults.config(for: type)
        case .aroundTheClock, .aroundTheClock180, .chaseTheDragon:
            participants = [
                MatchParticipant(playerId: p1, displayNameAtMatchStart: "A", turnOrder: 0)
            ]
            config = MatchConfigDefaults.config(for: type)
        case .blindKiller, .followTheLeader, .loop, .prisoner, .scam, .snooker, .ticTacToe, .bobs27, .halveIt:
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: false,
                userMessageKey: "error.match.forfeit.invalid"
            )
        }
        var session = try MatchLifecycleService.createMatch(type: type, config: config, participants: participants)
        session = try submitFixtureTurn(for: type, session: session)
        return session
    }

    private static func submitFixtureTurn(
        for type: MatchType,
        session: MatchLifecycleSession
    ) throws -> MatchLifecycleSession {
        let miss = DartInput(multiplier: .single, segment: .miss, isMiss: true)
        switch type {
        case .x01:
            return try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
        case .cricket:
            return try MatchLifecycleService.submitCricketTurn(session: session, darts: [miss])
        case .baseball:
            return try MatchLifecycleService.submitBaseballTurn(session: session, darts: [miss])
        case .killer:
            return try MatchLifecycleService.submitKillerPick(session: session, dart: miss)
        case .shanghai:
            return try MatchLifecycleService.submitShanghaiTurn(session: session, darts: [miss])
        case .americanCricket:
            return try MatchLifecycleService.submitAmericanCricketTurn(session: session, darts: [miss])
        case .mickeyMouse:
            return try MatchLifecycleService.submitMickeyMouseTurn(session: session, darts: [miss])
        case .mulligan:
            return try MatchLifecycleService.submitMulliganTurn(session: session, darts: [miss])
        case .englishCricket:
            return try MatchLifecycleService.submitEnglishCricketTurn(session: session, darts: [miss])
        case .knockout:
            return try MatchLifecycleService.submitKnockoutTurn(session: session, darts: [miss])
        case .suddenDeath:
            return try MatchLifecycleService.submitSuddenDeathTurn(session: session, darts: [miss])
        case .fiftyOneByFives:
            return try MatchLifecycleService.submitFiftyOneByFivesTurn(session: session, darts: [miss])
        case .golf:
            return try MatchLifecycleService.submitGolfTurn(session: session, input: GolfTurnInput(darts: [miss]))
        case .football:
            return try MatchLifecycleService.submitFootballTurn(session: session, darts: [miss])
        case .grandNational:
            return try MatchLifecycleService.submitGrandNationalTurn(session: session, darts: [miss])
        case .hareAndHounds:
            return try MatchLifecycleService.submitHareAndHoundsTurn(session: session, darts: [miss])
        case .aroundTheClock:
            return try MatchLifecycleService.submitAroundTheClockTurn(session: session, darts: [miss])
        case .aroundTheClock180:
            return try MatchLifecycleService.submitAroundTheClock180Turn(session: session, darts: [miss])
        case .chaseTheDragon:
            return try MatchLifecycleService.submitChaseTheDragonTurn(session: session, darts: [miss])
        case .nineLives:
            return try MatchLifecycleService.submitNineLivesTurn(session: session, darts: [miss])
        case .fleet:
            let playerId = session.runtime.participants.first.map { $0.playerId ?? $0.id } ?? UUID()
            let shipCount = session.runtime.fleetState?.config.shipCount.count ?? 5
            var updated = try MatchLifecycleService.confirmFleetHandoff(session: session, playerId: playerId)
            for segment in 1 ... shipCount {
                updated = try MatchLifecycleService.toggleFleetPlacementCell(
                    session: updated,
                    playerId: playerId,
                    cell: .segment(segment)
                )
            }
            return try MatchLifecycleService.submitFleetPlacementLock(session: updated, playerId: playerId)
        case .raid:
            return try MatchLifecycleService.submitRaidVisit(session: session, darts: [miss, miss, miss])
        case .blindKiller, .followTheLeader, .loop, .prisoner, .scam, .snooker, .ticTacToe, .bobs27, .halveIt:
            return session
        }
    }

    private static func pointsStanding(
        playerId: UUID,
        score: Int,
        turnOrder: Int,
        summaryKey: String = "play.match.forfeit.standingFormat.shanghai",
        prefersLowerScore: Bool = false
    ) -> MatchForfeitStanding {
        MatchForfeitStanding(
            playerId: playerId,
            primaryScore: score,
            tieBreakKey: -(score * 100) + turnOrder,
            summaryKey: summaryKey,
            summaryValue: score,
            prefersLowerScore: prefersLowerScore
        )
    }

    private static func closedMarks(for playerId: UUID, in session: MatchLifecycleSession) -> Int {
        if let state = session.runtime.mickeyMouseState,
           let player = state.players.first(where: { $0.playerId == playerId }) {
            return player.marksByTarget.reduce(0) { $0 + min($1, 3) }
        }
        if let state = session.runtime.mulliganState,
           let player = state.players.first(where: { $0.playerId == playerId }) {
            return player.marksOnActiveTarget
        }
        return 0
    }

    private static func invalidForfeitState() -> AppError {
        AppError(
            code: .invalidGameState,
            layer: .domain,
            severity: .error,
            isRecoverable: false,
            userMessageKey: "error.match.forfeit.invalid"
        )
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
