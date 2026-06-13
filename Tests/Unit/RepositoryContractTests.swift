import Foundation
import SwiftData
import Testing
@testable import DartBuddy

private func makeRepositories() throws -> (
    player: SwiftDataPlayerRepository,
    match: SwiftDataMatchRepository,
    stats: SwiftDataStatsRepository,
    settings: SwiftDataSettingsRepository,
    container: ModelContainer
) {
    let container = try ModelContainerFactory.makeContainer(mode: .inMemory)
    let match = SwiftDataMatchRepository(container: container)
    let stats = SwiftDataStatsRepository(container: container)
    return (
        SwiftDataPlayerRepository(container: container, matchRepository: match, statsRepository: stats),
        match,
        stats,
        SwiftDataSettingsRepository(container: container),
        container
    )
}

@Test(.tags(.integration, .player, .swiftdata, .regression))
func playerRepositoryRejectsDuplicateNames() async throws {
    let repos = try makeRepositories()
    _ = try await repos.player.createPlayer(name: "Alice")
    do {
        _ = try await repos.player.createPlayer(name: "alice")
        Issue.record("Expected duplicate name rejection")
    } catch let error as AppError {
        #expect(error.userMessageKey == "player.validation.duplicateName")
    }
}

@Test(.tags(.integration, .player, .swiftdata, .regression))
func playerRepositoryRejectsDeleteWhenParticipantExists() async throws {
    let repos = try makeRepositories()
    let alice = try await repos.player.createPlayer(name: "Alice")
    let bob = try await repos.player.createPlayer(name: "Bob")
    let payload = try CodablePayloadCoder.encode(MatchConfigPayload.x01(MatchConfigX01(
        startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut
    )))
    let matchId = UUID()
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: alice.id, turnOrder: 0, displayNameAtMatchStart: "Alice", avatarStyleAtMatchStart: nil),
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: bob.id, turnOrder: 1, displayNameAtMatchStart: "Bob", avatarStyleAtMatchStart: nil)
    ]
    _ = try await repos.match.createMatch(type: .x01, configPayload: payload, participants: participants)

    do {
        try await repos.player.deletePlayer(playerId: alice.id)
        Issue.record("Expected delete to be blocked when player has match history")
    } catch let error as AppError {
        #expect(error.userMessageKey == "players.delete.blocked.message")
    }

    let players = try await repos.player.fetchPlayers(includeArchived: true)
    #expect(players.contains(where: { $0.id == alice.id }))
}

@Test(.tags(.integration, .match, .swiftdata, .critical, .regression))
func matchRepositoryHistoryExcludesAbandonedMatches() async throws {
    let repos = try makeRepositories()
    let alice = try await repos.player.createPlayer(name: "Alice")
    let bob = try await repos.player.createPlayer(name: "Bob")
    let payload = try CodablePayloadCoder.encode(MatchConfigPayload.x01(MatchConfigX01(
        startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut
    )))
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: UUID(), playerId: alice.id, turnOrder: 0, displayNameAtMatchStart: "Alice", avatarStyleAtMatchStart: nil),
        MatchParticipantSummary(id: UUID(), matchId: UUID(), playerId: bob.id, turnOrder: 1, displayNameAtMatchStart: "Bob", avatarStyleAtMatchStart: nil)
    ]
    let created = try await repos.match.createMatch(type: .x01, configPayload: payload, participants: participants)
    let abandoned = MatchSummary(
        id: created.id,
        type: created.type,
        status: .abandoned,
        startedAt: created.startedAt,
        endedAt: Date(),
        winnerPlayerId: nil,
        currentTurnPlayerId: nil,
        currentLegIndex: created.currentLegIndex,
        currentSetIndex: created.currentSetIndex,
        eventCount: created.eventCount,
        createdAt: created.createdAt,
        updatedAt: Date()
    )
    try await repos.match.updateMatch(abandoned)

    #expect(try await repos.match.fetchActiveMatch() == nil)
    #expect(try await repos.match.fetchHistory(page: 0, pageSize: 10).isEmpty)
    #expect(try await repos.match.fetchHistoryWithParticipants(page: 0, pageSize: 10, filter: MatchHistoryFilter()).isEmpty)
}

@Test(.tags(.integration, .match, .swiftdata, .regression))
func matchRepositoryHistoryIncludesForfeitedMatches() async throws {
    let repos = try makeRepositories()
    let alice = try await repos.player.createPlayer(name: "Alice")
    let bob = try await repos.player.createPlayer(name: "Bob")
    let payload = try CodablePayloadCoder.encode(MatchConfigPayload.x01(MatchConfigX01(
        startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut
    )))
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: UUID(), playerId: alice.id, turnOrder: 0, displayNameAtMatchStart: "Alice", avatarStyleAtMatchStart: nil),
        MatchParticipantSummary(id: UUID(), matchId: UUID(), playerId: bob.id, turnOrder: 1, displayNameAtMatchStart: "Bob", avatarStyleAtMatchStart: nil)
    ]
    let created = try await repos.match.createMatch(type: .x01, configPayload: payload, participants: participants)
    let forfeited = try await repos.match.forfeitMatch(
        matchId: created.id,
        endedAt: Date(),
        winnerPlayerId: bob.id,
        forfeitedByPlayerId: alice.id
    )
    #expect(forfeited.status == .forfeited)
    let history = try await repos.match.fetchHistory(page: 0, pageSize: 10)
    #expect(history.count == 1)
    #expect(history.first?.status == .forfeited)
}

@Test(.tags(.integration, .player, .swiftdata, .regression))
func playerRepositoryHidesArchivedPlayersByDefault() async throws {
    let repos = try makeRepositories()
    let alice = try await repos.player.createPlayer(name: "Alice")
    _ = try await repos.player.createPlayer(name: "Bob")
    try await repos.player.archivePlayer(playerId: alice.id)

    let active = try await repos.player.fetchPlayers(includeArchived: false)
    #expect(active.count == 1)
    #expect(active.first?.name == "Bob")

    let all = try await repos.player.fetchPlayers(includeArchived: true)
    #expect(all.count == 2)
}

@Test(.tags(.integration, .match, .swiftdata, .regression))
func matchRepositoryTracksActiveMatchAndCompletedHistory() async throws {
    let repos = try makeRepositories()
    let alice = try await repos.player.createPlayer(name: "Alice")
    let bob = try await repos.player.createPlayer(name: "Bob")
    let payload = try CodablePayloadCoder.encode(MatchConfigPayload.x01(MatchConfigX01(
        startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut
    )))
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: UUID(), playerId: alice.id, turnOrder: 0, displayNameAtMatchStart: "Alice", avatarStyleAtMatchStart: nil),
        MatchParticipantSummary(id: UUID(), matchId: UUID(), playerId: bob.id, turnOrder: 1, displayNameAtMatchStart: "Bob", avatarStyleAtMatchStart: nil)
    ]
    let created = try await repos.match.createMatch(type: .x01, configPayload: payload, participants: participants)
    #expect(try await repos.match.fetchActiveMatch()?.id == created.id)

    let completed = try await repos.match.completeMatch(matchId: created.id, endedAt: Date(), winnerPlayerId: alice.id)
    #expect(completed.status == .completed)
    #expect(try await repos.match.fetchActiveMatch() == nil)

    let history = try await repos.match.fetchHistory(page: 0, pageSize: 10)
    #expect(history.count == 1)
    #expect(history.first?.winnerPlayerId == alice.id)
}

@Test(.tags(.integration, .match, .swiftdata, .history, .regression))
func matchRepositoryWritesHistoryCardPayloadOnCompleteWhenSnapshotExists() async throws {
    let repos = try makeRepositories()
    let alice = try await repos.player.createPlayer(name: "Alice")
    let bob = try await repos.player.createPlayer(name: "Bob")
    let payload = try CodablePayloadCoder.encode(MatchConfigPayload.cricket(MatchConfigCricket()))
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: UUID(), playerId: alice.id, turnOrder: 0, displayNameAtMatchStart: "Alice", avatarStyleAtMatchStart: nil),
        MatchParticipantSummary(id: UUID(), matchId: UUID(), playerId: bob.id, turnOrder: 1, displayNameAtMatchStart: "Bob", avatarStyleAtMatchStart: nil)
    ]
    let created = try await repos.match.createMatch(type: .cricket, configPayload: payload, participants: participants)

    var session = try MatchLifecycleService.createMatch(
        matchId: created.id,
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(playerId: alice.id, displayNameAtMatchStart: "Alice", turnOrder: 0),
            MatchParticipant(playerId: bob.id, displayNameAtMatchStart: "Bob", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [CricketTestDarts.triple(20)])
    let snapshotPayload = try CodablePayloadCoder.encode(session.runtime)
    _ = try await repos.match.saveSnapshot(matchId: created.id, snapshotVersion: 1, snapshotPayload: snapshotPayload)

    _ = try await repos.match.completeMatch(matchId: created.id, endedAt: Date(), winnerPlayerId: alice.id)

    let records = try await repos.match.fetchHistoryWithParticipants(page: 0, pageSize: 10, filter: MatchHistoryFilter())
    #expect(records.count == 1)
    let cardData = try #require(records.first?.historyCardPayload)
    let card = try CodablePayloadCoder.decode(MatchHistoryCardPayload.self, from: cardData)
    #expect(card.payloadVersion == MatchHistoryCardPayload.currentPayloadVersion)
    #expect(card.standings.count == 2)
    #expect(card.standings.contains(where: { $0.name == "Alice" && $0.isWinner }))
}

@Test(.tags(.integration, .match, .swiftdata, .regression))
func matchRepositoryHistoryFilterMapsToDatabase() async throws {
    let repos = try makeRepositories()
    let alice = try await repos.player.createPlayer(name: "Alice")
    let bob = try await repos.player.createPlayer(name: "Bob")
    let now = Date()

    func seedCompleted(type: MatchType, winner: UUID, startedAt: Date) async throws {
        let payload: Data = try CodablePayloadCoder.encode(MatchConfigDefaults.config(for: type))
        let matchId = UUID()
        let participants = [
            MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: alice.id, turnOrder: 0, displayNameAtMatchStart: "Alice", avatarStyleAtMatchStart: nil),
            MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: bob.id, turnOrder: 1, displayNameAtMatchStart: "Bob", avatarStyleAtMatchStart: nil)
        ]
        var summary = try await repos.match.createMatch(type: type, configPayload: payload, participants: participants)
        summary = MatchSummary(
            id: summary.id,
            type: summary.type,
            status: summary.status,
            startedAt: startedAt,
            endedAt: summary.endedAt,
            winnerPlayerId: summary.winnerPlayerId,
            currentTurnPlayerId: summary.currentTurnPlayerId,
            currentLegIndex: summary.currentLegIndex,
            currentSetIndex: summary.currentSetIndex,
            eventCount: summary.eventCount,
            createdAt: startedAt,
            updatedAt: startedAt
        )
        try await repos.match.updateMatch(summary)
        _ = try await repos.match.completeMatch(matchId: summary.id, endedAt: startedAt, winnerPlayerId: winner)
    }

    try await seedCompleted(type: .x01, winner: alice.id, startedAt: now)
    try await seedCompleted(type: .cricket, winner: bob.id, startedAt: now.addingTimeInterval(-864_000))

    let x01Only = try await repos.match.fetchHistoryWithParticipants(
        page: 0,
        pageSize: 10,
        filter: MatchHistoryFilter(matchType: .x01)
    )
    #expect(x01Only.count == 1)
    #expect(x01Only.first?.summary.type == .x01)

    let recent = try await repos.match.fetchHistoryWithParticipants(
        page: 0,
        pageSize: 10,
        filter: MatchHistoryFilter(startedAfter: now.addingTimeInterval(-86_400))
    )
    #expect(recent.count == 1)
    #expect(recent.first?.summary.type == .x01)

    let bobGames = try await repos.match.fetchHistoryWithParticipants(
        page: 0,
        pageSize: 10,
        filter: MatchHistoryFilter(participantPlayerId: bob.id)
    )
    #expect(bobGames.count == 2)
}

@Test(.tags(.integration, .settings, .swiftdata, .regression))
func settingsRepositoryPersistsFeedbackToggles() async throws {
    let repos = try makeRepositories()
    let baseline = try await repos.settings.seedDefaultsIfNeeded()
    #expect(baseline.hapticsEnabled == true)
    #expect(baseline.soundEnabled == true)
    #expect(baseline.botStaggerEnabled == true)
    #expect(baseline.botDartHapticsEnabled == true)

    let updated = SettingsSummary(
        id: baseline.id,
        appearanceModeRaw: baseline.appearanceModeRaw,
        hapticsEnabled: false,
        soundEnabled: false,
        turnTotalCallerEnabled: baseline.turnTotalCallerEnabled,
        defaultMatchTypeRaw: baseline.defaultMatchTypeRaw,
        defaultX01StartScore: baseline.defaultX01StartScore,
        defaultCheckoutModeRaw: baseline.defaultCheckoutModeRaw,
        defaultCheckInModeRaw: baseline.defaultCheckInModeRaw,
        defaultLegFormatRaw: baseline.defaultLegFormatRaw,
        defaultLegsToWin: baseline.defaultLegsToWin,
        defaultSetsEnabled: baseline.defaultSetsEnabled,
        botStaggerEnabled: false,
        botDartHapticsEnabled: false,
        defaultDartEntryPresentationRaw: "numberPad",
        updatedAt: baseline.updatedAt
    )
    _ = try await repos.settings.updateSettings(updated)

    let reloaded = try await repos.settings.fetchSettings()
    #expect(reloaded.hapticsEnabled == false)
    #expect(reloaded.soundEnabled == false)
    #expect(reloaded.botStaggerEnabled == false)
    #expect(reloaded.botDartHapticsEnabled == false)
}

@Test(.tags(.integration, .stats, .swiftdata, .regression))
func statsRepositoryStoresAndFetchesEventsByMatchId() async throws {
    let repos = try makeRepositories()
    let alice = try await repos.player.createPlayer(name: "Alice")
    let bob = try await repos.player.createPlayer(name: "Bob")
    let payload = try CodablePayloadCoder.encode(MatchConfigPayload.x01(MatchConfigX01(
        startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut
    )))
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: UUID(), playerId: alice.id, turnOrder: 0, displayNameAtMatchStart: "Alice", avatarStyleAtMatchStart: nil),
        MatchParticipantSummary(id: UUID(), matchId: UUID(), playerId: bob.id, turnOrder: 1, displayNameAtMatchStart: "Bob", avatarStyleAtMatchStart: nil)
    ]
    let match = try await repos.match.createMatch(type: .x01, configPayload: payload, participants: participants)
    let dart = DartInput(multiplier: .single, segment: .oneToTwenty(20))
    let envelope = MatchEventEnvelope(
        eventIndex: 0,
        payload: .x01Turn(X01TurnEvent(
            payloadVersion: 1,
            id: UUID(),
            playerId: alice.id,
            turnIndex: 0,
            legIndex: 0,
            setIndex: 0,
            startRemaining: 301,
            enteredTotal: 20,
            appliedTotal: 20,
            endRemaining: 281,
            isBust: false,
            didCheckout: false,
            checkoutModeRaw: X01CheckoutMode.singleOut.rawValue,
            checkoutDartCount: nil,
            darts: [
                X01DartEvent(
                    dartOrder: 1,
                    multiplierRaw: dart.multiplier.rawValue,
                    segmentRaw: "20",
                    points: dart.points,
                    wasMiss: false
                )
            ],
            timestamp: Date(),
            dartsThrown: 1
        )),
        timestamp: Date()
    )
    let eventData = try CodablePayloadCoder.encode(envelope)
    _ = try await repos.match.appendEvent(matchId: match.id, eventTypeRaw: "x01Turn", eventPayload: eventData)

    let events = try await repos.stats.fetchEvents(matchId: match.id)
    #expect(events.count == 1)
    #expect(events.first?.matchId == match.id)

    let batch = try await repos.stats.fetchEvents(matchIds: [match.id])
    #expect(batch.count == 1)
}

@Test(.tags(.integration, .settings, .swiftdata, .regression))
func settingsRepositoryResetsPreferencesToDefaults() async throws {
    let repos = try makeRepositories()
    let baseline = try await repos.settings.seedDefaultsIfNeeded()
    let customized = SettingsSummary(
        id: baseline.id,
        appearanceModeRaw: "dark",
        hapticsEnabled: false,
        soundEnabled: false,
        turnTotalCallerEnabled: true,
        defaultMatchTypeRaw: "cricket",
        defaultX01StartScore: 301,
        defaultCheckoutModeRaw: "singleOut",
        defaultCheckInModeRaw: "doubleIn",
        defaultLegFormatRaw: "bestOf",
        defaultLegsToWin: 5,
        defaultSetsEnabled: true,
        botStaggerEnabled: false,
        botDartHapticsEnabled: false,
        defaultDartEntryPresentationRaw: "visualBoard",
        updatedAt: Date()
    )
    _ = try await repos.settings.updateSettings(customized)
    let persisted = try await repos.settings.fetchSettings()
    #expect(persisted.defaultDartEntryPresentationRaw == "visualBoard")

    try await repos.settings.resetPreferencesToDefaults()

    let reloaded = try await repos.settings.fetchSettings()
    #expect(reloaded.appearanceModeRaw == "system")
    #expect(reloaded.defaultMatchTypeRaw == "x01")
    #expect(reloaded.defaultX01StartScore == 501)
    #expect(reloaded.hapticsEnabled)
    #expect(reloaded.soundEnabled)
    #expect(reloaded.botStaggerEnabled)
    #expect(reloaded.botDartHapticsEnabled)
    #expect(reloaded.defaultDartEntryPresentationRaw == "numberPad")
}

@Test(.tags(.integration, .settings, .swiftdata, .regression))
func settingsRepositoryResetAllLocalDataClearsEverySwiftDataTable() async throws {
    let repos = try makeRepositories()
    let alice = try await repos.player.createPlayer(name: "Alice")
    let bob = try await repos.player.createPlayer(name: "Bob")
    let payload = try CodablePayloadCoder.encode(MatchConfigPayload.x01(MatchConfigX01(
        startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut
    )))
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: UUID(), playerId: alice.id, turnOrder: 0, displayNameAtMatchStart: "Alice", avatarStyleAtMatchStart: nil),
        MatchParticipantSummary(id: UUID(), matchId: UUID(), playerId: bob.id, turnOrder: 1, displayNameAtMatchStart: "Bob", avatarStyleAtMatchStart: nil)
    ]
    let match = try await repos.match.createMatch(type: .x01, configPayload: payload, participants: participants)
    _ = try await repos.match.appendEvent(
        matchId: match.id,
        eventTypeRaw: "x01Turn",
        eventPayload: Data([0x01])
    )
    _ = try await repos.match.saveSnapshot(
        matchId: match.id,
        snapshotVersion: 1,
        snapshotPayload: Data([0x02])
    )
    #expect(try await repos.player.fetchPlayers(includeArchived: false).count == 2)
    #expect(try await repos.match.fetchActiveMatch() != nil)

    let beforeReset = try LocalDataResetInventory.swiftDataRecordCounts(in: repos.container)
    #expect(beforeReset[String(describing: SchemaV3.PlayerRecord.self)] == 2)
    #expect(beforeReset[String(describing: SchemaV3.MatchRecord.self)] == 1)
    #expect(beforeReset[String(describing: SchemaV3.MatchParticipantRecord.self)] == 2)
    #expect(beforeReset[String(describing: SchemaV3.MatchEventRecord.self)] == 1)
    #expect(beforeReset[String(describing: SchemaV3.MatchSnapshotRecord.self)] == 1)

    try await repos.settings.resetAllLocalData()

    #expect(try await repos.player.fetchPlayers(includeArchived: true).isEmpty)
    #expect(try await repos.match.fetchActiveMatch() == nil)
    #expect(try await repos.match.fetchHistory(page: 0, pageSize: 10).isEmpty)

    let afterReset = try LocalDataResetInventory.swiftDataRecordCounts(in: repos.container)
    #expect(afterReset[String(describing: SchemaV3.PlayerRecord.self)] == 0)
    #expect(afterReset[String(describing: SchemaV3.MatchRecord.self)] == 0)
    #expect(afterReset[String(describing: SchemaV3.MatchParticipantRecord.self)] == 0)
    #expect(afterReset[String(describing: SchemaV3.MatchEventRecord.self)] == 0)
    #expect(afterReset[String(describing: SchemaV3.MatchSnapshotRecord.self)] == 0)
    #expect(afterReset[String(describing: SchemaV3.SettingsRecord.self)] == 1)

    let settings = try await repos.settings.fetchSettings()
    #expect(settings.defaultMatchTypeRaw == "x01")
    #expect(settings.hapticsEnabled)
}

@Test(.tags(.integration, .match, .swiftdata, .regression))
func matchRepositoryFetchConfigPayloadReturnsPersistedData() async throws {
    let repos = try makeRepositories()
    let alice = try await repos.player.createPlayer(name: "Alice")
    let bob = try await repos.player.createPlayer(name: "Bob")
    let config = MatchConfigX01(startScore: 501, legsToWin: 3, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)
    let payload = try CodablePayloadCoder.encode(MatchConfigPayload.x01(config))
    let matchId = UUID()
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: alice.id, turnOrder: 0, displayNameAtMatchStart: "Alice", avatarStyleAtMatchStart: nil),
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: bob.id, turnOrder: 1, displayNameAtMatchStart: "Bob", avatarStyleAtMatchStart: nil)
    ]
    let created = try await repos.match.createMatch(type: .x01, configPayload: payload, participants: participants)

    let fetched = try await repos.match.fetchConfigPayload(matchId: created.id)
    let decoded = try CodablePayloadCoder.decode(MatchConfigPayload.self, from: try #require(fetched))
    #expect(decoded == .x01(config))
}

@Test(.tags(.integration, .player, .swiftdata, .regression))
func createHumanPlayerDesignatesPrimaryWhenRequested() async throws {
    let repos = try makeRepositories()
    let draft = EditablePlayer(
        id: UUID(),
        name: "Casey",
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
        colorToken: .green,
        playerRole: .primary
    )

    let created = try await repos.player.createHumanPlayer(from: draft)

    let primary = try await repos.player.fetchPrimaryPlayer()
    #expect(primary?.id == created.id)
    #expect(created.isPrimaryPlayer)
}

@Test(.tags(.integration, .player, .swiftdata, .regression))
func playerRepositoryDesignatesSinglePrimaryPlayer() async throws {
    let repos = try makeRepositories()
    let alice = try await repos.player.createPlayer(name: "Alice")
    let bob = try await repos.player.createPlayer(name: "Bob")

    let designated = try await repos.player.designatePrimaryPlayer(playerId: bob.id)
    #expect(designated.isPrimaryPlayer)

    let primary = try await repos.player.fetchPrimaryPlayer()
    #expect(primary?.id == bob.id)

    let players = try await repos.player.fetchPlayers(includeArchived: true)
    #expect(players.first(where: { $0.id == alice.id })?.isPrimaryPlayer == false)
    #expect(players.first(where: { $0.id == bob.id })?.playerRole == .primary)
}

@Test(.tags(.integration, .player, .swiftdata, .regression))
func primaryPlayerBootstrapPromotesOldestHuman() async throws {
    let repos = try makeRepositories()
    let older = try await repos.player.createPlayer(name: "Jacob")
    try await Task.sleep(nanoseconds: 5_000_000)
    _ = try await repos.player.createPlayer(name: "Guest")

    await PrimaryPlayerBootstrap.promoteOldestHumanIfNeeded(using: repos.player)

    let primary = try await repos.player.fetchPrimaryPlayer()
    #expect(primary?.id == older.id)
    #expect(primary?.name == "Jacob")
}
