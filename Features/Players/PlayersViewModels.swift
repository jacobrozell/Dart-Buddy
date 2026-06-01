import Foundation

struct EditablePlayer: Identifiable, Equatable {
    let id: UUID
    var name: String
    var isArchived: Bool
    var notes: String
}

@MainActor
final class PlayersListViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case ready
        case empty
        case searchNoResults
        case error
    }

    @Published var searchText = ""
    @Published private(set) var players: [EditablePlayer] = []
    @Published private(set) var filtered: [EditablePlayer] = []
    @Published private(set) var state: State = .loading
    @Published private(set) var errorMessageKey: String?

    private let repository: any PlayerRepository
    private let pendingMatchPlayerSelections: PendingMatchPlayerSelections

    init(repository: any PlayerRepository, pendingMatchPlayerSelections: PendingMatchPlayerSelections) {
        self.repository = repository
        self.pendingMatchPlayerSelections = pendingMatchPlayerSelections
    }

    func onAppear() async {
        errorMessageKey = nil
        do {
            let loaded = try await repository.fetchPlayers(includeArchived: true)
            players = loaded.map {
                EditablePlayer(id: $0.id, name: $0.name, isArchived: $0.isArchived, notes: "")
            }
            applySearch()
            state = players.isEmpty ? .empty : .ready
        } catch is CancellationError {
            return
        } catch {
            state = .error
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
        }
    }

    func applySearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if query.isEmpty {
            filtered = players.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            state = players.isEmpty ? .empty : .ready
        } else {
            filtered = players.filter { $0.name.lowercased().contains(query) }
            state = filtered.isEmpty ? .searchNoResults : .ready
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
            state = .error
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
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
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
            return false
        }
    }

    func save(_ player: EditablePlayer) async {
        do {
            if players.contains(where: { $0.id == player.id }) {
                _ = try await repository.updatePlayerName(playerId: player.id, name: player.name)
            } else {
                let created = try await repository.createPlayer(name: player.name)
                pendingMatchPlayerSelections.enqueueForNextMatchSetup(created.id)
            }
            await onAppear()
        } catch {
            state = .error
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
        }
    }

    func player(id: UUID) -> EditablePlayer? {
        players.first(where: { $0.id == id })
    }

    private func messageKey(for error: Error, fallback: String) -> String {
        if let appError = error as? AppError {
            return appError.userMessageKey
        }
        return fallback
    }
}

@MainActor
final class PlayerDetailViewModel: ObservableObject {
    @Published private(set) var x01: PlayerStatBreakdown?
    @Published private(set) var cricket: PlayerStatBreakdown?
    @Published private(set) var isLoading = true

    private let playerId: UUID
    private let playerName: String
    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository

    init(
        playerId: UUID,
        playerName: String,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository
    ) {
        self.playerId = playerId
        self.playerName = playerName
        self.matchRepository = matchRepository
        self.statsRepository = statsRepository
    }

    var hasAnyGames: Bool {
        (x01?.games ?? 0) + (cricket?.games ?? 0) > 0
    }

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let history = try await matchRepository.fetchHistoryWithParticipants(page: 0, pageSize: 1000)
            var x01Inputs: [MatchStatsInput] = []
            var cricketInputs: [MatchStatsInput] = []

            for record in history {
                let summary = record.summary
                guard summary.status == .completed else { continue }
                let keys = record.participants.map { $0.playerId ?? $0.id }
                guard keys.contains(playerId) else { continue }

                let events = (try? await fetchEvents(matchId: summary.id)) ?? []
                let input = MatchStatsInput(
                    type: summary.type,
                    participantKeys: keys,
                    winnerKey: summary.winnerPlayerId,
                    events: events
                )
                if summary.type == .x01 { x01Inputs.append(input) } else { cricketInputs.append(input) }
            }

            let names = [playerId: playerName]
            x01 = StatsService.breakdowns(from: x01Inputs, nameById: names).first { $0.playerId == playerId }
            cricket = StatsService.breakdowns(from: cricketInputs, nameById: names).first { $0.playerId == playerId }
        } catch {
            x01 = nil
            cricket = nil
        }
    }

    private func fetchEvents(matchId: UUID) async throws -> [MatchEventEnvelope] {
        let events = try await statsRepository.fetchEvents(matchId: matchId)
        return try events
            .map { try CodablePayloadCoder.decode(MatchEventEnvelope.self, from: $0.eventPayload) }
            .sorted { $0.eventIndex < $1.eventIndex }
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
    private let originalNormalizedName: String?

    init(existingNames: [String], editing: EditablePlayer?) {
        self.existingNames = existingNames
        self.editingId = editing?.id
        self.originalNormalizedName = editing.map { Self.normalizedName($0.name) }
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
        let normalized = Self.normalizedName(trimmed)
        let duplicateCount = existingNames.reduce(into: 0) { count, existingName in
            if Self.normalizedName(existingName) == normalized {
                count += 1
            }
        }
        if editingId == nil {
            if duplicateCount > 0 {
                validationMessage = "player.validation.duplicateName"
                canSave = false
                return
            }
        } else {
            let isSameAsOriginal = normalized == originalNormalizedName
            let allowedCount = isSameAsOriginal ? 1 : 0
            if duplicateCount > allowedCount {
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

    private static func normalizedName(_ value: String) -> String {
        value.lowercased().replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
}
