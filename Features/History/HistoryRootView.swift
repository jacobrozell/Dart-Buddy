import SwiftUI

struct HistoryRootView: View {
    let dependencies: AppDependencies
    @State private var path: [HistoryRoute] = []
    @StateObject private var viewModel: HistoryListViewModel
    @State private var filterTask: Task<Void, Never>?
    @State private var retryTask: Task<Void, Never>?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(
            wrappedValue: HistoryListViewModel(
                matchRepository: dependencies.matchRepository,
                logger: dependencies.logger
            )
        )
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                HStack {
                    Picker("history.filter.mode", selection: $viewModel.modeFilter) {
                        ForEach(HistoryListViewModel.ModeFilter.allCases) { mode in
                            Text(historyModeTitle(mode)).tag(mode)
                        }
                    }
                    Picker("history.filter.date", selection: $viewModel.dateFilter) {
                        Text("history.filter.7d").tag(HistoryListViewModel.DateFilter.d7)
                        Text("history.filter.30d").tag(HistoryListViewModel.DateFilter.d30)
                        Text("history.filter.all").tag(HistoryListViewModel.DateFilter.all)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if viewModel.state == .error {
                    ContentUnavailableView(
                        L10n.errorTitle,
                        systemImage: "exclamationmark.triangle",
                        description: Text(viewModel.errorMessageKey ?? "error.repository.storage")
                    )
                    .overlay(alignment: .bottom) {
                        Button(L10n.retry) {
                            retryTask?.cancel()
                            retryTask = Task { await viewModel.applyFilters() }
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.bottom, DS.Spacing.s6)
                    }
                } else if viewModel.rows.isEmpty {
                    ContentUnavailableView(L10n.historyNoMatches, systemImage: "clock")
                } else {
                    List(viewModel.rows) { row in
                        Button {
                            path.append(.detail(matchId: row.summary.id))
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(row.summary.type.rawValue.uppercased())
                                Text(row.participantNames.joined(separator: ", "))
                                    .font(.caption)
                                Text(L10n.format("history.winnerFormat", row.winnerName))
                                    .font(.caption)
                                    .foregroundStyle(DS.ColorRole.textSecondary)
                                Text(L10n.format("history.eventsFormat", row.summary.eventCount))
                                    .font(.caption2)
                                    .foregroundStyle(DS.ColorRole.textSecondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(L10n.historyTitle)
            .task { await viewModel.onAppear() }
            .onDisappear {
                filterTask?.cancel()
                retryTask?.cancel()
            }
            .onChange(of: viewModel.modeFilter) { _, _ in
                filterTask?.cancel()
                filterTask = Task { await viewModel.applyFilters() }
            }
            .onChange(of: viewModel.dateFilter) { _, _ in
                filterTask?.cancel()
                filterTask = Task { await viewModel.applyFilters() }
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
                        matchId: matchId
                    )
                }
            }
        }
    }
}

private func historyModeTitle(_ mode: HistoryListViewModel.ModeFilter) -> LocalizedStringKey {
    switch mode {
    case .all:
        return "history.filter.all"
    case .x01:
        return "settings.mode.x01"
    case .cricket:
        return "settings.mode.cricket"
    }
}

