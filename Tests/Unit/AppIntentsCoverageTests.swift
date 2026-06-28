import Foundation
import Testing
@testable import DartBuddy

@Suite("App intents coverage", .tags(.unit, .navigation, .regression))
struct AppIntentsCoverageTests {
    @Test
    func intentNamesMatchSpecIdentifiers() {
        #expect(OpenPlayIntent.intentName == "open_play")
        #expect(ResumeActiveMatchIntent.intentName == "resume_active_match")
    }

    @Test
    func shortcutsProviderRespectsAppIntentsFeatureFlag() {
        if LocalFeatureFlagsProvider().isEnabled(.enableAppIntents) {
            #expect(DartBuddyShortcutsProvider.appShortcuts.count == 2)
        } else {
            #expect(DartBuddyShortcutsProvider.appShortcuts.isEmpty)
        }
    }

    @Test
    @MainActor
    func openPlayIntentRoutesToPlayTabWhenEnabled() async throws {
        defer { resetIntentBridge() }
        let state = IntentPerformTestState(selectedTab: .settings)
        try configureIntentBridge(state: state)
        _ = try await OpenPlayIntent().perform()
        #expect(state.selectedTab == .play)
        #expect(state.resetCount == 1)
    }

    @Test
    @MainActor
    func openPlayIntentThrowsWhenFeatureDisabled() async throws {
        defer { resetIntentBridge() }
        IntentRoutingBridge.featureFlagOverrides = [.enableAppIntents: false]
        await #expect(throws: IntentRoutingError.disabled) {
            try await OpenPlayIntent().perform()
        }
    }

    @Test
    @MainActor
    func resumeActiveMatchIntentRoutesResumeWhenMatchExists() async throws {
        defer { resetIntentBridge() }
        let activeMatch = makeIntentActiveMatch()
        let state = IntentPerformTestState(selectedTab: .settings)
        try configureIntentBridge(state: state, activeMatch: activeMatch)
        _ = try await ResumeActiveMatchIntent().perform()
        #expect(state.pendingResume?.match.id == activeMatch.id)
        #expect(state.pendingResume?.startSource == .intent)
    }

    @Test
    @MainActor
    func resumeActiveMatchIntentFallsBackToHomeWhenNoActiveMatch() async throws {
        defer { resetIntentBridge() }
        let state = IntentPerformTestState(selectedTab: .settings)
        try configureIntentBridge(state: state, activeMatch: nil)
        _ = try await ResumeActiveMatchIntent().perform()
        #expect(state.selectedTab == .play)
        #expect(state.pendingResume == nil)
    }

    @Test
    @MainActor
    func resumeActiveMatchIntentEnqueuesWhenShellNotReady() async throws {
        defer { resetIntentBridge() }
        enableAppIntents()
        let pending = PendingAppDestination()
        IntentRoutingBridge.setPendingDeepLink(pending)
        _ = try await ResumeActiveMatchIntent().perform()
        #expect(pending.hasPending)
    }
}

@MainActor
private final class IntentPerformTestState {
    var selectedTab: MainTabView.RootTab
    var resetCount = 0
    var pendingResume: PendingMatchResume?

    init(selectedTab: MainTabView.RootTab) {
        self.selectedTab = selectedTab
    }

    func makeActions() -> AppRouteRouter.Actions {
        AppRouteRouter.Actions(
            setSelectedTab: { [weak self] in self?.selectedTab = $0 },
            setPendingPlayResume: { [weak self] in self?.pendingResume = $0 },
            resetPlayNavigation: { [weak self] in self?.resetCount += 1 }
        )
    }
}

@MainActor
private func configureIntentBridge(
    state: IntentPerformTestState,
    activeMatch: MatchSummary? = nil
) throws {
    enableAppIntents()
    IntentRoutingBridge.configure(
        dependencies: try makeIntentPerformDependencies(activeMatch: activeMatch),
        actions: state.makeActions()
    )
}

@MainActor
private func enableAppIntents() {
    IntentRoutingBridge.featureFlagOverrides = [.enableAppIntents: true]
}

@MainActor
private func resetIntentBridge() {
    IntentRoutingBridge.featureFlagOverrides = [:]
    IntentRoutingBridge.clearRouteActions()
}

@MainActor
private func makeIntentPerformDependencies(activeMatch: MatchSummary?) throws -> AppDependencies {
    AppDependencies(
        modelContainer: try ModelContainerFactory.makeContainer(mode: .inMemory),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        playerRepository: FakePlayerRepositoryBuilder.emptyThrowing(),
        matchRepository: FakeMatchRepositoryBuilder.withActiveMatch( activeMatch),
        statsRepository: FakeStatsRepository(),
        settingsRepository: FakeSettingsRepository(),
        hapticsService: NoopHapticsService(),
        audioFeedbackService: NoopAudioFeedbackService(),
        turnTotalCallerService: NoopTurnTotalCallerService(),
        userPreferencesStore: UserPreferencesStore(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
}

private func makeIntentActiveMatch() -> MatchSummary {
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
        eventCount: 1,
        createdAt: Date(),
        updatedAt: Date()
    )
}
