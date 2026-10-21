import Foundation
import Testing
@testable import DartBuddy

private var bobsMiss: DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private func bobsDouble(_ number: Int) -> DartInput {
    DartInput(multiplier: .double, segment: .oneToTwenty(number))
}

@MainActor
private func makeBobs27ViewModel(
    preRounds: [[DartInput]] = []
) throws -> (vm: Bobs27MatchViewModel, store: ActiveMatchStore) {
    let playerId = UUID()
    let participants = [
        MatchParticipant(playerId: playerId, displayNameAtMatchStart: "P1", turnOrder: 0)
    ]
    var session = try MatchLifecycleService.createMatch(
        type: .bobs27,
        config: .bobs27(MatchConfigBobs27()),
        participants: participants
    )
    for darts in preRounds {
        session = try MatchLifecycleService.submitBobs27Round(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = Bobs27MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .bobs27),
        statsRepository: FakeStatsRepository()
    )
    return (vm, store)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func bobs27ViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeBobs27ViewModel()
    vm.enteredDarts = [bobsDouble(1), bobsMiss]
    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func bobs27ViewModelHitAddsScoreAndAdvancesRound() async throws {
    let (vm, _) = try makeBobs27ViewModel()
    #expect(vm.bobs27State?.score == 27)
    #expect(vm.bobs27State?.roundIndex == 0)

    vm.enteredDarts = [bobsDouble(1), bobsMiss, bobsMiss]
    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.bobs27State?.score == 29)
    #expect(vm.bobs27State?.roundIndex == 1)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func bobs27ViewModelMissSubtractsAndCanBustOut() async throws {
    let (vm, _) = try makeBobs27ViewModel()
    vm.enteredDarts = [bobsMiss, bobsMiss, bobsMiss]
    await vm.submitTurn()

    #expect(vm.bobs27State?.score == 25)
    #expect(vm.bobs27State?.roundIndex == 1)
}
