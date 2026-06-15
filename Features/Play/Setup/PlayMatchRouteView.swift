import SwiftUI

/// Routes active match screens from `PlayRoute` without per-mode route wrapper structs.
struct PlayMatchRouteView: View {
    let route: PlayRoute
    let dependencies: AppDependencies
    let onShowSummary: () -> Void

    var body: some View {
        switch route {
        case let .x01Match(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                X01MatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                X01MatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    turnTotalCaller: dependencies.turnTotalCallerService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle,
                    visionScoringEnabled: dependencies.featureFlags.isEnabled(.enableVisionAutoScoring),
                    visualDartboardInputEnabled: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput),
                    visionLogger: dependencies.logger,
                    defaultDartEntryPresentation: dependencies.userPreferencesStore.defaultDartEntryPresentation
                        .resolved(allowsVisualBoard: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput))
                )
            }
        case let .cricketMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                CricketMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                CricketMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    turnTotalCaller: dependencies.turnTotalCallerService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle,
                    visualDartboardInputEnabled: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput),
                    defaultDartEntryPresentation: dependencies.userPreferencesStore.defaultDartEntryPresentation
                        .resolved(allowsVisualBoard: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput))
                )
            }
        case let .baseballMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                BaseballMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                BaseballMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .killerMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                KillerMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                KillerMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .shanghaiMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                ShanghaiMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                ShanghaiMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .americanCricketMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                AmericanCricketMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                AmericanCricketMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .mickeyMouseMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                MickeyMouseMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                MickeyMouseMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .mulliganMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                MulliganMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                MulliganMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .englishCricketMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                EnglishCricketMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                EnglishCricketMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .knockoutMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                KnockoutMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                KnockoutMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .suddenDeathMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                SuddenDeathMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                SuddenDeathMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .fiftyOneByFivesMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                FiftyOneByFivesMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                FiftyOneByFivesMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .golfMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                GolfMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                GolfMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .footballMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                FootballMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                FootballMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .grandNationalMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                GrandNationalMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                GrandNationalMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .hareAndHoundsMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                HareAndHoundsMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                HareAndHoundsMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .aroundTheClockMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                AroundTheClockMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                AroundTheClockMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .aroundTheClock180Match(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                AroundTheClock180MatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                AroundTheClock180MatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .chaseTheDragonMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                ChaseTheDragonMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                ChaseTheDragonMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .nineLivesMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                NineLivesMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                NineLivesMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .fleetMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                FleetMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback
                )
            } content: { viewModel, lifecycle in
                FleetMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        case let .raidMatch(matchId):
            MatchRouteScreen(
                matchId: matchId,
                dependencies: dependencies,
                onShowSummary: onShowSummary
            ) {
                RaidMatchViewModel(
                    matchId: matchId,
                    store: dependencies.activeMatchStore,
                    logger: dependencies.logger,
                    matchRepository: dependencies.matchRepository,
                    statsRepository: dependencies.statsRepository
                )
            } content: { viewModel, lifecycle in
                RaidMatchScreen(
                    viewModel: viewModel,
                    onShowSummary: onShowSummary,
                    audio: dependencies.audioFeedbackService,
                    haptics: dependencies.hapticsService,
                    feedbackPreferences: dependencies.userPreferencesStore.feedback,
                    lifecycleDependencies: lifecycle
                )
            }
        default:
            EmptyView()
        }
    }
}

/// Shared `@StateObject` host for match route screens.
private struct MatchRouteScreen<VM: ObservableObject, Content: View>: View {
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: VM
    private let content: (VM, MatchLifecycleChromeDependencies) -> Content

    init(
        matchId: UUID,
        dependencies: AppDependencies,
        onShowSummary: @escaping () -> Void,
        makeViewModel: @escaping () -> VM,
        @ViewBuilder content: @escaping (VM, MatchLifecycleChromeDependencies) -> Content
    ) {
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(wrappedValue: makeViewModel())
        self.content = content
    }

    var body: some View {
        let lifecycle = MatchLifecycleChromeDependencies(
            store: dependencies.activeMatchStore,
            matchRepository: dependencies.matchRepository,
            logger: dependencies.logger
        )
        content(viewModel, lifecycle)
    }
}
