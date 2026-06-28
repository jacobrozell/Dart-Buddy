import Foundation
import Testing
@testable import DartBuddy

@Suite("Intent routing bridge", .tags(.unit, .navigation, .regression))
@MainActor
struct IntentRoutingBridgeTests {
    @Test
    func routesDirectlyWhenConfigured() async throws {
        defer { resetBridge() }
        let pending = PendingAppDestination()
        let state = IntentRouteTestState(selectedTab: .settings)
        let dependencies = try makeDependencies()
        enableAppIntents()
        IntentRoutingBridge.setPendingDeepLink(pending)
        IntentRoutingBridge.configure(dependencies: dependencies, actions: state.makeActions())

        let outcome = await IntentRoutingBridge.route(.play(.home), intentName: OpenPlayIntent.intentName)

        #expect(outcome == .applied)
        #expect(state.selectedTab == .play)
        #expect(state.resetCount == 1)
        #expect(!pending.hasPending)
    }

    @Test
    func enqueuesWhenRouteActionsMissing() async throws {
        defer { resetBridge() }
        let pending = PendingAppDestination()
        enableAppIntents()
        IntentRoutingBridge.setPendingDeepLink(pending)
        IntentRoutingBridge.clearRouteActions()

        let outcome = await IntentRoutingBridge.route(
            .play(.resumeActive),
            intentName: ResumeActiveMatchIntent.intentName
        )

        #expect(outcome == .applied)
        #expect(pending.hasPending)
    }

    @Test
    func disabledFlagSkipsRouting() async throws {
        defer { resetBridge() }
        let state = IntentRouteTestState(selectedTab: .play)
        let dependencies = try makeDependencies()
        IntentRoutingBridge.featureFlagOverrides = [.enableAppIntents: false]
        IntentRoutingBridge.configure(dependencies: dependencies, actions: state.makeActions())

        let outcome = await IntentRoutingBridge.route(.play(.home), intentName: OpenPlayIntent.intentName)

        #expect(outcome == .failed(.unknownPath))
        #expect(state.resetCount == 0)
    }

    @Test
    func fetchActiveMatchUsesConfiguredDependencies() async throws {
        defer { resetBridge() }
        let activeMatch = makeMatchSummary()
        let dependencies = try makeDependencies(activeMatch: activeMatch)
        IntentRoutingBridge.configure(
            dependencies: dependencies,
            actions: IntentRouteTestState(selectedTab: .play).makeActions()
        )

        let fetched = await IntentRoutingBridge.fetchActiveMatch()

        #expect(fetched?.id == activeMatch.id)
    }

    private func enableAppIntents() {
        IntentRoutingBridge.featureFlagOverrides = [.enableAppIntents: true]
    }

    private func resetBridge() {
        IntentRoutingBridge.featureFlagOverrides = [:]
        IntentRoutingBridge.clearRouteActions()
    }

    private func makeDependencies(activeMatch: MatchSummary? = nil) throws -> AppDependencies {
        AppDependencies(
            modelContainer: try ModelContainerFactory.makeContainer(mode: .inMemory),
            logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
            playerRepository: FakePlayerRepositoryBuilder.readOnly(),
            matchRepository: FakeMatchRepositoryBuilder.withActiveMatch(activeMatch),
            statsRepository: FakeStatsRepositoryBuilder.empty(),
            settingsRepository: FakeSettingsRepository(),
            hapticsService: NoopHapticsService(),
            audioFeedbackService: NoopAudioFeedbackService(),
            turnTotalCallerService: NoopTurnTotalCallerService(),
            userPreferencesStore: UserPreferencesStore(),
            activeMatchStore: ActiveMatchStore(),
            pendingMatchPlayerSelections: PendingMatchPlayerSelections()
        )
    }

    private func makeMatchSummary() -> MatchSummary {
        MatchSummary(
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
    }
}

@MainActor
private final class IntentRouteTestState {
    var selectedTab: MainTabView.RootTab
    var resetCount = 0

    init(selectedTab: MainTabView.RootTab) {
        self.selectedTab = selectedTab
    }

    func makeActions() -> AppRouteRouter.Actions {
        AppRouteRouter.Actions(
            setSelectedTab: { [weak self] in self?.selectedTab = $0 },
            setPendingPlayResume: { _ in },
            resetPlayNavigation: { [weak self] in self?.resetCount += 1 }
        )
    }
}
