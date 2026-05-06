import SwiftUI

struct HistoryRootView: View {
    let dependencies: AppDependencies
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var path: [HistoryRoute] = []
    @StateObject private var viewModel: HistoryListViewModel
    @State private var filterTask: Task<Void, Never>?
    @State private var retryTask: Task<Void, Never>?

    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? 760 : .infinity
    }

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
            VStack(spacing: DS.Spacing.s4) {
                Group {
                    VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                        Text("settings.mode.label")
                            .font(.caption)
                            .foregroundStyle(DS.ColorRole.textSecondary)
                        Picker("history.filter.mode", selection: $viewModel.modeFilter) {
                            ForEach(HistoryListViewModel.ModeFilter.allCases) { mode in
                                Text(historyModeTitle(mode)).tag(mode)
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                        Text("history.filter.date")
                            .font(.caption)
                            .foregroundStyle(DS.ColorRole.textSecondary)
                        Picker("history.filter.date", selection: $viewModel.dateFilter) {
                            Text("history.filter.7d").tag(HistoryListViewModel.DateFilter.d7)
                            Text("history.filter.30d").tag(HistoryListViewModel.DateFilter.d30)
                            Text("history.filter.all").tag(HistoryListViewModel.DateFilter.all)
                        }
                    }
                }
                .modifier(HistoryFilterLayoutModifier(isRegular: horizontalSizeClass == .regular))
                .pickerStyle(.segmented)
                .padding(.horizontal, DS.Spacing.s4)
                .frame(maxWidth: contentMaxWidth, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)

                if viewModel.state == .error {
                    ContentUnavailableView(
                        L10n.errorTitle,
                        systemImage: "exclamationmark.triangle",
                        description: Text(LocalizedStringKey(viewModel.errorMessageKey ?? "error.repository.storage"))
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
                    if horizontalSizeClass == .regular {
                        VStack {
                            ContentUnavailableView(L10n.historyNoMatches, systemImage: "clock")
                        }
                        .frame(maxWidth: 560)
                        .padding(.vertical, DS.Spacing.s6)
                        .background(DS.ColorRole.backgroundSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
                    } else {
                        ContentUnavailableView(L10n.historyNoMatches, systemImage: "clock")
                    }
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
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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

private struct HistoryFilterLayoutModifier: ViewModifier {
    let isRegular: Bool

    func body(content: Content) -> some View {
        if isRegular {
            HStack(alignment: .top, spacing: DS.Spacing.s2) {
                content
            }
        } else {
            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                content
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

