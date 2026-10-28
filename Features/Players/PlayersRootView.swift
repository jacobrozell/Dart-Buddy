import SwiftUI

/// Drives the create/edit sheet so presentation always carries the intended player snapshot.
private struct PlayerSheetPresentation: Identifiable {
    let id: UUID
    let editing: EditablePlayer?

    static func add() -> PlayerSheetPresentation {
        PlayerSheetPresentation(id: UUID(), editing: nil)
    }

    static func edit(_ player: EditablePlayer) -> PlayerSheetPresentation {
        PlayerSheetPresentation(id: player.id, editing: player)
    }
}

private enum PlayersSheet: Identifiable {
    case customBot
    case player(PlayerSheetPresentation)
    case export(ExportShareItem)

    var id: String {
        switch self {
        case .customBot: "customBot"
        case let .player(presentation): "player-\(presentation.id)"
        case let .export(item): "export-\(item.id)"
        }
    }
}

struct PlayersRootView: View {
    let dependencies: AppDependencies
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var path: [PlayersRoute] = []
    @StateObject private var viewModel: PlayersListViewModel
    @State private var sheet: PlayersSheet?
    @State private var deleteBlockedMessage: String?
    @State private var exportErrorKey: String?
    @State private var actionTask: Task<Void, Never>?
    @State private var retryTask: Task<Void, Never>?
    @State private var didApplyCustomBotSnapshotNavigation = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: PlayersListViewModel(
            repository: dependencies.playerRepository,
            matchRepository: dependencies.matchRepository,
            pendingMatchPlayerSelections: dependencies.pendingMatchPlayerSelections
        ))
    }

    var body: some View {
        phonePlayersShell
        .sheet(item: $sheet) { sheet in
            sheetContent(sheet)
        }
        .alert(L10n.actionBlockedTitle, isPresented: Binding(
            get: { deleteBlockedMessage != nil },
            set: { if !$0 { deleteBlockedMessage = nil } }
        )) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(deleteBlockedMessage ?? "")
        }
        .alert(L10n.errorTitle, isPresented: Binding(
            get: { exportErrorKey != nil },
            set: { if !$0 { exportErrorKey = nil } }
        )) {
            Button(L10n.ok, role: .cancel) {}
        } message: {
            Text(LocalizedStringKey(exportErrorKey ?? "players.detail.export.error"))
        }
        .onDisappear {
            actionTask?.cancel()
            retryTask?.cancel()
        }
    }

    @ViewBuilder
    private func sheetContent(_ sheet: PlayersSheet) -> some View {
        switch sheet {
        case .customBot:
            CustomBotCreationSheet { name, metrics in
                actionTask?.cancel()
                actionTask = Task { await viewModel.createCustomBot(name: name, metrics: metrics) }
            }
        case let .player(presentation):
            PlayerEditSheet(
                viewModel: PlayerEditViewModel(
                    existingNames: viewModel.players.map(\.name),
                    editing: presentation.editing,
                    defaultPrimary: presentation.editing == nil && !viewModel.hasPrimaryPlayer
                ),
                existing: presentation.editing,
                onSave: { player in
                    await viewModel.save(player)
                }
            )
        case let .export(item):
            ActivityShareSheet(items: [item.url]) {
                try? FileManager.default.removeItem(at: item.url)
                self.sheet = nil
            }
        }
    }

    private var phonePlayersShell: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                playersListHeader
                playersBody
            }
            .tabRootScreenBackground()
            .onChange(of: viewModel.searchText) { _, _ in viewModel.applySearch() }
            .navigationBarHidden(true)
            .safeAreaInset(edge: .bottom) {
                if viewModel.state != .error && viewModel.players.isEmpty {
                    Button {
                        sheet = .player(.add())
                    } label: {
                        Text(L10n.addPlayerTitle)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Brand.green)
                    .controlSize(.large)
                    .padding(.horizontal, DS.Spacing.s4)
                    .padding(.vertical, DS.Spacing.s2)
                }
            }
            .task {
                await viewModel.onAppear()
                applyCustomBotSnapshotNavigationIfNeeded()
            }
            .navigationDestination(for: PlayersRoute.self) { route in
                playersNavigationDestination(route)
            }
        }
    }

    @ViewBuilder
    private func playersNavigationDestination(_ route: PlayersRoute) -> some View {
        switch route {
        case .list:
            EmptyView()
        case let .detail(playerId):
            PlayerDetailView(
                player: viewModel.player(id: playerId),
                existingNames: viewModel.players.map(\.name),
                dependencies: dependencies,
                onEdit: {
                    guard let player = viewModel.player(id: playerId) else { return }
                    sheet = .player(.edit(player))
                },
                onArchiveToggle: {
                    actionTask?.cancel()
                    actionTask = Task { await viewModel.archiveToggle(playerId) }
                },
                onSave: { player in
                    actionTask?.cancel()
                    actionTask = Task { await viewModel.save(player) }
                },
                onExportResult: handleExportResult,
                onSelectRecentMatch: { appendMatchDetail(matchId: $0) },
                onCreateCustomBot: { name, metrics in
                    await viewModel.createCustomBot(name: name, metrics: metrics)
                }
            )
        case let .edit(playerId):
            PlayerDetailView(
                player: playerId.flatMap { viewModel.player(id: $0) },
                existingNames: viewModel.players.map(\.name),
                dependencies: dependencies,
                onEdit: {
                    guard let id = playerId, let player = viewModel.player(id: id) else { return }
                    sheet = .player(.edit(player))
                },
                onArchiveToggle: {},
                onSave: { player in
                    actionTask?.cancel()
                    actionTask = Task { await viewModel.save(player) }
                },
                onSelectRecentMatch: { appendMatchDetail(matchId: $0) }
            )
        case let .matchDetail(matchId):
            MatchHistoryDetailScreen(
                matchId: matchId,
                matchRepository: dependencies.matchRepository,
                statsRepository: dependencies.statsRepository,
                onDeleted: {
                    popMatchDetail()
                }
            )
        }
    }

    private func appendMatchDetail(matchId: UUID) {
        path.append(.matchDetail(matchId: matchId))
    }

    private func popMatchDetail() {
        if !path.isEmpty {
            path.removeLast()
        }
    }

    private func selectPlayer(_ playerId: UUID) {
        path.append(.detail(playerId: playerId))
    }

    @ViewBuilder
    private var playersBody: some View {
        if viewModel.state == .loading {
            ProgressView()
                .tint(Brand.green)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, DS.Spacing.s6)
                .accessibilityIdentifier("players_loading")
                .accessibilityLabel(L10n.loading)
        } else if viewModel.state == .error {
            ContentUnavailableView(
                L10n.errorTitle,
                systemImage: "exclamationmark.triangle",
                description: Text(LocalizedStringKey(viewModel.errorMessageKey ?? "error.repository.storage"))
                    .foregroundStyle(Brand.textSecondary)
            )
            .brandScoreboardEmptyState()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.filteredHumans.isEmpty && viewModel.filteredBots.isEmpty {
            if horizontalSizeClass == .regular {
                VStack {
                    ContentUnavailableView(
                        L10n.playersEmptyTitle,
                        systemImage: "person.2",
                        description: Text(L10n.playersEmptyDescription)
                            .foregroundStyle(Brand.textSecondary)
                    )
                    .brandScoreboardEmptyState()
                }
                .frame(maxWidth: 560)
                .padding(.vertical, DS.Spacing.s6)
                .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ContentUnavailableView(
                    L10n.playersEmptyTitle,
                    systemImage: "person.2",
                    description: Text(L10n.playersEmptyDescription)
                        .foregroundStyle(Brand.textSecondary)
                )
                .brandScoreboardEmptyState()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                    playersCardSections
                }
                .padding(.horizontal, DS.Spacing.s4)
                .tabRootScrollChrome()
                .frame(maxWidth: GameplayLayout.contentMaxWidth(horizontalSizeClass: horizontalSizeClass))
                .frame(maxWidth: .infinity)
            }
            .motionTabContentReveal(when: true)
        }
    }

    @ViewBuilder
    private var playersCardSections: some View {
        if !viewModel.filteredHumans.isEmpty {
            sectionHeader(String(localized: "players.section.title"))
            ForEach(viewModel.filteredHumans) { player in
                playerCard(player)
            }
        }
        if !viewModel.filteredBots.isEmpty {
            sectionHeader(String(localized: "players.bots.section.title"))
            ForEach(viewModel.filteredBots) { bot in
                playerCard(bot)
            }
        }
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(Brand.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, DS.Spacing.s2)
    }

    private var playersListHeader: some View {
        VStack(spacing: DS.Spacing.s3) {
            HStack(alignment: .center) {
                BrandRootScreenTitle(title: L10n.playersTitle)
                Spacer(minLength: DS.Spacing.s2)
                if viewModel.state == .error {
                    Button(L10n.retry) {
                        retryTask?.cancel()
                        retryTask = Task { await viewModel.onAppear() }
                    }
                    .font(.subheadline.weight(.semibold))
                    .tint(Brand.green)
                } else {
                    playersToolbarMenu
                }
            }

            searchField
        }
        .padding(.horizontal, DS.Spacing.s4)
        .frame(maxWidth: GameplayLayout.contentMaxWidth(horizontalSizeClass: horizontalSizeClass))
        .frame(maxWidth: .infinity)
        .background(Brand.background)
    }

    private func applyCustomBotSnapshotNavigationIfNeeded() {
        guard !didApplyCustomBotSnapshotNavigation else { return }
        guard ProcessInfo.processInfo.arguments.contains("-snapshot_custom_bot") else { return }
        let bot = viewModel.players.first(where: { $0.isCustomBot && $0.name == DemoSeeder.customBotSnapshotName })
            ?? viewModel.players.first(where: \.isCustomBot)
        guard let bot else { return }
        didApplyCustomBotSnapshotNavigation = true
        path = [.detail(playerId: bot.id)]
    }

    private var playersToolbarMenu: some View {
        Menu {
            Button {
                sheet = .player(.add())
            } label: {
                Label(L10n.addPlayerTitle, systemImage: "person.badge.plus")
            }
            Menu {
                if ProductSurface.showsCustomBots {
                    Button {
                        sheet = .customBot
                    } label: {
                        Label(L10n.customBotAddMenu, systemImage: "slider.horizontal.3")
                    }
                    .accessibilityIdentifier("players_addCustomBot")
                }
                ForEach(BotDifficulty.allCases, id: \.rawValue) { difficulty in
                    Button(difficulty.displayName) {
                        actionTask?.cancel()
                        actionTask = Task { await viewModel.createBot(difficulty) }
                    }
                }
            } label: {
                Label(L10n.addBotTitle, systemImage: "cpu")
            }
        } label: {
            Image(systemName: "plus")
                .font(.headline.weight(.semibold))
                .foregroundStyle(Brand.green)
                .frame(width: 44, height: 44)
                .background(Brand.card, in: Circle())
        }
        .accessibilityLabel(L10n.addPlayerTitle)
    }

    private func playerCard(_ player: EditablePlayer) -> some View {
        PlayersListRow(
            player: player,
            summary: viewModel.summary(for: player.id),
            onSelect: { selectPlayer(player.id) },
            onArchiveToggle: {
                actionTask?.cancel()
                actionTask = Task { await viewModel.archiveToggle(player.id) }
            },
            onDelete: {
                actionTask?.cancel()
                actionTask = Task {
                    if !(await viewModel.delete(player.id)) {
                        deleteBlockedMessage = NSLocalizedString(
                            viewModel.errorMessageKey ?? "players.delete.blocked.message",
                            comment: ""
                        )
                    }
                }
            }
        )
    }

    private var searchField: some View {
        HStack(spacing: DS.Spacing.s2) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Brand.textSecondary)
            TextField(L10n.string("players.search.placeholder"), text: $viewModel.searchText)
                .foregroundStyle(Brand.textPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityLabel(L10n.string("players.search.accessibility"))
        }
        .padding(.horizontal, DS.Spacing.s3)
        .padding(.vertical, DS.Spacing.s2)
        .background(Brand.cardElevated, in: Capsule())
        .accessibilityIdentifier("players_searchField")
    }

    private func handleExportResult(_ result: Result<URL, Error>) {
        switch result {
        case let .success(url):
            sheet = .export(ExportShareItem(url: url))
        case let .failure(error):
            exportErrorKey = (error as? AppError)?.userMessageKey ?? "players.detail.export.error"
        }
    }
}
