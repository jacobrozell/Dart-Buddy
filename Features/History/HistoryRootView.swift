import SwiftUI

struct HistoryRootView: View {
    let dependencies: AppDependencies
    var onResumeActiveMatch: ((MatchSummary) -> Void)?
    var onStartMatch: (() -> Void)?
    @State private var path: [HistoryRoute] = []
    @StateObject private var viewModel: HistoryListViewModel
    @State private var filterTask: Task<Void, Never>?
    @State private var loadMoreTask: Task<Void, Never>?

    init(
        dependencies: AppDependencies,
        onResumeActiveMatch: ((MatchSummary) -> Void)? = nil,
        onStartMatch: (() -> Void)? = nil
    ) {
        self.dependencies = dependencies
        self.onResumeActiveMatch = onResumeActiveMatch
        self.onStartMatch = onStartMatch
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
                    Text(L10n.historyTitle)
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(Brand.textPrimary)

                    BrandSegmented(
                        options: [
                            (HistoryListViewModel.ModeFilter.all, L10n.string("history.filter.allGames")),
                            (HistoryListViewModel.ModeFilter.x01, L10n.string("play.x01.title")),
                            (HistoryListViewModel.ModeFilter.cricket, L10n.string("play.cricket.title"))
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
                        emptyListState
                    } else {
                        ForEach(viewModel.rows) { row in
                            Button { path.append(.detail(matchId: row.summary.id)) } label: {
                                MatchHistoryCard(row: row)
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(row.accessibilitySummary)
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
                                        Text(L10n.historyLoadMore)
                                            .font(.subheadline.weight(.semibold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DS.Spacing.s3)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(Brand.green)
                            .accessibilityLabel(L10n.string("history.loadMore.accessibility"))
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
                        matchId: matchId,
                        matchRepository: dependencies.matchRepository,
                        statsRepository: dependencies.statsRepository,
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

    private var emptyListState: some View {
        VStack(spacing: DS.Spacing.s3) {
            Text(viewModel.state == .emptyFiltered && viewModel.hasActiveFilters
                ? L10n.historyEmptyFiltered
                : L10n.historyEmptyPrompt)
                .foregroundStyle(Brand.textSecondary)
                .multilineTextAlignment(.center)
            if onStartMatch != nil,
               viewModel.state == .emptyFiltered,
               !viewModel.hasActiveFilters {
                Button(action: { onStartMatch?() }) {
                    Text(L10n.startMatchCTA)
                        .font(.headline)
                        .foregroundStyle(Brand.textPrimary)
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(Brand.green, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("emptyStateStartMatchButton")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.Spacing.s6)
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
                "history.filter.player.accessibilityFormat",
                viewModel.selectedPlayerName ?? L10n.string("stats.filter.allPlayers")
            )
        )
        .accessibilityIdentifier("historyPlayerFilterMenu")
    }

    private func inProgressBanner(_ match: MatchSummary) -> some View {
        Button {
            onResumeActiveMatch?(match)
        } label: {
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
                match.type == .x01 ? L10n.string("play.x01.title") : L10n.string("play.cricket.title")
            )
        )
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
                    .foregroundStyle(Brand.textPrimary)
                Spacer()
                if row.isFinished {
                    StatusBadge(text: L10n.string("history.status.finished"), color: Brand.green)
                }
            }
            Text(row.configText)
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)

            ForEach(Array(row.standings.enumerated()), id: \.element.id) { index, standing in
                HStack(alignment: .center) {
                    Text("\(index + 1). \(standing.name)")
                        .font(.body.weight(standing.isWinner ? .semibold : .regular))
                        .foregroundStyle(standing.isWinner ? Brand.textPrimary : Brand.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        if row.summary.type == .x01 {
                            Text(L10n.format("history.standing.setsLegsFormat", standing.sets, standing.legs))
                                .font(.caption)
                                .foregroundStyle(Brand.textSecondary)
                        }
                        Text("\(standing.score)")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Brand.textPrimary)
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
