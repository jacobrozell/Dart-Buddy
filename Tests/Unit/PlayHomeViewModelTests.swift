import Foundation
import Testing
@testable import DartBuddy

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
@Test(.tags(.integration, .navigation, .match, .regression))
func playHomeIgnoresActivePartyMatchWhenPartyHidden() async {
    guard !ProductSurface.showsPartyModes else { return }

    let activeMatch = MatchSummary(
        id: UUID(),
        type: .baseball,
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

    #expect(vm.state == .readyNoActiveMatch)
}

@MainActor
@Test(.tags(.integration, .navigation, .match, .regression))
func playHomeIgnoresActiveGolfMatchWhenGolfNotReachable() async {
    guard ProductSurface.showsPartyModes, !ProductSurface.isFullProductSurfaceEnabled else { return }

    let activeMatch = MatchSummary(
        id: UUID(),
        type: .golf,
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

    #expect(vm.state == .readyNoActiveMatch)
}

@MainActor
@Test(.tags(.integration, .navigation, .match, .regression))
func playHomeShowsResumeForBaseballMatch() async throws {
    guard ProductSurface.showsPartyModes, !ProductSurface.isFullProductSurfaceEnabled else { return }

    let activeMatch = MatchSummary(
        id: UUID(),
        type: .baseball,
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

    if case let .readyWithActiveMatch(match) = vm.state {
        #expect(match.type == .baseball)
    } else {
        Issue.record("Expected resume state for baseball match")
    }
}

@MainActor
@Test(.tags(.integration, .navigation, .match, .regression))
func playHomeShowsResumeForAroundTheClockMatch() async throws {
    guard !ProductSurface.isFullProductSurfaceEnabled else { return }

    let activeMatch = MatchSummary(
        id: UUID(),
        type: .aroundTheClock,
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
        playerRepository: FakePlayerRepository(players: [makePlayer("A")]),
        matchRepository: FakeMatchRepository(activeMatch: activeMatch),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: RecordingSink())
    )

    await vm.onAppear()

    if case let .readyWithActiveMatch(match) = vm.state {
        #expect(match.type == .aroundTheClock)
    } else {
        Issue.record("Expected resume state for Around the Clock match")
    }
}

@MainActor
@Test(.tags(.integration, .navigation, .match, .regression))
func playHomeShowsResumeForCricketMatch() async throws {
    var session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [CricketTestDarts.triple(20)])
    let activeMatch = MatchSummary(
        id: session.runtime.matchId,
        type: .cricket,
        status: .inProgress,
        startedAt: Date(),
        endedAt: nil,
        winnerPlayerId: nil,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: session.runtime.eventCount,
        createdAt: Date(),
        updatedAt: Date()
    )
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        matchRepository: FakeMatchRepository(activeMatch: activeMatch),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: RecordingSink())
    )

    await vm.onAppear()

    if case let .readyWithActiveMatch(match) = vm.state {
        #expect(match.type == .cricket)
    } else {
        Issue.record("Expected resume state for cricket match")
    }
}

@MainActor
@Test(.tags(.integration, .navigation, .regression))
func playHomeSurfacesErrorWhenActiveMatchLookupFails() async {
    let vm = PlayHomeViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A"), makePlayer("B")]),
        matchRepository: FailingMatchRepository(),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: RecordingSink())
    )

    await vm.onAppear()

    if case let .error(messageKey) = vm.state {
        #expect(messageKey == "error.playHome.load")
    } else {
        Issue.record("Expected error state when match repository fails")
    }
}

@MainActor
@Test(.tags(.integration, .navigation, .regression))
func playHomeSurfacesErrorWhenPlayerLoadFails() async {
    let vm = PlayHomeViewModel(
        playerRepository: FailingPlayerRepository(),
        matchRepository: FakeMatchRepository(activeMatch: nil),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: RecordingSink())
    )

    await vm.onAppear()

    if case let .error(messageKey) = vm.state {
        #expect(messageKey == "error.playHome.load")
    } else {
        Issue.record("Expected error state when player repository fails")
    }
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

private actor FailingPlayerRepository: PlayerRepository {
    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] {
        throw AppError(code: .storageUnavailable, layer: .data, severity: .error, isRecoverable: true, userMessageKey: "error.playHome.load")
    }
    func createPlayer(name _: String) async throws -> PlayerSummary { fatalError() }
    func createBot(difficulty _: BotDifficulty) async throws -> PlayerSummary { fatalError() }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { fatalError() }
    func updatePlayerProfile(playerId _: UUID, name _: String, avatarStyle _: PlayerAvatarStyle, colorToken _: PlayerColorToken, notes _: String) async throws -> PlayerSummary { fatalError() }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
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

private actor FailingMatchRepository: MatchRepository {
    func fetchActiveMatch() async throws -> MatchSummary? {
        throw AppError(code: .storageUnavailable, layer: .data, severity: .error, isRecoverable: true, userMessageKey: "error.playHome.load")
    }
    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { fatalError() }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { fatalError() }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { fatalError() }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { fatalError() }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
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
