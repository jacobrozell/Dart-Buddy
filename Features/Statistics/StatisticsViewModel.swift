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
            case .today: return "Today"
            case .d7: return "7 Days"
            case .d30: return "30 Days"
            case .all: return "All time"
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
                totals[sector, default: 0] += count
            }
        }
        return totals
            .map { SectorHit(sector: $0.key, count: $0.value) }
            .sorted { StatsSectorOrder.rank($0.sector, mode: mode) < StatsSectorOrder.rank($1.sector, mode: mode) }
    }

    func load() async {
        isLoading = true
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
            let result = try await MatchStatsLoader.load(
                matchRepository: matchRepository,
                statsRepository: statsRepository,
                request: MatchStatsLoadRequest(
                    matchType: mode,
                    startedAfter: periodCutoff(),
                    participantPlayerId: activePlayerFilter
                )
            )
            var breakdowns = StatsService.breakdowns(from: result.inputs, nameById: result.namesById)
            if let activePlayerFilter {
                breakdowns = breakdowns.filter { $0.playerId == activePlayerFilter }
                trendPoints = StatsService.x01TrendPoints(from: result.inputs, playerId: activePlayerFilter)
            } else {
                trendPoints = []
            }
            rows = breakdowns
        } catch {
            rows = []
            trendPoints = []
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
}

enum StatsSectorOrder {
    /// Ordering for charting: bull last for X01, board values descending otherwise.
    static func rank(_ sector: String, mode: MatchType) -> Int {
        switch sector {
        case "innerBull": return 100
        case "outerBull", "bull": return 99
        default:
            if let value = Int(sector) { return 50 - value }
            return 200
        }
    }

    static func label(_ sector: String) -> String {
        switch sector {
        case "innerBull": return "Bull"
        case "outerBull": return "25"
        case "bull": return "Bull"
        default: return sector
        }
    }
}
