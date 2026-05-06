import SwiftUI

struct PlayersRootView: View {
    let dependencies: AppDependencies
    @State private var path: [PlayersRoute] = []
    @StateObject private var viewModel: PlayersListViewModel
    @State private var editingPlayer: EditablePlayer?
    @State private var showEditSheet = false
    @State private var deleteBlockedMessage: String?
    @State private var actionTask: Task<Void, Never>?
    @State private var retryTask: Task<Void, Never>?

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _viewModel = StateObject(wrappedValue: PlayersListViewModel(repository: dependencies.playerRepository))
    }

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if viewModel.state == .error {
                    ContentUnavailableView(
                        L10n.errorTitle,
                        systemImage: "exclamationmark.triangle",
                        description: Text(viewModel.errorMessageKey ?? "error.repository.storage")
                    )
                } else if viewModel.filtered.isEmpty {
                    ContentUnavailableView(L10n.playersEmptyTitle, systemImage: "person.2", description: Text(L10n.playersEmptyDescription))
                } else {
                    List(viewModel.filtered) { player in
                        Button {
                            path.append(.detail(playerId: player.id))
                        } label: {
                            HStack {
                                Text(player.name)
                                if player.isArchived {
                                    Text(L10n.archived).font(.caption).foregroundStyle(DS.ColorRole.textSecondary)
                                }
                            }
                        }
                        .swipeActions {
                            Button(player.isArchived ? "players.unarchive" : "players.archive") {
                                actionTask?.cancel()
                                actionTask = Task { await viewModel.archiveToggle(player.id) }
                            }.tint(.orange)
                            Button(L10n.delete, role: .destructive) {
                                actionTask?.cancel()
                                actionTask = Task {
                                    if !await viewModel.delete(player.id) {
                                        deleteBlockedMessage = NSLocalizedString(
                                            viewModel.errorMessageKey ?? "players.delete.blocked.message",
                                            comment: ""
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText)
            .onChange(of: viewModel.searchText) { _, _ in viewModel.applySearch() }
            .navigationTitle(L10n.playersTitle)
            .toolbar {
                Button {
                    editingPlayer = nil
                    showEditSheet = true
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
}

private struct PlayerDetailView: View {
    let player: EditablePlayer?
    let onEdit: () -> Void
    let onArchiveToggle: () -> Void

    var body: some View {
        Group {
            if let player {
                List {
                    Section(L10n.identitySection) {
                        Text(player.name)
                        Text(player.isArchived ? "players.archived" : "common.active")
                            .foregroundStyle(DS.ColorRole.textSecondary)
                    }
                    Section(L10n.actionsSection) {
                        Button(L10n.edit, action: onEdit)
                        Button(player.isArchived ? "players.unarchive" : "players.archive", action: onArchiveToggle)
                    }
                }
            } else {
                ContentUnavailableView(L10n.playerNotFound, systemImage: "person.crop.circle.badge.exclamationmark")
            }
        }
        .navigationTitle(L10n.playerDetailTitle)
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
