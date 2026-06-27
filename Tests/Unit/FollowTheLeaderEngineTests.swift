import Foundation
import Testing
@testable import DartBuddy

@Suite("Follow the Leader engine", .tags(.unit, .match, .regression))
struct FollowTheLeaderEngineTests {
    private func makePlayers(_ count: Int = 2) -> [UUID] {
        (0 ..< count).map { _ in UUID() }
    }

    private func single(_ segment: Int) -> DartInput {
        DartInput(multiplier: .single, segment: .oneToTwenty(segment), isMiss: false)
    }

    private func double(_ segment: Int) -> DartInput {
        DartInput(multiplier: .double, segment: .oneToTwenty(segment), isMiss: false)
    }

    private func miss() -> DartInput {
        DartInput(multiplier: .single, segment: .miss, isMiss: true)
    }

    @Test
    func followTheLeaderRequiresAtLeastTwoPlayers() {
        #expect(throws: (any Error).self) {
            _ = try FollowTheLeaderEngine.makeInitialState(
                config: MatchConfigFollowTheLeader(),
                playerIds: makePlayers(1)
            )
        }
    }

    @Test
    func openingDartSetsTarget() throws {
        let players = makePlayers()
        var state = try FollowTheLeaderEngine.makeInitialState(
            config: MatchConfigFollowTheLeader(),
            playerIds: players
        )
        #expect(state.needsOpeningTarget)

        let outcome = try FollowTheLeaderEngine.submitVisit(state: state, darts: [double(12)])
        state = outcome.updatedState

        #expect(outcome.event.setOpeningTarget)
        #expect(state.target?.segment == 12)
        #expect(state.target?.ring == .double)
        #expect(!state.needsOpeningTarget)
    }

    @Test
    func missCostsLife() throws {
        let players = makePlayers()
        var state = try FollowTheLeaderEngine.makeInitialState(
            config: MatchConfigFollowTheLeader(),
            playerIds: players
        )
        state = try FollowTheLeaderEngine.submitVisit(state: state, darts: [double(8)]).updatedState

        let startingLives = state.config.startingLives
        let outcome = try FollowTheLeaderEngine.submitVisit(
            state: state,
            darts: [miss(), miss(), miss()]
        )
        state = outcome.updatedState

        #expect(outcome.event.lifeLost)
        #expect(state.players[1].lives == startingLives - 1)
    }

    @Test
    func spareDartsCanSetNewTarget() throws {
        let players = makePlayers()
        var state = try FollowTheLeaderEngine.makeInitialState(
            config: MatchConfigFollowTheLeader(),
            playerIds: players
        )
        state = try FollowTheLeaderEngine.submitVisit(state: state, darts: [double(8)]).updatedState

        let outcome = try FollowTheLeaderEngine.submitVisit(
            state: state,
            darts: [double(8), single(15)]
        )
        state = outcome.updatedState

        #expect(outcome.event.matched)
        #expect(state.target?.segment == 15)
        #expect(state.target?.ring == .single)
        #expect(state.targetSetterId == players[1])
    }

    @Test
    func allMissOfferPassDecision() throws {
        let players = makePlayers(3)
        var state = try FollowTheLeaderEngine.makeInitialState(
            config: MatchConfigFollowTheLeader(),
            playerIds: players
        )
        state = try FollowTheLeaderEngine.submitVisit(state: state, darts: [double(6)]).updatedState

        state = try FollowTheLeaderEngine.submitVisit(state: state, darts: [miss(), miss(), miss()]).updatedState
        state = try FollowTheLeaderEngine.submitVisit(state: state, darts: [miss(), miss(), miss()]).updatedState

        #expect(state.awaitingPassDecision)
        #expect(state.currentPlayerId == players[0])
    }

    @Test
    func passAdvancesToNextPlayer() throws {
        let players = makePlayers(3)
        var state = try FollowTheLeaderEngine.makeInitialState(
            config: MatchConfigFollowTheLeader(),
            playerIds: players
        )
        state = try FollowTheLeaderEngine.submitVisit(state: state, darts: [double(6)]).updatedState
        state = try FollowTheLeaderEngine.submitVisit(state: state, darts: [miss(), miss(), miss()]).updatedState
        state = try FollowTheLeaderEngine.submitVisit(state: state, darts: [miss(), miss(), miss()]).updatedState

        let outcome = try FollowTheLeaderEngine.submitPass(state: state)
        state = outcome.updatedState

        #expect(outcome.event.passed)
        #expect(!state.awaitingPassDecision)
        #expect(state.currentPlayerId == players[1])
    }

    @Test
    func lastPlayerWithLivesWins() throws {
        let players = makePlayers(2)
        var state = try FollowTheLeaderEngine.makeInitialState(
            config: MatchConfigFollowTheLeader(startingLives: 1),
            playerIds: players
        )
        state = try FollowTheLeaderEngine.submitVisit(state: state, darts: [double(4)]).updatedState
        state = try FollowTheLeaderEngine.submitVisit(state: state, darts: [miss(), miss(), miss()]).updatedState

        #expect(state.isComplete)
        #expect(state.winnerPlayerId == players[0])
    }
}
