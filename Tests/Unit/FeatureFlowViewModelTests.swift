import Foundation
import Testing
@testable import DartBuddy

@MainActor
@Test(.tags(.unit, .player, .regression))
func playerEditValidationRejectsDuplicateName() {
    let vm = PlayerEditViewModel(existingNames: ["Alice"], editing: nil)
    vm.name = "alice"
    vm.validate()
    #expect(!vm.canSave)
    #expect(vm.validationMessage == "player.validation.duplicateName")
}

@MainActor
@Test(.tags(.unit, .player, .regression))
func playerEditValidationAllowsUnchangedNameWhenEditing() {
    let aliceId = UUID()
    let editing = EditablePlayer(
        id: aliceId,
        name: "Alice",
        isArchived: false,
        notes: "",
        isBot: false,
        isTrainingBot: false,
        isCustomBot: false,
        customX01Average: CustomBotMetrics.defaultX01Average,
        customCricketMPR: CustomBotMetrics.defaultCricketMPR,
        linkedPlayerId: nil,
        botDifficulty: nil,
        avatarStyle: .dart,
        colorToken: .green
    )
    let vm = PlayerEditViewModel(existingNames: ["Alice", "Bob"], editing: editing)
    vm.name = "Alice"
    vm.validate()
    #expect(vm.canSave)
    #expect(vm.validationMessage == nil)
}

@MainActor
@Test(.tags(.unit, .player, .regression))
func playerEditValidationRejectsRenameToExistingName() {
    let editing = EditablePlayer(
        id: UUID(),
        name: "Alice",
        isArchived: false,
        notes: "",
        isBot: false,
        isTrainingBot: false,
        isCustomBot: false,
        customX01Average: CustomBotMetrics.defaultX01Average,
        customCricketMPR: CustomBotMetrics.defaultCricketMPR,
        linkedPlayerId: nil,
        botDifficulty: nil,
        avatarStyle: .dart,
        colorToken: .green
    )
    let vm = PlayerEditViewModel(existingNames: ["Alice", "Bob"], editing: editing)
    vm.name = "Bob"
    vm.validate()
    #expect(!vm.canSave)
    #expect(vm.validationMessage == "player.validation.duplicateName")
}

@MainActor
@Test(.tags(.unit, .player, .regression))
func playerEditBuildPlayerPreservesIdentityWhenEditing() {
    let editing = EditablePlayer(
        id: UUID(),
        name: "Alice",
        isArchived: true,
        notes: "note",
        isBot: false,
        isTrainingBot: false,
        isCustomBot: false,
        customX01Average: CustomBotMetrics.defaultX01Average,
        customCricketMPR: CustomBotMetrics.defaultCricketMPR,
        linkedPlayerId: nil,
        botDifficulty: nil,
        avatarStyle: .trophy,
        colorToken: .amber
    )
    let vm = PlayerEditViewModel(existingNames: ["Alice"], editing: editing)
    vm.name = "Alicia"
    vm.notes = "updated"
    vm.avatarStyle = .star
    vm.colorToken = .blue

    let built = vm.buildPlayer(from: editing)
    #expect(built.id == editing.id)
    #expect(built.name == "Alicia")
    #expect(built.isArchived)
    #expect(built.notes == "updated")
    #expect(built.avatarStyle == .star)
    #expect(built.colorToken == .blue)
}

@MainActor
@Test(.tags(.integration, .player, .regression))
func playersListDeleteReturnsFalseWhenRepositoryBlocks() async {
    let aliceId = UUID()
    let alice = PlayerSummary(
        id: aliceId,
        name: "Alice",
        isArchived: false,
        isBot: false,
        botDifficultyRaw: nil,
        avatarStyleRaw: nil,
        preferredColorToken: nil,
        notes: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
    let repository = BlockingDeletePlayerRepository()
    await repository.seed(players: [alice])

    let vm = PlayersListViewModel(
        repository: repository,
        matchRepository: PlayerListTestMatchRepository(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()

    let deleted = await vm.delete(aliceId)

    #expect(deleted == false)
    #expect(vm.errorMessageKey == "players.delete.blocked.message")
    #expect(vm.players.contains(where: { $0.id == aliceId }))
}

@MainActor
@Test(.tags(.integration, .player, .regression))
func playersListSaveUpdatesExistingPlayerProfile() async {
    let repository = UpdatingPlayerRepository()
    let aliceId = UUID()
    let alice = PlayerSummary(
        id: aliceId,
        name: "Alice",
        isArchived: false,
        isBot: false,
        botDifficultyRaw: nil,
        avatarStyleRaw: PlayerAvatarStyle.dart.rawValue,
        preferredColorToken: PlayerColorToken.green.rawValue,
        notes: nil,
        createdAt: Date(),
        updatedAt: Date()
    )
    await repository.seed(players: [alice])

    let vm = PlayersListViewModel(
        repository: repository,
        matchRepository: PlayerListTestMatchRepository(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()

    var edited = EditablePlayer.from(alice)
    edited.name = "Alicia"
    edited.notes = "Captain"
    edited.avatarStyle = .star
    edited.colorToken = .blue
    await vm.save(edited)

    let update = await repository.lastProfileUpdate()
    #expect(update?.playerId == aliceId)
    #expect(update?.name == "Alicia")
    #expect(update?.notes == "Captain")
    #expect(update?.avatarStyle == .star)
    #expect(update?.colorToken == .blue)
    #expect(vm.players.first(where: { $0.id == aliceId })?.name == "Alicia")
}

private actor BlockingDeletePlayerRepository: PlayerRepository {
    private var players: [PlayerSummary] = []

    func seed(players: [PlayerSummary]) {
        self.players = players
    }

    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { players }
    func createPlayer(name _: String) async throws -> PlayerSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func createBot(difficulty _: BotDifficulty) async throws -> PlayerSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { players[0] }
    func updatePlayerProfile(playerId _: UUID, name _: String, avatarStyle _: PlayerAvatarStyle, colorToken _: PlayerColorToken, notes _: String) async throws -> PlayerSummary { players[0] }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {
        throw AppError(
            code: .conflict,
            layer: .data,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: "players.delete.blocked.message"
        )
    }
}

private actor UpdatingPlayerRepository: PlayerRepository {
    struct ProfileUpdate: Equatable {
        let playerId: UUID
        let name: String
        let avatarStyle: PlayerAvatarStyle
        let colorToken: PlayerColorToken
        let notes: String
    }

    private var players: [PlayerSummary] = []
    private var lastUpdate: ProfileUpdate?

    func seed(players: [PlayerSummary]) {
        self.players = players
    }

    func lastProfileUpdate() -> ProfileUpdate? { lastUpdate }

    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { players }
    func createPlayer(name _: String) async throws -> PlayerSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func createBot(difficulty _: BotDifficulty) async throws -> PlayerSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { players[0] }
    func updatePlayerProfile(
        playerId: UUID,
        name: String,
        avatarStyle: PlayerAvatarStyle,
        colorToken: PlayerColorToken,
        notes: String
    ) async throws -> PlayerSummary {
        lastUpdate = ProfileUpdate(playerId: playerId, name: name, avatarStyle: avatarStyle, colorToken: colorToken, notes: notes)
        guard let index = players.firstIndex(where: { $0.id == playerId }) else {
            throw AppError(code: .notFound, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notFound")
        }
        let existing = players[index]
        let updated = PlayerSummary(
            id: existing.id,
            name: name,
            isArchived: existing.isArchived,
            isBot: existing.isBot,
            botDifficultyRaw: existing.botDifficultyRaw,
            avatarStyleRaw: avatarStyle.rawValue,
            preferredColorToken: colorToken.rawValue,
            notes: notes.isEmpty ? nil : notes,
            createdAt: existing.createdAt,
            updatedAt: Date()
        )
        players[index] = updated
        return updated
    }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
}

private actor PlayerListTestMatchRepository: MatchRepository {
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

@MainActor
@Test(.tags(.integration, .history, .match, .regression))
func historyFiltersByModeDeterministically() async {
    let now = Date()
    let vm = HistoryListViewModel(
        matchRepository: FakeHistoryMatchRepository(
            rows: [
                MatchSummary(
                    id: UUID(),
                    type: .x01,
                    status: .completed,
                    startedAt: now,
                    endedAt: now,
                    winnerPlayerId: nil,
                    currentTurnPlayerId: nil,
                    currentLegIndex: 0,
                    currentSetIndex: 0,
                    eventCount: 10,
                    createdAt: now,
                    updatedAt: now
                ),
                MatchSummary(
                    id: UUID(),
                    type: .cricket,
                    status: .completed,
                    startedAt: now,
                    endedAt: now,
                    winnerPlayerId: nil,
                    currentTurnPlayerId: nil,
                    currentLegIndex: 0,
                    currentSetIndex: 0,
                    eventCount: 12,
                    createdAt: now,
                    updatedAt: now
                )
            ]
        ),
        playerRepository: FakeHistoryPlayerRepository(players: [])
    )
    vm.modeFilter = .x01
    await vm.applyFilters()

    #expect(vm.rows.count == 1)
    #expect(vm.rows.first?.summary.type == .x01)
}

@MainActor
@Test(.tags(.integration, .history, .player, .regression))
func historyFiltersByPlayer() async {
    let alice = UUID()
    let bob = UUID()
    let carol = UUID()
    let now = Date()
    let x01Match = MatchSummary(
        id: UUID(),
        type: .x01,
        status: .completed,
        startedAt: now,
        endedAt: now,
        winnerPlayerId: alice,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: 10,
        createdAt: now,
        updatedAt: now
    )
    let cricketMatch = MatchSummary(
        id: UUID(),
        type: .cricket,
        status: .completed,
        startedAt: now,
        endedAt: now,
        winnerPlayerId: carol,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: 12,
        createdAt: now,
        updatedAt: now
    )
    let vm = HistoryListViewModel(
        matchRepository: FakeHistoryMatchRepository(
            rows: [x01Match, cricketMatch],
            participantsByMatchId: [
                x01Match.id: [
                    MatchParticipantSummary(id: UUID(), matchId: x01Match.id, playerId: alice, turnOrder: 0, displayNameAtMatchStart: "Alice", avatarStyleAtMatchStart: nil),
                    MatchParticipantSummary(id: UUID(), matchId: x01Match.id, playerId: bob, turnOrder: 1, displayNameAtMatchStart: "Bob", avatarStyleAtMatchStart: nil)
                ],
                cricketMatch.id: [
                    MatchParticipantSummary(id: UUID(), matchId: cricketMatch.id, playerId: carol, turnOrder: 0, displayNameAtMatchStart: "Carol", avatarStyleAtMatchStart: nil),
                    MatchParticipantSummary(id: UUID(), matchId: cricketMatch.id, playerId: bob, turnOrder: 1, displayNameAtMatchStart: "Bob", avatarStyleAtMatchStart: nil)
                ]
            ]
        ),
        playerRepository: FakeHistoryPlayerRepository(players: [
            PlayerSummary(id: alice, name: "Alice", isArchived: false, isBot: false, botDifficultyRaw: nil, avatarStyleRaw: nil, preferredColorToken: nil, notes: nil, createdAt: now, updatedAt: now),
            PlayerSummary(id: bob, name: "Bob", isArchived: false, isBot: false, botDifficultyRaw: nil, avatarStyleRaw: nil, preferredColorToken: nil, notes: nil, createdAt: now, updatedAt: now),
            PlayerSummary(id: carol, name: "Carol", isArchived: false, isBot: false, botDifficultyRaw: nil, avatarStyleRaw: nil, preferredColorToken: nil, notes: nil, createdAt: now, updatedAt: now)
        ])
    )

    await vm.applyFilters()
    #expect(vm.rows.count == 2)

    vm.playerFilter = bob
    await vm.applyFilters()
    #expect(vm.rows.count == 2)

    vm.playerFilter = carol
    await vm.applyFilters()
    #expect(vm.rows.count == 1)
    #expect(vm.rows.first?.summary.type == .cricket)
    #expect(vm.state == .readyFiltered)
}

@MainActor
@Test(.tags(.integration, .history, .regression))
func historyFiltersByDatePeriodDeterministically() async {
    let now = Date()
    let recent = MatchSummary(
        id: UUID(),
        type: .x01,
        status: .completed,
        startedAt: now,
        endedAt: now,
        winnerPlayerId: nil,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: 1,
        createdAt: now,
        updatedAt: now
    )
    let older = MatchSummary(
        id: UUID(),
        type: .x01,
        status: .completed,
        startedAt: now.addingTimeInterval(-864_000),
        endedAt: now.addingTimeInterval(-864_000),
        winnerPlayerId: nil,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: 1,
        createdAt: now,
        updatedAt: now
    )
    let vm = HistoryListViewModel(
        matchRepository: FakeHistoryMatchRepository(rows: [recent, older]),
        playerRepository: FakeHistoryPlayerRepository(players: [])
    )

    vm.dateFilter = .all
    await vm.applyFilters()
    #expect(vm.rows.count == 2)

    vm.dateFilter = .d7
    await vm.applyFilters()
    #expect(vm.rows.count == 1)
    #expect(vm.rows.first?.summary.id == recent.id)
}

@MainActor
@Test(.tags(.integration, .history, .regression))
func historyHasActiveFiltersWhenAnyFilterApplied() async {
    let vm = HistoryListViewModel(
        matchRepository: FakeHistoryMatchRepository(rows: []),
        playerRepository: FakeHistoryPlayerRepository(players: [])
    )

    #expect(vm.hasActiveFilters == false)

    vm.modeFilter = .cricket
    #expect(vm.hasActiveFilters == true)

    vm.modeFilter = .all
    vm.dateFilter = .d30
    #expect(vm.hasActiveFilters == true)
}

@MainActor
@Test(.tags(.integration, .history, .regression))
func historyListViewModelPaginatesResults() async {
    let now = Date()
    let rows = (0 ..< 30).map { index in
        MatchSummary(
            id: UUID(),
            type: .x01,
            status: .completed,
            startedAt: now.addingTimeInterval(TimeInterval(-index)),
            endedAt: now.addingTimeInterval(TimeInterval(-index)),
            winnerPlayerId: nil,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 1,
            createdAt: now,
            updatedAt: now
        )
    }
    let vm = HistoryListViewModel(
        matchRepository: FakeHistoryMatchRepository(rows: rows),
        playerRepository: FakeHistoryPlayerRepository(players: [])
    )

    await vm.applyFilters()
    #expect(vm.rows.count == 25)
    #expect(vm.hasMorePages == true)

    await vm.loadMore()
    #expect(vm.rows.count == 30)
    #expect(vm.hasMorePages == false)
}

@MainActor
@Test(.tags(.integration, .history, .match, .regression))
func historyFiltersByPartyPackModes() async {
    let now = Date()
    let summaries = [
        MatchSummary(
            id: UUID(), type: .baseball, status: .completed, startedAt: now, endedAt: now,
            winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0,
            eventCount: 1, createdAt: now, updatedAt: now
        ),
        MatchSummary(
            id: UUID(), type: .killer, status: .completed, startedAt: now, endedAt: now,
            winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0,
            eventCount: 1, createdAt: now, updatedAt: now
        ),
        MatchSummary(
            id: UUID(), type: .shanghai, status: .completed, startedAt: now, endedAt: now,
            winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0,
            eventCount: 1, createdAt: now, updatedAt: now
        ),
        MatchSummary(
            id: UUID(), type: .aroundTheClock, status: .completed, startedAt: now, endedAt: now,
            winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0,
            eventCount: 1, createdAt: now, updatedAt: now
        )
    ]
    let repository = FakeHistoryMatchRepository(rows: summaries)
    let vm = HistoryListViewModel(
        matchRepository: repository,
        playerRepository: FakeHistoryPlayerRepository(players: [])
    )

    let filters: [(ActivityModeFilter, MatchType)] = [
        (.baseball, .baseball),
        (.killer, .killer),
        (.shanghai, .shanghai),
        (.aroundTheClock, .aroundTheClock)
    ]
    for (filter, expectedType) in filters {
        vm.modeFilter = filter
        await vm.applyFilters()
        #expect(vm.rows.count == 1)
        #expect(vm.rows.first?.summary.type == expectedType)
    }
}

@MainActor
@Test(.tags(.integration, .history, .match, .regression))
func historyAllGamesFilterExcludesUnreachableModesOnPartyPack() async {
    guard ProductSurface.showsPartyModes, !ProductSurface.isFullProductSurfaceEnabled else { return }

    let now = Date()
    let reachable = MatchSummary(
        id: UUID(), type: .baseball, status: .completed, startedAt: now, endedAt: now,
        winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0,
        eventCount: 1, createdAt: now, updatedAt: now
    )
    let hidden = MatchSummary(
        id: UUID(), type: .golf, status: .completed, startedAt: now, endedAt: now,
        winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0,
        eventCount: 1, createdAt: now, updatedAt: now
    )
    let vm = HistoryListViewModel(
        matchRepository: FakeHistoryMatchRepository(rows: [reachable, hidden]),
        playerRepository: FakeHistoryPlayerRepository(players: [])
    )

    vm.modeFilter = .all
    await vm.applyFilters()

    #expect(vm.rows.count == 1)
    #expect(vm.rows.first?.summary.type == .baseball)
}

@MainActor
@Test(.tags(.integration, .history, .match, .regression))
func historyIgnoresUnreachableGolfActiveMatch() async {
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
    let vm = HistoryListViewModel(
        matchRepository: FakeHistoryMatchRepository(rows: [], activeMatch: activeMatch),
        playerRepository: FakeHistoryPlayerRepository(players: [])
    )

    await vm.applyFilters()

    #expect(vm.activeMatch == nil)
}

@MainActor
@Test(.tags(.integration, .history, .match, .regression))
func historyExposesReachableBaseballActiveMatch() async throws {
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
        eventCount: 2,
        createdAt: Date(),
        updatedAt: Date()
    )
    let vm = HistoryListViewModel(
        matchRepository: FakeHistoryMatchRepository(rows: [], activeMatch: activeMatch),
        playerRepository: FakeHistoryPlayerRepository(players: [])
    )

    await vm.applyFilters()

    #expect(vm.activeMatch?.id == activeMatch.id)
    #expect(vm.activeMatch?.type == .baseball)
}

// MARK: - Stats / detail fixtures

private struct StatsFixture {
    let matchId: UUID
    let jacob: UUID
    let sam: UUID
    let summary: MatchSummary
    let participants: [MatchParticipantSummary]
    let events: [MatchEventSummary]
    let snapshot: MatchSnapshotSummary
}

private func makeForfeitedX01Fixture() throws -> StatsFixture {
    let matchId = UUID()
    let jacob = UUID()
    let sam = UUID()
    func d(_ multiplier: DartMultiplier, _ value: Int) -> DartInput {
        DartInput(multiplier: multiplier, segment: .oneToTwenty(value))
    }
    var session = try MatchLifecycleService.createMatch(
        matchId: matchId,
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: jacob, displayNameAtMatchStart: "Jacob", turnOrder: 0),
            MatchParticipant(playerId: sam, displayNameAtMatchStart: "Sam", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(
        session: session,
        enteredTotal: nil,
        darts: [d(.triple, 20), d(.triple, 20), d(.triple, 20)]
    )
    session = try MatchLifecycleService.forfeit(
        session: session,
        forfeitingPlayerId: jacob,
        winnerPlayerId: sam
    )

    let now = Date()
    let summary = MatchSummary(
        id: matchId,
        type: .x01,
        status: .forfeited,
        startedAt: now,
        endedAt: now,
        winnerPlayerId: sam,
        forfeitedByPlayerId: jacob,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: session.events.count,
        createdAt: now,
        updatedAt: now
    )
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: jacob, turnOrder: 0, displayNameAtMatchStart: "Jacob", avatarStyleAtMatchStart: nil),
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: sam, turnOrder: 1, displayNameAtMatchStart: "Sam", avatarStyleAtMatchStart: nil)
    ]
    let events = try session.events.map { envelope in
        MatchEventSummary(
            id: UUID(),
            matchId: matchId,
            eventIndex: envelope.eventIndex,
            eventTypeRaw: "x01Turn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: now
        )
    }
    let snapshot = MatchSnapshotSummary(
        id: UUID(),
        matchId: matchId,
        snapshotVersion: session.latestSnapshot.payloadVersion,
        snapshotPayload: session.latestSnapshot.payload,
        updatedAt: now
    )
    return StatsFixture(matchId: matchId, jacob: jacob, sam: sam, summary: summary, participants: participants, events: events, snapshot: snapshot)
}

private func makeCompletedX01Fixture() throws -> StatsFixture {
    let matchId = UUID()
    let jacob = UUID()
    let sam = UUID()
    func d(_ multiplier: DartMultiplier, _ value: Int) -> DartInput {
        DartInput(multiplier: multiplier, segment: .oneToTwenty(value))
    }
    var session = try MatchLifecycleService.createMatch(
        matchId: matchId,
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: jacob, displayNameAtMatchStart: "Jacob", turnOrder: 0),
            MatchParticipant(playerId: sam, displayNameAtMatchStart: "Sam", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: nil, darts: [d(.triple, 20), d(.triple, 20), d(.triple, 20)])
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: nil, darts: [d(.triple, 20), d(.single, 20), d(.single, 20)])
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: nil, darts: [d(.triple, 20), d(.triple, 20), d(.single, 1)])

    let now = Date()
    let summary = MatchSummary(
        id: matchId,
        type: .x01,
        status: .completed,
        startedAt: now,
        endedAt: now,
        winnerPlayerId: jacob,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: session.events.count,
        createdAt: now,
        updatedAt: now
    )
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: jacob, turnOrder: 0, displayNameAtMatchStart: "Jacob", avatarStyleAtMatchStart: nil),
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: sam, turnOrder: 1, displayNameAtMatchStart: "Sam", avatarStyleAtMatchStart: nil)
    ]
    let events = try session.events.map { envelope in
        MatchEventSummary(
            id: UUID(),
            matchId: matchId,
            eventIndex: envelope.eventIndex,
            eventTypeRaw: "x01Turn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: now
        )
    }
    let snapshot = MatchSnapshotSummary(
        id: UUID(),
        matchId: matchId,
        snapshotVersion: session.latestSnapshot.payloadVersion,
        snapshotPayload: session.latestSnapshot.payload,
        updatedAt: now
    )
    return StatsFixture(matchId: matchId, jacob: jacob, sam: sam, summary: summary, participants: participants, events: events, snapshot: snapshot)
}

private func makeCompletedCricketFixture() throws -> StatsFixture {
    let matchId = UUID()
    let carol = UUID()
    let bob = UUID()
    func triple(_ value: Int) -> DartInput {
        DartInput(multiplier: .triple, segment: .oneToTwenty(value))
    }
    func miss() -> DartInput {
        DartInput(multiplier: .single, segment: .miss, isMiss: true)
    }
    var session = try MatchLifecycleService.createMatch(
        matchId: matchId,
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(playerId: carol, displayNameAtMatchStart: "Carol", turnOrder: 0),
            MatchParticipant(playerId: bob, displayNameAtMatchStart: "Bob", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [triple(20)])
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [miss(), miss(), miss()])
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [triple(19)])

    let now = Date()
    let summary = MatchSummary(
        id: matchId,
        type: .cricket,
        status: .completed,
        startedAt: now,
        endedAt: now,
        winnerPlayerId: carol,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: session.events.count,
        createdAt: now,
        updatedAt: now
    )
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: carol, turnOrder: 0, displayNameAtMatchStart: "Carol", avatarStyleAtMatchStart: nil),
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: bob, turnOrder: 1, displayNameAtMatchStart: "Bob", avatarStyleAtMatchStart: nil)
    ]
    let events = try session.events.map { envelope in
        MatchEventSummary(
            id: UUID(),
            matchId: matchId,
            eventIndex: envelope.eventIndex,
            eventTypeRaw: "cricketTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: now
        )
    }
    let snapshot = MatchSnapshotSummary(
        id: UUID(),
        matchId: matchId,
        snapshotVersion: session.latestSnapshot.payloadVersion,
        snapshotPayload: session.latestSnapshot.payload,
        updatedAt: now
    )
    return StatsFixture(matchId: matchId, jacob: carol, sam: bob, summary: summary, participants: participants, events: events, snapshot: snapshot)
}

private extension HistoryMatchRecord {
    init(_ fixture: StatsFixture) {
        self.init(
            matchId: fixture.matchId,
            summary: fixture.summary,
            participants: fixture.participants,
            snapshot: fixture.snapshot
        )
    }
}

@MainActor
@Test(.tags(.integration, .stats, .x01, .regression))
func statisticsViewModelComputesBreakdownRows() async throws {
    let fixture = try makeCompletedX01Fixture()
    let vm = StatisticsViewModel(
        matchRepository: FakeMatchRepositoryBuilder.statsFlow(record: HistoryMatchRecord(fixture)),
        statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events),
        playerRepository: FakePlayerRepositoryBuilder.readOnly()
    )
    await vm.load()

    #expect(vm.rows.count == 2)
    let jacob = try #require(vm.rows.first { $0.playerId == fixture.jacob })
    #expect(jacob.wins == 1)
    #expect(jacob.points == 301)
    #expect(jacob.highestScore == 180)
    #expect(!vm.sectorHits.isEmpty)
}

@MainActor
@Test(.tags(.integration, .stats, .player, .regression))
func statisticsViewModelFiltersToSinglePlayer() async throws {
    let fixture = try makeCompletedX01Fixture()
    let vm = StatisticsViewModel(
        matchRepository: FakeMatchRepositoryBuilder.statsFlow(record: HistoryMatchRecord(fixture)),
        statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events),
        playerRepository: FakePlayerRepositoryBuilder.readOnly()
    )
    vm.playerFilter = fixture.jacob
    await vm.load()

    #expect(vm.rows.count == 1)
    #expect(vm.rows.first?.playerId == fixture.jacob)
    #expect(vm.rows.first?.wins == 1)
}

@MainActor
@Test(.tags(.integration, .stats, .player, .regression))
func playerDetailViewModelLoadsAllGamesStats() async throws {
    let fixture = try makeCompletedX01Fixture()
    let vm = PlayerDetailViewModel(
        playerId: fixture.jacob,
        playerName: "Jacob",
        playerRepository: FakePlayerRepositoryBuilder.readOnly(),
        matchRepository: FakeMatchRepositoryBuilder.statsFlow(record: HistoryMatchRecord(fixture)),
        statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
    )
    await vm.load()

    #expect(vm.hasAnyGames)
    #expect(vm.cricket == nil)
    let x01 = try #require(vm.x01)
    #expect(x01.games == 1)
    #expect(x01.wins == 1)
    #expect(x01.legs == 1)
    #expect(x01.highestCheckout == 121)
}

@MainActor
@Test(.tags(.integration, .history, .regression))
func historyDetailViewModelDeletesMatch() async throws {
    let fixture = try makeCompletedX01Fixture()
    let repo = FakeMatchRepositoryBuilder.statsFlow(record: HistoryMatchRecord(fixture))
    let vm = HistoryDetailViewModel(
        matchId: fixture.matchId,
        matchRepository: repo,
        statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
    )
    await vm.onAppear()
    #expect(!vm.breakdowns.isEmpty)
    #expect(vm.isX01)

    let deleted = await vm.deleteMatch()
    #expect(deleted)
    #expect(await repo.wasMatchDeleted(fixture.matchId))
}

@MainActor
@Test(.tags(.integration, .history, .accessibility, .regression))
func historyDetailViewModelResultAccessibilitySummaryIncludesStandings() async throws {
    let fixture = try makeCompletedX01Fixture()
    let vm = HistoryDetailViewModel(
        matchId: fixture.matchId,
        matchRepository: FakeMatchRepositoryBuilder.statsFlow(record: HistoryMatchRecord(fixture)),
        statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
    )
    await vm.onAppear()

    let accessibility = vm.resultAccessibilitySummary
    #expect(accessibility.contains("Jacob"))
    #expect(accessibility.contains("Sam"))
    #expect(!vm.configText.isEmpty)
    #expect(!vm.dateText.isEmpty)
}

@MainActor
@Test(.tags(.integration, .history, .regression))
func historyDetailViewModelReportsNotFoundForMissingMatch() async {
    let vm = HistoryDetailViewModel(
        matchId: UUID(),
        matchRepository: FakeHistoryMatchRepository(rows: []),
        statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: [])
    )
    await vm.onAppear()

    #expect(vm.state == "error")
    #expect(vm.errorMessageKey == "error.match.notFound")
    #expect(vm.timeline.isEmpty)
}

@MainActor
@Test(.tags(.integration, .history, .cricket, .regression))
func historyDetailViewModelBuildsCricketTimelineFromEvents() async throws {
    let fixture = try makeCompletedCricketFixture()
    let vm = HistoryDetailViewModel(
        matchId: fixture.matchId,
        matchRepository: FakeMatchRepositoryBuilder.statsFlow(record: HistoryMatchRecord(fixture)),
        statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
    )
    await vm.onAppear()

    #expect(!vm.isX01)
    #expect(vm.matchType == .cricket)
    #expect(vm.timeline.count == 3)
    #expect(vm.timeline.allSatisfy { $0.contains("Carol") || $0.contains("Bob") })
    #expect(vm.header?.modeSpecificSummaryText.isEmpty == false)
    #expect(vm.throwsRows.count == 2)
    #expect(vm.throwsRows.allSatisfy { $0.throwCount > 0 })
}

@MainActor
@Test(.tags(.integration, .history, .cricket, .stats, .regression))
func historyDetailViewModelLoadsCricketBreakdownsAndStandings() async throws {
    let fixture = try makeCompletedCricketFixture()
    let vm = HistoryDetailViewModel(
        matchId: fixture.matchId,
        matchRepository: FakeMatchRepositoryBuilder.statsFlow(record: HistoryMatchRecord(fixture)),
        statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
    )
    await vm.onAppear()

    #expect(vm.state == "ready")
    #expect(vm.breakdowns.count == 2)
    #expect(vm.standings.count == 2)
    #expect(vm.standings.contains { $0.name == "Carol" })
    let carolBreakdown = try #require(vm.breakdowns.first { $0.playerId == fixture.jacob })
    #expect(carolBreakdown.cricketMarks > 0)
}

@MainActor
@Test(.tags(.integration, .history, .x01, .regression))
func historyDetailViewModelBuildsX01TimelineFromEvents() async throws {
    let fixture = try makeCompletedX01Fixture()
    let vm = HistoryDetailViewModel(
        matchId: fixture.matchId,
        matchRepository: FakeMatchRepositoryBuilder.statsFlow(record: HistoryMatchRecord(fixture)),
        statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
    )
    await vm.onAppear()

    #expect(vm.timeline.count == 3)
    #expect(vm.timeline.allSatisfy { $0.contains("Jacob") || $0.contains("Sam") })
    #expect(vm.header?.modeSpecificSummaryText.isEmpty == false)
}

@MainActor
@Test(.tags(.integration, .history, .x01, .regression))
func historyListViewModelBuildsStandingsFromSnapshot() async throws {
    let fixture = try makeCompletedX01Fixture()
    let vm = HistoryListViewModel(
        matchRepository: FakeHistoryMatchRepository(
            rows: [fixture.summary],
            participantsByMatchId: [fixture.matchId: fixture.participants],
            snapshotsByMatchId: [fixture.matchId: fixture.snapshot]
        ),
        playerRepository: FakeHistoryPlayerRepository(players: [])
    )
    await vm.applyFilters()

    #expect(vm.rows.count == 1)
    #expect(vm.rows.first?.configText.contains("301") == true)
    #expect(vm.rows.first?.standings.count == 2)
    #expect(vm.rows.first?.standings.first(where: { $0.name == "Jacob" })?.isWinner == true)
    #expect(vm.rows.first?.standings.first(where: { $0.name == "Sam" })?.score == 201)
}

@MainActor
@Test(.tags(.integration, .history, .match, .regression))
func historyListRowMarksForfeitedBadge() async throws {
    let fixture = try makeForfeitedX01Fixture()
    let vm = HistoryListViewModel(
        matchRepository: FakeHistoryMatchRepository(
            rows: [fixture.summary],
            participantsByMatchId: [fixture.matchId: fixture.participants],
            snapshotsByMatchId: [fixture.matchId: fixture.snapshot]
        ),
        playerRepository: FakeHistoryPlayerRepository(players: [])
    )
    await vm.applyFilters()

    #expect(vm.rows.count == 1)
    #expect(vm.rows.first?.isForfeited == true)
    #expect(vm.rows.first?.isFinished == true)
}

@MainActor
@Test(.tags(.integration, .history, .match, .regression))
func historyDetailFormatsForfeitWinner() async throws {
    let fixture = try makeForfeitedX01Fixture()
    let vm = HistoryDetailViewModel(
        matchId: fixture.matchId,
        matchRepository: FakeMatchRepositoryBuilder.statsFlow(record: HistoryMatchRecord(fixture)),
        statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
    )
    await vm.onAppear()

    let header = try #require(vm.header)
    #expect(header.winnerText.localizedCaseInsensitiveContains("Sam"))
    #expect(header.winnerText.localizedCaseInsensitiveContains("Jacob"))
}

@MainActor
@Test(.tags(.integration, .history, .player, .regression))
func historyListViewModelSelectedPlayerNameReflectsFilter() async {
    let aliceId = UUID()
    let now = Date()
    let vm = HistoryListViewModel(
        matchRepository: FakeHistoryMatchRepository(rows: []),
        playerRepository: FakeHistoryPlayerRepository(players: [
            PlayerSummary(
                id: aliceId,
                name: "Alice",
                isArchived: false,
                isBot: false,
                botDifficultyRaw: nil,
                avatarStyleRaw: nil,
                preferredColorToken: nil,
                notes: nil,
                createdAt: now,
                updatedAt: now
            )
        ])
    )

    await vm.applyFilters()
    #expect(vm.selectedPlayerName == nil)

    vm.playerFilter = aliceId
    #expect(vm.selectedPlayerName == "Alice")
}

@MainActor
@Test(.tags(.integration, .history, .stats, .regression))
func historyDetailViewModelLoadsBreakdownsForCompletedMatch() async throws {
    let fixture = try makeCompletedX01Fixture()
    let vm = HistoryDetailViewModel(
        matchId: fixture.matchId,
        matchRepository: FakeMatchRepositoryBuilder.statsFlow(record: HistoryMatchRecord(fixture)),
        statsRepository: FakeStatsRepositoryBuilder.unfiltered(events: fixture.events)
    )
    await vm.onAppear()

    #expect(vm.state == "ready")
    #expect(vm.breakdowns.count == 2)
    #expect(vm.isX01)
    #expect(!vm.configText.isEmpty)
    #expect(vm.standings.count == 2)
}

private actor FakeHistoryMatchRepository: MatchRepository {
    let rows: [MatchSummary]
    let participantsByMatchId: [UUID: [MatchParticipantSummary]]
    let snapshotsByMatchId: [UUID: MatchSnapshotSummary]
    let activeMatch: MatchSummary?

    init(
        rows: [MatchSummary],
        participantsByMatchId: [UUID: [MatchParticipantSummary]] = [:],
        snapshotsByMatchId: [UUID: MatchSnapshotSummary] = [:],
        activeMatch: MatchSummary? = nil
    ) {
        self.rows = rows
        self.participantsByMatchId = participantsByMatchId
        self.snapshotsByMatchId = snapshotsByMatchId
        self.activeMatch = activeMatch
    }

    private var allRecords: [MatchHistoryRecord] {
        rows.map { MatchHistoryRecord(summary: $0, participants: participantsByMatchId[$0.id] ?? []) }
    }

    private func filteredRecords(filter: MatchHistoryFilter) -> [MatchHistoryRecord] {
        allRecords.filter { record in
            if let type = filter.matchType, record.summary.type != type { return false }
            if let included = filter.includedMatchTypes, !included.contains(record.summary.type) { return false }
            if let startedAfter = filter.startedAfter, record.summary.startedAt < startedAfter { return false }
            if let playerId = filter.participantPlayerId {
                guard record.participants.contains(where: { ($0.playerId ?? $0.id) == playerId }) else { return false }
            }
            return true
        }
    }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { rows.first! }
    func fetchActiveMatch() async throws -> MatchSummary? { activeMatch }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { rows }
    func fetchHistoryWithParticipants(page: Int, pageSize: Int, filter: MatchHistoryFilter) async throws -> [MatchHistoryRecord] {
        let filtered = filteredRecords(filter: filter)
        let start = max(0, page) * max(1, pageSize)
        guard start < filtered.count else { return [] }
        return Array(filtered.dropFirst(start).prefix(pageSize))
    }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { rows.first! }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func fetchLatestSnapshot(matchId: UUID) async throws -> MatchSnapshotSummary? { snapshotsByMatchId[matchId] }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor FakeHistoryPlayerRepository: PlayerRepository {
    let players: [PlayerSummary]

    init(players: [PlayerSummary]) {
        self.players = players
    }

    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { players }
    func createPlayer(name _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func createBot(difficulty _: BotDifficulty) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func updatePlayerProfile(playerId _: UUID, name _: String, avatarStyle _: PlayerAvatarStyle, colorToken _: PlayerColorToken, notes _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
}
