import Foundation
import Testing
@testable import DartBuddy

// State-machine coverage for the live X01 match view model using in-memory fakes.

@MainActor
private func makeX01ViewModel(
    totals: [Int],
    failAppend: Bool = false,
    seedSession: Bool = true
) throws -> (vm: X01MatchViewModel, matchId: UUID, store: ActiveMatchStore) {
    let p0 = UUID()
    let p1 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    for total in totals {
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: total, darts: nil)
    }
    let matchId = session.runtime.matchId
    let store = ActiveMatchStore()
    if seedSession { store.save(session) }
    let vm = X01MatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: SilentLogSink()),
        matchRepository: X01FakeMatchRepository(failAppend: failAppend),
        statsRepository: X01FakeStatsRepository()
    )
    return (vm, matchId, store)
}

/// Leaves player 0 on 40 remaining with player 1 to throw (301 start, alternating visits).
private let x01TotalsPlayer0OnForty: [Int] = [180, 0, 81, 0]

@MainActor
private func makeHumanBotX01ViewModel(preloadedTotals: [Int] = []) throws -> X01MatchViewModel {
    let humanId = UUID()
    let botId = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: humanId, displayNameAtMatchStart: "Human", turnOrder: 0),
            MatchParticipant(
                playerId: botId,
                displayNameAtMatchStart: BotDifficulty.easy.rosterName,
                turnOrder: 1,
                botDifficultyRaw: BotDifficulty.easy.rawValue
            )
        ]
    )
    for total in preloadedTotals {
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: total, darts: nil)
    }
    let store = ActiveMatchStore()
    store.save(session)
    return X01MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: SilentLogSink()),
        matchRepository: X01FakeMatchRepository(),
        statsRepository: X01FakeStatsRepository()
    )
}

@MainActor
private func makeDoubleOutX01ViewModel(
    totals: [Int],
    seedSession: Bool = true
) throws -> (vm: X01MatchViewModel, matchId: UUID, store: ActiveMatchStore) {
    let p0 = UUID()
    let p1 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    for total in totals {
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: total, darts: nil)
    }
    let matchId = session.runtime.matchId
    let store = ActiveMatchStore()
    if seedSession { store.save(session) }
    let vm = X01MatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: SilentLogSink()),
        matchRepository: X01FakeMatchRepository(),
        statsRepository: X01FakeStatsRepository()
    )
    return (vm, matchId, store)
}

/// Leaves player 0 on 60 remaining with player 0 to throw (301 start, alternating visits).
private let x01TotalsPlayer0OnSixty: [Int] = [180, 0, 61, 0]

@MainActor
@Test(.tags(.integration, .x01, .match, .critical, .regression))
func x01ViewModelCompletesOnValidDoubleOutFinish() async throws {
    let (vm, _, store) = try makeDoubleOutX01ViewModel(totals: x01TotalsPlayer0OnForty)
    vm.inputMode = .dartEntry
    vm.enteredDarts = [DartInput(multiplier: .double, segment: .oneToTwenty(20))]

    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(store.completedSessions().count == 1)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .critical, .regression))
func x01ViewModelShowsBustFeedbackOnInvalidDoubleOutFinish() async throws {
    let (vm, _, _) = try makeDoubleOutX01ViewModel(totals: x01TotalsPlayer0OnSixty)
    vm.inputMode = .dartEntry
    vm.enteredDarts = [DartInput(multiplier: .triple, segment: .oneToTwenty(20))]

    await vm.submitTurn()

    #expect(vm.state == .bustFeedback)
    #expect(vm.playerCards[0].score == 60)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelPlayerCardsCarryParticipantColor() async throws {
    let p0 = UUID()
    let p1 = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(
                playerId: p0,
                displayNameAtMatchStart: "A",
                turnOrder: 0,
                preferredColorTokenAtMatchStart: PlayerColorToken.blue.rawValue
            ),
            MatchParticipant(
                playerId: p1,
                displayNameAtMatchStart: "B",
                turnOrder: 1,
                preferredColorTokenAtMatchStart: PlayerColorToken.coral.rawValue
            )
        ]
    )
    let store = ActiveMatchStore()
    store.save(session)
    let vm = X01MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: SilentLogSink()),
        matchRepository: X01FakeMatchRepository(),
        statsRepository: X01FakeStatsRepository()
    )
    await vm.onAppear()

    #expect(vm.playerCards[0].colorToken == .blue)
    #expect(vm.playerCards[1].colorToken == .coral)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelPlayerCardsFallbackColorForLegacyParticipants() async throws {
    let p0 = UUID()
    let p1 = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(
                playerId: p0,
                displayNameAtMatchStart: "A",
                turnOrder: 0,
                preferredColorTokenAtMatchStart: nil
            ),
            MatchParticipant(
                playerId: p1,
                displayNameAtMatchStart: "B",
                turnOrder: 1,
                preferredColorTokenAtMatchStart: PlayerColorToken.coral.rawValue
            )
        ]
    )
    let store = ActiveMatchStore()
    store.save(session)
    let vm = X01MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: SilentLogSink()),
        matchRepository: X01FakeMatchRepository(),
        statsRepository: X01FakeStatsRepository()
    )
    await vm.onAppear()

    #expect(vm.playerCards[0].colorToken == PlayerColorToken.defaultForPlayer(id: p0))
}

@MainActor
@Test(.tags(.integration, .x01, .match, .critical, .regression))
func x01ViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let p0 = UUID()
    let p1 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
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
            eventTypeRaw: "x01Turn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = X01MatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: SilentLogSink()),
        matchRepository: X01RehydratingFakeMatchRepository(snapshot: snapshotSummary),
        statsRepository: X01RehydratingFakeStatsRepository(events: eventSummaries)
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(vm.playerCards[0].score == 241)
    #expect(store.session(for: matchId) != nil)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .critical, .regression))
func x01ViewModelEntersBustFeedbackOnOverflow() async throws {
    // Player 0 sits on 40 remaining; entering 100 overflows -> bust.
    let (vm, _, _) = try makeX01ViewModel(totals: x01TotalsPlayer0OnForty)
    vm.inputMode = .totalEntry
    vm.totalEntryText = "100"

    await vm.submitTurn()

    #expect(vm.state == .bustFeedback)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .critical, .regression))
func x01ViewModelCompletesMatchOnCheckout() async throws {
    let (vm, _, store) = try makeX01ViewModel(totals: x01TotalsPlayer0OnForty)
    vm.inputMode = .totalEntry
    vm.totalEntryText = "40"

    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(vm.legFinishSoundToken == 0)
    #expect(store.completedSessions().count == 1)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .critical, .regression))
func x01ViewModelAllowsOpponentInputDuringBustFeedback() async throws {
    // Player 0 on 40; a 50 visit busts and passes to player 1.
    let (vm, _, _) = try makeX01ViewModel(totals: x01TotalsPlayer0OnForty)
    vm.inputMode = .totalEntry
    vm.totalEntryText = "50"

    await vm.submitTurn()

    #expect(vm.state == .bustFeedback)
    #expect(vm.x01State?.currentPlayerIndex == 1)
    #expect(vm.isCurrentPlayerBot == false)
    #expect(vm.canHumanInput)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .critical, .regression))
func x01ViewModelOpponentCompletesTurnDuringBustFeedback() async throws {
    // Regression: the next human must score without manually dismissing the bust banner.
    let (vm, _, _) = try makeX01ViewModel(totals: x01TotalsPlayer0OnForty)
    vm.inputMode = .totalEntry
    vm.totalEntryText = "50"
    await vm.submitTurn()
    #expect(vm.state == .bustFeedback)

    vm.totalEntryText = "60"
    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.session?.events.count == 6)
    if case let .x01Turn(event) = vm.session?.events.last?.payload {
        #expect(event.appliedTotal == 60)
    } else {
        Issue.record("Expected last event to be an X01 turn")
    }
}

@MainActor
@Test(.tags(.integration, .x01, .match, .critical, .regression))
func x01ViewModelPreviewUpdatesDuringBustFeedbackForActiveHuman() async throws {
    let (vm, _, _) = try makeX01ViewModel(totals: x01TotalsPlayer0OnForty)
    vm.inputMode = .totalEntry
    vm.totalEntryText = "50"
    await vm.submitTurn()
    #expect(vm.state == .bustFeedback)
    #expect(vm.x01State?.currentPlayerIndex == 1)

    vm.inputMode = .dartEntry
    vm.enteredDarts = [DartInput(multiplier: .triple, segment: .oneToTwenty(20))]

    #expect(vm.canHumanInput)
    #expect(vm.playerCards[1].score == 241)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .critical, .regression))
func x01ViewModelBlocksPadWhileBotTurnPendingAfterHumanBust() async throws {
    // Human bust is persisted via lifecycle; bot is up but has not thrown in this VM yet.
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "Human", turnOrder: 0),
            MatchParticipant(
                playerId: UUID(),
                displayNameAtMatchStart: BotDifficulty.easy.rosterName,
                turnOrder: 1,
                botDifficultyRaw: BotDifficulty.easy.rawValue
            )
        ]
    )
    for total in x01TotalsPlayer0OnForty {
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: total, darts: nil)
    }
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 50, darts: nil)
    let store = ActiveMatchStore()
    store.save(session)
    let vm = X01MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: SilentLogSink()),
        matchRepository: X01FakeMatchRepository(),
        statsRepository: X01FakeStatsRepository()
    )

    #expect(vm.isCurrentPlayerBot)
    #expect(!vm.canHumanInput)

    await vm.playBotTurnIfNeeded()

    #expect(vm.state == .readyTurn)
    #expect(!vm.isCurrentPlayerBot)
    #expect(vm.canHumanInput)
    #expect(vm.session?.events.count == 6)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .critical, .regression))
func x01ViewModelResumesPlayAfterBust() async throws {
    // Regression: a busted turn must not strand the board. Acknowledging the
    // bust returns to readyTurn so the next visit can be scored.
    let (vm, _, _) = try makeX01ViewModel(totals: x01TotalsPlayer0OnForty)
    vm.inputMode = .totalEntry
    vm.totalEntryText = "100"
    await vm.submitTurn()
    #expect(vm.state == .bustFeedback)

    vm.acknowledgeBustFeedback()
    #expect(vm.state == .readyTurn)

    // The opponent can now score a normal turn.
    vm.totalEntryText = "60"
    await vm.submitTurn()
    #expect(vm.state == .readyTurn)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelSurfacesErrorWhenPersistenceFails() async throws {
    let (vm, _, _) = try makeX01ViewModel(totals: [], failAppend: true)
    vm.inputMode = .totalEntry
    vm.totalEntryText = "20"

    await vm.submitTurn()

    if case .error = vm.state {
        #expect(Bool(true))
    } else {
        Issue.record("Expected error state, got \(vm.state)")
    }
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelErrorsWhenSessionUnavailable() async throws {
    let vm = X01MatchViewModel(
        matchId: UUID(),
        store: ActiveMatchStore(),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: SilentLogSink()),
        matchRepository: X01FakeMatchRepository(),
        statsRepository: X01FakeStatsRepository()
    )
    vm.inputMode = .totalEntry
    vm.totalEntryText = "20"

    await vm.submitTurn()

    #expect(vm.state == .error("x01.error.sessionMissing"))
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelPreviewRemainingScoreDuringVisit() async throws {
    let (vm, _, _) = try makeX01ViewModel(totals: [])
    vm.inputMode = .dartEntry

    #expect(vm.playerCards[0].score == 301)

    vm.enteredDarts = [
        DartInput(multiplier: .triple, segment: .oneToTwenty(20))
    ]
    #expect(vm.playerCards[0].score == 241)

    vm.enteredDarts.append(DartInput(multiplier: .single, segment: .oneToTwenty(20)))
    #expect(vm.playerCards[0].score == 221)

    vm.enteredDarts.removeLast()
    #expect(vm.playerCards[0].score == 241)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelPreviewDartsAndAverageDuringVisit() async throws {
    let (vm, _, _) = try makeX01ViewModel(totals: [])
    vm.inputMode = .dartEntry

    #expect(vm.playerCards[0].dartsThrown == 0)
    #expect(vm.playerCards[0].average == 0)

    vm.enteredDarts = [
        DartInput(multiplier: .triple, segment: .oneToTwenty(20))
    ]
    #expect(vm.playerCards[0].dartsThrown == 1)
    #expect(vm.playerCards[0].average == 60)

    vm.enteredDarts.append(DartInput(multiplier: .single, segment: .oneToTwenty(20)))
    #expect(vm.playerCards[0].dartsThrown == 2)
    #expect(vm.playerCards[0].average == 40)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelSignalsLegFinishSoundBeforeMatchEnds() async throws {
    let p0 = UUID()
    let p1 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 101, legsToWin: 3, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 30, darts: nil)
    let store = ActiveMatchStore()
    store.save(session)
    let vm = X01MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: SilentLogSink()),
        matchRepository: X01FakeMatchRepository(),
        statsRepository: X01FakeStatsRepository()
    )
    vm.inputMode = .totalEntry
    vm.totalEntryText = "41"

    await vm.submitTurn()

    #expect(vm.legFinishSoundToken == 1)
    #expect(vm.state == .readyTurn)
    #expect(vm.playerCards[0].legsWon == 1)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelSignalsTurnTotalCallerForHumanVisit() async throws {
    let (vm, _, _) = try makeX01ViewModel(totals: [])
    vm.inputMode = .totalEntry
    vm.totalEntryText = "60"

    await vm.submitTurn()

    #expect(vm.turnTotalCallerSignal?.total == 60)
}

/// Three T20 darts for dart-entry visit tests.
private let x01TripleTwentyVisit: [DartInput] = [
    DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
    DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
    DartInput(multiplier: .triple, segment: .oneToTwenty(20))
]

@MainActor
private func makeThreePlayerX01ViewModel(
    preloadedTotals: [Int] = []
) throws -> X01MatchViewModel {
    let p0 = UUID()
    let p1 = UUID()
    let p2 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "B", turnOrder: 1),
            MatchParticipant(playerId: p2, displayNameAtMatchStart: "C", turnOrder: 2)
        ]
    )
    for total in preloadedTotals {
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: total, darts: nil)
    }
    let store = ActiveMatchStore()
    store.save(session)
    return X01MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: SilentLogSink()),
        matchRepository: X01FakeMatchRepository(),
        statsRepository: X01FakeStatsRepository()
    )
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelPersistsCompletedVisitUntilRoundAdvances() async throws {
    let (vm, _, _) = try makeX01ViewModel(totals: [])
    vm.inputMode = .dartEntry
    vm.enteredDarts = x01TripleTwentyVisit

    await vm.submitTurn()

    #expect(vm.x01State?.currentPlayerIndex == 1)
    #expect(vm.playerCards[0].visitDarts.count == 3)
    #expect(vm.playerCards[1].visitDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelClearsVisitSlotsWhenRoundWraps() async throws {
    let (vm, _, _) = try makeX01ViewModel(totals: [])
    vm.inputMode = .dartEntry
    vm.enteredDarts = x01TripleTwentyVisit
    await vm.submitTurn()

    vm.enteredDarts = x01TripleTwentyVisit
    await vm.submitTurn()

    #expect(vm.x01State?.currentPlayerIndex == 0)
    #expect(vm.playerCards[0].visitDarts.isEmpty)
    #expect(vm.playerCards[1].visitDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelShowsPartialRoundVisitsForThreePlayers() async throws {
    let vm = try makeThreePlayerX01ViewModel()
    vm.inputMode = .dartEntry
    vm.enteredDarts = x01TripleTwentyVisit
    await vm.submitTurn()

    vm.enteredDarts = x01TripleTwentyVisit
    await vm.submitTurn()

    #expect(vm.x01State?.currentPlayerIndex == 2)
    #expect(vm.playerCards[0].visitDarts.count == 3)
    #expect(vm.playerCards[1].visitDarts.count == 3)
    #expect(vm.playerCards[2].visitDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelUndoClearsPersistedRoundVisit() async throws {
    let (vm, _, _) = try makeX01ViewModel(totals: [])
    vm.inputMode = .dartEntry
    vm.enteredDarts = x01TripleTwentyVisit
    await vm.submitTurn()
    #expect(vm.playerCards[0].visitDarts.count == 3)

    await vm.undoLastTurn()

    #expect(vm.x01State?.currentPlayerIndex == 0)
    #expect(vm.playerCards[0].visitDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelClearsVisitSlotsAtLegBoundary() async throws {
    let p0 = UUID()
    let p1 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 101, legsToWin: 3, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 30, darts: nil)
    let store = ActiveMatchStore()
    store.save(session)
    let vm = X01MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: SilentLogSink()),
        matchRepository: X01FakeMatchRepository(),
        statsRepository: X01FakeStatsRepository()
    )
    vm.inputMode = .totalEntry
    vm.totalEntryText = "41"

    await vm.submitTurn()

    #expect(vm.legFinishSoundToken == 1)
    #expect(vm.x01State?.legIndex == 1)
    #expect(vm.playerCards.allSatisfy { $0.visitDarts.isEmpty })
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelUndoRevertsToReadyTurn() async throws {
    let (vm, _, store) = try makeX01ViewModel(totals: [])
    vm.inputMode = .totalEntry
    vm.totalEntryText = "60"
    await vm.submitTurn()
    #expect(vm.session?.events.count == 1)

    await vm.undoLastTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.session?.events.isEmpty == true)
    #expect(store.session(for: vm.session!.runtime.matchId)?.events.isEmpty == true)
}

// MARK: - Fakes

private final class SilentLogSink: LogSink, @unchecked Sendable {
    func write(_: LogEntry) {}
}

private actor X01RehydratingFakeStatsRepository: StatsRepository {
    let events: [MatchEventSummary]

    init(events: [MatchEventSummary]) { self.events = events }

    func fetchEvents(matchId: UUID) async throws -> [MatchEventSummary] {
        events.filter { $0.matchId == matchId }
    }

    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private actor X01RehydratingFakeMatchRepository: MatchRepository {
    let snapshot: MatchSnapshotSummary

    init(snapshot: MatchSnapshotSummary) { self.snapshot = snapshot }

    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        makeSummary(type: type, status: .inProgress)
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        makeSummary(type: .x01, status: .completed)
    }
    func appendEvent(matchId: UUID, eventTypeRaw: String, eventPayload: Data) async throws -> MatchEventSummary {
        MatchEventSummary(id: UUID(), matchId: matchId, eventIndex: 0, eventTypeRaw: eventTypeRaw, eventPayload: eventPayload, createdAt: Date())
    }
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary {
        MatchSnapshotSummary(id: UUID(), matchId: matchId, snapshotVersion: snapshotVersion, snapshotPayload: snapshotPayload, updatedAt: Date())
    }
    func fetchLatestSnapshot(matchId: UUID) async throws -> MatchSnapshotSummary? {
        snapshot.matchId == matchId ? snapshot : nil
    }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}

    private func makeSummary(type: MatchType, status: MatchStatus) -> MatchSummary {
        MatchSummary(
            id: UUID(), type: type, status: status, startedAt: Date(), endedAt: nil,
            winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0,
            eventCount: 0, createdAt: Date(), updatedAt: Date()
        )
    }
}

private actor X01FakeStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private actor X01FakeMatchRepository: MatchRepository {
    let failAppend: Bool
    init(failAppend: Bool = false) { self.failAppend = failAppend }

    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        makeSummary(type: type, status: .inProgress)
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        makeSummary(type: .x01, status: .completed)
    }
    func appendEvent(matchId: UUID, eventTypeRaw: String, eventPayload: Data) async throws -> MatchEventSummary {
        if failAppend {
            throw AppError(code: .storageUnavailable, layer: .data, severity: .error, isRecoverable: true, userMessageKey: "error.repository.storage")
        }
        return MatchEventSummary(id: UUID(), matchId: matchId, eventIndex: 0, eventTypeRaw: eventTypeRaw, eventPayload: eventPayload, createdAt: Date())
    }
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary {
        MatchSnapshotSummary(id: UUID(), matchId: matchId, snapshotVersion: snapshotVersion, snapshotPayload: snapshotPayload, updatedAt: Date())
    }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}

    private func makeSummary(type: MatchType, status: MatchStatus) -> MatchSummary {
        MatchSummary(
            id: UUID(), type: type, status: status, startedAt: Date(), endedAt: nil,
            winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0,
            eventCount: 0, createdAt: Date(), updatedAt: Date()
        )
    }
}

@Test func dartSpokenAccessibilityUsesFullMultiplierNames() {
    let triple20 = DartInput(multiplier: .triple, segment: .oneToTwenty(20))
    #expect(triple20.spokenAccessibilityName == L10n.format("scoring.dart.triple.accessibility", 20))
    #expect(
        DartInput.padKeyAccessibilityLabel(segmentValue: 20, armedMultiplier: .triple)
            == L10n.format("scoring.dart.triple.accessibility", 20)
    )
    #expect(
        DartInput.padKeyAccessibilityLabel(segmentValue: 25, armedMultiplier: .double)
            == L10n.string("scoring.dart.doubleBull.accessibility")
    )
}
