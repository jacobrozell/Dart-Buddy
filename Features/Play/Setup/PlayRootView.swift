import SwiftUI

struct PlayRootView: View {
    let dependencies: AppDependencies
    @Binding var pendingResumeMatch: PendingMatchResume?
    var navigationResetTrigger: Int = 0
    var onChangeMode: () -> Void = {}
    @State private var path: [PlayRoute] = []
    @State private var hasAppliedSnapshotRoute = false
    @StateObject private var viewModel: PlayHomeViewModel
    @StateObject private var setupViewModel: MatchSetupViewModel

    init(
        dependencies: AppDependencies,
        pendingResumeMatch: Binding<PendingMatchResume?> = .constant(nil),
        navigationResetTrigger: Int = 0,
        onChangeMode: @escaping () -> Void = {}
    ) {
        self.dependencies = dependencies
        self.navigationResetTrigger = navigationResetTrigger
        self.onChangeMode = onChangeMode
        _pendingResumeMatch = pendingResumeMatch
        _viewModel = StateObject(
            wrappedValue: PlayHomeViewModel(
                playerRepository: dependencies.playerRepository,
                matchRepository: dependencies.matchRepository,
                logger: dependencies.logger
            )
        )
        _setupViewModel = StateObject(
            wrappedValue: MatchSetupViewModel(
                playerRepository: dependencies.playerRepository,
                settingsRepository: dependencies.settingsRepository,
                matchRepository: dependencies.matchRepository,
                activeMatchStore: dependencies.activeMatchStore,
                pendingMatchPlayerSelections: dependencies.pendingMatchPlayerSelections,
                logger: dependencies.logger
            )
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            SetupHomeView(
                homeViewModel: viewModel,
                setupViewModel: setupViewModel,
                pendingMatchPlayerSelections: dependencies.pendingMatchPlayerSelections,
                onResumeMatch: { match in
                    guard ProductSurface.isMatchTypeReachable(match.type) else { return }
                    MatchAnalytics.logResumed(
                        logger: dependencies.logger,
                        match: match,
                        startSource: .resume,
                        session: dependencies.activeMatchStore.session(for: match.id)
                    )
                    path.append(match.type.playRoute(matchId: match.id))
                },
                onStartRoute: { next in path.append(next) },
                onChangeMode: onChangeMode
            )
            .navigationDestination(for: PlayRoute.self) { route in
                switch route {
                case .setup:
                    EmptyView()
                case let .x01Match(matchId):
                    X01MatchRouteView(
                        matchId: matchId,
                        dependencies: dependencies,
                        onShowSummary: { path.append(.matchSummary(matchId: matchId)) }
                    )
                case let .cricketMatch(matchId):
                    CricketMatchRouteView(
                        matchId: matchId,
                        dependencies: dependencies,
                        onShowSummary: { path.append(.matchSummary(matchId: matchId)) }
                    )
                case let .baseballMatch(matchId):
                    BaseballMatchRouteView(
                        matchId: matchId,
                        dependencies: dependencies,
                        onShowSummary: { path.append(.matchSummary(matchId: matchId)) }
                    )
                case let .killerMatch(matchId):
                    KillerMatchRouteView(
                        matchId: matchId,
                        dependencies: dependencies,
                        onShowSummary: { path.append(.matchSummary(matchId: matchId)) }
                    )
                case let .shanghaiMatch(matchId):
                    ShanghaiMatchRouteView(
                        matchId: matchId,
                        dependencies: dependencies,
                        onShowSummary: { path.append(.matchSummary(matchId: matchId)) }
                    )
                case let .americanCricketMatch(matchId),
                     let .mickeyMouseMatch(matchId),
                     let .mulliganMatch(matchId),
                     let .englishCricketMatch(matchId),
                     let .knockoutMatch(matchId),
                     let .suddenDeathMatch(matchId),
                     let .fiftyOneByFivesMatch(matchId),
                     let .golfMatch(matchId),
                     let .footballMatch(matchId),
                     let .grandNationalMatch(matchId),
                     let .hareAndHoundsMatch(matchId),
                     let .aroundTheClockMatch(matchId),
                     let .aroundTheClock180Match(matchId),
                     let .chaseTheDragonMatch(matchId),
                     let .nineLivesMatch(matchId),
                     let .fleetMatch(matchId),
                     let .raidMatch(matchId):
                    PlayMatchRouteView(
                        route: route,
                        dependencies: dependencies,
                        onShowSummary: { path.append(.matchSummary(matchId: matchId)) }
                    )
                case .blindKillerMatch,
                     .followTheLeaderMatch,
                     .loopMatch,
                     .prisonerMatch,
                     .scamMatch,
                     .snookerMatch,
                     .ticTacToeMatch,
                     .bobs27Match,
                     .halveItMatch:
                    EmptyView()
                case let .matchSummary(matchId):
                    MatchSummaryScreen(
                        viewModel: MatchSummaryViewModel(
                            matchId: matchId,
                            store: dependencies.activeMatchStore,
                            matchRepository: dependencies.matchRepository,
                            statsRepository: dependencies.statsRepository
                        ),
                        onRematch: { runtime in
                            if let route = await setupViewModel.startRematchRoute(from: runtime) {
                                path = [route]
                                return nil
                            }
                            return setupViewModel.displayValidationErrors.first
                                ?? "play.summary.rematchFailed"
                        },
                        onDone: { path.removeAll() },
                        onViewHistoryDetail: { id in path.append(.historyDetail(matchId: id)) },
                        onUndoLastThrow: { restoredDarts in
                            dependencies.activeMatchStore.setResumeHint(
                                matchId: matchId,
                                restoredDarts: restoredDarts
                            )
                            path.removeLast()
                        }
                    )
                case let .historyDetail(matchId):
                    MatchHistoryDetailScreen(
                        matchId: matchId,
                        matchRepository: dependencies.matchRepository,
                        statsRepository: dependencies.statsRepository,
                        onDeleted: { path.removeAll() }
                    )
                }
            }
            .task {
                await viewModel.onAppear()
                await setupViewModel.onAppear()
                if hasAppliedSnapshotRoute == false {
                    hasAppliedSnapshotRoute = true
                    if ProcessInfo.processInfo.arguments.contains("-open_active_match"),
                       case let .readyWithActiveMatch(match) = viewModel.state,
                       ProductSurface.isMatchTypeReachable(match.type) {
                        path = [match.type.playRoute(matchId: match.id)]
                    } else if let snapshotRoute = initialSnapshotRoute() {
                        path = [snapshotRoute]
                    }
                }
            }
            .onChange(of: path) { _, newValue in
                if newValue.isEmpty {
                    Task {
                        await viewModel.onAppear()
                        await setupViewModel.onAppear()
                    }
                }
            }
            .onChange(of: pendingResumeMatch) { _, pending in
                guard let pending, ProductSurface.isMatchTypeReachable(pending.match.type) else {
                    pendingResumeMatch = nil
                    return
                }
                MatchAnalytics.logResumed(
                    logger: dependencies.logger,
                    match: pending.match,
                    startSource: pending.startSource,
                    session: dependencies.activeMatchStore.session(for: pending.match.id)
                )
                path = [pending.match.type.playRoute(matchId: pending.match.id)]
                pendingResumeMatch = nil
            }
            .onChange(of: navigationResetTrigger) { _, _ in
                path.removeAll()
            }
        }
    }

    private func initialSnapshotRoute() -> PlayRoute? {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-snapshot_match_x01_8player") {
            return .x01Match(matchId: UUID(uuidString: "00000000-0000-0000-0000-000000000008") ?? UUID())
        } else if arguments.contains("-snapshot_match_x01") {
            return .x01Match(matchId: UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID())
        }
        if arguments.contains("-snapshot_match_cricket") {
            return .cricketMatch(matchId: UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID())
        }
        if arguments.contains("-snapshot_match_baseball") {
            return .baseballMatch(matchId: UUID(uuidString: "00000000-0000-0000-0000-000000000004") ?? UUID())
        }
        if arguments.contains("-snapshot_match_summary") {
            return .matchSummary(matchId: UUID(uuidString: "00000000-0000-0000-0000-000000000003") ?? UUID())
        }
        return nil
    }
}

private struct X01MatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: X01MatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: X01MatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        let lifecycleDependencies = MatchLifecycleChromeDependencies(
            store: dependencies.activeMatchStore,
            matchRepository: dependencies.matchRepository,
            logger: dependencies.logger
        )
        X01MatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            turnTotalCaller: dependencies.turnTotalCallerService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback,
            lifecycleDependencies: lifecycleDependencies,
            visionScoringEnabled: dependencies.featureFlags.isEnabled(.enableVisionAutoScoring),
            visualDartboardInputEnabled: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput),
            visionLogger: dependencies.logger,
            defaultDartEntryPresentation: dependencies.userPreferencesStore.defaultDartEntryPresentation
                .resolved(allowsVisualBoard: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput))
        )
    }
}

private struct CricketMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: CricketMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: CricketMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        let lifecycleDependencies = MatchLifecycleChromeDependencies(
            store: dependencies.activeMatchStore,
            matchRepository: dependencies.matchRepository,
            logger: dependencies.logger
        )
        CricketMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            turnTotalCaller: dependencies.turnTotalCallerService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback,
            lifecycleDependencies: lifecycleDependencies,
            visualDartboardInputEnabled: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput),
            defaultDartEntryPresentation: dependencies.userPreferencesStore.defaultDartEntryPresentation
                .resolved(allowsVisualBoard: dependencies.featureFlags.isEnabled(.enableVisualDartboardInput))
        )
    }
}

private struct KillerMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: KillerMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: KillerMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        let lifecycleDependencies = MatchLifecycleChromeDependencies(
            store: dependencies.activeMatchStore,
            matchRepository: dependencies.matchRepository,
            logger: dependencies.logger
        )
        KillerMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback,
            lifecycleDependencies: lifecycleDependencies
        )
    }
}

private struct ShanghaiMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: ShanghaiMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: ShanghaiMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        let lifecycleDependencies = MatchLifecycleChromeDependencies(
            store: dependencies.activeMatchStore,
            matchRepository: dependencies.matchRepository,
            logger: dependencies.logger
        )
        ShanghaiMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback,
            lifecycleDependencies: lifecycleDependencies
        )
    }
}

private struct BaseballMatchRouteView: View {
    let matchId: UUID
    let dependencies: AppDependencies
    let onShowSummary: () -> Void
    @StateObject private var viewModel: BaseballMatchViewModel

    init(matchId: UUID, dependencies: AppDependencies, onShowSummary: @escaping () -> Void) {
        self.matchId = matchId
        self.dependencies = dependencies
        self.onShowSummary = onShowSummary
        _viewModel = StateObject(
            wrappedValue: BaseballMatchViewModel(
                matchId: matchId,
                store: dependencies.activeMatchStore,
                logger: dependencies.logger,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                feedbackPreferences: dependencies.userPreferencesStore.feedback
            )
        )
    }

    var body: some View {
        let lifecycleDependencies = MatchLifecycleChromeDependencies(
            store: dependencies.activeMatchStore,
            matchRepository: dependencies.matchRepository,
            logger: dependencies.logger
        )
        BaseballMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback,
            lifecycleDependencies: lifecycleDependencies
        )
    }
}
