import Foundation
import Testing
@testable import DartBuddy

@Suite struct FleetEngineTests {
    private let p1 = UUID()
    private let p2 = UUID()

    @Test func makeInitialStateRequiresTwoPlayers() throws {
        #expect(throws: AppError.self) {
            try FleetEngine.makeInitialState(config: MatchConfigFleet(), playerIds: [p1])
        }
    }

    @Test func placementLockStartsHunt() throws {
        var state = try FleetEngine.makeInitialState(config: MatchConfigFleet(shipCount: .quick), playerIds: [p1, p2])
        guard case let .handoff(firstPlayer) = state.placementUIStep else {
            Issue.record("Expected handoff step at placement start")
            return
        }
        state = try FleetEngine.confirmHandoff(state: state, playerId: firstPlayer).0
        for segment in 1 ... 3 {
            state = try FleetEngine.togglePlacementCell(state: state, playerId: firstPlayer, cell: .segment(segment))
        }
        let first = try FleetEngine.lockPlacement(state: state, playerId: firstPlayer)
        #expect(first.updatedState.placementLocks[firstPlayer] == true)
        #expect(first.updatedState.phase == .placement)

        var secondState = first.updatedState
        guard let secondPlayer = secondState.opponentId(for: firstPlayer) else {
            Issue.record("Expected two-player fleet match")
            return
        }
        secondState = try FleetEngine.confirmPassDevice(state: secondState, playerId: secondPlayer).0
        secondState = try FleetEngine.confirmHandoff(state: secondState, playerId: secondPlayer).0
        for segment in 10 ... 12 {
            secondState = try FleetEngine.togglePlacementCell(state: secondState, playerId: secondPlayer, cell: .segment(segment))
        }
        let second = try FleetEngine.lockPlacement(state: secondState, playerId: secondPlayer)
        #expect(second.updatedState.phase == .hunt)
        #expect(second.updatedState.currentPlayerId == firstPlayer)
    }

    @Test func tripleAutoSinksArmoredShip() throws {
        var state = makeHuntState(shipHealth: .armored, ships: [.segment(20)])
        state = try FleetEngine.setCall(state: state, playerId: p1, cell: .segment(20))
        let outcome = try FleetEngine.submitDart(
            state: state,
            playerId: p1,
            dart: DartInput(multiplier: .triple, segment: .oneToTwenty(20))
        )
        #expect(outcome.event.outcome == .sink)
        #expect(outcome.updatedState.fleets[p2]?.sunk.contains(.segment(20)) == true)
    }

    @Test func strictWildMissDoesNotProbe() throws {
        var state = makeHuntState(ships: [.segment(20)])
        state = try FleetEngine.setCall(state: state, playerId: p1, cell: .segment(20))
        let outcome = try FleetEngine.submitDart(
            state: state,
            playerId: p1,
            dart: DartInput(multiplier: .single, segment: .oneToTwenty(19))
        )
        #expect(outcome.event.outcome == .wildMiss)
        #expect(outcome.updatedState.probeMaps[p1]?[.segment(20)] == nil)
    }

    @Test func callOnlyAppliesSingleDamage() throws {
        var state = makeHuntState(callMode: .callOnly, shipHealth: .armored, ships: [.segment(18)])
        state = try FleetEngine.setCall(state: state, playerId: p1, cell: .segment(18))
        let outcome = try FleetEngine.submitDart(
            state: state,
            playerId: p1,
            dart: DartInput(multiplier: .triple, segment: .oneToTwenty(19), isMiss: true)
        )
        #expect(outcome.event.outcome == .hit)
        #expect(outcome.updatedState.fleets[p2]?.damage[.segment(18)] == 1)
    }

    @Test func sonarDoesNotSink() throws {
        var state = makeHuntState(ships: [.segment(5)])
        let outcome = try FleetEngine.useSonar(state: state, playerId: p1, cell: .segment(5))
        #expect(outcome.event.inFleet)
        #expect(outcome.updatedState.fleets[p2]?.sunk.isEmpty == true)
        #expect(outcome.updatedState.fleets[p1]?.sonarRemaining == 0)
    }

    private func makeHuntState(
        callMode: FleetCallMode = .strict,
        shipHealth: FleetShipHealth = .fragile,
        ships: Set<FleetBoardCell>
    ) -> FleetState {
        FleetState(
            config: MatchConfigFleet(shipCount: .quick, shipHealth: shipHealth, callMode: callMode),
            playerIds: [p1, p2],
            phase: .hunt,
            currentPlayerIndex: 0,
            fleets: [
                p1: FleetPlayerFleet(ships: [], sonarRemaining: 1),
                p2: FleetPlayerFleet(ships: ships, sonarRemaining: 1)
            ],
            probeMaps: [p1: [:], p2: [:]],
            placementLocks: [p1: true, p2: true],
            placementUIStep: .placementComplete
        )
    }
}
