import Charts
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
    var onResumeActiveMatch: ((MatchSummary) -> Void)?
    var onStartMatch: (() -> Void)?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var segment: ActivitySegment = ActivityRootView.startupSegment
    @State private var modeFilter: ActivityModeFilter = .all
    @State private var period: ActivityPeriod = .all
    @State private var playerFilter: UUID?
    @State private var historyPath: [HistoryRoute] = []
    @State private var hasLoadedHistory = false
    @State private var hasLoadedStatistics = false
    @State private var filterTask: Task<Void, Never>?
    @State private var loadMoreTask: Task<Void, Never>?
    @State private var statsLoadTask: Task<Void, Never>?

    @StateObject private var historyViewModel: HistoryListViewModel
    @StateObject private var statisticsViewModel: StatisticsViewModel

    init(
        dependencies: AppDependencies,
        onResumeActiveMatch: ((MatchSummary) -> Void)? = nil,
        onStartMatch: (() -> Void)? = nil
    ) {
        self.dependencies = dependencies
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
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                    BrandRootScreenTitle(title: L10n.activityTitle)

                    BrandSegmented(
                        options: ActivitySegment.allCases.map { ($0, $0.title) },
                        selection: $segment,
                        accessibilityIdentifiers: [
                            .history: "activity_segment_history",
                            .statistics: "activity_segment_statistics"
                        ]
                    )

                    ActivityFilterBar(
                        modeFilter: $modeFilter,
                        period: $period,
                        playerFilter: $playerFilter,
                        playerOptions: currentPlayerOptions,
                        selectedPlayerName: currentSelectedPlayerName
                    )

                    switch segment {
                    case .history:
                        historySegmentContent
                    case .statistics:
                        statisticsSegmentContent
                    }
                }
                .padding(.horizontal, DS.Spacing.s4)
                .tabRootScrollChrome()
                .frame(maxWidth: GameplayLayout.contentMaxWidth(horizontalSizeClass: horizontalSizeClass))
                .frame(maxWidth: .infinity)
            }
            .background(Brand.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .task { await loadSegmentIfNeeded() }
            .onChange(of: segment) { _, newSegment in
                Task {
                    syncFiltersToViewModels()
                    switch newSegment {
                    case .history:
                        hasLoadedHistory = true
                        await historyViewModel.applyFilters()
                    case .statistics:
                        hasLoadedStatistics = true
                        await statisticsViewModel.load()
                    }
                }
            }
            .onChange(of: modeFilter) { _, _ in applySharedFilters() }
            .onChange(of: period) { _, _ in applySharedFilters() }
            .onChange(of: playerFilter) { _, _ in applySharedFilters() }
            .onDisappear {
                filterTask?.cancel()
                loadMoreTask?.cancel()
                statsLoadTask?.cancel()
            }
            .navigationDestination(for: HistoryRoute.self) { route in
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
        }
    }

    private var currentPlayerOptions: [PlayerSummary] {
        segment == .history ? historyViewModel.playerOptions : statisticsViewModel.playerOptions
    }

    private var currentSelectedPlayerName: String? {
        segment == .history ? historyViewModel.selectedPlayerName : statisticsViewModel.selectedPlayerName
    }

    @ViewBuilder
    private var historySegmentContent: some View {
        if let activeMatch = historyViewModel.activeMatch {
            historyResumeBanner(activeMatch)
        }

        if historyViewModel.state == .loading && historyViewModel.rows.isEmpty {
            ProgressView()
                .tint(Brand.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.s6)
                .accessibilityLabel(L10n.loading)
        } else if historyViewModel.state == .error {
            Text(LocalizedStringKey(historyViewModel.errorMessageKey ?? "error.repository.storage"))
                .foregroundStyle(Brand.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.s6)
        } else if historyViewModel.rows.isEmpty {
            historyEmptyState
        } else {
            ForEach(historyViewModel.rows) { row in
                Button { historyPath.append(.detail(matchId: row.summary.id)) } label: {
                    MatchHistoryCard(row: row)
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(row.accessibilitySummary)
            }

            if historyViewModel.hasMorePages {
                Button {
                    loadMoreTask?.cancel()
                    loadMoreTask = Task { await historyViewModel.loadMore() }
                } label: {
                    Group {
                        if historyViewModel.isLoadingMore {
                            ProgressView().tint(Brand.green)
                                .accessibilityLabel(L10n.loading)
                        } else {
                            Text(L10n.historyLoadMore)
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.s3)
                }
                .buttonStyle(.plain)
                .foregroundStyle(Brand.green)
                .accessibilityIdentifier("historyLoadMoreButton")
            }
        }
    }

    @ViewBuilder
    private var statisticsSegmentContent: some View {
        if statisticsViewModel.includesPartialActiveMatch {
            statisticsPartialBanner
        }

        if statisticsViewModel.isLoading && statisticsViewModel.rows.isEmpty {
            ProgressView()
                .tint(Brand.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.s6)
                .accessibilityLabel(L10n.loading)
        } else if statisticsViewModel.rows.isEmpty {
            statisticsEmptyState
        } else {
            StatisticsTablesContent(viewModel: statisticsViewModel)
        }
    }

    private var historyEmptyState: some View {
        VStack(spacing: DS.Spacing.s3) {
            Text(historyViewModel.state == .emptyFiltered && historyViewModel.hasActiveFilters
                ? L10n.historyEmptyFiltered
                : L10n.historyEmptyPrompt)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
            if onStartMatch != nil,
               historyViewModel.state == .emptyFiltered,
               !historyViewModel.hasActiveFilters {
                StartMatchCTAButton(action: { onStartMatch?() })
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.s6)
    }

    private var statisticsEmptyState: some View {
        VStack(spacing: DS.Spacing.s3) {
            Text(L10n.statsEmptyTitle)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
            if onStartMatch != nil,
               statisticsViewModel.playerFilter == nil,
               statisticsViewModel.period == .all {
                StartMatchCTAButton(action: { onStartMatch?() })
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, DS.Spacing.s6)
    }

    private func historyResumeBanner(_ match: MatchSummary) -> some View {
        Button { onResumeActiveMatch?(match) } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.resumeMatch).font(.headline)
                    Text(MatchConfigText.modeLabel(for: match.type)).font(.caption).foregroundStyle(Brand.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Brand.textSecondary)
            }
            .foregroundStyle(Brand.textPrimary)
            .padding(DS.Spacing.s4)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.md).stroke(Brand.green, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            L10n.format(
                "play.home.resumeAccessibilityFormat",
                L10n.string("play.home.resumeButton"),
                MatchConfigText.modeLabel(for: match.type)
            )
        )
        .accessibilityIdentifier("historyResumeMatchButton")
    }

    @Environment(\.colorScheme) private var colorScheme

    private var statisticsPartialBanner: some View {
        HStack(spacing: DS.Spacing.s2) {
            Image(systemName: "clock.arrow.circlepath")
                .accessibilityHidden(true)
            Text(L10n.statsPartialMatchBanner)
                .font(.footnote)
        }
        .foregroundStyle(Brand.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.s3)
        .background(
            Brand.amber.opacity(colorScheme == .dark ? 0.32 : 0.22),
            in: RoundedRectangle(cornerRadius: DS.Radius.md)
        )
        .accessibilityIdentifier("statsPartialMatchBanner")
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

    private func loadSegmentIfNeeded() async {
        syncFiltersToViewModels()
        switch segment {
        case .history where !hasLoadedHistory:
            hasLoadedHistory = true
            await historyViewModel.applyFilters()
        case .statistics where !hasLoadedStatistics:
            hasLoadedStatistics = true
            await statisticsViewModel.load()
        default:
            break
        }
    }
}

/// Statistics tables/charts extracted for Activity segment reuse.
struct StatisticsTablesContent: View {
    @ObservedObject var viewModel: StatisticsViewModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s4) {
            gamesTable
            if viewModel.isX01 {
                sectionTitle(L10n.string("stats.section.averageHighest"))
                averageTable
                averageChart
                if viewModel.showsTrendChart {
                    sectionTitle(L10n.string("stats.trend.title"))
                    AverageTrendChart(points: viewModel.trendPoints)
                }
                sectionTitle(L10n.string("stats.section.legsCheckout"))
                checkoutTable
            } else if !viewModel.isAllGames {
                sectionTitle(L10n.string("stats.section.marksPerRound"))
                mprTable
            }
            sectionTitle(L10n.string("stats.points"))
            pointsTable
            sectionTitle(L10n.string("stats.throws"))
            throwsTable
            if !viewModel.isAllGames, let matchType = viewModel.modeFilter.matchType {
                sectionTitle(L10n.string("stats.hitsInSector"))
                SectorHitsChart(hitsBySector: sectorHitsDictionary, mode: matchType)
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title2.weight(.bold))
            .foregroundStyle(Brand.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.top, DS.Spacing.s2)
    }

    private var gamesTable: some View {
        StatTable(
            title: L10n.string("stats.games"),
            columns: [(L10n.string("stats.games"), 70), (L10n.string("stats.wins"), 60), (L10n.string("stats.column.winsPercent"), 80)],
            rows: viewModel.rows
        ) { row in
            ["\(row.games)", "\(row.wins)", String(format: "%.0f%%", row.winPercent)]
        }
    }

    private var averageTable: some View {
        StatTable(
            columns: [(L10n.string("stats.threeDartAverage"), 90), (L10n.string("stats.column.highest"), 80)],
            rows: viewModel.rows
        ) { row in
            [String(format: "%.1f", row.average3Dart), "\(row.highestScore)"]
        }
    }

    private var checkoutTable: some View {
        StatTable(
            columns: [(L10n.string("stats.column.legs"), 60), (L10n.string("stats.checkouts"), 90), (L10n.string("stats.column.bestCO"), 80)],
            rows: viewModel.rows
        ) { row in
            ["\(row.legs)", "\(row.checkouts)", row.highestCheckout > 0 ? "\(row.highestCheckout)" : "-"]
        }
    }

    private var mprTable: some View {
        StatTable(
            columns: [(L10n.string("stats.mpr"), 80), (L10n.string("stats.marks"), 80), (L10n.string("stats.rounds"), 80)],
            rows: viewModel.rows
        ) { row in
            [
                String(format: "%.2f", row.marksPerRound),
                "\(row.cricketMarks)",
                "\(row.cricketRounds)"
            ]
        }
    }

    private var pointsTable: some View {
        StatTable(
            columns: [(L10n.string("stats.points"), 90)],
            rows: viewModel.rows
        ) { row in
            ["\(row.points)"]
        }
    }

    private var throwsTable: some View {
        StatTable(
            columns: [(L10n.string("stats.throws"), 70), (L10n.string("stats.doublePercent"), 80), (L10n.string("stats.triplePercent"), 80)],
            rows: viewModel.rows
        ) { row in
            ["\(row.darts)", String(format: "%.1f%%", row.doublePercent), String(format: "%.1f%%", row.triplePercent)]
        }
    }

    private var averageChart: some View {
        Chart(viewModel.rows) { row in
            BarMark(
                x: .value(L10n.string("stats.chart.axis.average"), row.average3Dart),
                y: .value(L10n.string("stats.chart.axis.player"), row.name)
            )
            .foregroundStyle(Brand.green)
            .annotation(position: .trailing) {
                Text(String(format: "%.1f", row.average3Dart))
                    .font(.caption2)
                    .foregroundStyle(Brand.textSecondary)
                    .accessibilityHidden(true)
            }
        }
        .chartXAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Brand.textSecondary) } }
        .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Brand.textSecondary) } }
        .frame(height: CGFloat(viewModel.rows.count) * 44 + 24)
        .padding(DS.Spacing.s4)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "stats.section.averageHighest"))
        .accessibilityValue(averageChartAccessibilityValue)
    }

    private var averageChartAccessibilityValue: String {
        viewModel.rows.map { row in
            L10n.format("stats.trend.accessibilityPointFormat", row.name, row.average3Dart)
        }.joined(separator: ", ")
    }

    private var sectorHitsDictionary: [String: Int] {
        var totals: [String: Int] = [:]
        for row in viewModel.rows {
            for (sector, count) in row.hitsBySector {
                let key = StatsSectorOrder.normalizedSectorKey(sector)
                totals[key, default: 0] += count
            }
        }
        return totals
    }
}
