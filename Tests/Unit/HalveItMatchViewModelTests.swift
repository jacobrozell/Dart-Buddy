import Foundation
import Testing
@testable import DartBuddy

private var halveMiss: DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private func halveSingle(_ number: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(number))
}

@MainActor
private func makeHalveItViewModel(
    startingScore: Int = 301,
    preRounds: [[DartInput]] = []
) throws -> (vm: HalveItMatchViewModel, store: ActiveMatchStore) {
    let playerId = UUID()
    let participants = [
        MatchParticipant(playerId: playerId, displayNameAtMatchStart: "P1", turnOrder: 0)
    ]
    var session = try MatchLifecycleService.createMatch(
        type: .halveIt,
        config: .halveIt(MatchConfigHalveIt(startingScore: startingScore)),
        participants: participants
    )
    for darts in preRounds {
        session = try MatchLifecycleService.submitHalveItRound(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = HalveItMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .halveIt),
        statsRepository: FakeStatsRepository()
    )
    return (vm, store)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func halveItViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeHalveItViewModel()
    vm.enteredDarts = [halveSingle(20), halveMiss]
    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func halveItViewModelHitAddsVisitScore() async throws {
    let (vm, _) = try makeHalveItViewModel()
    #expect(vm.currentPlayerTotal == 301)
    #expect(vm.halveItState?.roundIndex == 0)

    vm.enteredDarts = [halveSingle(20), halveMiss, halveMiss]
    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.currentPlayerTotal == 321)
    #expect(vm.halveItState?.roundIndex == 1)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func halveItViewModelMissHalvesTotal() async throws {
    let (vm, _) = try makeHalveItViewModel(startingScore: 100)
    vm.enteredDarts = [halveMiss, halveMiss, halveMiss]
    await vm.submitTurn()

    #expect(vm.currentPlayerTotal == 50)
    #expect(vm.halveItState?.roundIndex == 1)
}
