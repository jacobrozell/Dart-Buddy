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
                case let .x01Match(matchId),
                     let .cricketMatch(matchId),
                     let .baseballMatch(matchId),
                     let .killerMatch(matchId),
                     let .shanghaiMatch(matchId),
                     let .americanCricketMatch(matchId),
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
        if arguments.contains("-snapshot_match_killer") {
            return .killerMatch(matchId: UUID(uuidString: "00000000-0000-0000-0000-000000000005") ?? UUID())
        }
        if arguments.contains("-snapshot_match_shanghai") {
            return .shanghaiMatch(matchId: UUID(uuidString: "00000000-0000-0000-0000-000000000006") ?? UUID())
        }
        if arguments.contains("-snapshot_match_aroundTheClock") {
            return .aroundTheClockMatch(matchId: UUID(uuidString: "00000000-0000-0000-0000-000000000007") ?? UUID())
        }
        if arguments.contains("-snapshot_match_summary") {
            return .matchSummary(matchId: UUID(uuidString: "00000000-0000-0000-0000-000000000003") ?? UUID())
        }
        return nil
    }
}
