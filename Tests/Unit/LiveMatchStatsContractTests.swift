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
        logger: DefaultAppLogger(minimumLevel: .fault, sink: LiveStatsSilentLogSink()),
        matchRepository: LiveStatsFakeMatchRepository(),
        statsRepository: LiveStatsFakeStatsRepository()
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
        logger: DefaultAppLogger(minimumLevel: .fault, sink: LiveStatsSilentLogSink()),
        matchRepository: LiveStatsFakeMatchRepository(),
        statsRepository: LiveStatsFakeStatsRepository()
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

private final class LiveStatsSilentLogSink: LogSink, @unchecked Sendable {
    func write(_: LogEntry) {}
}

private actor LiveStatsFakeMatchRepository: MatchRepository {
    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        MatchSummary(
            id: UUID(), type: type, status: .inProgress, startedAt: Date(), endedAt: nil,
            winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0,
            eventCount: 0, createdAt: Date(), updatedAt: Date()
        )
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        MatchSummary(
            id: UUID(), type: .x01, status: .completed, startedAt: Date(), endedAt: Date(),
            winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0,
            eventCount: 0, createdAt: Date(), updatedAt: Date()
        )
    }
    func appendEvent(matchId: UUID, eventTypeRaw: String, eventPayload: Data) async throws -> MatchEventSummary {
        MatchEventSummary(id: UUID(), matchId: matchId, eventIndex: 0, eventTypeRaw: eventTypeRaw, eventPayload: eventPayload, createdAt: Date())
    }
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary {
        MatchSnapshotSummary(id: UUID(), matchId: matchId, snapshotVersion: snapshotVersion, snapshotPayload: snapshotPayload, updatedAt: Date())
    }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor LiveStatsFakeStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}
