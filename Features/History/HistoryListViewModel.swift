import Foundation

@MainActor
final class HistoryListViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case readyFiltered
        case emptyFiltered
        case error
    }

    @Published var modeFilter: ActivityModeFilter = .all
    @Published var dateFilter: ActivityPeriod = .all
    @Published var playerFilter: UUID?
    @Published private(set) var rows: [HistoryListRow] = []
    @Published private(set) var playerOptions: [PlayerSummary] = []
    @Published private(set) var activeMatch: MatchSummary?
    @Published private(set) var hasMorePages = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var state: State = .loading
    @Published private(set) var errorMessageKey: String?

    private static let pageSize = 25
    private var currentPage = 0

    private let matchRepository: any MatchRepository
    private let playerRepository: any PlayerRepository
    private let logger: (any AppLogger)?

    init(
        matchRepository: any MatchRepository,
        playerRepository: any PlayerRepository,
        logger: (any AppLogger)? = nil
    ) {
        self.matchRepository = matchRepository
        self.playerRepository = playerRepository
        self.logger = logger
    }

    var selectedPlayerName: String? {
        guard let playerFilter else { return nil }
        return playerOptions.first(where: { $0.id == playerFilter })?.name
    }

    var hasActiveFilters: Bool {
        modeFilter != .all || dateFilter != .all || playerFilter != nil
    }

    func onAppear() async {
        await applyFilters()
    }

    func loadMore() async {
        guard hasMorePages, isLoadingMore == false, state != .loading else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let nextPage = currentPage + 1
            let batch = try await fetchHistoryPage(nextPage)
            currentPage = nextPage
            hasMorePages = batch.count == Self.pageSize
            rows.append(contentsOf: await buildRows(from: batch))
        } catch is CancellationError {
            return
        } catch {
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
        }
    }

    func applyFilters() async {
        state = .loading
        errorMessageKey = nil
        rows = []
        currentPage = 0
        hasMorePages = false
        do {
            playerOptions = try await playerRepository.fetchPlayers(includeArchived: true)
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            if !playerOptions.isEmpty,
               let playerFilter,
               !playerOptions.contains(where: { $0.id == playerFilter }) {
                self.playerFilter = nil
            }
            let fetchedActive = try await matchRepository.fetchActiveMatch()
            activeMatch = fetchedActive.flatMap {
                ProductSurface.isMatchTypeReachable($0.type) ? $0 : nil
            }
            let batch = try await PerformanceMonitor.measure(.historyLoad, logger: logger) {
                try await fetchHistoryPage(0)
            }
            rows = await buildRows(from: batch)
            hasMorePages = batch.count == Self.pageSize
            state = rows.isEmpty ? .emptyFiltered : .readyFiltered
        } catch is CancellationError {
            state = rows.isEmpty ? .emptyFiltered : .readyFiltered
        } catch {
            rows = []
            state = .error
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
        }
    }

    private func fetchHistoryPage(_ page: Int) async throws -> [MatchHistoryRecord] {
        try await matchRepository.fetchHistoryWithParticipants(
            page: page,
            pageSize: Self.pageSize,
            filter: repositoryFilter()
        )
    }

    private func repositoryFilter() -> MatchHistoryFilter {
        MatchHistoryFilter(
            matchType: modeFilter.matchType,
            startedAfter: dateFilter.startedAfter,
            participantPlayerId: playerFilter
        )
    }

    private func buildRows(from records: [MatchHistoryRecord]) async -> [HistoryListRow] {
        var built: [HistoryListRow] = []
        for record in records {
            let (configText, standings) = await standingsAndConfig(for: record)
            built.append(
                HistoryListRow(
                    summary: record.summary,
                    dateText: Self.dateFormatter.string(from: record.summary.startedAt),
                    configText: configText,
                    standings: standings,
                    isFinished: record.summary.status == .completed || record.summary.status == .forfeited,
                    isForfeited: record.summary.status == .forfeited
                )
            )
        }
        return built
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter
    }()

    private func standingsAndConfig(for record: MatchHistoryRecord) async -> (String, [HistoryStanding]) {
        if let data = record.historyCardPayload,
           let payload = try? CodablePayloadCoder.decode(MatchHistoryCardPayload.self, from: data) {
            let standings = payload.standings.map {
                HistoryStanding(
                    id: $0.playerId,
                    name: $0.name,
                    isWinner: $0.isWinner,
                    sets: $0.sets,
                    legs: $0.legs,
                    score: $0.score
                )
            }
            return (payload.configText, standings)
        }

        let summary = record.summary
        let nameById = Dictionary(
            uniqueKeysWithValues: record.participants.map { ($0.playerId ?? $0.id, $0.displayNameAtMatchStart) }
        )

        func fallback() -> (String, [HistoryStanding]) {
            let standings = record.participants.map { participant -> HistoryStanding in
                let key = participant.playerId ?? participant.id
                return HistoryStanding(
                    id: key,
                    name: participant.displayNameAtMatchStart,
                    isWinner: key == summary.winnerPlayerId,
                    sets: 0,
                    legs: 0,
                    score: 0
                )
            }
            return (MatchConfigText.modeLabel(for: summary.type), standings)
        }

        guard let snapshot = try? await matchRepository.fetchLatestSnapshot(matchId: summary.id),
              let runtime = try? CodablePayloadCoder.decode(MatchRuntimeState.self, from: snapshot.snapshotPayload) else {
            return fallback()
        }

        if let state = runtime.x01State {
            let configText = MatchConfigText.x01CardConfig(from: state.config)
            let standings = state.players.map { player in
                HistoryStanding(
                    id: player.playerId,
                    name: MatchConfigText.playerName(nameById[player.playerId]),
                    isWinner: player.playerId == runtime.winnerPlayerId,
                    sets: player.setsWon,
                    legs: player.legsWon,
                    score: player.remainingScore
                )
            }
            return (configText, sortStandings(standings))
        }

        if let state = runtime.cricketState {
            let standings = state.players.map { player in
                HistoryStanding(
                    id: player.playerId,
                    name: MatchConfigText.playerName(nameById[player.playerId]),
                    isWinner: player.playerId == runtime.winnerPlayerId,
                    sets: 0,
                    legs: 0,
                    score: player.score
                )
            }
            return (MatchConfigText.modeLabel(for: .cricket), sortStandings(standings))
        }

        if let state = runtime.baseballState {
            let standings = state.players.map { player in
                HistoryStanding(
                    id: player.playerId,
                    name: MatchConfigText.playerName(nameById[player.playerId]),
                    isWinner: player.playerId == runtime.winnerPlayerId,
                    sets: 0,
                    legs: 0,
                    score: player.cumulativeRuns
                )
            }
            return (MatchConfigText.modeLabel(for: .baseball), sortStandings(standings))
        }

        if let state = runtime.killerState {
            let standings = state.players.map { player in
                HistoryStanding(
                    id: player.playerId,
                    name: MatchConfigText.playerName(nameById[player.playerId]),
                    isWinner: player.playerId == runtime.winnerPlayerId,
                    sets: 0,
                    legs: 0,
                    score: player.lives
                )
            }
            return (MatchConfigText.modeLabel(for: .killer), sortStandings(standings))
        }

        if let state = runtime.shanghaiState {
            let standings = state.players.map { player in
                HistoryStanding(
                    id: player.playerId,
                    name: MatchConfigText.playerName(nameById[player.playerId]),
                    isWinner: player.playerId == runtime.winnerPlayerId,
                    sets: 0,
                    legs: 0,
                    score: player.cumulativePoints
                )
            }
            return (MatchConfigText.modeLabel(for: .shanghai), sortStandings(standings))
        }

        return fallback()
    }

    private func sortStandings(_ standings: [HistoryStanding]) -> [HistoryStanding] {
        standings.sorted { lhs, rhs in
            if lhs.isWinner != rhs.isWinner { return lhs.isWinner }
            return lhs.score < rhs.score
        }
    }

    private func messageKey(for error: Error, fallback: String) -> String {
        if let appError = error as? AppError {
            return appError.userMessageKey
        }
        return fallback
    }
}
