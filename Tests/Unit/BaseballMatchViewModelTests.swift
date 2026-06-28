import Foundation
import Testing
@testable import DartBuddy

private func baseballDart(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

@MainActor
private func makeBaseballViewModel(
    participantCount: Int = 2,
    inningCount: Int = 1,
    tieBreaker: BaseballTieBreaker = .extraInnings,
    preTurns: [[DartInput]] = []
) throws -> (vm: BaseballMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .baseball,
        config: .baseball(MatchConfigBaseball(inningCount: inningCount, tieBreaker: tieBreaker)),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitBaseballTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = BaseballMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .baseball),
        statsRepository: FakeStatsRepository()
    )
    return (vm, store)
}

@MainActor
@Test(.tags(.integration, .baseball, .match, .critical, .regression))
func baseballViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let p0 = UUID()
    let p1 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .baseball,
        config: .baseball(MatchConfigBaseball()),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitBaseballTurn(session: session, darts: [baseballDart(.single, 1)])
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
            eventTypeRaw: "baseballTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = BaseballMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.rehydrating(snapshot: snapshotSummary, completedType: .baseball),
        statsRepository: FakeStatsRepository(events: eventSummaries)
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(vm.baseballState?.players[0].cumulativeRuns == 1)
    #expect(store.session(for: matchId) != nil)
}

@MainActor
@Test(.tags(.integration, .baseball, .match, .critical, .regression))
func baseballViewModelHumanSubmitUpdatesRuns() async throws {
    let (vm, _) = try makeBaseballViewModel()
    vm.enteredDarts = [
        baseballDart(.single, 1),
        baseballDart(.double, 1),
        DartInput(multiplier: .single, segment: .miss, isMiss: true)
    ]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.baseballState?.players[0].cumulativeRuns == 3)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .baseball, .match, .regression))
func baseballViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeBaseballViewModel()
    vm.enteredDarts = [baseballDart(.single, 1), baseballDart(.double, 1)]

    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .baseball, .match, .critical, .regression))
func baseballViewModelCompletesSingleInningMatch() async throws {
    let (vm, store) = try makeBaseballViewModel(
        inningCount: 1,
        preTurns: [[baseballDart(.single, 1)]]
    )
    vm.enteredDarts = [
        baseballDart(.triple, 1),
        DartInput(multiplier: .single, segment: .miss, isMiss: true),
        DartInput(multiplier: .single, segment: .miss, isMiss: true)
    ]

    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(store.completedSessions().count == 1)
    #expect(vm.baseballState?.winnerPlayerId != nil)
}

@MainActor
@Test(.tags(.integration, .baseball, .match, .regression))
func baseballViewModelScoreboardShowsPlayoffRoundRuns() async throws {
    let (vm, _) = try makeBaseballViewModel(
        inningCount: 1,
        tieBreaker: .bullPlayoff,
        preTurns: [
            [baseballDart(.single, 1)],
            [baseballDart(.single, 1)]
        ]
    )

    #expect(vm.baseballState?.phase == .bullPlayoff)
    vm.enteredDarts = [
        DartInput(multiplier: .single, segment: .outerBull),
        DartInput(multiplier: .single, segment: .miss, isMiss: true),
        DartInput(multiplier: .single, segment: .miss, isMiss: true)
    ]

    let row = vm.scoreboardRows.first
    #expect(row?.visitRunsKind == .playoffRound)
    #expect(row?.visitRuns == 1)
    #expect(row?.isLeading == true)
}

@MainActor
@Test(.tags(.integration, .baseball, .match, .regression))
func baseballViewModelHidesInningStripDuringPlayoff() async throws {
    let (vm, _) = try makeBaseballViewModel(
        inningCount: 1,
        tieBreaker: .bullPlayoff,
        preTurns: [
            [baseballDart(.single, 1)],
            [baseballDart(.single, 1)]
        ]
    )

    #expect(vm.showsInningProgressStrip == false)
}

@MainActor
@Test(.tags(.integration, .baseball, .match, .regression))
func baseballViewModelHeaderAccessibilityIncludesTitleAndPhase() async throws {
    let (vm, _) = try makeBaseballViewModel(
        inningCount: 1,
        tieBreaker: .bullPlayoff,
        preTurns: [
            [baseballDart(.single, 1)],
            [baseballDart(.single, 1)]
        ]
    )

    #expect(vm.headerAccessibilityLabel.contains(L10n.string("play.baseball.title")))
    #expect(vm.headerAccessibilityLabel.contains(L10n.string("play.baseball.header.bullPlayoff")))
}

private struct BaseballSilentLogSink: LogSink {
    func write(_: LogEntry) {}
}
