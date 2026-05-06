import Foundation

struct EditablePlayer: Identifiable, Equatable {
    let id: UUID
    var name: String
    var isArchived: Bool
    var notes: String
}

@MainActor
final class PlayersListViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var players: [EditablePlayer] = []
    @Published private(set) var filtered: [EditablePlayer] = []
    @Published private(set) var state: String = "loading"

    private let repository: any PlayerRepository

    init(repository: any PlayerRepository) {
        self.repository = repository
    }

    func onAppear() async {
        do {
            let loaded = try await repository.fetchPlayers(includeArchived: true)
            players = loaded.map {
                EditablePlayer(id: $0.id, name: $0.name, isArchived: $0.isArchived, notes: "")
            }
            applySearch()
            state = players.isEmpty ? "empty" : "ready"
        } catch {
            state = "error"
        }
    }

    func applySearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            filtered = players.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } else {
            filtered = players.filter { $0.name.lowercased().contains(query) }
            if filtered.isEmpty { state = "searchNoResults" }
        }
    }

    func archiveToggle(_ id: UUID) async {
        guard let idx = players.firstIndex(where: { $0.id == id }) else { return }
        let nextArchived = !players[idx].isArchived
        do {
            if nextArchived {
                try await repository.archivePlayer(playerId: id)
            } else {
                try await repository.unarchivePlayer(playerId: id)
            }
            players[idx].isArchived = nextArchived
            applySearch()
        } catch {
            state = "error"
        }
    }

    func delete(_ id: UUID) async -> Bool {
        guard let idx = players.firstIndex(where: { $0.id == id }) else { return false }
        do {
            try await repository.deletePlayer(playerId: id)
            players.remove(at: idx)
            applySearch()
            return true
        } catch {
            return false
        }
    }

    func save(_ player: EditablePlayer) async {
        do {
            if players.contains(where: { $0.id == player.id }) {
                _ = try await repository.updatePlayerName(playerId: player.id, name: player.name)
            } else {
                _ = try await repository.createPlayer(name: player.name)
            }
            await onAppear()
        } catch {
            state = "error"
        }
    }

    func player(id: UUID) -> EditablePlayer? {
        players.first(where: { $0.id == id })
    }
}

@MainActor
final class PlayerEditViewModel: ObservableObject {
    @Published var name = ""
    @Published var notes = ""
    @Published private(set) var validationMessage: String?
    @Published private(set) var canSave = false

    private let existingNames: [String]
    private let editingId: UUID?

    init(existingNames: [String], editing: EditablePlayer?) {
        self.existingNames = existingNames
        self.editingId = editing?.id
        self.name = editing?.name ?? ""
        self.notes = editing?.notes ?? ""
        validate()
    }

    func validate() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            validationMessage = "player.validation.nameRequired"
            canSave = false
            return
        }
        if trimmed.count > 32 {
            validationMessage = "player.validation.nameTooLong"
            canSave = false
            return
        }
        let normalized = normalizedName(trimmed)
        if existingNames.contains(where: { normalizedName($0) == normalized }) {
            if editingId == nil {
                validationMessage = "player.validation.duplicateName"
                canSave = false
                return
            }
        }
        validationMessage = nil
        canSave = true
    }

    func buildPlayer(from existing: EditablePlayer?) -> EditablePlayer {
        EditablePlayer(
            id: existing?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            isArchived: existing?.isArchived ?? false,
            notes: notes
        )
    }

    private func normalizedName(_ value: String) -> String {
        value.lowercased().replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
