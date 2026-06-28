import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func englishCricketDart(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

private func bull() -> DartInput {
    DartInput(multiplier: .single, segment: .outerBull)
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

@MainActor
private func makeEnglishCricketViewModel(
    wicketsPerInnings: Int = 10,
    endWhenTargetPassed: Bool = true,
    runsThreshold: Int = 40,
    preTurns: [[DartInput]] = []
) throws -> (vm: EnglishCricketMatchViewModel, store: ActiveMatchStore) {
    let ids = [UUID(), UUID()]
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .englishCricket,
        config: .englishCricket(MatchConfigEnglishCricket(
            wicketsPerInnings: wicketsPerInnings,
            runsThreshold: runsThreshold,
            endWhenTargetPassed: endWhenTargetPassed
        )),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitEnglishCricketTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = EnglishCricketMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .englishCricket),
        statsRepository: FakeStatsRepository(),
        feedbackPreferences: {
            let prefs = FeedbackPreferences()
            prefs.botStaggerEnabled = false
            return prefs
        }()
    )
    return (vm, store)
}

// MARK: - Tests

@MainActor
@Test(.tags(.integration, .match, .regression))
func englishCricketViewModelInitialStateIsBatting() async throws {
    let (vm, _) = try makeEnglishCricketViewModel()

    #expect(vm.isBatterPhase == true)
    #expect(vm.isBowlerPhase == false)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func englishCricketViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeEnglishCricketViewModel()
    vm.enteredDarts = [englishCricketDart(.single, 20), englishCricketDart(.double, 20)]

    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func englishCricketViewModelBatterSubmitScoresRuns() async throws {
    let (vm, _) = try makeEnglishCricketViewModel(runsThreshold: 40)
    // 60+20+5 = 85 raw → 45 runs
    vm.enteredDarts = [
        englishCricketDart(.triple, 20),
        englishCricketDart(.single, 20),
        englishCricketDart(.single, 5)
    ]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.englishCricketState?.players[0].totalRuns == 45)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func englishCricketViewModelPhaseSwapsAfterBatterTurn() async throws {
    let (vm, _) = try makeEnglishCricketViewModel()
    vm.enteredDarts = [miss(), miss(), miss()]

    await vm.submitTurn()

    #expect(vm.englishCricketState?.phase == .bowling)
    #expect(vm.isBowlerPhase == true)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func englishCricketViewModelPadHintDiffersPerPhase() async throws {
    let (vm, _) = try makeEnglishCricketViewModel()

    let batterHint = vm.padHint
    vm.enteredDarts = [miss(), miss(), miss()]
    await vm.submitTurn()
    let bowlerHint = vm.padHint

    #expect(batterHint == L10n.string("play.englishCricket.pad.fullBoardHint"))
    #expect(bowlerHint == L10n.string("play.englishCricket.pad.bullOnlyHint"))
    #expect(batterHint != bowlerHint)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func englishCricketViewModelHeaderAccessibilityContainsTitle() async throws {
    let (vm, _) = try makeEnglishCricketViewModel()

    #expect(vm.headerAccessibilityLabel.contains(L10n.string("play.englishCricket.navTitle")))
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func englishCricketViewModelScoreboardRowsExposeBatterAndBowler() async throws {
    let (vm, _) = try makeEnglishCricketViewModel()

    #expect(vm.scoreboardRows.count == 2)
    #expect(vm.scoreboardRows.contains { $0.isBatter })
    #expect(vm.scoreboardRows.contains { $0.isBowler })
    #expect(vm.scoreboardRows.filter { $0.isActiveTurn }.count == 1)
    let bowler = try #require(vm.scoreboardRows.first { $0.isBowler })
    #expect(bowler.wicketsRemaining == 10)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func englishCricketViewModelMatchCompletesAfterBothInnings() async throws {
    let (vm, store) = try makeEnglishCricketViewModel(
        wicketsPerInnings: 1,
        endWhenTargetPassed: false,
        runsThreshold: 0
    )

    // Innings 0: batter (miss = 0 runs), bowler takes 1 wicket.
    vm.enteredDarts = [miss(), miss(), miss()]
    await vm.submitTurn()
    vm.enteredDarts = [bull(), miss(), miss()]
    await vm.submitTurn()

    // Innings 1: batter (miss = 0 runs), bowler takes 1 wicket.
    vm.enteredDarts = [miss(), miss(), miss()]
    await vm.submitTurn()
    vm.enteredDarts = [bull(), miss(), miss()]
    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(vm.englishCricketState?.isComplete == true)
    #expect(store.completedSessions().count == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func englishCricketViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let ids = [UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .englishCricket,
        config: .englishCricket(MatchConfigEnglishCricket()),
        participants: ids.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    session = try MatchLifecycleService.submitEnglishCricketTurn(
        session: session,
        darts: [miss(), miss(), miss()]
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
            eventTypeRaw: "englishCricketTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = EnglishCricketMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.rehydrating(snapshot: snapshotSummary, completedType: .englishCricket),
        statsRepository: FakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(store.session(for: matchId) != nil)
}

// MARK: - Test Doubles

private struct EnglishCricketSilentLogSink: LogSink {
    func write(_: LogEntry) {}
}
