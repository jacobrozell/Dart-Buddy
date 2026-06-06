import Foundation

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
    @Published private(set) var filteredHumans: [EditablePlayer] = []
    @Published private(set) var filteredBots: [EditablePlayer] = []
    @Published private(set) var state: State = .loading
    @Published private(set) var errorMessageKey: String?

    private let repository: any PlayerRepository
    private let matchRepository: any MatchRepository
    private let pendingMatchPlayerSelections: PendingMatchPlayerSelections
    @Published private(set) var summariesByPlayerId: [UUID: PlayerListSummary] = [:]

    init(
        repository: any PlayerRepository,
        matchRepository: any MatchRepository,
        pendingMatchPlayerSelections: PendingMatchPlayerSelections
    ) {
        self.repository = repository
        self.matchRepository = matchRepository
        self.pendingMatchPlayerSelections = pendingMatchPlayerSelections
    }

    func summary(for playerId: UUID) -> PlayerListSummary? {
        summariesByPlayerId[playerId]
    }

    func onAppear() async {
        errorMessageKey = nil
        do {
            let loaded = try await repository.fetchPlayers(includeArchived: true)
            players = loaded.map(EditablePlayer.from)
            summariesByPlayerId = try await MatchStatsLoader.buildPlayerSummaries(matchRepository: matchRepository)
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
        let matched: [EditablePlayer]
        if query.isEmpty {
            matched = players
        } else {
            matched = players.filter { $0.name.lowercased().contains(query) }
        }
        filteredHumans = matched
            .filter { !$0.isBot }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        filteredBots = matched
            .filter(\.isBot)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        if players.isEmpty {
            state = .empty
        } else if matched.isEmpty {
            state = .searchNoResults
        } else {
            state = .ready
        }
    }

    func createBot(_ difficulty: BotDifficulty) async {
        do {
            _ = try await repository.createBot(difficulty: difficulty)
            await onAppear()
        } catch {
            state = .error
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
        }
    }

    func createCustomBot(name: String, metrics: CustomBotMetrics) async {
        do {
            _ = try await repository.createCustomBot(name: name, metrics: metrics)
            await onAppear()
        } catch {
            state = .error
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
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
                _ = try await repository.updatePlayerProfile(
                    playerId: player.id,
                    name: player.name,
                    avatarStyle: player.avatarStyle,
                    colorToken: player.colorToken,
                    notes: player.notes
                )
                if player.isCustomBot {
                    _ = try await repository.updateCustomBotMetrics(
                        playerId: player.id,
                        metrics: CustomBotMetrics(
                            x01Average: player.customX01Average,
                            cricketMPR: player.customCricketMPR
                        )
                    )
                }
            } else {
                let created = try await repository.createPlayer(name: player.name)
                _ = try await repository.updatePlayerProfile(
                    playerId: created.id,
                    name: player.name,
                    avatarStyle: player.avatarStyle,
                    colorToken: player.colorToken,
                    notes: player.notes
                )
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
