import SwiftUI

private func playerBotDifficultyColor(_ difficulty: BotDifficulty?) -> Color {
    switch difficulty {
    case .easy: Brand.green
    case .medium: Brand.amber
    case .hard: Brand.red
    case .pro: Brand.proBot
    case .none: Brand.textSecondary
    }
}

struct PlayersRootView: View {
    let dependencies: AppDependencies
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var path: [PlayersRoute] = []
    @StateObject private var viewModel: PlayersListViewModel
    @State private var editingPlayer: EditablePlayer?
    @State private var showEditSheet = false
    @State private var deleteBlockedMessage: String?
    @State private var actionTask: Task<Void, Never>?
    @State private var retryTask: Task<Void, Never>?

    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? 760 : .infinity
    }

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: PlayersListViewModel(
            repository: dependencies.playerRepository,
            pendingMatchPlayerSelections: dependencies.pendingMatchPlayerSelections
        ))
    }

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: DS.Spacing.s3) {
                searchField
                    .padding(.horizontal, DS.Spacing.s4)
                    .frame(maxWidth: contentMaxWidth, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .center)

                Group {
                    if viewModel.state == .error {
                        ContentUnavailableView(
                            L10n.errorTitle,
                            systemImage: "exclamationmark.triangle",
                            description: Text(LocalizedStringKey(viewModel.errorMessageKey ?? "error.repository.storage"))
                        )
                    } else if viewModel.filteredHumans.isEmpty && viewModel.filteredBots.isEmpty {
                        if horizontalSizeClass == .regular {
                            VStack {
                                ContentUnavailableView(
                                    L10n.playersEmptyTitle,
                                    systemImage: "person.2",
                                    description: Text(L10n.playersEmptyDescription)
                                )
                            }
                            .frame(maxWidth: 560)
                            .padding(.vertical, DS.Spacing.s6)
                            .background(DS.ColorRole.backgroundSecondary, in: RoundedRectangle(cornerRadius: DS.Radius.lg))
                        } else {
                            ContentUnavailableView(
                                L10n.playersEmptyTitle,
                                systemImage: "person.2",
                                description: Text(L10n.playersEmptyDescription)
                            )
                        }
                    } else {
                        List {
                            if !viewModel.filteredHumans.isEmpty {
                                Section(L10n.playersSectionTitle) {
                                    ForEach(viewModel.filteredHumans) { player in
                                        playerRow(player)
                                    }
                                }
                            }
                            Section(L10n.botsSectionTitle) {
                                ForEach(viewModel.filteredBots) { bot in
                                    playerRow(bot)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .background(Brand.background.ignoresSafeArea())
            .onChange(of: viewModel.searchText) { _, _ in viewModel.applySearch() }
            .frame(maxWidth: contentMaxWidth, alignment: .center)
            .frame(maxWidth: .infinity, alignment: .center)
            .navigationTitle(L10n.playersTitle)
            .safeAreaInset(edge: .bottom) {
                if viewModel.state != .error && viewModel.players.isEmpty {
                    Button {
                        editingPlayer = nil
                        showEditSheet = true
                    } label: {
                        Text(L10n.addPlayerTitle)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, DS.Spacing.s4)
                    .padding(.vertical, DS.Spacing.s2)
                }
            }
            .toolbar {
                Menu {
                    Button {
                        editingPlayer = nil
                        showEditSheet = true
                    } label: {
                        Label(L10n.addPlayerTitle, systemImage: "person.badge.plus")
                    }
                    Menu {
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
                }
                if viewModel.state == .error {
                    Button(L10n.retry) {
                        retryTask?.cancel()
                        retryTask = Task { await viewModel.onAppear() }
                    }
                }
            }
            .task {
                await viewModel.onAppear()
            }
            .navigationDestination(for: PlayersRoute.self) { route in
                switch route {
                case .list:
                    EmptyView()
                case let .detail(playerId):
                    PlayerDetailView(
                        player: viewModel.player(id: playerId),
                        dependencies: dependencies,
                        onEdit: {
                            editingPlayer = viewModel.player(id: playerId)
                            showEditSheet = true
                        },
                        onArchiveToggle: {
                            actionTask?.cancel()
                            actionTask = Task { await viewModel.archiveToggle(playerId) }
                        }
                    )
                case let .edit(playerId):
                    PlayerDetailView(
                        player: playerId.flatMap { viewModel.player(id: $0) },
                        dependencies: dependencies,
                        onEdit: { showEditSheet = true },
                        onArchiveToggle: {}
                    )
                }
            }
            .sheet(isPresented: $showEditSheet) {
                PlayerEditSheet(
                    viewModel: PlayerEditViewModel(
                        existingNames: viewModel.players.map(\.name),
                        editing: editingPlayer
                    ),
                    existing: editingPlayer,
                    onSave: { player in
                        actionTask?.cancel()
                        actionTask = Task { await viewModel.save(player) }
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
            .onDisappear {
                actionTask?.cancel()
                retryTask?.cancel()
            }
        }
    }

    private func playerRow(_ player: EditablePlayer) -> some View {
        Button {
            path.append(.detail(playerId: player.id))
        } label: {
            HStack(spacing: DS.Spacing.s3) {
                if player.isBot {
                    Image(systemName: "cpu.fill")
                        .foregroundStyle(playerBotDifficultyColor(player.botDifficulty))
                } else {
                    Image(systemName: "location.north.fill")
                        .rotationEffect(.degrees(135))
                        .foregroundStyle(Brand.textSecondary)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    if let difficulty = player.botDifficulty {
                        Text(difficulty.displayName)
                            .font(.caption)
                            .foregroundStyle(playerBotDifficultyColor(difficulty))
                    }
                }
                if player.isArchived {
                    Text(L10n.archived).font(.caption).foregroundStyle(Brand.textSecondary)
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .listRowBackground(Brand.background)
        .listRowSeparatorTint(Brand.cardElevated)
        .swipeActions {
            Button(player.isArchived ? "players.unarchive" : "players.archive") {
                actionTask?.cancel()
                actionTask = Task { await viewModel.archiveToggle(player.id) }
            }.tint(.orange)
            Button(L10n.delete, role: .destructive) {
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
        }
    }

    private func botDifficultyColor(_ difficulty: BotDifficulty?) -> Color {
        playerBotDifficultyColor(difficulty)
    }

    private var searchField: some View {
        HStack(spacing: DS.Spacing.s2) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DS.ColorRole.textSecondary)
            TextField("Search", text: $viewModel.searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, DS.Spacing.s3)
        .padding(.vertical, DS.Spacing.s2)
        .background(DS.ColorRole.backgroundSecondary, in: Capsule())
    }
}

private struct PlayerDetailView: View {
    let player: EditablePlayer?
    let dependencies: AppDependencies
    let onEdit: () -> Void
    let onArchiveToggle: () -> Void

    var body: some View {
        Group {
            if let player {
                PlayerStatsDetailView(player: player, dependencies: dependencies, onEdit: onEdit, onArchiveToggle: onArchiveToggle)
            } else {
                ContentUnavailableView(L10n.playerNotFound, systemImage: "person.crop.circle.badge.exclamationmark")
            }
        }
        .navigationTitle(L10n.playerDetailTitle)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PlayerStatsDetailView: View {
    let player: EditablePlayer
    let onEdit: () -> Void
    let onArchiveToggle: () -> Void
    @StateObject private var viewModel: PlayerDetailViewModel
    @State private var loadTask: Task<Void, Never>?

    init(player: EditablePlayer, dependencies: AppDependencies, onEdit: @escaping () -> Void, onArchiveToggle: @escaping () -> Void) {
        self.player = player
        self.onEdit = onEdit
        self.onArchiveToggle = onArchiveToggle
        _viewModel = StateObject(wrappedValue: PlayerDetailViewModel(
            playerId: player.id,
            playerName: player.name,
            matchRepository: dependencies.matchRepository,
            statsRepository: dependencies.statsRepository
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                HStack {
                    Text(player.name)
                        .font(.largeTitle.weight(.heavy))
                        .foregroundStyle(.white)
                    if player.isBot {
                        Image(systemName: "cpu.fill")
                            .foregroundStyle(playerBotDifficultyColor(player.botDifficulty))
                    }
                    if player.isArchived {
                        Text(L10n.archived).font(.caption).foregroundStyle(Brand.textSecondary)
                    }
                }

                if viewModel.isLoading {
                    ProgressView().tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.s6)
                } else if !viewModel.hasAnyGames {
                    Text("No completed games yet.")
                        .foregroundStyle(Brand.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.s6)
                } else {
                    if let x01 = viewModel.x01, x01.games > 0 {
                        modeSection(title: "X01", stats: x01, isX01: true)
                    }
                    if let cricket = viewModel.cricket, cricket.games > 0 {
                        modeSection(title: "Cricket", stats: cricket, isX01: false)
                    }
                }

                HStack(spacing: DS.Spacing.s3) {
                    Button(L10n.edit, action: onEdit)
                        .buttonStyle(.bordered)
                    if !player.isBot {
                        Button(player.isArchived ? "players.unarchive" : "players.archive", action: onArchiveToggle)
                            .buttonStyle(.bordered)
                            .tint(.orange)
                    }
                }
                .padding(.top, DS.Spacing.s2)
            }
            .padding(.horizontal, DS.Spacing.s4)
            .padding(.bottom, DS.Spacing.s6)
        }
        .background(Brand.background.ignoresSafeArea())
        .task { await viewModel.load() }
        .onDisappear { loadTask?.cancel() }
    }

    @ViewBuilder
    private func modeSection(title: String, stats: PlayerStatBreakdown, isX01: Bool) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: DS.Spacing.s3) {
                StatTile(label: "Games", value: "\(stats.games)")
                StatTile(label: "Wins", value: "\(stats.wins) (\(String(format: "%.0f%%", stats.winPercent)))")
                StatTile(label: "Throws", value: "\(stats.darts)")
                StatTile(label: "Points", value: "\(stats.points)")
                if isX01 {
                    StatTile(label: "Legs Won", value: "\(stats.legs)")
                    StatTile(label: "3-Dart Avg", value: String(format: "%.1f", stats.average3Dart))
                    StatTile(label: "Highest Score", value: "\(stats.highestScore)")
                    StatTile(label: "Checkouts", value: "\(stats.checkouts)")
                    StatTile(label: "Best Checkout", value: stats.highestCheckout > 0 ? "\(stats.highestCheckout)" : "-")
                }
                StatTile(label: "Double %", value: String(format: "%.1f%%", stats.doublePercent))
                StatTile(label: "Triple %", value: String(format: "%.1f%%", stats.triplePercent))
            }

            if !stats.hitsBySector.isEmpty {
                Text("Hits in Sector")
                    .font(.headline)
                    .foregroundStyle(.white)
                SectorHitsView(hitsBySector: stats.hitsBySector, mode: isX01 ? .x01 : .cricket)
            }
        }
        .padding(.bottom, DS.Spacing.s3)
    }
}

private struct StatTile: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s1) {
            Text(label)
                .font(.caption)
                .foregroundStyle(Brand.textSecondary)
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Spacing.s3)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }
}

struct SectorHitsView: View {
    let hitsBySector: [String: Int]
    let mode: MatchType

    private var sorted: [(String, Int)] {
        hitsBySector
            .map { ($0.key, $0.value) }
            .sorted { StatsSectorOrder.rank($0.0, mode: mode) < StatsSectorOrder.rank($1.0, mode: mode) }
    }

    var body: some View {
        let maxCount = max(1, hitsBySector.values.max() ?? 1)
        VStack(spacing: DS.Spacing.s2) {
            ForEach(sorted, id: \.0) { sector, count in
                HStack(spacing: DS.Spacing.s2) {
                    Text(StatsSectorOrder.label(sector))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(width: 44, alignment: .leading)
                    GeometryReader { geo in
                        Capsule()
                            .fill(Brand.green)
                            .frame(width: max(4, geo.size.width * CGFloat(count) / CGFloat(maxCount)))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 14)
                    Text("\(count)")
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                        .frame(width: 40, alignment: .trailing)
                }
            }
        }
        .padding(DS.Spacing.s3)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
    }
}

private struct PlayerEditSheet: View {
    @ObservedObject var viewModel: PlayerEditViewModel
    let existing: EditablePlayer?
    let onSave: (EditablePlayer) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("players.edit.name", text: $viewModel.name)
                    .onChange(of: viewModel.name) { _, _ in viewModel.validate() }
                TextField("players.edit.notes", text: $viewModel.notes, axis: .vertical)
                if let message = viewModel.validationMessage {
                    Text(message).foregroundStyle(.red).font(.footnote)
                }
            }
            .navigationTitle(existing == nil ? L10n.addPlayerTitle : L10n.editPlayerTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.save) {
                        onSave(viewModel.buildPlayer(from: existing))
                        dismiss()
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}
