import Charts
import SwiftUI

struct StatisticsRootView: View {
    let dependencies: AppDependencies
    @StateObject private var viewModel: StatisticsViewModel
    @State private var loadTask: Task<Void, Never>?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: StatisticsViewModel(
            matchRepository: dependencies.matchRepository,
            statsRepository: dependencies.statsRepository
        ))
    }

    private var isX01: Bool { viewModel.mode == .x01 }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                    Text("Statistics")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(.white)

                    BrandSegmented(
                        options: [(MatchType.x01, "X01"), (MatchType.cricket, "Cricket")],
                        selection: $viewModel.mode
                    )

                    BrandSegmented(
                        options: StatisticsViewModel.Period.allCases.map { ($0, $0.title) },
                        selection: $viewModel.period
                    )

                    if viewModel.isLoading && viewModel.rows.isEmpty {
                        ProgressView()
                            .tint(Brand.green)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Spacing.s6)
                    } else if viewModel.rows.isEmpty {
                        emptyState
                    } else {
                        gamesTable
                        if isX01 {
                            sectionTitle("Average & Highest Score")
                            averageTable
                            averageChart
                            sectionTitle("Legs & Checkout")
                            checkoutTable
                        } else {
                            sectionTitle("Marks Per Round")
                            mprTable
                        }
                        sectionTitle("Points")
                        pointsTable
                        sectionTitle("Throws")
                        throwsTable
                        sectionTitle("Hits in Sector")
                        sectorChart
                    }
                }
                .padding(.horizontal, DS.Spacing.s4)
                .padding(.bottom, DS.Spacing.s6)
            }
            .background(Brand.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .task { await viewModel.load() }
            .onChange(of: viewModel.mode) { _, _ in reload() }
            .onChange(of: viewModel.period) { _, _ in reload() }
            .onDisappear { loadTask?.cancel() }
        }
    }

    private func reload() {
        loadTask?.cancel()
        loadTask = Task { await viewModel.load() }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title2.weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.top, DS.Spacing.s2)
    }

    private var emptyState: some View {
        Text("No completed games yet.")
            .foregroundStyle(Brand.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, DS.Spacing.s6)
    }

    private var gamesTable: some View {
        StatTable(
            title: "Games",
            columns: [("Games", 70), ("Wins", 60), ("Wins %", 80)],
            rows: viewModel.rows
        ) { row in
            ["\(row.games)", "\(row.wins)", String(format: "%.0f%%", row.winPercent)]
        }
    }

    private var averageTable: some View {
        StatTable(
            columns: [("3-Dart Avg", 90), ("Highest", 80)],
            rows: viewModel.rows
        ) { row in
            [String(format: "%.1f", row.average3Dart), "\(row.highestScore)"]
        }
    }

    private var checkoutTable: some View {
        StatTable(
            columns: [("Legs", 60), ("Checkouts", 90), ("Best CO", 80)],
            rows: viewModel.rows
        ) { row in
            ["\(row.legs)", "\(row.checkouts)", row.highestCheckout > 0 ? "\(row.highestCheckout)" : "-"]
        }
    }

    private var mprTable: some View {
        StatTable(
            columns: [("MPR", 80), ("Marks", 80), ("Rounds", 80)],
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
            columns: [("Points", 90)],
            rows: viewModel.rows
        ) { row in
            ["\(row.points)"]
        }
    }

    private var throwsTable: some View {
        StatTable(
            columns: [("Throws", 70), ("Double %", 80), ("Triple %", 80)],
            rows: viewModel.rows
        ) { row in
            ["\(row.darts)", String(format: "%.1f%%", row.doublePercent), String(format: "%.1f%%", row.triplePercent)]
        }
    }

    private var averageChart: some View {
        Chart(viewModel.rows) { row in
            BarMark(
                x: .value("Average", row.average3Dart),
                y: .value("Player", row.name)
            )
            .foregroundStyle(Brand.green)
            .annotation(position: .trailing) {
                Text(String(format: "%.1f", row.average3Dart))
                    .font(.caption2)
                    .foregroundStyle(Brand.textSecondary)
            }
        }
        .chartXAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Brand.textSecondary) } }
        .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(.white) } }
        .frame(height: CGFloat(viewModel.rows.count) * 44 + 24)
        .padding(DS.Spacing.s4)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }

    private var sectorChart: some View {
        let hits = viewModel.sectorHits
        return Group {
            if hits.isEmpty {
                Text("No recorded dart-level data.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, DS.Spacing.s4)
            } else {
                Chart(hits) { hit in
                    BarMark(
                        x: .value("Sector", StatsSectorOrder.label(hit.sector)),
                        y: .value("Hits", hit.count)
                    )
                    .foregroundStyle(Brand.green)
                }
                .chartXAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Brand.textSecondary) } }
                .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Brand.textSecondary) } }
                .frame(height: 200)
                .padding(DS.Spacing.s4)
                .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            }
        }
    }
}

/// Reusable striped table that lists players in a leading column with trailing numeric columns.
struct StatTable: View {
    var title: String?
    let columns: [(label: String, width: CGFloat)]
    let rows: [PlayerStatBreakdown]
    let values: (PlayerStatBreakdown) -> [String]

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
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
            }
            VStack(spacing: 0) {
                HStack {
                    Text("Players").frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(columns, id: \.label) { column in
                        Text(column.label).frame(width: column.width, alignment: .trailing)
                    }
                }
                .font(.caption)
                .foregroundStyle(Brand.textSecondary)
                .padding(.horizontal, DS.Spacing.s3)
                .padding(.vertical, DS.Spacing.s2)

                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    let cells = values(row)
                    HStack {
                        Text("\(index + 1). \(row.name)")
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .lineLimit(1)
                        ForEach(Array(columns.enumerated()), id: \.offset) { columnIndex, column in
                            Text(columnIndex < cells.count ? cells[columnIndex] : "-")
                                .frame(width: column.width, alignment: .trailing)
                                .foregroundStyle(.white)
                        }
                    }
                    .font(.subheadline)
                    .padding(.horizontal, DS.Spacing.s3)
                    .padding(.vertical, DS.Spacing.s3)
                    .background(index.isMultiple(of: 2) ? Color.clear : Brand.cardElevated.opacity(0.4))
                }
            }
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        }
    }
}
