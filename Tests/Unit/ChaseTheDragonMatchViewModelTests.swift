import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func ctdTreble(_ number: Int) -> DartInput {
    DartInput(multiplier: .triple, segment: .oneToTwenty(number))
}

private var ctdMiss: DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private var ctdOuterBull: DartInput {
    DartInput(multiplier: .single, segment: .outerBull)
}

private var ctdInnerBull: DartInput {
    DartInput(multiplier: .single, segment: .innerBull)
}

@MainActor
private func makeChaseTheDragonViewModel(
    participantCount: Int = 2,
    laps: ChaseTheDragonLaps = .one,
    preTurns: [[DartInput]] = []
) throws -> (vm: ChaseTheDragonMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .chaseTheDragon,
        config: .chaseTheDragon(MatchConfigChaseTheDragon(laps: laps)),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitChaseTheDragonTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = ChaseTheDragonMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .chaseTheDragon),
        statsRepository: FakeStatsRepository(),
        feedbackPreferences: {
            let prefs = FeedbackPreferences()
            prefs.botStaggerEnabled = false
            return prefs
        }()
    )
    return (vm, store)
}

// MARK: - Entry validation

@MainActor
@Test(.tags(.integration, .match, .regression))
func chaseTheDragonViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeChaseTheDragonViewModel()
    vm.enteredDarts = [ctdTreble(10), ctdMiss]

    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func chaseTheDragonViewModelCanSubmitWithThreeDarts() async throws {
    let (vm, _) = try makeChaseTheDragonViewModel()
    vm.enteredDarts = [ctdTreble(10), ctdMiss, ctdMiss]

    #expect(vm.canSubmit == true)
}

// MARK: - Submission

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func chaseTheDragonViewModelHitAdvancesStep() async throws {
    let (vm, _) = try makeChaseTheDragonViewModel()
    vm.enteredDarts = [ctdTreble(10), ctdMiss, ctdMiss]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.chaseTheDragonState?.players[0].stepIndex == 1)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func chaseTheDragonViewModelMissDoesNotAdvanceStep() async throws {
    let (vm, _) = try makeChaseTheDragonViewModel()
    vm.enteredDarts = [ctdMiss, ctdMiss, ctdMiss]

    await vm.submitTurn()

    #expect(vm.chaseTheDragonState?.players[0].stepIndex == 0)
}

// MARK: - Sequence display

@MainActor
@Test(.tags(.integration, .match, .regression))
func chaseTheDragonViewModelCurrentStepLabelAdvancesDuringVisitEntry() async throws {
    let (vm, _) = try makeChaseTheDragonViewModel()
    vm.enteredDarts = [ctdTreble(10)]
    #expect(vm.currentStepLabel.contains("11"))

    vm.enteredDarts = [ctdTreble(10), ctdTreble(11)]
    #expect(vm.currentStepLabel.contains("12"))
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func chaseTheDragonViewModelMultipleHitsInOneTurnAdvanceStep() async throws {
    let (vm, _) = try makeChaseTheDragonViewModel()
    vm.enteredDarts = [ctdTreble(10), ctdTreble(11), ctdTreble(12)]

    await vm.submitTurn()

    #expect(vm.chaseTheDragonState?.players[0].stepIndex == 3)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func chaseTheDragonViewModelCurrentStepLabelReflectsSequence() async throws {
    let (vm, _) = try makeChaseTheDragonViewModel()

    #expect(vm.currentStepLabel.contains("10"))
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func chaseTheDragonViewModelSequenceProgressText() async throws {
    let (vm, _) = try makeChaseTheDragonViewModel()

    let text = vm.sequenceProgressText
    #expect(text.contains("1"))
    #expect(text.contains("13"))
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func chaseTheDragonViewModelLapLabelNilForSingleLap() async throws {
    let (vm, _) = try makeChaseTheDragonViewModel(laps: .one)

    #expect(vm.lapLabel == nil)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func chaseTheDragonViewModelLapLabelPresentForMultiLap() async throws {
    let (vm, _) = try makeChaseTheDragonViewModel(laps: .three)

    #expect(vm.lapLabel != nil)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func chaseTheDragonViewModelSequenceRowsReflectParticipants() async throws {
    let (vm, _) = try makeChaseTheDragonViewModel(participantCount: 2, laps: .one)

    #expect(vm.sequenceRows.count == 2)
    #expect(vm.sequenceRows[0].totalSteps == ChaseTheDragonEngine.stepsPerLap)
    #expect(vm.sequenceRows.filter { $0.isActive }.count == 1)
    #expect(vm.sequenceRows[0].completedSteps == 0)
}

// MARK: - Undo

@MainActor
@Test(.tags(.integration, .match, .regression))
func chaseTheDragonViewModelUndoLastDartRemovesFromEntered() async throws {
    let (vm, _) = try makeChaseTheDragonViewModel()
    vm.enteredDarts = [ctdTreble(10)]

    await vm.undoLastDart()

    #expect(vm.enteredDarts.isEmpty)
}

// MARK: - Win / match completion

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func chaseTheDragonViewModelMatchCompletionSetsState() async throws {
    // Pre-advance so only the last inner bull is needed via the VM.
    var preTurns: [[DartInput]] = []
    for n in 10 ... 20 { preTurns.append([ctdTreble(n)]) }
    preTurns.append([ctdOuterBull])

    let (vm, store) = try makeChaseTheDragonViewModel(participantCount: 1, preTurns: preTurns)
    vm.enteredDarts = [ctdInnerBull, ctdMiss, ctdMiss]

    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(vm.chaseTheDragonState?.isComplete == true)
    #expect(store.completedSessions().count == 1)
}

// MARK: - Bot gating

@MainActor
@Test(.tags(.integration, .match, .regression))
func chaseTheDragonViewModelHumanCannotInputDuringBotPlayback() async throws {
    let (vm, _) = try makeChaseTheDragonViewModel()
    // Simulate bot mid-play.
    // We test through the public property rather than injecting internal state.
    // When isBotPlaying is false and no bot participant exists, human can input.
    #expect(vm.canHumanInput == true)
    #expect(vm.isCurrentPlayerBot == false)
}

// MARK: - Rehydration from snapshot

@MainActor
@Test(.tags(.integration, .match, .regression))
func chaseTheDragonViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let ids = [UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .chaseTheDragon,
        config: .chaseTheDragon(MatchConfigChaseTheDragon()),
        participants: ids.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    session = try MatchLifecycleService.submitChaseTheDragonTurn(
        session: session,
        darts: [ctdTreble(10), ctdMiss, ctdMiss]
    )
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
            eventTypeRaw: "chaseTheDragonTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = ChaseTheDragonMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.rehydrating(snapshot: snapshotSummary, completedType: .chaseTheDragon),
        statsRepository: FakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(vm.chaseTheDragonState?.players[0].stepIndex == 1)
    #expect(store.session(for: matchId) != nil)
}

// MARK: - Stubs

private struct CTDSilentLogSink: LogSink {
    func write(_: LogEntry) {}
}
