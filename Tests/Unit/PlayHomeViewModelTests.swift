import Foundation
import Testing
@testable import DartsScoreboard

@MainActor
@Test(.tags(.integration, .navigation, .match, .smoke, .regression))
func playHomeShowsResumeWhenActiveMatchExists() async throws {
    let activeMatch = MatchSummary(
        id: UUID(),
        type: .x01,
        status: .inProgress,
        startedAt: Date(),
        endedAt: nil,
        winnerPlayerId: nil,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: 0,
        createdAt: Date(),
        updatedAt: Date()
    )
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        matchRepository: FakeMatchRepository(activeMatch: activeMatch),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: RecordingSink())
    )

    await vm.onAppear()

    switch vm.state {
    case let .readyWithActiveMatch(match):
        #expect(match.id == activeMatch.id)
    default:
        Issue.record("Expected resume state")
    }
}

@MainActor
@Test(.tags(.integration, .navigation, .smoke, .regression))
func playHomeDoesNotOfferAbandonedMatch() async {
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        matchRepository: FakeMatchRepository(activeMatch: nil),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: RecordingSink())
    )

    await vm.onAppear()

    #expect(vm.state == .readyNoActiveMatch)
}

@MainActor
@Test(.tags(.integration, .navigation, .smoke, .regression))
func playHomeShowsNoActiveMatchWhenRosterExistsButNoActiveMatch() async {
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        matchRepository: FakeMatchRepository(activeMatch: nil),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: RecordingSink())
    )

    await vm.onAppear()

    #expect(vm.state == .readyNoActiveMatch)
}

@MainActor
@Test(.tags(.integration, .navigation, .smoke, .regression))
func playHomeShowsNoActiveMatchWhenRosterEmpty() async {
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: []),
        matchRepository: FakeMatchRepository(activeMatch: nil),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: RecordingSink())
    )

    await vm.onAppear()

    #expect(vm.state == .readyNoActiveMatch)
}

private func makePlayer(_ name: String) -> PlayerSummary {
    PlayerSummary(id: UUID(), name: name, isArchived: false, createdAt: Date(), updatedAt: Date())
}

private actor FakePlayerRepository: PlayerRepository {
    let players: [PlayerSummary]
    init(players: [PlayerSummary]) { self.players = players }
    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { players }
    func createPlayer(name _: String) async throws -> PlayerSummary { players[0] }
    func createBot(difficulty _: BotDifficulty) async throws -> PlayerSummary { players[0] }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { players[0] }
    func updatePlayerProfile(playerId _: UUID, name _: String, avatarStyle _: PlayerAvatarStyle, colorToken _: PlayerColorToken, notes _: String) async throws -> PlayerSummary { players[0] }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
}

private actor FakeMatchRepository: MatchRepository {
    let activeMatch: MatchSummary?
    init(activeMatch: MatchSummary?) { self.activeMatch = activeMatch }
    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func fetchActiveMatch() async throws -> MatchSummary? { activeMatch }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private final class RecordingSink: LogSink, @unchecked Sendable {
    func write(_: LogEntry) {}
}
