import Foundation
import Testing
@testable import DartBuddy

@Suite("Blind Killer engine", .tags(.unit, .match, .regression))
struct BlindKillerEngineTests {
    private func makePlayers(_ count: Int = 3) -> [UUID] {
        (0 ..< count).map { _ in UUID() }
    }

    private func makeConfig(playerIds: [UUID], seed: UInt64 = 42) -> MatchConfigBlindKiller {
        let base = MatchConfigBlindKiller(assignmentSeed: seed)
        return BlindKillerEngine.resolvedConfig(base, playerIds: playerIds)
    }

    private func double(_ segment: Int) -> DartInput {
        DartInput(multiplier: .double, segment: .oneToTwenty(segment), isMiss: false)
    }

    @Test
    func blindKillerRequiresAtLeastThreePlayers() {
        #expect(throws: (any Error).self) {
            _ = try BlindKillerEngine.makeInitialState(
                config: makeConfig(playerIds: makePlayers(2)),
                playerIds: makePlayers(2)
            )
        }
    }

    @Test
    func assignmentsAreUniquePerPlayer() throws {
        let players = makePlayers(4)
        let config = makeConfig(playerIds: players, seed: 99)
        let numbers = players.compactMap { config.secretNumber(for: $0) }
        #expect(numbers.count == 4)
        #expect(Set(numbers).count == 4)
        #expect(numbers.allSatisfy { (1 ... 20).contains($0) })
    }

    @Test
    func doubleHitIncrementsSegmentTally() throws {
        let players = makePlayers()
        var state = try BlindKillerEngine.makeInitialState(
            config: makeConfig(playerIds: players),
            playerIds: players
        )
        let outcome = try BlindKillerEngine.submitTurn(state: state, darts: [double(5)])
        state = outcome.updatedState
        #expect(state.segmentHitCounts[5] == 1)
        #expect(outcome.event.darts.first?.doubleHitSegment == 5)
    }

    @Test
    func thirdDoubleHitEliminatesHolder() throws {
        let players = makePlayers()
        let config = makeConfig(playerIds: players, seed: 7)
        var state = try BlindKillerEngine.makeInitialState(config: config, playerIds: players)

        guard let victimSegment = config.secretNumber(for: players[1]) else {
            Issue.record("Missing assignment")
            return
        }

        for _ in 0 ..< 2 {
            state = try BlindKillerEngine.submitTurn(
                state: state,
                darts: [double(victimSegment)]
            ).updatedState
            #expect(state.players.first { $0.playerId == players[1] }?.isEliminated == false)
        }

        let final = try BlindKillerEngine.submitTurn(state: state, darts: [double(victimSegment)])
        #expect(final.updatedState.players.first { $0.playerId == players[1] }?.isEliminated == true)
        #expect(final.event.eliminatedPlayerIds.contains(players[1]))
    }

    @Test
    func lastPlayerStandingWins() throws {
        let players = makePlayers(3)
        let config = makeConfig(playerIds: players, seed: 11)
        var state = try BlindKillerEngine.makeInitialState(config: config, playerIds: players)

        for playerId in players.dropLast() {
            guard let segment = config.secretNumber(for: playerId) else { continue }
            for _ in 0 ..< 3 {
                state = try BlindKillerEngine.submitTurn(state: state, darts: [double(segment)]).updatedState
            }
        }

        #expect(state.isComplete)
        #expect(state.winnerPlayerId == players.last)
    }
}
