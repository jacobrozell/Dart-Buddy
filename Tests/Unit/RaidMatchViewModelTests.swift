import Foundation
import Testing
@testable import DartBuddy

@MainActor
private func makeRaidViewModel(
    heroCount: Int = 2,
    bossTier: RaidBossTier = .challenger,
    heroHearts: Int = 3
) throws -> (vm: RaidMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< heroCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "Hero\(index + 1)", turnOrder: index)
    }
    let session = try MatchLifecycleService.createMatch(
        type: .raid,
        config: .raid(MatchConfigRaid(bossTier: bossTier, heroHearts: heroHearts, enrageEnabled: true)),
        participants: participants
    )
    let store = ActiveMatchStore()
    store.save(session)
    let vm = RaidMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .raid),
        statsRepository: FakeStatsRepository()
    )
    return (vm, store)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func raidViewModelLoadsBossChromeAndHeader() async throws {
    let (vm, _) = try makeRaidViewModel()
    await vm.onAppear()

    #expect(vm.raidState != nil)
    #expect(vm.state == .readyTurn)
    #expect(vm.coopChromeHeroes.count == 2)
    #expect(vm.headerText.contains(L10n.string("play.raid.phase.shield")))
    #expect(vm.headerAccessibilityLabel.contains(L10n.string("play.raid.navTitle")))
    #expect(vm.headerAccessibilityLabel.contains("Hero1"))
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func raidViewModelUndoClearsMidEntryDartsWithoutSubmitting() async throws {
    let (vm, _) = try makeRaidViewModel()
    await vm.onAppear()

    vm.enteredDarts = [
        DartInput(multiplier: .single, segment: .oneToTwenty(20)),
        DartInput(multiplier: .single, segment: .miss, isMiss: true)
    ]
    #expect(vm.canSubmit == false)

    await vm.undoLastDart()
    #expect(vm.enteredDarts.count == 1)
    #expect(vm.state == .readyTurn)

    await vm.undoLastDart()
    #expect(vm.enteredDarts.isEmpty)
    #expect(vm.state == .readyTurn)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func raidViewModelRejectsPartialTurnSubmit() async throws {
    let (vm, _) = try makeRaidViewModel()
    await vm.onAppear()

    vm.enteredDarts = [DartInput(multiplier: .single, segment: .oneToTwenty(20))]
    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func raidViewModelSubmitsFullVisitAndAdvances() async throws {
    let (vm, _) = try makeRaidViewModel()
    await vm.onAppear()
    let bossBefore = try #require(vm.raidState?.bossHP)

    vm.enteredDarts = [
        DartInput(multiplier: .single, segment: .miss, isMiss: true),
        DartInput(multiplier: .single, segment: .miss, isMiss: true),
        DartInput(multiplier: .single, segment: .miss, isMiss: true)
    ]
    await vm.submitTurn()

    #expect(vm.state == .readyTurn || vm.state == .matchCompleted)
    #expect(vm.enteredDarts.isEmpty)
    if let bossAfter = vm.raidState?.bossHP {
        #expect(bossAfter == bossBefore)
    }
}
