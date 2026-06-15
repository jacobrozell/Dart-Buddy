import Foundation
import Testing
@testable import DartBuddy

private func killerDart(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

private func killerPick(_ segment: Int) -> DartInput {
    killerDart(.single, segment)
}

@MainActor
private func makeKillerViewModel(
    participantCount: Int = 3,
    prePicks: [Int] = [],
    preTurns: [[DartInput]] = []
) throws -> (vm: KillerMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .killer,
        config: .killer(MatchConfigKiller()),
        participants: participants
    )
    for number in prePicks {
        session = try MatchLifecycleService.submitKillerPick(session: session, dart: killerPick(number))
    }
    for darts in preTurns {
        session = try MatchLifecycleService.submitKillerTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = KillerMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .killer),
        statsRepository: FakeStatsRepository(),
        feedbackPreferences: {
            let prefs = FeedbackPreferences()
            prefs.botStaggerEnabled = false
            return prefs
        }()
    )
    return (vm, store)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func killerViewModelStartsInPickPhase() async throws {
    let (vm, _) = try makeKillerViewModel(participantCount: 3)

    #expect(vm.isPickPhase)
    #expect(vm.state == .readyPick)
    #expect(vm.canSubmit == false)
    #expect(!vm.headerText.isEmpty)
    #expect(vm.targetHint == L10n.string("play.killer.pickHint"))
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func killerViewModelRequiresSingleDartDuringPick() async throws {
    let (vm, _) = try makeKillerViewModel(participantCount: 3)
    vm.enteredDarts = [killerPick(5), killerPick(12)]

    #expect(vm.canSubmit == false)
    #expect(vm.maxDartsPerSubmission == 1)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func killerViewModelSubmitPickAdvancesToPlaying() async throws {
    let (vm, _) = try makeKillerViewModel(participantCount: 3)
    vm.enteredDarts = [killerPick(5)]

    await vm.submitTurn()

    #expect(vm.enteredDarts.isEmpty)
    #expect(vm.killerState?.players.contains(where: { $0.assignedNumber == 5 }) == true)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func killerViewModelHumanSubmitTurnAfterPickPhase() async throws {
    let (vm, _) = try makeKillerViewModel(prePicks: [5, 12, 20])
    let miss = DartInput(multiplier: .single, segment: .miss, isMiss: true)
    vm.enteredDarts = [miss, miss, miss]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.killerState?.phase == .playing)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func killerViewModelScoreboardMarksActiveThrower() async throws {
    let (vm, _) = try makeKillerViewModel(prePicks: [5, 12, 20])
    let activeRows = vm.scoreboardRows.filter(\.isActive)

    #expect(activeRows.count == 1)
    #expect(vm.numberGridAssignments.count == 3)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func killerViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let ids = [UUID(), UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .killer,
        config: .killer(MatchConfigKiller()),
        participants: ids.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    session = try MatchLifecycleService.submitKillerPick(session: session, dart: killerPick(7))
    let matchId = session.runtime.matchId
    let snapshot = session.latestSnapshot
    let snapshotSummary = MatchSnapshotSummary(
        id: UUID(),
        matchId: matchId,
        snapshotVersion: snapshot.payloadVersion,
        snapshotPayload: snapshot.payload,
        updatedAt: Date()
    )
    let eventSummaries = try session.events.map { envelope in
        MatchEventSummary(
            id: UUID(),
            matchId: matchId,
            eventIndex: envelope.eventIndex,
            eventTypeRaw: "killerPick",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = KillerMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.rehydrating(snapshot: snapshotSummary, completedType: .killer),
        statsRepository: FakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(vm.killerState?.players.contains(where: { $0.assignedNumber == 7 }) == true)
    #expect(store.session(for: matchId) != nil)
}

private struct KillerSilentLogSink: LogSink {
    func write(_: LogEntry) {}
}
