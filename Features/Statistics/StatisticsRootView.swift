import Charts
import SwiftUI

struct StatisticsRootView: View {
    let dependencies: AppDependencies
    var onStartMatch: (() -> Void)?
    @StateObject private var viewModel: StatisticsViewModel
    @State private var loadTask: Task<Void, Never>?
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(dependencies: AppDependencies, onStartMatch: (() -> Void)? = nil) {
        self.dependencies = dependencies
        self.onStartMatch = onStartMatch
        _viewModel = StateObject(wrappedValue: StatisticsViewModel(
            matchRepository: dependencies.matchRepository,
            statsRepository: dependencies.statsRepository,
            playerRepository: dependencies.playerRepository
        ))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                    BrandRootScreenTitle(title: L10n.statsTitle)

                    BrandSegmented(
                        options: ActivityModeFilter.allCases.map { ($0, $0.title) },
                        selection: $viewModel.modeFilter
                    )

                    BrandSegmented(
                        options: ActivityPeriod.allCases.map { ($0, $0.title) },
                        selection: $viewModel.period
                    )

                    playerFilterMenu

                    if viewModel.includesPartialActiveMatch {
                        partialStatsBanner
                    }

                    if viewModel.isLoading && viewModel.rows.isEmpty {
                        ProgressView()
                            .tint(Brand.green)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Spacing.s6)
                            .accessibilityLabel(L10n.loading)
                    } else if viewModel.rows.isEmpty {
                        emptyState
                    } else {
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
                            sectorChart(mode: matchType)
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.s4)
                .tabRootScrollChrome()
                .frame(maxWidth: GameplayLayout.contentMaxWidth(horizontalSizeClass: horizontalSizeClass))
                .frame(maxWidth: .infinity)
            }
            .background(Brand.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .task { await viewModel.load() }
            .onChange(of: viewModel.modeFilter) { _, _ in reload() }
            .onChange(of: viewModel.period) { _, _ in reload() }
            .onChange(of: viewModel.playerFilter) { _, _ in reload() }
            .onDisappear { loadTask?.cancel() }
        }
    }

    private func reload() {
        loadTask?.cancel()
        loadTask = Task { await viewModel.load() }
    }

    private var playerFilterMenu: some View {
        Menu {
            Button {
                viewModel.playerFilter = nil
            } label: {
                if viewModel.playerFilter == nil {
                    Label(String(localized: "stats.filter.allPlayers"), systemImage: "checkmark")
                } else {
                    Text(String(localized: "stats.filter.allPlayers"))
                }
            }
            if !viewModel.playerOptions.isEmpty {
                Divider()
                ForEach(viewModel.playerOptions) { player in
                    Button {
                        viewModel.playerFilter = player.id
                    } label: {
                        if viewModel.playerFilter == player.id {
                            Label(player.name, systemImage: "checkmark")
                        } else {
                            Text(player.name)
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "person.crop.circle")
                Text(viewModel.selectedPlayerName ?? String(localized: "stats.filter.allPlayers"))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(Brand.textPrimary)
            .padding(.horizontal, DS.Spacing.s3)
            .padding(.vertical, DS.Spacing.s3)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        }
        .accessibilityLabel(
            L10n.format(
                "stats.filter.player.accessibilityFormat",
                viewModel.selectedPlayerName ?? L10n.string("stats.filter.allPlayers")
            )
        )
        .accessibilityIdentifier("statsPlayerFilterMenu")
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title2.weight(.bold))
            .foregroundStyle(Brand.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.top, DS.Spacing.s2)
    }

    private var partialStatsBanner: some View {
        HStack(spacing: DS.Spacing.s2) {
            Image(systemName: "clock.arrow.circlepath")
            Text(L10n.statsPartialMatchBanner)
                .font(.footnote)
        }
        // Amber text on the white card fails AA contrast in light mode; use primary text on
        // an amber-tinted surface so the warning stays legible (icon + tint = non-color cue).
        .foregroundStyle(Brand.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.s3)
        .background(
            Brand.amber.opacity(colorScheme == .dark ? 0.32 : 0.22),
            in: RoundedRectangle(cornerRadius: DS.Radius.md)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.string("stats.partialMatchBanner.accessibility"))
        .accessibilityIdentifier("statsPartialMatchBanner")
    }

    private var emptyState: some View {
        VStack(spacing: DS.Spacing.s3) {
            Text(L10n.statsEmptyTitle)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
            if onStartMatch != nil,
               viewModel.playerFilter == nil,
               viewModel.period == .all {
                StartMatchCTAButton(action: { onStartMatch?() })
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, DS.Spacing.s6)
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
            }
        }
        .chartXAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Brand.textSecondary) } }
        .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Brand.textPrimary) } }
        .frame(height: CGFloat(viewModel.rows.count) * 44 + 24)
        .padding(DS.Spacing.s4)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.string("stats.threeDartAverage"))
        .accessibilityValue(
            viewModel.rows.map { "\($0.name) \(String(format: "%.1f", $0.average3Dart))" }.joined(separator: ", ")
        )
    }

    private func sectorChart(mode: MatchType) -> some View {
        SectorHitsChart(hitsBySector: sectorHitsDictionary, mode: mode)
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

/// Reusable striped table that lists players in a leading column with trailing numeric columns.
struct StatTable: View {
    var title: String?
    let columns: [(label: String, width: CGFloat)]
    let rows: [PlayerStatBreakdown]
    let values: (PlayerStatBreakdown) -> [String]
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(
        title: String? = nil,
        columns: [(label: String, width: CGFloat)],
        rows: [PlayerStatBreakdown],
        values: @escaping (PlayerStatBreakdown) -> [String]
    ) {
        self.title = title
        self.columns = columns
        self.rows = rows
        self.values = values
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            if let title {
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Brand.textPrimary)
                    .frame(maxWidth: .infinity)
            }
            VStack(spacing: 0) {
                HStack {
                    Text(L10n.statsTablePlayersColumn).frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(columns, id: \.label) { column in
                        Text(column.label)
                            .frame(minWidth: resolvedColumnWidth(column.width), alignment: .trailing)
                            .lineLimit(1)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .font(.caption)
                .foregroundStyle(Brand.textSecondary)
                .padding(.horizontal, DS.Spacing.s3)
                .padding(.vertical, DS.Spacing.s2)
                .accessibilityHidden(true)

                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    let cells = values(row)
                    HStack {
                        Text("\(index + 1). \(row.name)")
                            .foregroundStyle(Brand.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                        ForEach(Array(columns.enumerated()), id: \.offset) { columnIndex, column in
                            Text(columnIndex < cells.count ? cells[columnIndex] : "-")
                                .frame(minWidth: resolvedColumnWidth(column.width), alignment: .trailing)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .foregroundStyle(Brand.textPrimary)
                        }
                    }
                    .font(.subheadline)
                    .padding(.horizontal, DS.Spacing.s3)
                    .padding(.vertical, DS.Spacing.s3)
                    .background(index.isMultiple(of: 2) ? Color.clear : Brand.cardElevated.opacity(0.4))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(rowAccessibilityLabel(index: index, row: row, cells: cells))
                }
            }
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        }
    }

    private func rowAccessibilityLabel(index: Int, row: PlayerStatBreakdown, cells: [String]) -> String {
        let stats = zip(columns.map(\.label), cells).map { "\($0) \($1)" }.joined(separator: ", ")
        return L10n.format("stats.table.row.accessibilityFormat", index + 1, row.name, stats)
    }

    private func resolvedColumnWidth(_ base: CGFloat) -> CGFloat {
        horizontalSizeClass == .regular ? max(base, base * 1.2) : base
    }
}
