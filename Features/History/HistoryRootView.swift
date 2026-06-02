import SwiftUI

struct HistoryRootView: View {
    let dependencies: AppDependencies
    var onResumeActiveMatch: ((MatchSummary) -> Void)?
    @State private var path: [HistoryRoute] = []
    @StateObject private var viewModel: HistoryListViewModel
    @State private var filterTask: Task<Void, Never>?
    @State private var loadMoreTask: Task<Void, Never>?

    init(dependencies: AppDependencies, onResumeActiveMatch: ((MatchSummary) -> Void)? = nil) {
        self.dependencies = dependencies
        self.onResumeActiveMatch = onResumeActiveMatch
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
                    Text("History")
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

                    if let activeMatch = viewModel.activeMatch {
                        inProgressBanner(activeMatch)
                    }

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
                        Text(viewModel.state == .emptyFiltered && viewModel.hasActiveFilters
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

                        if viewModel.hasMorePages {
                            Button {
                                loadMoreTask?.cancel()
                                loadMoreTask = Task { await viewModel.loadMore() }
                            } label: {
                                Group {
                                    if viewModel.isLoadingMore {
                                        ProgressView().tint(Brand.green)
                                    } else {
                                        Text("Load more")
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
            .onDisappear {
                filterTask?.cancel()
                loadMoreTask?.cancel()
            }
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

    private func inProgressBanner(_ match: MatchSummary) -> some View {
        Button {
            onResumeActiveMatch?(match)
        } label: {
            HStack {
                Image(systemName: "play.circle.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text("Resume match").font(.headline)
                    Text(match.type.rawValue.uppercased()).font(.caption).foregroundStyle(Brand.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(Brand.textSecondary)
            }
            .foregroundStyle(.white)
            .padding(DS.Spacing.s4)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: DS.Radius.md).stroke(Brand.green, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("historyResumeMatchButton")
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
