import Foundation
import Testing
@testable import DartBuddy

@Suite("Demo seeder", .tags(.integration, .regression))
@MainActor
struct DemoSeederTests {
    @Test
    func seedPlayersOnlyCreatesAliceBobAndCarol() async throws {
        let dependencies = try makeDependencies()

        await DemoSeeder.seedIfRequested(dependencies, arguments: ["-seed_players"])

        let players = try await dependencies.playerRepository.fetchPlayers(includeArchived: false)
        #expect(players.count == 3)
        #expect(Set(players.map(\.name)) == Set(["Alice", "Bob", "Carol"]))
    }

    @Test
    func seedPlayersOnlyIsIdempotentWhenPlayersExist() async throws {
        let dependencies = try makeDependencies()
        _ = try await dependencies.playerRepository.createPlayer(name: "Existing")

        await DemoSeeder.seedIfRequested(dependencies, arguments: ["-seed_players"])

        let players = try await dependencies.playerRepository.fetchPlayers(includeArchived: false)
        #expect(players.count == 1)
        #expect(players.first?.name == "Existing")
    }

    @Test
    func appearanceModeLaunchArgumentUpdatesSettingsAndPreferences() async throws {
        let dependencies = try makeDependencies()

        await DemoSeeder.seedIfRequested(
            dependencies,
            arguments: ["-appearance_mode", "dark"]
        )

        let settings = try await dependencies.settingsRepository.fetchSettings()
        #expect(settings.appearanceModeRaw == "dark")
        #expect(dependencies.userPreferencesStore.appearanceModeRaw == "dark")
        #expect(dependencies.userPreferencesStore.preferredColorScheme == .dark)
    }

    @Test
    func invalidAppearanceModeLaunchArgumentIsIgnored() async throws {
        let dependencies = try makeDependencies()

        await DemoSeeder.seedIfRequested(
            dependencies,
            arguments: ["-appearance_mode", "sepia"]
        )

        let settings = try await dependencies.settingsRepository.fetchSettings()
        #expect(settings.appearanceModeRaw == "system")
    }

    @Test
    func disableFeedbackLaunchArgumentTurnsOffFeedbackToggles() async throws {
        let dependencies = try makeDependencies()

        await DemoSeeder.seedIfRequested(dependencies, arguments: ["-ui_test_disable_feedback"])

        let settings = try await dependencies.settingsRepository.fetchSettings()
        #expect(!settings.hapticsEnabled)
        #expect(!settings.soundEnabled)
        #expect(!settings.botStaggerEnabled)
        #expect(!settings.botDartHapticsEnabled)
        #expect(!dependencies.userPreferencesStore.feedback.hapticsEnabled)
    }

    @Test
    func x01SnapshotLaunchArgumentStoresActiveMatch() async throws {
        let dependencies = try makeDependencies()

        await DemoSeeder.seedIfRequested(dependencies, arguments: ["-snapshot_match_x01"])

        let summary = await MainActor.run { dependencies.activeMatchStore.activeMatchSummary() }
        #expect(summary?.id.uuidString == "00000000-0000-0000-0000-000000000001")
        #expect(summary?.type == .x01)
        #expect(summary?.status == .inProgress)
    }

    @Test
    func cricketSnapshotLaunchArgumentStoresActiveMatch() async throws {
        let dependencies = try makeDependencies()

        await DemoSeeder.seedIfRequested(dependencies, arguments: ["-snapshot_match_cricket"])

        let summary = await MainActor.run { dependencies.activeMatchStore.activeMatchSummary() }
        #expect(summary?.id.uuidString == "00000000-0000-0000-0000-000000000002")
        #expect(summary?.type == .cricket)
    }

    @Test
    func summarySnapshotLaunchArgumentStoresCompletedMatch() async throws {
        let dependencies = try makeDependencies()
        let matchId = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!

        await DemoSeeder.seedIfRequested(dependencies, arguments: ["-snapshot_match_summary"])

        let session = await MainActor.run { dependencies.activeMatchStore.session(for: matchId) }
        #expect(session?.runtime.matchId == matchId)
        #expect(session?.runtime.status == .completed)
    }

    @Test
    func customBotSnapshotLaunchArgumentSeedsTunedAce() async throws {
        let dependencies = try makeDependencies()

        await DemoSeeder.seedIfRequested(
            dependencies,
            arguments: ["-ui_test_reset", "-snapshot_custom_bot"]
        )

        let players = try await dependencies.playerRepository.fetchPlayers(includeArchived: false)
        guard let customBot = players.first(where: \.isCustomBot) else {
            Issue.record("Expected a custom bot after snapshot seed")
            return
        }
        #expect(customBot.name == DemoSeeder.customBotSnapshotName)
        #expect(customBot.customBotMetrics == DemoSeeder.customBotSnapshotMetrics)
    }

    @Test
    func seedDemoCreatesPlayersHistoryAndInProgressMatch() async throws {
        let dependencies = try makeDependencies()

        await DemoSeeder.seedIfRequested(dependencies, arguments: ["-seed_demo"])

        let players = try await dependencies.playerRepository.fetchPlayers(includeArchived: false)
        #expect(players.count >= 3)
        #expect(players.contains(where: { $0.name == "Jacob" && !$0.isBot }))
        #expect(players.contains(where: { $0.isBot }))
        #expect(players.contains(where: { $0.name == "Sam" && !$0.isBot }))

        let history = try await dependencies.matchRepository.fetchHistory(page: 0, pageSize: 20)
        let expectedCompletedMatches = ProductSurface.showsPartyModes ? 3 : 2
        #expect(history.count >= expectedCompletedMatches)
        if !ProductSurface.showsPartyModes {
            #expect(!history.contains { $0.type == .baseball })
        }

        let active = await MainActor.run { dependencies.activeMatchStore.activeMatchSummary() }
        #expect(active?.status == .inProgress)
    }

    @Test
    func seedDemoSkipsWhenPlayersAlreadyExist() async throws {
        let dependencies = try makeDependencies()
        _ = try await dependencies.playerRepository.createPlayer(name: "Preexisting")

        await DemoSeeder.seedIfRequested(dependencies, arguments: ["-seed_demo"])

        let players = try await dependencies.playerRepository.fetchPlayers(includeArchived: false)
        #expect(players.count == 1)
        #expect(try await dependencies.matchRepository.fetchHistory(page: 0, pageSize: 10).isEmpty)
    }

    @Test
    func uiTestResetClearsPlayersAndActiveMatch() async throws {
        let dependencies = try makeDependencies()
        _ = try await dependencies.playerRepository.createPlayer(name: "Alice")
        let session = try MatchLifecycleService.createMatch(
            type: .x01,
            config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
            participants: [
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
                MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
            ]
        )
        await MainActor.run { dependencies.activeMatchStore.save(session) }

        await DemoSeeder.seedIfRequested(dependencies, arguments: ["-ui_test_reset"])

        #expect(try await dependencies.playerRepository.fetchPlayers(includeArchived: true).isEmpty)
        #expect(await MainActor.run { dependencies.activeMatchStore.activeMatchSummary() } == nil)
    }

    @Test
    func trainingPartnerSeedCreatesCompletedGamesWithoutBot() async throws {
        let dependencies = try makeDependencies()

        await DemoSeeder.seedIfRequested(dependencies, arguments: ["-seed_training_locked"])

        let players = try await dependencies.playerRepository.fetchPlayers(includeArchived: false)
        #expect(players.contains(where: { $0.name == "Alice" }))
        #expect(players.contains(where: { $0.name == "Bob" }))
        let history = try await dependencies.matchRepository.fetchHistory(page: 0, pageSize: 20)
        #expect(history.count == 3)
        #expect(try await dependencies.playerRepository.fetchTrainingBot(linkedTo: players.first(where: { $0.name == "Alice" })!.id) == nil)
    }

    @Test
    func trainingPartnerSeedCreatesBotWhenRequested() async throws {
        let dependencies = try makeDependencies()

        await DemoSeeder.seedIfRequested(dependencies, arguments: ["-seed_training_partner"])

        let alice = try await dependencies.playerRepository.fetchPlayers(includeArchived: false)
            .first(where: { $0.name == "Alice" })
        let bot = try await dependencies.playerRepository.fetchTrainingBot(linkedTo: try #require(alice).id)
        #expect(bot != nil)
        #expect(bot?.isBot == true)
    }

    private func makeDependencies() throws -> AppDependencies {
        let container = try ModelContainerFactory.makeContainer(mode: .inMemory)
        let matchRepository = SwiftDataMatchRepository(container: container)
        let statsRepository = SwiftDataStatsRepository(container: container)
        return AppDependencies(
            modelContainer: container,
            logger: DefaultAppLogger(minimumLevel: .fault, sink: DemoSeederRecordingSink()),
            playerRepository: SwiftDataPlayerRepository(
                container: container,
                matchRepository: matchRepository,
                statsRepository: statsRepository
            ),
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            settingsRepository: SwiftDataSettingsRepository(container: container),
            hapticsService: NoopHapticsService(),
            audioFeedbackService: NoopAudioFeedbackService(),
            turnTotalCallerService: NoopTurnTotalCallerService(),
            userPreferencesStore: UserPreferencesStore(),
            activeMatchStore: ActiveMatchStore(),
            pendingMatchPlayerSelections: PendingMatchPlayerSelections()
        )
    }
}

private final class DemoSeederRecordingSink: LogSink, @unchecked Sendable {
    func write(_: LogEntry) {}
}
