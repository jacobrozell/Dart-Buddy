import Foundation
import Testing
@testable import DartBuddy

@Suite("Onboarding setup integration", .tags(.integration, .setupFlow, .regression))
@MainActor
struct OnboardingSetupIntegrationTests {
    @Test
    func onAppearDoesNotClearSelectionsWhenRosterFetchIsEmpty() async {
        let alice = makePlayer("Alice")
        let bob = makePlayer("Bob")
        let pending = PendingMatchPlayerSelections()
        let players = FakePlayerRepository(players: [])
        let vm = MatchSetupViewModel(
            playerRepository: players,
            settingsRepository: FakeSettingsRepository(),
            matchRepository: FakeMatchRepository(),
            activeMatchStore: ActiveMatchStore(),
            pendingMatchPlayerSelections: pending
        )
        vm.selectedPlayerIds = [alice.id, bob.id]

        await vm.onAppear()

        #expect(vm.selectedPlayerIds == [alice.id, bob.id])
    }

    @Test
    func persistedOnboardingRosterStagesOnSetupOnAppear() async throws {
        let container = try ModelContainerFactory.makeContainer(mode: .inMemory)
        let pending = PendingMatchPlayerSelections()
        let matchRepository = SwiftDataMatchRepository(container: container)
        let statsRepository = SwiftDataStatsRepository(container: container)
        let playerRepository = SwiftDataPlayerRepository(
            container: container,
            matchRepository: matchRepository,
            statsRepository: statsRepository
        )
        let settingsRepository = SwiftDataSettingsRepository(container: container)

        let human = try await playerRepository.createHumanPlayer(
            from: EditablePlayer(
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
        )
        let bot = try await playerRepository.createBot(difficulty: .medium)
        pending.enqueueForNextMatchSetup(human.id)
        pending.enqueueForNextMatchSetup(bot.id)

        let viewModel = MatchSetupViewModel(
            playerRepository: playerRepository,
            settingsRepository: settingsRepository,
            matchRepository: matchRepository,
            activeMatchStore: ActiveMatchStore(),
            pendingMatchPlayerSelections: pending
        )

        await viewModel.onAppear()

        #expect(viewModel.selectedPlayerIds.contains(human.id))
        let stagedBots = viewModel.selectedPlayerIds.compactMap { id in
            viewModel.availablePlayers.first { $0.id == id && $0.isBot }
        }
        #expect(!stagedBots.isEmpty)
    }

    @Test
    func setupViewModelAppliesPendingAfterOnboardingPersist() async throws {
        let container = try ModelContainerFactory.makeContainer(mode: .inMemory)
        let pending = PendingMatchPlayerSelections()
        let matchRepository = SwiftDataMatchRepository(container: container)
        let statsRepository = SwiftDataStatsRepository(container: container)
        let playerRepository = SwiftDataPlayerRepository(
            container: container,
            matchRepository: matchRepository,
            statsRepository: statsRepository
        )
        let settingsRepository = SwiftDataSettingsRepository(container: container)

        let setupViewModel = MatchSetupViewModel(
            playerRepository: playerRepository,
            settingsRepository: settingsRepository,
            matchRepository: matchRepository,
            activeMatchStore: ActiveMatchStore(),
            pendingMatchPlayerSelections: pending
        )

        await setupViewModel.onAppear()
        #expect(setupViewModel.selectedPlayerIds.isEmpty)

        let human = try await playerRepository.createHumanPlayer(
            from: EditablePlayer(
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
        )
        let bot = try await playerRepository.createBot(difficulty: .medium)
        pending.enqueueForNextMatchSetup(human.id)
        pending.enqueueForNextMatchSetup(bot.id)

        await PlaySetupStagingRefresh.applyPendingSelections(
            AppDependencies(
                modelContainer: container,
                logger: DefaultAppLogger(minimumLevel: .fault, sink: NoOpLogSink()),
                playerRepository: playerRepository,
                matchRepository: matchRepository,
                statsRepository: statsRepository,
                settingsRepository: settingsRepository,
                hapticsService: SystemHapticsService(),
                audioFeedbackService: BundledAudioFeedbackService(),
                turnTotalCallerService: SpeechTurnTotalCallerService(),
                userPreferencesStore: UserPreferencesStore(),
                activeMatchStore: ActiveMatchStore(),
                pendingMatchPlayerSelections: pending,
                featureFlags: LocalFeatureFlagsProvider()
            )
        )
        await setupViewModel.onAppear()

        #expect(setupViewModel.selectedPlayerIds.contains(human.id))
        #expect(setupViewModel.selectedPlayerIds.contains(bot.id))
    }

    @Test
    func onboardingBackupStagesWhenPendingQueueIsEmpty() async throws {
        let container = try ModelContainerFactory.makeContainer(mode: .inMemory)
        let pending = PendingMatchPlayerSelections()
        let matchRepository = SwiftDataMatchRepository(container: container)
        let statsRepository = SwiftDataStatsRepository(container: container)
        let playerRepository = SwiftDataPlayerRepository(
            container: container,
            matchRepository: matchRepository,
            statsRepository: statsRepository
        )
        let settingsRepository = SwiftDataSettingsRepository(container: container)

        let human = try await playerRepository.createHumanPlayer(
            from: EditablePlayer(
                id: UUID(),
                name: "Jordan",
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
        )
        let bot = try await playerRepository.createBot(difficulty: .medium)
        OnboardingSetupStaging.savePendingPlayerIds([human.id, bot.id])

        let setupViewModel = MatchSetupViewModel(
            playerRepository: playerRepository,
            settingsRepository: settingsRepository,
            matchRepository: matchRepository,
            activeMatchStore: ActiveMatchStore(),
            pendingMatchPlayerSelections: pending
        )

        await setupViewModel.onAppear()

        #expect(setupViewModel.selectedPlayerIds.contains(human.id))
        #expect(setupViewModel.selectedPlayerIds.contains(bot.id))
        #expect(OnboardingSetupStaging.peekPendingPlayerIds().isEmpty)
    }
}
