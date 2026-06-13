import Foundation

enum MatchRuntimeProjection {
    static func project(_ runtime: inout MatchRuntimeState, timestamp: Date) {
        if let x01State = runtime.x01State {
            projectRotatingPlayerState(
                &runtime,
                currentTurnPlayerId: x01State.players[x01State.currentPlayerIndex].playerId,
                legIndex: x01State.legIndex,
                setIndex: x01State.setIndex,
                isComplete: x01State.isComplete,
                winnerPlayerId: x01State.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let cricketState = runtime.cricketState {
            projectRotatingPlayerState(
                &runtime,
                currentTurnPlayerId: cricketState.players[cricketState.currentPlayerIndex].playerId,
                legIndex: cricketState.legIndex,
                setIndex: cricketState.setIndex,
                isComplete: cricketState.isComplete,
                winnerPlayerId: cricketState.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let baseballState = runtime.baseballState {
            projectRotatingPlayerState(
                &runtime,
                currentTurnPlayerId: baseballState.players[baseballState.currentPlayerIndex].playerId,
                legIndex: max(0, baseballState.currentInning - 1),
                isComplete: baseballState.isComplete,
                winnerPlayerId: baseballState.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let killerState = runtime.killerState {
            projectKillerState(&runtime, killerState: killerState, timestamp: timestamp)
            return
        }
        if let shanghaiState = runtime.shanghaiState {
            projectRotatingPlayerState(
                &runtime,
                currentTurnPlayerId: shanghaiState.players[shanghaiState.currentPlayerIndex].playerId,
                legIndex: max(0, shanghaiState.currentRound - 1),
                isComplete: shanghaiState.isComplete,
                winnerPlayerId: shanghaiState.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.americanCricketState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.mickeyMouseState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.mulliganState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.englishCricketState {
            projectRotatingPlayerState(
                &runtime,
                currentTurnPlayerId: state.currentTurnPlayerId,
                legIndex: state.inningsIndex,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.knockoutState {
            projectRotatingPlayerState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                legIndex: max(0, state.currentRound - 1),
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.suddenDeathState {
            projectRotatingPlayerState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                legIndex: max(0, state.currentRound - 1),
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.fiftyOneByFivesState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.golfState {
            projectRotatingPlayerState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                legIndex: max(0, state.currentHole - 1),
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.footballState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.grandNationalState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.hareAndHoundsState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.aroundTheClockState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.aroundTheClock180State {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.chaseTheDragonState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.nineLivesState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.raidState {
            let currentHero = state.heroes.indices.contains(state.currentHeroIndex)
                ? state.heroes[state.currentHeroIndex].playerId
                : nil
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.isComplete ? nil : currentHero,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.fleetState {
            projectFleetState(&runtime, fleetState: state, timestamp: timestamp)
        }
    }

    private static func projectRotatingPlayerState(
        _ runtime: inout MatchRuntimeState,
        currentTurnPlayerId: UUID,
        legIndex: Int,
        setIndex: Int = 0,
        isComplete: Bool,
        winnerPlayerId: UUID?,
        timestamp: Date
    ) {
        runtime.currentTurnPlayerId = currentTurnPlayerId
        runtime.currentLegIndex = legIndex
        runtime.currentSetIndex = setIndex
        if isComplete {
            runtime.status = .completed
            runtime.endedAt = timestamp
            runtime.winnerPlayerId = winnerPlayerId
            runtime.currentTurnPlayerId = nil
        }
    }

    private static func projectKillerState(
        _ runtime: inout MatchRuntimeState,
        killerState: KillerState,
        timestamp: Date
    ) {
        if killerState.phase == .numberPick, let pickerId = killerState.pickQueue.first {
            runtime.currentTurnPlayerId = pickerId
        } else if !killerState.isComplete {
            runtime.currentTurnPlayerId = killerState.players[killerState.currentPlayerIndex].playerId
        }
        runtime.currentLegIndex = 0
        runtime.currentSetIndex = 0
        if killerState.isComplete {
            runtime.status = .completed
            runtime.endedAt = timestamp
            runtime.winnerPlayerId = killerState.winnerPlayerId
            runtime.currentTurnPlayerId = nil
        }
    }

    private static func projectFleetState(
        _ runtime: inout MatchRuntimeState,
        fleetState: FleetState,
        timestamp: Date
    ) {
        runtime.currentTurnPlayerId = fleetState.phase == .hunt ? fleetState.currentPlayerId : nil
        runtime.currentLegIndex = 0
        runtime.currentSetIndex = 0
        if fleetState.isComplete {
            runtime.status = .completed
            runtime.endedAt = timestamp
            runtime.winnerPlayerId = fleetState.winnerPlayerId
            runtime.currentTurnPlayerId = nil
        }
    }

    private static func projectStandardTurnState(
        _ runtime: inout MatchRuntimeState,
        currentTurnPlayerId: UUID?,
        legIndex: Int = 0,
        setIndex: Int = 0,
        isComplete: Bool,
        winnerPlayerId: UUID?,
        timestamp: Date
    ) {
        runtime.currentTurnPlayerId = currentTurnPlayerId
        runtime.currentLegIndex = legIndex
        runtime.currentSetIndex = setIndex
        if isComplete {
            runtime.status = .completed
            runtime.endedAt = timestamp
            runtime.winnerPlayerId = winnerPlayerId
            runtime.currentTurnPlayerId = nil
        }
    }
}
