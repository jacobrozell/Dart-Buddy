import SwiftUI

enum ActivitySegment: String, CaseIterable, Identifiable {
    case history
    case statistics

    var id: String { rawValue }

    var title: String {
        switch self {
        case .history: L10n.string("activity.segment.history")
        case .statistics: L10n.string("activity.segment.statistics")
        }
    }
}

struct ActivityRootView: View {
    let dependencies: AppDependencies
    /// Bumped by `MainTabView` when the Activity tab is selected so data reloads
    /// even if SwiftUI does not re-fire `onAppear` on an already-mounted tab.
    let refreshToken: Int
    var onResumeActiveMatch: ((MatchSummary) -> Void)?
    var onStartMatch: (() -> Void)?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var segment: ActivitySegment = ActivityRootView.startupSegment
    @State private var modeFilter: ActivityModeFilter = ActivityRootView.startupModeFilter
    @State private var period: ActivityPeriod = .all
    @State private var playerFilter: UUID?
    @State private var historyPath: [HistoryRoute] = []
    @State private var filterTask: Task<Void, Never>?
    @State private var loadMoreTask: Task<Void, Never>?
    @State private var statsLoadTask: Task<Void, Never>?

    @StateObject private var historyViewModel: HistoryListViewModel
    @StateObject private var statisticsViewModel: StatisticsViewModel

    init(
        dependencies: AppDependencies,
        refreshToken: Int = 0,
        onResumeActiveMatch: ((MatchSummary) -> Void)? = nil,
        onStartMatch: (() -> Void)? = nil
    ) {
        self.dependencies = dependencies
        self.refreshToken = refreshToken
        self.onResumeActiveMatch = onResumeActiveMatch
        self.onStartMatch = onStartMatch
        _historyViewModel = StateObject(
            wrappedValue: HistoryListViewModel(
                matchRepository: dependencies.matchRepository,
                playerRepository: dependencies.playerRepository
            )
        )
        _statisticsViewModel = StateObject(
            wrappedValue: StatisticsViewModel(
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                playerRepository: dependencies.playerRepository
            )
        )
    }

    var body: some View {
        NavigationStack(path: $historyPath) {
            activityScrollContent
                .background(Brand.background.ignoresSafeArea())
                .navigationBarHidden(true)
                .onAppear { scheduleSegmentRefresh() }
                .onChange(of: refreshToken) { _, _ in scheduleSegmentRefresh() }
                .onChange(of: segment) { _, _ in scheduleSegmentRefresh() }
                .onChange(of: modeFilter) { _, _ in applySharedFilters() }
                .onChange(of: period) { _, _ in applySharedFilters() }
                .onChange(of: playerFilter) { _, _ in applySharedFilters() }
                .onDisappear {
                    filterTask?.cancel()
                    loadMoreTask?.cancel()
                    statsLoadTask?.cancel()
                }
                .navigationDestination(for: HistoryRoute.self) { route in
                    historyNavigationDestination(route)
                }
        }
    }

    private var activityScrollContent: some View {
        ScrollView {
            activityMainColumn
                .padding(.horizontal, DS.Spacing.s4)
                .tabRootScrollChrome()
                .frame(maxWidth: GameplayLayout.contentMaxWidth(horizontalSizeClass: horizontalSizeClass))
                .frame(maxWidth: .infinity)
        }
    }

    private var activityMainColumn: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            BrandRootScreenTitle(title: L10n.activityTitle)
            ActivitySegmentChrome(
                segment: $segment,
                modeFilter: $modeFilter,
                period: $period,
                playerFilter: $playerFilter,
                playerOptions: currentPlayerOptions,
                selectedPlayerName: currentSelectedPlayerName
            )
            switch segment {
            case .history:
                ActivityHistoryContent(
                    viewModel: historyViewModel,
                    onSelectMatch: { historyPath.append(.detail(matchId: $0)) },
                    onLoadMore: {
                        loadMoreTask?.cancel()
                        loadMoreTask = Task { await historyViewModel.loadMore() }
                    },
                    onResumeActiveMatch: onResumeActiveMatch,
                    onStartMatch: onStartMatch
                )
            case .statistics:
                ActivityStatisticsContent(viewModel: statisticsViewModel, onStartMatch: onStartMatch)
            }
        }
    }

    @ViewBuilder
    private func historyNavigationDestination(_ route: HistoryRoute) -> some View {
        switch route {
        case .list:
            EmptyView()
        case let .detail(matchId):
            MatchHistoryDetailScreen(
                matchId: matchId,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                onDeleted: {
                    if !historyPath.isEmpty { historyPath.removeLast() }
                    filterTask?.cancel()
                    filterTask = Task { await historyViewModel.applyFilters() }
                }
            )
        }
    }

    private var currentPlayerOptions: [PlayerSummary] {
        segment == .history ? historyViewModel.playerOptions : statisticsViewModel.playerOptions
    }

    private var currentSelectedPlayerName: String? {
        segment == .history ? historyViewModel.selectedPlayerName : statisticsViewModel.selectedPlayerName
    }

    private func syncFiltersToViewModels() {
        historyViewModel.modeFilter = modeFilter
        historyViewModel.dateFilter = period
        historyViewModel.playerFilter = playerFilter
        statisticsViewModel.modeFilter = modeFilter
        statisticsViewModel.period = period
        statisticsViewModel.playerFilter = playerFilter
    }

    private func applySharedFilters() {
        syncFiltersToViewModels()
        filterTask?.cancel()
        filterTask = Task {
            if segment == .history {
                await historyViewModel.applyFilters()
            } else {
                statsLoadTask?.cancel()
                statsLoadTask = Task { await statisticsViewModel.load() }
            }
        }
    }

    private static var startupModeFilter: ActivityModeFilter {
        let arguments = ProcessInfo.processInfo.arguments
        if let filterIndex = arguments.firstIndex(of: "-snapshot_activity_mode_filter"),
           arguments.indices.contains(filterIndex + 1),
           let filter = ActivityModeFilter(rawValue: arguments[filterIndex + 1]) {
            return filter
        }
        return .all
    }

    private static var startupSegment: ActivitySegment {
        let arguments = ProcessInfo.processInfo.arguments
        if let tabFlagIndex = arguments.firstIndex(of: "-snapshot_tab"),
           arguments.indices.contains(tabFlagIndex + 1),
           arguments[tabFlagIndex + 1] == "statistics" {
            return .statistics
        }
        if let segmentIndex = arguments.firstIndex(of: "-snapshot_activity_segment"),
           arguments.indices.contains(segmentIndex + 1),
           let segment = ActivitySegment(rawValue: arguments[segmentIndex + 1]) {
            return segment
        }
        return .history
    }

    private func scheduleSegmentRefresh() {
        filterTask?.cancel()
        filterTask = Task { await refreshCurrentSegment() }
    }

    private func refreshCurrentSegment() async {
        syncFiltersToViewModels()
        switch segment {
        case .history:
            await historyViewModel.applyFilters()
        case .statistics:
            await statisticsViewModel.load()
        }
    }
}
