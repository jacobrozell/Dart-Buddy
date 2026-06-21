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

struct PlayersRootView: View {
    let dependencies: AppDependencies
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var path: [PlayersRoute] = []
    @StateObject private var viewModel: PlayersListViewModel
    @State private var playerSheet: PlayerSheetPresentation?
    @State private var showsCustomBotSheet = false
    @State private var deleteBlockedMessage: String?
    @State private var exportShareItem: ExportShareItem?
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
        .sheet(isPresented: $showsCustomBotSheet) {
            CustomBotCreationSheet { name, metrics in
                actionTask?.cancel()
                actionTask = Task { await viewModel.createCustomBot(name: name, metrics: metrics) }
            }
        }
        .sheet(item: $playerSheet) { presentation in
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
        .sheet(item: $exportShareItem) { item in
            ActivityShareSheet(items: [item.url]) {
                try? FileManager.default.removeItem(at: item.url)
                exportShareItem = nil
            }
        }
        .onDisappear {
            actionTask?.cancel()
            retryTask?.cancel()
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
                        playerSheet = .add()
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
                    playerSheet = .edit(player)
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
                onSelectRecentMatch: { appendMatchDetail(matchId: $0) }
            )
        case let .edit(playerId):
            PlayerDetailView(
                player: playerId.flatMap { viewModel.player(id: $0) },
                existingNames: viewModel.players.map(\.name),
                dependencies: dependencies,
                onEdit: {
                    guard let id = playerId, let player = viewModel.player(id: id) else { return }
                    playerSheet = .edit(player)
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
                playerSheet = .add()
            } label: {
                Label(L10n.addPlayerTitle, systemImage: "person.badge.plus")
            }
            Menu {
                if ProductSurface.showsCustomBots {
                    Button {
                        showsCustomBotSheet = true
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
        Button {
            selectPlayer(player.id)
        } label: {
            HStack(spacing: DS.Spacing.s3) {
                PlayerAvatarChip(player: player, size: 40)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: DS.Spacing.s2) {
                        Text(player.name)
                            .font(.headline)
                            .foregroundStyle(Brand.textPrimary)
                        if player.isPrimaryPlayer {
                            Text(L10n.playersPrimaryBadge)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Brand.inkOnBright)
                                .padding(.horizontal, DS.Spacing.s2)
                                .padding(.vertical, 2)
                                .background(Brand.green, in: Capsule())
                                .accessibilityHidden(true)
                        }
                    }
                    if let difficulty = player.botDifficulty {
                        BotDifficultyBadge(difficulty: difficulty, prominence: .compact)
                    } else if player.isCustomBot {
                        CustomBotBadge(
                            metrics: CustomBotMetrics(
                                x01Average: player.customX01Average,
                                cricketMPR: player.customCricketMPR
                            ),
                            prominence: .compact
                        )
                    } else if let summary = viewModel.summary(for: player.id), summary.games > 0 {
                        Text(L10n.format("players.list.record", summary.games, summary.wins))
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                    }
                }
                if player.isArchived {
                    Text(L10n.archived).font(.caption).foregroundStyle(Brand.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(DS.Spacing.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            .contentShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(playerRowAccessibilityLabel(player))
        .accessibilityIdentifier(player.botDifficulty == nil ? "player_row_\(player.name)" : "player_row_bot_\(player.id.uuidString)")
        .contextMenu {
            Button {
                actionTask?.cancel()
                actionTask = Task { await viewModel.archiveToggle(player.id) }
            } label: {
                Label(
                    player.isArchived ? L10n.string("players.unarchive") : L10n.string("players.archive"),
                    systemImage: player.isArchived ? "tray.and.arrow.up" : "archivebox"
                )
            }
            Button(role: .destructive) {
                actionTask?.cancel()
                actionTask = Task {
                    if !(await viewModel.delete(player.id)) {
                        deleteBlockedMessage = NSLocalizedString(
                            viewModel.errorMessageKey ?? "players.delete.blocked.message",
                            comment: ""
                        )
                    }
                }
            } label: {
                Label(L10n.delete, systemImage: "trash")
            }
        }
    }

    private func playerRowAccessibilityLabel(_ player: EditablePlayer) -> String {
        var suffix = ""
        if let difficulty = player.botDifficulty {
            suffix += L10n.format("players.row.botSuffix", difficulty.displayName)
        } else if player.isCustomBot {
            suffix += L10n.format(
                "customBot.row.accessibilitySuffix",
                player.customX01Average,
                player.customCricketMPR
            )
        } else if let summary = viewModel.summary(for: player.id), summary.games > 0 {
            suffix += ", \(L10n.format("players.list.record.accessibility", summary.games, summary.wins))"
        }
        if player.isPrimaryPlayer {
            suffix += L10n.string("players.row.primarySuffix")
        }
        if player.isArchived {
            suffix += L10n.string("players.row.archivedSuffix")
        }
        return L10n.format("players.row.accessibilityFormat", player.name, suffix)
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
            exportShareItem = ExportShareItem(url: url)
        case let .failure(error):
            exportErrorKey = (error as? AppError)?.userMessageKey ?? "players.detail.export.error"
        }
    }
}


