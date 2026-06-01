import SwiftUI

struct StatisticsRootView: View {
    let dependencies: AppDependencies
    @StateObject private var viewModel: StatisticsViewModel
    @State private var loadTask: Task<Void, Never>?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: StatisticsViewModel(matchRepository: dependencies.matchRepository))
    }

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

                    Text("Games")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)

                    if viewModel.rows.isEmpty {
                        emptyState
                    } else {
                        gamesTable
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

    private var emptyState: some View {
        Text("No completed games yet.")
            .foregroundStyle(Brand.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, DS.Spacing.s6)
    }

    private var gamesTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Players").frame(maxWidth: .infinity, alignment: .leading)
                Text("Games").frame(width: 70, alignment: .trailing)
                Text("Wins").frame(width: 60, alignment: .trailing)
                Text("Wins %").frame(width: 80, alignment: .trailing)
            }
            .font(.caption)
            .foregroundStyle(Brand.textSecondary)
            .padding(.horizontal, DS.Spacing.s3)
            .padding(.vertical, DS.Spacing.s2)

            ForEach(Array(viewModel.rows.enumerated()), id: \.element.id) { index, row in
                HStack {
                    Text("\(index + 1). \(row.name)")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)
                    Text("\(row.games)").frame(width: 70, alignment: .trailing).foregroundStyle(.white)
                    Text("\(row.wins)").frame(width: 60, alignment: .trailing).foregroundStyle(.white)
                    Text(String(format: "%.2f%%", row.winPercent)).frame(width: 80, alignment: .trailing).foregroundStyle(.white)
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
