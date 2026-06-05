import SwiftUI

struct PlayRootView: View {
    let dependencies: AppDependencies
    @Binding var pendingResumeMatch: MatchSummary?
    @State private var path: [PlayRoute] = []
    @State private var hasAppliedSnapshotRoute = false
    @StateObject private var viewModel: PlayHomeViewModel
    @StateObject private var setupViewModel: MatchSetupViewModel

    init(dependencies: AppDependencies, pendingResumeMatch: Binding<MatchSummary?> = .constant(nil)) {
        self.dependencies = dependencies
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
                    path.append(match.type.playRoute(matchId: match.id))
                },
                onStartRoute: { next in path.append(next) },
                onQuickAddPlayer: { path.append(.quickAddPlayer) }
            )
            .uiTestAccessibilityDynamicTypeOverride()
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
                case let .matchSummary(matchId):
                    MatchSummaryScreen(
                        viewModel: MatchSummaryViewModel(
                            matchId: matchId,
                            store: dependencies.activeMatchStore,
                            matchRepository: dependencies.matchRepository,
                            statsRepository: dependencies.statsRepository
                        ),
                        onStartNewMatch: { path.removeAll() },
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
                case .quickAddPlayer:
                    QuickAddPlayerScreen(repository: dependencies.playerRepository) { created in
                        dependencies.pendingMatchPlayerSelections.enqueueForNextMatchSetup(created.id)
                        await setupViewModel.onAppear()
                    }
                }
            }
            .task {
                await viewModel.onAppear()
                await setupViewModel.onAppear()
                if hasAppliedSnapshotRoute == false {
                    hasAppliedSnapshotRoute = true
                    if ProcessInfo.processInfo.arguments.contains("-open_active_match"),
                       case let .readyWithActiveMatch(match) = viewModel.state {
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
            .onChange(of: pendingResumeMatch) { _, match in
                guard let match else { return }
                path = [match.type.playRoute(matchId: match.id)]
                pendingResumeMatch = nil
            }
        }
    }

    private func initialSnapshotRoute() -> PlayRoute? {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-snapshot_match_x01") {
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
        X01MatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            turnTotalCaller: dependencies.turnTotalCallerService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
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
        CricketMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            turnTotalCaller: dependencies.turnTotalCallerService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
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
                statsRepository: dependencies.statsRepository
            )
        )
    }

    var body: some View {
        KillerMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService
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
        BaseballMatchScreen(
            viewModel: viewModel,
            onShowSummary: onShowSummary,
            audio: dependencies.audioFeedbackService,
            haptics: dependencies.hapticsService,
            feedbackPreferences: dependencies.userPreferencesStore.feedback
        )
    }
}
