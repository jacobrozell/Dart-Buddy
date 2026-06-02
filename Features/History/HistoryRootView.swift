import SwiftUI

struct HistoryRootView: View {
    let dependencies: AppDependencies
    @State private var path: [HistoryRoute] = []
    @StateObject private var viewModel: HistoryListViewModel
    @State private var filterTask: Task<Void, Never>?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(
            wrappedValue: HistoryListViewModel(
                matchRepository: dependencies.matchRepository,
                playerRepository: dependencies.playerRepository
            )
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                    Text("All Games")
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(.white)

                    BrandSegmented(
                        options: [
                            (HistoryListViewModel.ModeFilter.all, "All Games"),
                            (HistoryListViewModel.ModeFilter.x01, "X01"),
                            (HistoryListViewModel.ModeFilter.cricket, "Cricket")
                        ],
                        selection: $viewModel.modeFilter
                    )

                    BrandSegmented(
                        options: HistoryListViewModel.DateFilter.allCases.map { ($0, $0.title) },
                        selection: $viewModel.dateFilter
                    )

                    playerFilterMenu

                    if viewModel.state == .loading && viewModel.rows.isEmpty {
                        ProgressView()
                            .tint(Brand.green)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Spacing.s6)
                    } else if viewModel.state == .error {
                        Text(LocalizedStringKey(viewModel.errorMessageKey ?? "error.repository.storage"))
                            .foregroundStyle(Brand.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Spacing.s6)
                    } else if viewModel.rows.isEmpty {
                        Text(viewModel.state == .emptyFiltered
                            ? "No games match these filters."
                            : "No games yet. Start a match to see it here.")
                            .foregroundStyle(Brand.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DS.Spacing.s6)
                    } else {
                        ForEach(viewModel.rows) { row in
                            Button { path.append(.detail(matchId: row.summary.id)) } label: {
                                MatchHistoryCard(row: row)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.s4)
                .padding(.bottom, DS.Spacing.s6)
            }
            .background(Brand.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .task { await viewModel.onAppear() }
            .onChange(of: viewModel.modeFilter) { _, _ in
                filterTask?.cancel()
                filterTask = Task { await viewModel.applyFilters() }
            }
            .onChange(of: viewModel.dateFilter) { _, _ in
                filterTask?.cancel()
                filterTask = Task { await viewModel.applyFilters() }
            }
            .onChange(of: viewModel.playerFilter) { _, _ in
                filterTask?.cancel()
                filterTask = Task { await viewModel.applyFilters() }
            }
            .onDisappear { filterTask?.cancel() }
            .navigationDestination(for: HistoryRoute.self) { route in
                switch route {
                case .list:
                    EmptyView()
                case let .detail(matchId):
                    MatchHistoryDetailScreen(
                        viewModel: HistoryDetailViewModel(
                            matchId: matchId,
                            matchRepository: dependencies.matchRepository,
                            statsRepository: dependencies.statsRepository
                        ),
                        matchId: matchId,
                        onDeleted: {
                            if !path.isEmpty { path.removeLast() }
                            filterTask?.cancel()
                            filterTask = Task { await viewModel.applyFilters() }
                        }
                    )
                }
            }
        }
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
            .foregroundStyle(.white)
            .padding(.horizontal, DS.Spacing.s3)
            .padding(.vertical, DS.Spacing.s3)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        }
        .accessibilityIdentifier("historyPlayerFilterMenu")
    }
}

struct MatchHistoryCard: View {
    let row: HistoryListRow

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            HStack {
                Text(row.dateText)
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                if row.isFinished {
                    StatusBadge(text: "FINISHED", color: Brand.green)
                }
            }
            Text(row.configText)
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)

            ForEach(Array(row.standings.enumerated()), id: \.element.id) { index, standing in
                HStack(alignment: .center) {
                    Text("\(index + 1). \(standing.name)")
                        .font(.body.weight(standing.isWinner ? .semibold : .regular))
                        .foregroundStyle(standing.isWinner ? .white : Brand.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Sets: \(standing.sets)  Legs: \(standing.legs)")
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                        Text("\(standing.score)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(DS.Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }
}
