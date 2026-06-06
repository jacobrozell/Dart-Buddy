import Foundation

struct SectorHit: Identifiable, Equatable {
    let sector: String
    let count: Int
    var id: String { sector }
}

@MainActor
final class StatisticsViewModel: ObservableObject {
    @Published var modeFilter: ActivityModeFilter = .all
    @Published var period: ActivityPeriod = .all
    /// `nil` = all players; otherwise filters to one player.
    @Published var playerFilter: UUID?
    @Published private(set) var rows: [PlayerStatBreakdown] = []
    @Published private(set) var trendPoints: [StatsTrendPoint] = []
    @Published private(set) var playerOptions: [PlayerSummary] = []
    @Published private(set) var isLoading = false
    @Published private(set) var includesPartialActiveMatch = false

    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository
    private let playerRepository: any PlayerRepository

    init(
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository,
        playerRepository: any PlayerRepository
    ) {
        self.matchRepository = matchRepository
        self.statsRepository = statsRepository
        self.playerRepository = playerRepository
    }

    var selectedPlayerName: String? {
        guard let playerFilter else { return nil }
        return playerOptions.first(where: { $0.id == playerFilter })?.name
    }

    var isAllGames: Bool { modeFilter == .all }
    var isX01: Bool { modeFilter == .x01 }

    var showsTrendChart: Bool {
        isX01 && playerFilter != nil && trendPoints.count >= 2
    }

    /// Sectors hit across all listed players, ordered by board value, for charting.
    var sectorHits: [SectorHit] {
        var totals: [String: Int] = [:]
        for row in rows {
            for (sector, count) in row.hitsBySector {
                let key = StatsSectorOrder.normalizedSectorKey(sector)
                totals[key, default: 0] += count
            }
        }
        return totals
            .map { SectorHit(sector: $0.key, count: $0.value) }
            .sorted {
                StatsSectorOrder.rank($0.sector, mode: modeFilter.matchType ?? .x01)
                    < StatsSectorOrder.rank($1.sector, mode: modeFilter.matchType ?? .x01)
            }
    }

    func load() async {
        isLoading = true
        includesPartialActiveMatch = false
        defer { isLoading = false }
        do {
            playerOptions = try await playerRepository.fetchPlayers(includeArchived: true)
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            if !playerOptions.isEmpty,
               let playerFilter,
               !playerOptions.contains(where: { $0.id == playerFilter }) {
                self.playerFilter = nil
            }
            let activePlayerFilter = self.playerFilter
            let cutoff = periodCutoff()
            let result = try await MatchStatsLoader.load(
                matchRepository: matchRepository,
                statsRepository: statsRepository,
                request: MatchStatsLoadRequest(
                    matchType: modeFilter.matchType,
                    startedAfter: cutoff,
                    participantPlayerId: activePlayerFilter
                )
            )
            var inputs = result.inputs
            var nameById = result.namesById

            if let active = try await matchRepository.fetchActiveMatch(),
               matchesModeFilter(active),
               matchesPeriodFilter(active, cutoff: cutoff),
               try await matchesPlayerFilter(active, playerId: activePlayerFilter),
               let partial = try await MatchStatsLoader.loadPartialActiveMatchInput(
                   matchRepository: matchRepository,
                   statsRepository: statsRepository,
                   activeMatch: active
               ) {
                inputs.append(contentsOf: partial.inputs)
                for (key, name) in partial.namesById {
                    nameById[key] = name
                }
                includesPartialActiveMatch = true
            }

            var breakdowns = StatsService.breakdowns(from: inputs, nameById: nameById)
            if let activePlayerFilter {
                breakdowns = breakdowns.filter { $0.playerId == activePlayerFilter }
                let completedInputs = inputs.filter { !$0.isPartial }
                trendPoints = StatsService.x01TrendPoints(from: completedInputs, playerId: activePlayerFilter)
            } else {
                trendPoints = []
            }
            rows = breakdowns
        } catch {
            rows = []
            trendPoints = []
            includesPartialActiveMatch = false
        }
    }

    private func periodCutoff() -> Date? {
        period.startedAfter
    }

    private func matchesModeFilter(_ active: MatchSummary) -> Bool {
        guard let matchType = modeFilter.matchType else { return true }
        return active.type == matchType
    }

    private func matchesPeriodFilter(_ active: MatchSummary, cutoff: Date?) -> Bool {
        guard let cutoff else { return true }
        return active.startedAt >= cutoff
    }

    private func matchesPlayerFilter(_ active: MatchSummary, playerId: UUID?) async throws -> Bool {
        guard let playerId else { return true }
        let participants = try await matchRepository.fetchParticipants(matchId: active.id)
        return participants.contains { ($0.playerId ?? $0.id) == playerId }
    }
}

enum StatsSectorOrder {
    /// Chart/storage key for misses (matches number-pad `0`).
    static let missSectorKey = "0"

    static func normalizedSectorKey(_ raw: String) -> String {
        raw == "miss" ? missSectorKey : raw
    }

    static func normalizedSectorKey(for dart: X01DartEvent) -> String {
        dart.wasMiss ? missSectorKey : normalizedSectorKey(dart.segmentRaw)
    }

    static func normalizedSectorKey(for touch: CricketDartTouch) -> String {
        touch.wasMiss ? missSectorKey : normalizedSectorKey(touch.targetRaw)
    }

    /// Ordering for charting: X01/Cricket use board sectors; baseball uses inning buckets.
    static func rank(_ sector: String, mode: MatchType) -> Int {
        let sector = normalizedSectorKey(sector)
        if mode == .baseball {
            switch sector {
            case missSectorKey: return 1_000
            case "innerBull": return 900
            case "outerBull", "bull": return 899
            default:
                if let value = Int(sector) { return value }
                return 500
            }
        }
        switch sector {
        case "innerBull": return 100
        case "outerBull", "bull": return 99
        default:
            if let value = Int(sector) { return 50 - value }
            return 200
        }
    }

    static func label(_ sector: String, mode: MatchType) -> String {
        let sector = normalizedSectorKey(sector)
        if mode == .baseball, let inning = Int(sector) {
            return L10n.format("stats.sector.inningFormat", inning)
        }
        switch sector {
        case missSectorKey: return "0"
        case "innerBull": return L10n.string("stats.sector.bull")
        case "outerBull": return "25"
        case "bull": return L10n.string("stats.sector.bull")
        default: return sector
        }
    }

    static func label(_ sector: String) -> String {
        label(sector, mode: .x01)
    }
}
