import Foundation

struct SectorHit: Identifiable, Equatable {
    let sector: String
    let count: Int
    var id: String { sector }
}

@MainActor
final class StatisticsViewModel: ObservableObject {
    enum Period: String, CaseIterable, Identifiable {
        case today, d7, d30, all
        var id: String { rawValue }
        var title: String {
            switch self {
            case .today: L10n.string("stats.period.today")
            case .d7: L10n.string("stats.period.7d")
            case .d30: L10n.string("stats.period.30d")
            case .all: L10n.string("stats.period.all")
            }
        }
    }

    @Published var mode: MatchType = .x01
    @Published var period: Period = .all
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

    var showsTrendChart: Bool {
        mode == .x01 && playerFilter != nil && trendPoints.count >= 2
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
            .sorted { StatsSectorOrder.rank($0.sector, mode: mode) < StatsSectorOrder.rank($1.sector, mode: mode) }
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
                    matchType: mode,
                    startedAfter: cutoff,
                    participantPlayerId: activePlayerFilter
                )
            )
            var inputs = result.inputs
            var nameById = result.namesById

            if let active = try await matchRepository.fetchActiveMatch(),
               active.type == mode,
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
        let calendar = Calendar.current
        switch period {
        case .all:
            return nil
        case .today:
            return calendar.startOfDay(for: Date())
        case .d7:
            return calendar.date(byAdding: .day, value: -7, to: Date())
        case .d30:
            return calendar.date(byAdding: .day, value: -30, to: Date())
        }
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
