import Foundation

struct HistoryStanding: Identifiable, Equatable {
    let id: UUID
    let name: String
    let isWinner: Bool
    let sets: Int
    let legs: Int
    let score: Int
}

struct HistoryListRow: Identifiable, Equatable {
    let summary: MatchSummary
    let dateText: String
    let configText: String
    let standings: [HistoryStanding]
    let isFinished: Bool

    var id: UUID { summary.id }

    var accessibilitySummary: String {
        let players = standings.map { standing in
            let role = standing.isWinner ? ", winner" : ""
            return "\(standing.name)\(role), score \(standing.score)"
        }.joined(separator: ". ")
        return L10n.format("history.row.accessibilityFormat", dateText, configText, players)
    }
}

struct HistoryDetailHeader: Equatable {
    let modeText: String
    let winnerText: String
    let dateText: String
    let durationText: String
    let participantsText: String
    let modeSpecificSummaryText: String
}

@MainActor
final class HistoryListViewModel: ObservableObject {
    enum State: Equatable {
        case loading
        case readyFiltered
        case emptyFiltered
        case error
    }

    enum ModeFilter: String, CaseIterable, Identifiable {
        case all
        case x01
        case cricket
        var id: String { rawValue }
    }

    enum DateFilter: String, CaseIterable, Identifiable {
        case d7
        case d30
        case all
        var id: String { rawValue }
        var title: String {
            switch self {
            case .d7: L10n.string("stats.period.7d")
            case .d30: L10n.string("stats.period.30d")
            case .all: L10n.string("stats.period.all")
            }
        }
    }

    @Published var modeFilter: ModeFilter = .all
    @Published var dateFilter: DateFilter = .all
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
            activeMatch = try await matchRepository.fetchActiveMatch()
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
        let matchType: MatchType? = switch modeFilter {
        case .all: nil
        case .x01: .x01
        case .cricket: .cricket
        }
        let startedAfter: Date? = switch dateFilter {
        case .all: nil
        case .d7: Calendar.current.date(byAdding: .day, value: -7, to: Date())
        case .d30: Calendar.current.date(byAdding: .day, value: -30, to: Date())
        }
        return MatchHistoryFilter(
            matchType: matchType,
            startedAfter: startedAfter,
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
                    isFinished: record.summary.status == .completed
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
            return (summary.type == .x01 ? "X01" : "Cricket", standings)
        }

        guard let snapshot = try? await matchRepository.fetchLatestSnapshot(matchId: summary.id),
              let runtime = try? CodablePayloadCoder.decode(MatchRuntimeState.self, from: snapshot.snapshotPayload) else {
            return fallback()
        }

        if let state = runtime.x01State {
            var configParts = ["\(state.config.startScore)", state.config.checkoutMode.displayName]
            if state.config.checkInMode != .straightIn {
                configParts.append(state.config.checkInMode.displayName)
            }
            let format = state.config.legFormat.displayName
            if state.config.setsEnabled {
                let sets = state.config.setsToWin ?? 1
                configParts.append("\(format) \(sets) Set\(sets == 1 ? "" : "s")")
            }
            configParts.append("\(format) \(state.config.legsToWin) Leg\(state.config.legsToWin == 1 ? "" : "s")")
            let configText = "X01 (\(configParts.joined(separator: ", ")))"
            let standings = state.players.map { player in
                HistoryStanding(
                    id: player.playerId,
                    name: nameById[player.playerId] ?? "Player",
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
                    name: nameById[player.playerId] ?? "Player",
                    isWinner: player.playerId == runtime.winnerPlayerId,
                    sets: 0,
                    legs: 0,
                    score: player.score
                )
            }
            return ("Cricket", sortStandings(standings))
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

struct ThrowStatRow: Identifiable, Equatable {
    let id: UUID
    let name: String
    let throwCount: Int
    let doublePercent: Double
    let triplePercent: Double
}

@MainActor
final class HistoryDetailViewModel: ObservableObject {
    @Published private(set) var header: HistoryDetailHeader?
    @Published private(set) var timeline: [String] = []
    @Published private(set) var state: String = "loading"
    @Published private(set) var errorMessageKey: String?
    @Published private(set) var dateText = ""
    @Published private(set) var configText = ""
    @Published private(set) var standings: [HistoryStanding] = []
    @Published private(set) var throwsRows: [ThrowStatRow] = []
    @Published private(set) var breakdowns: [PlayerStatBreakdown] = []
    @Published private(set) var matchType: MatchType = .x01
    private let matchId: UUID
    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository

    var isX01: Bool { matchType == .x01 }

    var resultAccessibilitySummary: String {
        let players = standings.map { standing in
            let role = standing.isWinner ? ", winner" : ""
            return "\(standing.name)\(role), score \(standing.score)"
        }.joined(separator: ". ")
        return L10n.format("history.detail.result.accessibilityFormat", dateText, configText, players)
    }

    init(
        matchId: UUID,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository
    ) {
        self.matchId = matchId
        self.matchRepository = matchRepository
        self.statsRepository = statsRepository
    }

    func onAppear() async {
        errorMessageKey = nil
        do {
            guard let match = try await matchRepository.fetchMatch(matchId: matchId) else {
                timeline = []
                state = "error"
                errorMessageKey = "error.match.notFound"
                return
            }
            let participants = try await matchRepository.fetchParticipants(matchId: matchId)
            let events = try await statsRepository.fetchEvents(matchId: matchId)
            let envelopes = try events
                .map { try CodablePayloadCoder.decode(MatchEventEnvelope.self, from: $0.eventPayload) }
                .sorted { $0.eventIndex < $1.eventIndex }
            let participantNames = Dictionary(
                uniqueKeysWithValues: participants.map { ($0.playerId ?? $0.id, $0.displayNameAtMatchStart) }
            )
            timeline = envelopes.map { envelope in
                switch envelope.payload {
                case let .x01Turn(turn):
                    let name = participantNames[turn.playerId] ?? String(turn.playerId.uuidString.prefix(6))
                    return "Turn \(turn.turnIndex + 1): \(name) +\(turn.appliedTotal)"
                case let .cricketTurn(turn):
                    let name = participantNames[turn.playerId] ?? String(turn.playerId.uuidString.prefix(6))
                    return "Turn \(turn.turnIndex + 1): \(name) +\(turn.totalPointsAdded)"
                }
            }
            matchType = match.type
            header = buildHeader(match: match, participants: participants, envelopes: envelopes)
            dateText = Self.detailDateFormatter.string(from: match.startedAt)
            await computeStandingsAndThrows(
                match: match,
                participants: participants,
                envelopes: envelopes,
                participantNames: participantNames
            )
            breakdowns = StatsService.breakdowns(
                from: [
                    MatchStatsInput(
                        type: match.type,
                        participantKeys: participants.map { $0.playerId ?? $0.id },
                        winnerKey: match.winnerPlayerId,
                        events: envelopes
                    )
                ],
                nameById: participantNames
            )
            state = "ready"
        } catch is CancellationError {
            return
        } catch {
            header = nil
            timeline = []
            state = "error"
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
        }
    }

    private func buildHeader(
        match: MatchSummary,
        participants: [MatchParticipantSummary],
        envelopes: [MatchEventEnvelope]
    ) -> HistoryDetailHeader {
        let winnerName = participants
            .first(where: { $0.playerId == match.winnerPlayerId })?
            .displayNameAtMatchStart ?? NSLocalizedString("common.unknown", comment: "")
        let modeText = match.type == .x01 ? "X01" : "Cricket"
        let dateText = DateFormatter.localizedString(from: match.startedAt, dateStyle: .medium, timeStyle: .short)
        let durationText: String = {
            guard let end = match.endedAt else { return NSLocalizedString("common.unknown", comment: "") }
            let minutes = Int(max(0, end.timeIntervalSince(match.startedAt)) / 60)
            return "\(minutes)m"
        }()
        let participantsText = participants.map(\.displayNameAtMatchStart).joined(separator: ", ")
        let modeSpecificSummaryText: String = {
            switch match.type {
            case .x01:
                let turns = envelopes.compactMap { envelope -> X01TurnEvent? in
                    if case let .x01Turn(turn) = envelope.payload { return turn }
                    return nil
                }
                let total = turns.reduce(0) { $0 + $1.appliedTotal }
                let busts = turns.filter(\.isBust).count
                return "Total scored: \(total) • Busts: \(busts)"
            case .cricket:
                let turns = envelopes.compactMap { envelope -> CricketTurnEvent? in
                    if case let .cricketTurn(turn) = envelope.payload { return turn }
                    return nil
                }
                let points = turns.reduce(0) { $0 + $1.totalPointsAdded }
                return "Total points: \(points) • Turns: \(turns.count)"
            }
        }()
        return HistoryDetailHeader(
            modeText: modeText,
            winnerText: winnerName,
            dateText: dateText,
            durationText: durationText,
            participantsText: participantsText,
            modeSpecificSummaryText: modeSpecificSummaryText
        )
    }

    private static let detailDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter
    }()

    private func computeStandingsAndThrows(
        match: MatchSummary,
        participants: [MatchParticipantSummary],
        envelopes: [MatchEventEnvelope],
        participantNames: [UUID: String]
    ) async {
        if let snapshot = try? await matchRepository.fetchLatestSnapshot(matchId: match.id),
           let runtime = try? CodablePayloadCoder.decode(MatchRuntimeState.self, from: snapshot.snapshotPayload) {
            if let s = runtime.x01State {
                var parts = ["\(s.config.startScore)", s.config.checkoutMode.displayName]
                if s.config.checkInMode != .straightIn {
                    parts.append(s.config.checkInMode.displayName)
                }
                let format = s.config.legFormat.displayName
                if s.config.setsEnabled {
                    let sets = s.config.setsToWin ?? 1
                    parts.append("\(format) \(sets) Set\(sets == 1 ? "" : "s")")
                }
                parts.append("\(format) \(s.config.legsToWin) Leg\(s.config.legsToWin == 1 ? "" : "s")")
                configText = "X01 (\(parts.joined(separator: ", ")))"
                standings = sortStandings(s.players.map {
                    HistoryStanding(id: $0.playerId, name: participantNames[$0.playerId] ?? "Player", isWinner: $0.playerId == runtime.winnerPlayerId, sets: $0.setsWon, legs: $0.legsWon, score: $0.remainingScore)
                })
            } else if let c = runtime.cricketState {
                configText = "Cricket"
                standings = sortStandings(c.players.map {
                    HistoryStanding(id: $0.playerId, name: participantNames[$0.playerId] ?? "Player", isWinner: $0.playerId == runtime.winnerPlayerId, sets: 0, legs: 0, score: $0.score)
                })
            }
        }

        var throwsByPlayer: [UUID: Int] = [:]
        var doublesByPlayer: [UUID: Int] = [:]
        var triplesByPlayer: [UUID: Int] = [:]
        for envelope in envelopes {
            switch envelope.payload {
            case let .x01Turn(turn):
                for dart in turn.darts {
                    throwsByPlayer[turn.playerId, default: 0] += 1
                    if dart.multiplierRaw == DartMultiplier.double.rawValue { doublesByPlayer[turn.playerId, default: 0] += 1 }
                    if dart.multiplierRaw == DartMultiplier.triple.rawValue { triplesByPlayer[turn.playerId, default: 0] += 1 }
                }
            case let .cricketTurn(turn):
                for touch in turn.targetsTouched {
                    throwsByPlayer[turn.playerId, default: 0] += 1
                    if touch.multiplierRaw == DartMultiplier.double.rawValue { doublesByPlayer[turn.playerId, default: 0] += 1 }
                    if touch.multiplierRaw == DartMultiplier.triple.rawValue { triplesByPlayer[turn.playerId, default: 0] += 1 }
                }
            }
        }
        throwsRows = standings.map { standing in
            let total = throwsByPlayer[standing.id] ?? 0
            let doubles = doublesByPlayer[standing.id] ?? 0
            let triples = triplesByPlayer[standing.id] ?? 0
            return ThrowStatRow(
                id: standing.id,
                name: standing.name,
                throwCount: total,
                doublePercent: total > 0 ? Double(doubles) / Double(total) * 100 : 0,
                triplePercent: total > 0 ? Double(triples) / Double(total) * 100 : 0
            )
        }
    }

    func deleteMatch() async -> Bool {
        do {
            try await matchRepository.deleteMatch(matchId: matchId)
            return true
        } catch {
            errorMessageKey = messageKey(for: error, fallback: "error.repository.storage")
            return false
        }
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
