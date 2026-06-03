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
    @State private var path: [PlayersRoute] = []
    @StateObject private var viewModel: PlayersListViewModel
    @State private var playerSheet: PlayerSheetPresentation?
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
            matchRepository: dependencies.matchRepository,
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
                                .foregroundStyle(Brand.textSecondary)
                        )
                        .brandScoreboardEmptyState()
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
                        } else {
                            ContentUnavailableView(
                                L10n.playersEmptyTitle,
                                systemImage: "person.2",
                                description: Text(L10n.playersEmptyDescription)
                                    .foregroundStyle(Brand.textSecondary)
                            )
                            .brandScoreboardEmptyState()
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
            .toolbar {
                Menu {
                    Button {
                        playerSheet = .add()
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
                    .tint(Brand.green)
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
                            guard let player = viewModel.player(id: playerId) else { return }
                            playerSheet = .edit(player)
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
                        onEdit: {
                            guard let id = playerId, let player = viewModel.player(id: id) else { return }
                            playerSheet = .edit(player)
                        },
                        onArchiveToggle: {}
                    )
                }
            }
            .sheet(item: $playerSheet) { presentation in
                PlayerEditSheet(
                    viewModel: PlayerEditViewModel(
                        existingNames: viewModel.players.map(\.name),
                        editing: presentation.editing
                    ),
                    existing: presentation.editing,
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
                PlayerAvatarChip(player: player, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(.headline)
                        .foregroundStyle(Brand.textPrimary)
                    if let difficulty = player.botDifficulty {
                        Text(difficulty.displayName)
                            .font(.caption)
                            .foregroundStyle(PlayerVisualViews.botDifficultyColor(difficulty))
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
            .contentShape(Rectangle())
        }
        .listRowBackground(Brand.background)
        .listRowSeparatorTint(Brand.cardElevated)
        .accessibilityLabel(playerRowAccessibilityLabel(player))
        .accessibilityHint(L10n.string("players.row.accessibilityHint"))
        .accessibilityIdentifier(player.botDifficulty == nil ? "player_row_\(player.name)" : "player_row_bot_\(player.id.uuidString)")
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

    private func playerRowAccessibilityLabel(_ player: EditablePlayer) -> String {
        var suffix = ""
        if let difficulty = player.botDifficulty {
            suffix += L10n.format("players.row.botSuffix", difficulty.displayName)
        } else if let summary = viewModel.summary(for: player.id), summary.games > 0 {
            suffix += ", \(L10n.format("players.list.record", summary.games, summary.wins))"
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
                    .accessibilityLabel(L10n.string("players.edit.name.accessibility"))
                    .accessibilityIdentifier("playerEdit_name")
                    .onChange(of: viewModel.name) { _, _ in viewModel.validate() }
                if !viewModel.isBot {
                    Section(L10n.playersEditAvatar) {
                        AvatarStylePicker(selection: $viewModel.avatarStyle)
                    }
                    Section(L10n.playersEditColor) {
                        PlayerColorTokenPicker(selection: $viewModel.colorToken)
                    }
                }
                TextField("players.edit.notes", text: $viewModel.notes, axis: .vertical)
                    .accessibilityLabel(L10n.string("players.edit.notes.accessibility"))
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
                    .accessibilityLabel(L10n.string("players.edit.save.accessibility"))
                    .accessibilityIdentifier("playerEdit_save")
                }
            }
        }
    }
}
