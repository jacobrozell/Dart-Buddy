import Foundation
import Testing
@testable import DartBuddy

// Live scoreboard stats must agree with post-game StatsService for the same session.

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01LiveDartsThrownMatchesStatsServiceAfterBotTurn() async throws {
    let humanId = UUID()
    let botId = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 501,
                legsToWin: 1,
                setsEnabled: false,
                setsToWin: nil,
                checkoutMode: .doubleOut
            )
        ),
        participants: [
            MatchParticipant(
                playerId: botId,
                displayNameAtMatchStart: BotDifficulty.medium.rosterName,
                turnOrder: 0,
                botDifficultyRaw: BotDifficulty.medium.rawValue
            ),
            MatchParticipant(playerId: humanId, displayNameAtMatchStart: "Human", turnOrder: 1)
        ]
    )
    let store = ActiveMatchStore()
    store.save(session)
    let vm = X01MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .x01),
        statsRepository: FakeStatsRepository()
    )

    await vm.playBotTurnIfNeeded()

    let liveSession = try #require(vm.session)
    let botCard = try #require(vm.playerCards.first { $0.id == botId })
    let breakdownDarts = statsDartsThrown(for: botId, session: liveSession)
    #expect(botCard.dartsThrown == breakdownDarts)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketLiveDartsThrownMatchesStatsServiceWithMisses() async throws {
    let participants = cricketParticipants(count: 2)
    var session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: participants
    )
    session = try MatchLifecycleService.submitCricketTurn(
        session: session,
        darts: [CricketTestDarts.triple(20), CricketTestDarts.miss(), CricketTestDarts.single(19)]
    )
    let store = ActiveMatchStore()
    store.save(session)
    let vm = CricketMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .x01),
        statsRepository: FakeStatsRepository()
    )

    let liveSession = try #require(vm.session)
    let playerId = try #require(liveSession.runtime.cricketState?.players[0].playerId)
    let column = try #require(vm.boardColumns.first { $0.id == playerId })
    let breakdownDarts = statsDartsThrown(for: playerId, session: liveSession)
    #expect(column.dartsThrown == breakdownDarts)
    #expect(column.dartsThrown == 3)
}

private func statsDartsThrown(for playerId: UUID, session: MatchLifecycleSession) -> Int {
    let input = MatchStatsInput(
        type: session.runtime.type,
        participantKeys: session.runtime.participants.map { $0.playerId ?? $0.id },
        winnerKey: session.runtime.winnerPlayerId,
        events: session.events
    )
    let nameById = Dictionary(
        session.runtime.participants.map { ($0.playerId ?? $0.id, $0.displayNameAtMatchStart) },
        uniquingKeysWith: { first, _ in first }
    )
    return StatsService.breakdowns(from: [input], nameById: nameById)
        .first { $0.playerId == playerId }?
        .darts ?? 0
}
